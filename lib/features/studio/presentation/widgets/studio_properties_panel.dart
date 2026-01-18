import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:karrolle/features/studio/logic/studio_controller.dart';

class StudioPropertiesPanel extends StatelessWidget {
  const StudioPropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF252526),
        border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: ValueListenableBuilder<SelectionState?>(
              valueListenable: StudioController().selectionNotifier,
              builder: (context, selection, child) {
                if (selection == null) {
                  return _buildNoSelection();
                }
                return PropertiesForm(
                  key: ValueKey(selection.id),
                  selection: selection,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.tune, size: 18, color: Colors.white70),
          SizedBox(width: 8),
          Text(
            "Properties",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSelection() {
    return const Center(
      child: Text(
        "No object selected",
        style: TextStyle(color: Colors.white30, fontSize: 13),
      ),
    );
  }
}

class PropertiesForm extends StatefulWidget {
  final SelectionState selection;

  const PropertiesForm({super.key, required this.selection});

  @override
  State<PropertiesForm> createState() => _PropertiesFormState();
}

class _PropertiesFormState extends State<PropertiesForm> {
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
      text: widget.selection.fontSize.toString(),
    );
  }

  @override
  void didUpdateWidget(PropertiesForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection.id != widget.selection.id) {
      _xCtrl.text = widget.selection.x.toString();
      _yCtrl.text = widget.selection.y.toString();
      _wCtrl.text = widget.selection.w.toString();
      _hCtrl.text = widget.selection.h.toString();
      _textCtrl.text = widget.selection.text;
      _fontCtrl.text = widget.selection.fontSize.toString();
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
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              currentColor = color;
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              StudioController().updateSelectionColor(currentColor.value);
              Navigator.of(context).pop();
            },
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
        _buildSection("Layout"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildField(
                "X",
                _xCtrl,
                onSubmitted: (_) => _submitRect(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                "Y",
                _yCtrl,
                onSubmitted: (_) => _submitRect(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildField(
                "W",
                _wCtrl,
                onSubmitted: (_) => _submitRect(),
                enabled: widget.selection.type != LayerType.text,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                "H",
                _hCtrl,
                onSubmitted: (_) => _submitRect(),
                enabled: widget.selection.type != LayerType.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (widget.selection.type == LayerType.text) ...[
          _buildSection("Text Content"),
          const SizedBox(height: 12),
          _buildField(
            "Text",
            _textCtrl,
            onSubmitted: (_) => _submitText(),
            isNumber: false,
          ),
          const SizedBox(height: 12),
          _buildField(
            "Font Size",
            _fontCtrl,
            onSubmitted: (_) => _submitFont(),
          ),
          const SizedBox(height: 24),
        ],

        _buildSection("Appearance"),
        const SizedBox(height: 12),
        _buildColorTile("Fill", widget.selection.color),
      ],
    );
  }

  Widget _buildSection(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Colors.white30,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    required ValueChanged<String> onSubmitted,
    bool isNumber = true,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          enabled: enabled,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white24,
            fontSize: 13,
          ),
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            fillColor: Colors.white.withOpacity(0.03),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }

  Widget _buildColorTile(String label, int colorValue) {
    final color = Color(colorValue);
    return InkWell(
      onTap: _showColorPicker,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24, width: 1),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const Spacer(),
            Text(
              "#${colorValue.toRadixString(16).padLeft(8, '0').toUpperCase()}",
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
