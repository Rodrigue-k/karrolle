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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('TRANSFORM (ID: ${selection.id})'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPropertyField('X', '${selection.x}'),
                  const SizedBox(width: 8),
                  _buildPropertyField('Y', '${selection.y}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPropertyField('W', '${selection.w}'),
                  const SizedBox(width: 8),
                  _buildPropertyField('H', '${selection.h}'),
                ],
              ),
              const SizedBox(height: 8),
              _buildPropertyField('Rotation', '0°'),

              const SizedBox(height: 24),
              const Divider(color: Color(0xFF333333)),
              const SizedBox(height: 24),

              _buildSectionTitle('APPEARANCE'),
              const SizedBox(height: 12),
              // Dummy color for now (reading color from C++ requires extending ObjectInfo struct)
              _buildColorRow('Fill', const Color(0xFF007AFF)),

              const SizedBox(height: 24),
              const Divider(color: Color(0xFF333333)),

              // Only show Typography for Text objects (Need 'type' info from C++)
              // For now, static placeholder
            ],
          );
        },
      ),
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

  Widget _buildPropertyField(String label, String value) {
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                value,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
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
          child: color == null
              ? const Icon(Icons.close, size: 10, color: Colors.white24)
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const Spacer(),
        if (color != null)
          Text(
            '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
      ],
    );
  }
}
