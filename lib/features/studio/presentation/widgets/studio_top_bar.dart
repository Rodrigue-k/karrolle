import 'package:flutter/material.dart';

/// Top bar similar to Figma/Canva with logo, menus, and actions
class StudioTopBar extends StatelessWidget {
  final String documentName;
  final VoidCallback? onToggleLeftSidebar;
  final VoidCallback? onToggleRightSidebar;

  const StudioTopBar({
    super.key,
    required this.documentName,
    this.onToggleLeftSidebar,
    this.onToggleRightSidebar,
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
          _buildMenuButton('File', [
            _MenuItem('New', Icons.add, () {}),
            _MenuItem('Open', Icons.folder_open, () {}),
            _MenuItem('Save', Icons.save, () {}),
            _MenuItem('Export', Icons.download, () {}),
          ]),
          _buildMenuButton('Edit', []),
          _buildMenuButton('View', []),

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

          // Action Buttons
          _buildActionButton(
            icon: Icons.undo,
            tooltip: 'Undo (Ctrl+Z)',
            onTap: () {},
          ),
          _buildActionButton(
            icon: Icons.redo,
            tooltip: 'Redo (Ctrl+Y)',
            onTap: () {},
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

          // Share / Export
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

  Widget _buildMenuButton(String label, List<_MenuItem> items) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          child: Transform.flip(
            flipX: flipHorizontal,
            child: Icon(icon, size: 18, color: Colors.white60),
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
