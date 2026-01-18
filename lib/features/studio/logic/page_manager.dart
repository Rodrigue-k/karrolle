import 'package:flutter/material.dart';

/// Represents a single page/slide in the document
class DocumentPage {
  final String id;
  String name;
  final DateTime createdAt;

  // Page-specific data would be stored in the native engine
  // This is just metadata for the Flutter UI

  DocumentPage({required this.id, required this.name, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  DocumentPage copyWith({String? name}) {
    return DocumentPage(id: id, name: name ?? this.name, createdAt: createdAt);
  }
}

/// Manages multiple pages in a document
class PageManager {
  static final PageManager _instance = PageManager._internal();
  factory PageManager() => _instance;
  PageManager._internal() {
    // Initialize with one default page
    _pages.add(DocumentPage(id: _generateId(), name: 'Page 1'));
    _currentPageIndex = 0;
  }

  final List<DocumentPage> _pages = [];
  int _currentPageIndex = 0;

  final ValueNotifier<List<DocumentPage>> pagesNotifier = ValueNotifier([]);
  final ValueNotifier<int> currentPageNotifier = ValueNotifier(0);

  List<DocumentPage> get pages => List.unmodifiable(_pages);
  int get currentPageIndex => _currentPageIndex;
  DocumentPage? get currentPage =>
      _pages.isNotEmpty && _currentPageIndex < _pages.length
      ? _pages[_currentPageIndex]
      : null;
  int get pageCount => _pages.length;

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _notifyChanges() {
    pagesNotifier.value = List.from(_pages);
    currentPageNotifier.value = _currentPageIndex;
  }

  /// Add a new page
  DocumentPage addPage({String? name}) {
    final newPage = DocumentPage(
      id: _generateId(),
      name: name ?? 'Page ${_pages.length + 1}',
    );
    _pages.add(newPage);
    _notifyChanges();
    return newPage;
  }

  /// Insert a page at specific index
  DocumentPage insertPage(int index, {String? name}) {
    final newPage = DocumentPage(
      id: _generateId(),
      name: name ?? 'Page ${_pages.length + 1}',
    );
    _pages.insert(index.clamp(0, _pages.length), newPage);
    _notifyChanges();
    return newPage;
  }

  /// Remove a page by index
  bool removePage(int index) {
    if (_pages.length <= 1) return false; // Keep at least one page
    if (index < 0 || index >= _pages.length) return false;

    _pages.removeAt(index);

    // Adjust current page index if needed
    if (_currentPageIndex >= _pages.length) {
      _currentPageIndex = _pages.length - 1;
    }

    _notifyChanges();
    return true;
  }

  /// Go to a specific page
  bool goToPage(int index) {
    if (index < 0 || index >= _pages.length) return false;
    if (index == _currentPageIndex) return true;

    // TODO: Save current page state to native engine
    // TODO: Load new page state from native engine

    _currentPageIndex = index;
    _notifyChanges();
    return true;
  }

  /// Rename a page
  void renamePage(int index, String newName) {
    if (index < 0 || index >= _pages.length) return;
    _pages[index] = _pages[index].copyWith(name: newName);
    _notifyChanges();
  }

  /// Duplicate a page
  DocumentPage? duplicatePage(int index) {
    if (index < 0 || index >= _pages.length) return null;

    final original = _pages[index];
    final duplicate = DocumentPage(
      id: _generateId(),
      name: '${original.name} (copy)',
    );

    // TODO: Copy page content in native engine

    _pages.insert(index + 1, duplicate);
    _notifyChanges();
    return duplicate;
  }

  /// Reorder pages
  void reorderPage(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _pages.length) return;
    if (newIndex < 0 || newIndex >= _pages.length) return;
    if (oldIndex == newIndex) return;

    final page = _pages.removeAt(oldIndex);
    _pages.insert(newIndex, page);

    // Update current page index
    if (_currentPageIndex == oldIndex) {
      _currentPageIndex = newIndex;
    } else if (oldIndex < _currentPageIndex && newIndex >= _currentPageIndex) {
      _currentPageIndex--;
    } else if (oldIndex > _currentPageIndex && newIndex <= _currentPageIndex) {
      _currentPageIndex++;
    }

    _notifyChanges();
  }

  /// Navigate to next page
  bool nextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      return goToPage(_currentPageIndex + 1);
    }
    return false;
  }

  /// Navigate to previous page
  bool previousPage() {
    if (_currentPageIndex > 0) {
      return goToPage(_currentPageIndex - 1);
    }
    return false;
  }

  /// Clear all pages and reset
  void reset() {
    _pages.clear();
    _pages.add(DocumentPage(id: _generateId(), name: 'Page 1'));
    _currentPageIndex = 0;
    _notifyChanges();
  }
}
