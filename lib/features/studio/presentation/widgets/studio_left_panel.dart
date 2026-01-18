import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:karrolle/bridge/native_api.dart';
import 'package:karrolle/core/logger/app_logger.dart';
import 'package:karrolle/features/studio/logic/studio_controller.dart';

class StudioLeftPanel extends StatelessWidget {
  const StudioLeftPanel({super.key});

  Future<void> _onAddImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final bytes = await File(path).readAsBytes();

        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;

        final byteData = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (byteData != null) {
          final pixels = byteData.buffer.asUint32List();

          double aspect = image.width / image.height;
          int displayW = 200;
          int displayH = (200 / aspect).round();

          NativeApi.addImage(
            100,
            100,
            displayW,
            displayH,
            pixels,
            image.width,
            image.height,
          );

          StudioController().refreshLayers();
        }
      }
    } catch (e) {
      AppLog.e("Failed to add image", e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(right: BorderSide(color: Color(0xFF333333))),
      ),
      child: Column(
        children: [
          // Basic tool toggles
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildToolIcon(Icons.mouse_rounded, isActive: true),
                _buildToolIcon(
                  Icons.text_fields,
                  onTap: () {
                    NativeApi.addText(100, 100, "New Text", 0xFFFFFFFF, 32.0);
                    StudioController().refreshLayers();
                  },
                ),
                _buildToolIcon(
                  Icons.crop_square,
                  onTap: () {
                    NativeApi.addRect(150, 150, 100, 100, 0xFF007AFF);
                    StudioController().refreshLayers();
                  },
                ),
                _buildToolIcon(Icons.image_outlined, onTap: _onAddImage),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF333333)),

          // Layers / Pages List
          Expanded(
            child: ValueListenableBuilder<List<LayerInfo>>(
              valueListenable: StudioController().layersNotifier,
              builder: (context, layers, child) {
                return ValueListenableBuilder<SelectionState?>(
                  valueListenable: StudioController().selectionNotifier,
                  builder: (context, selection, _) {
                    final selectedUid = selection?.id;
                    return ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        _buildSectionTitle('LAYERS'),
                        const SizedBox(height: 8),
                        if (layers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                "No layers yet",
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                        else
                          ...layers.map(
                            (layer) => _buildLayerItem(
                              _getLayerIcon(layer.type),
                              layer.name,
                              isSelected: layer.uid == selectedUid,
                              onTap: () =>
                                  StudioController().selectObject(layer.uid),
                              onDelete: () =>
                                  StudioController().removeObject(layer.uid),
                            ),
                          ),

                        const SizedBox(height: 32),
                        _buildSectionTitle('PAGES'),
                        const SizedBox(height: 8),
                        _buildPageItem(1, 'Page 1'),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLayerIcon(LayerType type) {
    switch (type) {
      case LayerType.rectangle:
        return Icons.crop_square;
      case LayerType.text:
        return Icons.text_fields;
      case LayerType.image:
        return Icons.image;
      default:
        return Icons.layers;
    }
  }

  Widget _buildToolIcon(
    IconData icon, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 32,
        decoration: isActive
            ? BoxDecoration(
                color: Colors.blueAccent.withAlpha(51),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Icon(
          icon,
          size: 16,
          color: isActive ? Colors.blueAccent : Colors.white60,
        ),
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

  Widget _buildLayerItem(
    IconData icon,
    String label, {
    bool isSelected = false,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF37373D) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.visibility_outlined,
              size: 14,
              color: Colors.white30,
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 14, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onDelete != null)
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.delete_outline,
                    size: 14,
                    color: Colors.white30,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageItem(int index, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '$index',
              style: const TextStyle(fontSize: 9, color: Colors.white54),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
