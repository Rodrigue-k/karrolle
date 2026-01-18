import 'package:flutter/material.dart';

/// Base class for all undoable commands
abstract class Command {
  final String description;

  Command(this.description);

  /// Execute the command
  void execute();

  /// Undo the command
  void undo();
}

/// Command for moving an object
class MoveCommand extends Command {
  final int objectId;
  final int oldX, oldY;
  final int newX, newY;
  final void Function(int, int, int, int, int) setRectFn;
  final int w, h;

  MoveCommand({
    required this.objectId,
    required this.oldX,
    required this.oldY,
    required this.newX,
    required this.newY,
    required this.w,
    required this.h,
    required this.setRectFn,
  }) : super('Move object');

  @override
  void execute() {
    setRectFn(objectId, newX, newY, w, h);
  }

  @override
  void undo() {
    setRectFn(objectId, oldX, oldY, w, h);
  }
}

/// Command for resizing an object
class ResizeCommand extends Command {
  final int objectId;
  final int oldX, oldY, oldW, oldH;
  final int newX, newY, newW, newH;
  final void Function(int, int, int, int, int) setRectFn;

  ResizeCommand({
    required this.objectId,
    required this.oldX,
    required this.oldY,
    required this.oldW,
    required this.oldH,
    required this.newX,
    required this.newY,
    required this.newW,
    required this.newH,
    required this.setRectFn,
  }) : super('Resize object');

  @override
  void execute() {
    setRectFn(objectId, newX, newY, newW, newH);
  }

  @override
  void undo() {
    setRectFn(objectId, oldX, oldY, oldW, oldH);
  }
}

/// Command for changing color
class ColorCommand extends Command {
  final int objectId;
  final int oldColor;
  final int newColor;
  final void Function(int, int) setColorFn;

  ColorCommand({
    required this.objectId,
    required this.oldColor,
    required this.newColor,
    required this.setColorFn,
  }) : super('Change color');

  @override
  void execute() {
    setColorFn(objectId, newColor);
  }

  @override
  void undo() {
    setColorFn(objectId, oldColor);
  }
}

/// Command for adding an object
class AddObjectCommand extends Command {
  final int objectId;
  final void Function() addFn;
  final void Function(int) removeFn;

  AddObjectCommand({
    required this.objectId,
    required this.addFn,
    required this.removeFn,
    required String objectType,
  }) : super('Add $objectType');

  @override
  void execute() {
    addFn();
  }

  @override
  void undo() {
    removeFn(objectId);
  }
}

/// Command for removing an object (stores all object data for restoration)
class RemoveObjectCommand extends Command {
  final int objectId;
  final Map<String, dynamic> objectData;
  final void Function(Map<String, dynamic>) restoreFn;
  final void Function(int) removeFn;

  RemoveObjectCommand({
    required this.objectId,
    required this.objectData,
    required this.restoreFn,
    required this.removeFn,
  }) : super('Delete object');

  @override
  void execute() {
    removeFn(objectId);
  }

  @override
  void undo() {
    restoreFn(objectData);
  }
}

/// History manager for undo/redo operations
class HistoryManager {
  static final HistoryManager _instance = HistoryManager._internal();
  factory HistoryManager() => _instance;
  HistoryManager._internal();

  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];

  static const int maxHistorySize = 50;

  final ValueNotifier<bool> canUndoNotifier = ValueNotifier(false);
  final ValueNotifier<bool> canRedoNotifier = ValueNotifier(false);

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Execute a command and add it to history
  void executeCommand(Command command) {
    command.execute();
    _undoStack.add(command);
    _redoStack.clear();

    // Limit history size
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }

    _updateNotifiers();
  }

  /// Add a command to history without executing (for external changes)
  void addToHistory(Command command) {
    _undoStack.add(command);
    _redoStack.clear();

    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }

    _updateNotifiers();
  }

  /// Undo the last command
  void undo() {
    if (_undoStack.isEmpty) return;

    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);

    _updateNotifiers();
  }

  /// Redo the last undone command
  void redo() {
    if (_redoStack.isEmpty) return;

    final command = _redoStack.removeLast();
    command.execute();
    _undoStack.add(command);

    _updateNotifiers();
  }

  /// Clear all history
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _updateNotifiers();
  }

  void _updateNotifiers() {
    canUndoNotifier.value = canUndo;
    canRedoNotifier.value = canRedo;
  }

  /// Get description of next undo action
  String? get undoDescription =>
      _undoStack.isNotEmpty ? _undoStack.last.description : null;

  /// Get description of next redo action
  String? get redoDescription =>
      _redoStack.isNotEmpty ? _redoStack.last.description : null;
}
