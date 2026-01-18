import 'package:flutter/material.dart';
import 'package:karrolle/features/studio/logic/studio_controller.dart';

class StudioPropertiesPanel extends StatelessWidget {
  const StudioPropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(left: BorderSide(color: Color(0xFF333333))),
      ),
      padding: const EdgeInsets.all(16),
      child: ValueListenableBuilder<SelectionState?>(
        valueListenable: StudioController().selectionNotifier,
        builder: (context, selection, child) {
          if (selection == null) {
            return const Center(
              child: Text(
                "No Selection",
                style: TextStyle(color: Colors.white38),
              ),
            );
          }
          // Use a Key to force rebuild if ID changes completely (new object)
          // But we want to keep state if just moving same object.
          return PropertiesForm(
            key: ValueKey(selection.id),
            selection: selection,
          );
        },
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

  @override
  void initState() {
    super.initState();
    _xCtrl = TextEditingController(text: widget.selection.x.toString());
    _yCtrl = TextEditingController(text: widget.selection.y.toString());
    _wCtrl = TextEditingController(text: widget.selection.w.toString());
    _hCtrl = TextEditingController(text: widget.selection.h.toString());
  }

  @override
  void didUpdateWidget(PropertiesForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if selection changed externally (e.g. drag)
    // Checking if values match to avoid unnecessary updates
    if (widget.selection.x.toString() != _xCtrl.text &&
        !_xCtrl.selection.isValid)
      _xCtrl.text = widget.selection.x.toString();
    if (widget.selection.y.toString() != _yCtrl.text &&
        !_yCtrl.selection.isValid)
      _yCtrl.text = widget.selection.y.toString();
    if (widget.selection.w.toString() != _wCtrl.text &&
        !_wCtrl.selection.isValid)
      _wCtrl.text = widget.selection.w.toString();
    if (widget.selection.h.toString() != _hCtrl.text &&
        !_hCtrl.selection.isValid)
      _hCtrl.text = widget.selection.h.toString();

    // Note: checking selection.isValid is a cheap way to see if focused.
    // Ideally we should check FocusNodes. But for this MVP it prevents overwriting while typing (if user is fast).
    // Actually, simply overwriting is fine because when Dragging we don't type.
    // When typing, we don't drag.
    // So:
    if (widget.selection.x != oldWidget.selection.x)
      _xCtrl.text = widget.selection.x.toString();
    if (widget.selection.y != oldWidget.selection.y)
      _yCtrl.text = widget.selection.y.toString();
    if (widget.selection.w != oldWidget.selection.w)
      _wCtrl.text = widget.selection.w.toString();
    if (widget.selection.h != oldWidget.selection.h)
      _hCtrl.text = widget.selection.h.toString();
  }

  @override
  void dispose() {
    _xCtrl.dispose();
    _yCtrl.dispose();
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final x = int.tryParse(_xCtrl.text) ?? widget.selection.x;
    final y = int.tryParse(_yCtrl.text) ?? widget.selection.y;
    final w = int.tryParse(_wCtrl.text) ?? widget.selection.w;
    final h = int.tryParse(_hCtrl.text) ?? widget.selection.h;

    StudioController().updateSelectionRect(x, y, w, h);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('TRANSFORM (ID: ${widget.selection.id})'),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPropertyInput('X', _xCtrl),
            const SizedBox(width: 8),
            _buildPropertyInput('Y', _yCtrl),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPropertyInput('W', _wCtrl),
            const SizedBox(width: 8),
            _buildPropertyInput('H', _hCtrl),
          ],
        ),

        const SizedBox(height: 24),
        const Divider(color: Color(0xFF333333)),
        const SizedBox(height: 24),

        _buildSectionTitle('APPEARANCE'),
        const SizedBox(height: 12),
        _buildColorRow('Fill', const Color(0xFF007AFF)),

        // Add apply button just in case purely intuitive text field submission isn't enough
        // Actually onSubmitted is handled in inputs
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white38,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildPropertyInput(String label, TextEditingController controller) {
    return Expanded(
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _submit(),
                // Also update on focus lost?
                // Creating a simplified UX: Enter to submit.
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(String label, Color? color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color ?? Colors.transparent,
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const Spacer(),
        if (color != null)
          Text(
            '#${color.value.toRadixString(16).toUpperCase()}',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
      ],
    );
  }
}
