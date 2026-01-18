import 'package:flutter/material.dart';
import 'package:karrolle/bridge/native_api.dart';
import 'package:karrolle/features/studio/logic/studio_controller.dart';

/// Figma-style vertical toolbar with tool icons
class StudioToolbar extends StatefulWidget {
  const StudioToolbar({super.key});

  @override
  State<StudioToolbar> createState() => _StudioToolbarState();
}

class _StudioToolbarState extends State<StudioToolbar> {
  int _selectedTool = 0; // 0=select, 1=frame, 2=shape, 3=text, 4=hand

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        border: Border(right: BorderSide(color: Color(0xFF3C3C3C))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Move/Select Tool
          _buildToolButton(
            icon: Icons.near_me,
            tooltip: 'Move (V)',
            isSelected: _selectedTool == 0,
            onTap: () => setState(() => _selectedTool = 0),
          ),

          // Frame Tool
          _buildToolButton(
            icon: Icons.crop_free,
            tooltip: 'Frame (F)',
            isSelected: _selectedTool == 1,
            onTap: () => setState(() => _selectedTool = 1),
          ),

          const SizedBox(height: 4),
          _buildDivider(),
          const SizedBox(height: 4),

          // Shape Tools (with dropdown)
          _buildShapeToolButton(),

          // Text Tool
          _buildToolButton(
            icon: Icons.text_fields,
            tooltip: 'Text (T)',
            isSelected: _selectedTool == 3,
            onTap: () {
              setState(() => _selectedTool = 3);
              _addText();
            },
          ),

          // Pen Tool
          _buildToolButton(
            icon: Icons.edit,
            tooltip: 'Pen (P)',
            isSelected: _selectedTool == 4,
            onTap: () => setState(() => _selectedTool = 4),
          ),

          const SizedBox(height: 4),
          _buildDivider(),
          const SizedBox(height: 4),

          // Hand Tool
          _buildToolButton(
            icon: Icons.pan_tool_alt,
            tooltip: 'Hand (H)',
            isSelected: _selectedTool == 5,
            onTap: () => setState(() => _selectedTool = 5),
          ),

          // Comment Tool
          _buildToolButton(
            icon: Icons.mode_comment_outlined,
            tooltip: 'Comment (C)',
            isSelected: _selectedTool == 6,
            onTap: () => setState(() => _selectedTool = 6),
          ),

          const Spacer(),

          // Help
          _buildToolButton(
            icon: Icons.help_outline,
            tooltip: 'Help',
            onTap: () {},
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildShapeToolButton() {
    return PopupMenuButton<String>(
      offset: const Offset(48, 0),
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (value) {
        setState(() => _selectedTool = 2);
        _addShape(value);
      },
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: _selectedTool == 2
              ? const Color(0xFF4F46E5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.crop_square_rounded,
              size: 20,
              color: _selectedTool == 2 ? Colors.white : Colors.white60,
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Icon(
                Icons.arrow_drop_down,
                size: 10,
                color: Colors.white.withAlpha(102),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildShapeMenuItem('rectangle', Icons.crop_square, 'Rectangle'),
        _buildShapeMenuItem('ellipse', Icons.circle_outlined, 'Ellipse'),
        _buildShapeMenuItem('line', Icons.remove, 'Line'),
        _buildShapeMenuItem('polygon', Icons.hexagon_outlined, 'Polygon'),
        _buildShapeMenuItem('star', Icons.star_border, 'Star'),
      ],
    );
  }

  PopupMenuItem<String> _buildShapeMenuItem(
    String value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white60),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 24, height: 1, color: const Color(0xFF4A4A4A));
  }

  void _addShape(String type) {
    switch (type) {
      case 'rectangle':
        NativeApi.addRect(200, 200, 120, 80, 0xFF6366F1);
        break;
      case 'ellipse':
        // TODO: Add ellipse support in engine
        NativeApi.addRect(200, 200, 100, 100, 0xFF10B981);
        break;
      case 'line':
        // TODO: Add line support in engine
        NativeApi.addRect(200, 200, 150, 4, 0xFFEF4444);
        break;
      default:
        NativeApi.addRect(200, 200, 100, 100, 0xFF8B5CF6);
    }
    StudioController().refreshLayers();
  }

  void _addText() {
    NativeApi.addText(200, 200, 'Add a heading', 0xFF1A1A1A, 48.0);
    StudioController().refreshLayers();
  }
}
