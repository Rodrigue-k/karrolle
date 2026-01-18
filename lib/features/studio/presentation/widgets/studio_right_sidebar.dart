import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:karrolle/features/studio/logic/studio_controller.dart';

/// Figma/Canva-style right sidebar with Design and Prototype tabs
class StudioRightSidebar extends StatefulWidget {
  const StudioRightSidebar({super.key});

  @override
  State<StudioRightSidebar> createState() => _StudioRightSidebarState();
}

class _StudioRightSidebarState extends State<StudioRightSidebar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xFF252526),
        border: Border(left: BorderSide(color: Color(0xFF3C3C3C))),
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF3C3C3C))),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF6366F1),
              indicatorWeight: 2,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Design'),
                Tab(text: 'Prototype'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildDesignTab(), _buildPrototypeTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignTab() {
    return ValueListenableBuilder<SelectionState?>(
      valueListenable: StudioController().selectionNotifier,
      builder: (context, selection, child) {
        if (selection == null) {
          return _buildNoSelection();
        }
        return _PropertiesContent(
          key: ValueKey(selection.id),
          selection: selection,
        );
      },
    );
  }

  Widget _buildNoSelection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Canvas'),
          const SizedBox(height: 16),

          // Background color
          _buildPropertyRow('Background', Colors.white),

          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 32,
                  color: Colors.white.withAlpha(30),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select an element to see\nits properties',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(77),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrototypeTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 48,
            color: Colors.white.withAlpha(30),
          ),
          const SizedBox(height: 12),
          Text(
            'Prototype',
            style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Create interactive flows\nbetween frames',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withAlpha(51), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white38,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPropertyRow(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const Spacer(),
        Text(
          '#FFFFFF',
          style: TextStyle(
            color: Colors.white.withAlpha(77),
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _PropertiesContent extends StatefulWidget {
  final SelectionState selection;

  const _PropertiesContent({super.key, required this.selection});

  @override
  State<_PropertiesContent> createState() => _PropertiesContentState();
}

class _PropertiesContentState extends State<_PropertiesContent> {
  late TextEditingController _xCtrl;
  late TextEditingController _yCtrl;
  late TextEditingController _wCtrl;
  late TextEditingController _hCtrl;
  late TextEditingController _textCtrl;
  late TextEditingController _fontCtrl;

  @override
  void initState() {
    super.initState();
    _xCtrl = TextEditingController(text: widget.selection.x.toString());
    _yCtrl = TextEditingController(text: widget.selection.y.toString());
    _wCtrl = TextEditingController(text: widget.selection.w.toString());
    _hCtrl = TextEditingController(text: widget.selection.h.toString());
    _textCtrl = TextEditingController(text: widget.selection.text);
    _fontCtrl = TextEditingController(
      text: widget.selection.fontSize.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(_PropertiesContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection.id != widget.selection.id) {
      _xCtrl.text = widget.selection.x.toString();
      _yCtrl.text = widget.selection.y.toString();
      _wCtrl.text = widget.selection.w.toString();
      _hCtrl.text = widget.selection.h.toString();
      _textCtrl.text = widget.selection.text;
      _fontCtrl.text = widget.selection.fontSize.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _xCtrl.dispose();
    _yCtrl.dispose();
    _wCtrl.dispose();
    _hCtrl.dispose();
    _textCtrl.dispose();
    _fontCtrl.dispose();
    super.dispose();
  }

  void _submitRect() {
    final x = int.tryParse(_xCtrl.text) ?? widget.selection.x;
    final y = int.tryParse(_yCtrl.text) ?? widget.selection.y;
    final w = int.tryParse(_wCtrl.text) ?? widget.selection.w;
    final h = int.tryParse(_hCtrl.text) ?? widget.selection.h;
    StudioController().updateSelectionRect(x, y, w, h);
  }

  void _submitText() {
    StudioController().updateSelectionText(_textCtrl.text);
  }

  void _submitFont() {
    final size = double.tryParse(_fontCtrl.text) ?? widget.selection.fontSize;
    StudioController().updateSelectionFontSize(size);
  }

  void _showColorPicker() {
    Color currentColor = Color(widget.selection.color);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Pick a color',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) => currentColor = color,
            enableAlpha: true,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              StudioController().updateSelectionColor(currentColor.value);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Object type header
        Row(
          children: [
            Icon(
              _getTypeIcon(widget.selection.type),
              size: 16,
              color: const Color(0xFF818CF8),
            ),
            const SizedBox(width: 8),
            Text(
              _getTypeName(widget.selection.type),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('Position'),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildCompactField(
                'X',
                _xCtrl,
                onSubmitted: (_) => _submitRect(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactField(
                'Y',
                _yCtrl,
                onSubmitted: (_) => _submitRect(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        _buildSectionHeader('Size'),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildCompactField(
                'W',
                _wCtrl,
                onSubmitted: (_) => _submitRect(),
                enabled: widget.selection.type != LayerType.text,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactField(
                'H',
                _hCtrl,
                onSubmitted: (_) => _submitRect(),
                enabled: widget.selection.type != LayerType.text,
              ),
            ),
            const SizedBox(width: 8),
            // Aspect ratio lock
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF3C3C3C),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.link, size: 14, color: Colors.white54),
            ),
          ],
        ),

        if (widget.selection.type == LayerType.text) ...[
          const SizedBox(height: 20),
          _buildSectionHeader('Typography'),
          const SizedBox(height: 10),

          // Font size
          Row(
            children: [
              const Icon(Icons.format_size, size: 14, color: Colors.white54),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactField(
                  'Size',
                  _fontCtrl,
                  onSubmitted: (_) => _submitFont(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Text content
          TextField(
            controller: _textCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter text...',
              hintStyle: TextStyle(color: Colors.white.withAlpha(51)),
              fillColor: const Color(0xFF3C3C3C),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onSubmitted: (_) => _submitText(),
            onEditingComplete: _submitText,
          ),
        ],

        const SizedBox(height: 20),
        _buildSectionHeader('Fill'),
        const SizedBox(height: 10),

        _buildColorRow(widget.selection.color),

        const SizedBox(height: 20),
        _buildSectionHeader('Effects'),
        const SizedBox(height: 10),

        // Opacity slider
        Row(
          children: [
            const Icon(Icons.opacity, size: 14, color: Colors.white54),
            const SizedBox(width: 8),
            const Text(
              'Opacity',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const Spacer(),
            const Text(
              '100%',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white38,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCompactField(
    String label,
    TextEditingController ctrl, {
    required ValueChanged<String> onSubmitted,
    bool enabled = true,
  }) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF3C3C3C),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white54 : Colors.white24,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              enabled: enabled,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.white38,
                fontSize: 12,
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4),
                isDense: true,
              ),
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(int colorValue) {
    final color = Color(colorValue);
    return InkWell(
      onTap: _showColorPicker,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF3C3C3C),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '#${colorValue.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Text(
              '${((color.alpha / 255) * 100).toInt()}%',
              style: TextStyle(color: Colors.white.withAlpha(77), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(LayerType type) {
    switch (type) {
      case LayerType.rectangle:
        return Icons.crop_square_rounded;
      case LayerType.text:
        return Icons.text_fields;
      case LayerType.image:
        return Icons.image_outlined;
      default:
        return Icons.layers;
    }
  }

  String _getTypeName(LayerType type) {
    switch (type) {
      case LayerType.rectangle:
        return 'Rectangle';
      case LayerType.text:
        return 'Text';
      case LayerType.image:
        return 'Image';
      default:
        return 'Layer';
    }
  }
}
