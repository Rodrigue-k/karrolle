import 'package:flutter/material.dart';
import 'package:karrolle/features/studio/logic/history_manager.dart';
import 'package:karrolle/features/studio/logic/export_service.dart';
import 'package:karrolle/features/studio/logic/studio_controller.dart';

/// Top bar similar to Figma/Canva with logo, menus, and actions
class StudioTopBar extends StatelessWidget {
  final String documentName;
  final VoidCallback? onToggleLeftSidebar;
  final VoidCallback? onToggleRightSidebar;
  final VoidCallback? onNewDocument;
  final VoidCallback? onOpenDocument;
  final VoidCallback? onSaveDocument;
  final int documentWidth;
  final int documentHeight;

  const StudioTopBar({
    super.key,
    required this.documentName,
    this.onToggleLeftSidebar,
    this.onToggleRightSidebar,
    this.onNewDocument,
    this.onOpenDocument,
    this.onSaveDocument,
    this.documentWidth = 1920,
    this.documentHeight = 1080,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        border: Border(bottom: BorderSide(color: Color(0xFF3C3C3C))),
      ),
      child: Row(
        children: [
          // Logo / Home
          _buildLogoSection(),

          // Divider
          _buildVerticalDivider(),

          // File Menu
          _buildMenuButton(context, 'File', [
            _MenuItem('New', Icons.add, onNewDocument ?? () {}),
            _MenuItem('Open', Icons.folder_open, onOpenDocument ?? () {}),
            _MenuItem('Save', Icons.save, onSaveDocument ?? () {}),
            _MenuItem(
              'Import PPTX',
              Icons.upload_file,
              () => StudioController().importPptx(),
            ),
            _MenuItem('Export as PNG', Icons.image, () => _exportPng(context)),
            _MenuItem(
              'Export as PDF',
              Icons.picture_as_pdf,
              () => _exportPdf(context),
            ),
          ]),
          _buildMenuButton(context, 'Edit', [
            _MenuItem('Undo', Icons.undo, () => HistoryManager().undo()),
            _MenuItem('Redo', Icons.redo, () => HistoryManager().redo()),
          ]),
          _buildMenuButton(context, 'View', [
            _MenuItem(
              'Toggle Left Panel',
              Icons.view_sidebar,
              onToggleLeftSidebar ?? () {},
            ),
            _MenuItem(
              'Toggle Right Panel',
              Icons.view_sidebar_outlined,
              onToggleRightSidebar ?? () {},
            ),
          ]),

          const Spacer(),

          // Document Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF3C3C3C),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  documentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 14, color: Colors.white54),
              ],
            ),
          ),

          const Spacer(),

          // Undo/Redo with state awareness
          ValueListenableBuilder<bool>(
            valueListenable: HistoryManager().canUndoNotifier,
            builder: (context, canUndo, _) {
              return _buildActionButton(
                icon: Icons.undo,
                tooltip: HistoryManager().undoDescription ?? 'Undo (Ctrl+Z)',
                onTap: canUndo ? () => HistoryManager().undo() : null,
                enabled: canUndo,
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: HistoryManager().canRedoNotifier,
            builder: (context, canRedo, _) {
              return _buildActionButton(
                icon: Icons.redo,
                tooltip: HistoryManager().redoDescription ?? 'Redo (Ctrl+Y)',
                onTap: canRedo ? () => HistoryManager().redo() : null,
                enabled: canRedo,
              );
            },
          ),

          _buildVerticalDivider(),

          // Toggle panels
          _buildActionButton(
            icon: Icons.view_sidebar,
            tooltip: 'Toggle Left Panel',
            onTap: onToggleLeftSidebar,
          ),
          _buildActionButton(
            icon: Icons.view_sidebar_outlined,
            tooltip: 'Toggle Right Panel',
            onTap: onToggleRightSidebar,
            flipHorizontal: true,
          ),

          _buildVerticalDivider(),

          // Export button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 40),
              color: const Color(0xFF2D2D2D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (value) {
                if (value == 'png') _exportPng(context);
                if (value == 'pdf') _exportPdf(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Export',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'png',
                  child: Row(
                    children: [
                      Icon(Icons.image, size: 16, color: Colors.white60),
                      SizedBox(width: 12),
                      Text('PNG Image', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        size: 16,
                        color: Colors.white60,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'PDF Document',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Share button
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share, size: 16),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // User Avatar
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF6366F1),
              child: Text(
                'K',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportPng(BuildContext context) async {
    final result = await ExportService().exportAsPng(
      width: documentWidth,
      height: documentHeight,
      suggestedName: '$documentName.png',
    );
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported to: $result'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _exportPdf(BuildContext context) async {
    final result = await ExportService().exportAsPdf(
      width: documentWidth,
      height: documentHeight,
      suggestedName: '$documentName.pdf',
    );
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported to: $result'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Widget _buildLogoSection() {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.dashboard_rounded,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFF4A4A4A),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String label,
    List<_MenuItem> items,
  ) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (value) {
        final item = items.firstWhere((i) => i.label == value);
        item.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
      itemBuilder: (context) => items
          .map(
            (item) => PopupMenuItem<String>(
              value: item.label,
              child: Row(
                children: [
                  Icon(item.icon, size: 16, color: Colors.white60),
                  const SizedBox(width: 12),
                  Text(
                    item.label,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    bool flipHorizontal = false,
    bool enabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          child: Transform.flip(
            flipX: flipHorizontal,
            child: Icon(
              icon,
              size: 18,
              color: enabled ? Colors.white60 : Colors.white24,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  _MenuItem(this.label, this.icon, this.onTap);
}
