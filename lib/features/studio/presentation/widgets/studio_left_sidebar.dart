import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:karrolle/bridge/native_api.dart';
import 'package:karrolle/core/logger/app_logger.dart';
import 'package:karrolle/features/studio/logic/studio_controller.dart';
import 'package:karrolle/features/studio/logic/page_manager.dart';

/// Figma/Canva-style left sidebar with tabs for Layers, Assets, and Pages
class StudioLeftSidebar extends StatefulWidget {
  const StudioLeftSidebar({super.key});

  @override
  State<StudioLeftSidebar> createState() => _StudioLeftSidebarState();
}

class _StudioLeftSidebarState extends State<StudioLeftSidebar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          int displayW = 300;
          int displayH = (300 / aspect).round();

          NativeApi.addImage(
            100.0,
            100.0,
            displayW.toDouble(),
            displayH.toDouble(),
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
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xFF252526),
        border: Border(right: BorderSide(color: Color(0xFF3C3C3C))),
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
                Tab(text: 'Layers'),
                Tab(text: 'Assets'),
                Tab(text: 'Pages'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLayersTab(),
                _buildAssetsTab(),
                _buildPagesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayersTab() {
    return ValueListenableBuilder<List<LayerInfo>>(
      valueListenable: StudioController().layersNotifier,
      builder: (context, layers, child) {
        return ValueListenableBuilder<SelectionState?>(
          valueListenable: StudioController().selectionNotifier,
          builder: (context, selection, _) {
            final selectedUid = selection?.id;

            if (layers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.layers_outlined,
                      size: 48,
                      color: Colors.white.withAlpha(30),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No layers yet',
                      style: TextStyle(
                        color: Colors.white.withAlpha(77),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add elements to see them here',
                      style: TextStyle(
                        color: Colors.white.withAlpha(51),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: layers.length,
              onReorder: (oldIndex, newIndex) {
                // TODO: Implement layer reordering in engine
              },
              proxyDecorator: (child, index, animation) {
                return Material(color: Colors.transparent, child: child);
              },
              itemBuilder: (context, index) {
                final layer =
                    layers[layers.length -
                        1 -
                        index]; // Reverse order (top layer first)
                return _buildLayerItem(
                  key: ValueKey(layer.uid),
                  layer: layer,
                  isSelected: layer.uid == selectedUid,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLayerItem({
    required Key key,
    required LayerInfo layer,
    required bool isSelected,
  }) {
    return InkWell(
      key: key,
      onTap: () => StudioController().selectObject(layer.uid),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4F46E5).withAlpha(51)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: const Color(0xFF4F46E5).withAlpha(128))
              : null,
        ),
        child: Row(
          children: [
            // Visibility toggle
            InkWell(
              onTap: () {}, // TODO: Toggle visibility
              child: const Icon(
                Icons.visibility_outlined,
                size: 16,
                color: Colors.white38,
              ),
            ),
            const SizedBox(width: 10),

            // Lock toggle
            InkWell(
              onTap: () {}, // TODO: Toggle lock
              child: const Icon(
                Icons.lock_open_outlined,
                size: 14,
                color: Colors.white24,
              ),
            ),
            const SizedBox(width: 10),

            // Layer icon
            Icon(
              _getLayerIcon(layer.type),
              size: 16,
              color: isSelected ? const Color(0xFF818CF8) : Colors.white54,
            ),
            const SizedBox(width: 10),

            // Layer name
            Expanded(
              child: Text(
                layer.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Delete button (on hover would be better)
            if (isSelected)
              InkWell(
                onTap: () => StudioController().removeObject(layer.uid),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    size: 14,
                    color: Colors.white38,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getLayerIcon(LayerType type) {
    switch (type) {
      case LayerType.rectangle:
        return Icons.crop_square_rounded;
      case LayerType.text:
        return Icons.text_fields;
      case LayerType.image:
        return Icons.image_outlined;
      case LayerType.ellipse:
        return Icons.circle_outlined;
      case LayerType.line:
        return Icons.remove;
      default:
        return Icons.layers;
    }
  }

  Widget _buildAssetsTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _onAddImage,
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Upload Image'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Color(0xFF4A4A4A)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Quick shapes section
          _buildSectionHeader('Quick Shapes'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickAsset(Icons.crop_square, 'Rectangle', () {
                NativeApi.addRect(150.0, 150.0, 100.0, 100.0, 0xFF6366F1);
                StudioController().refreshLayers();
              }),
              _buildQuickAsset(Icons.circle_outlined, 'Circle', () {
                NativeApi.addEllipse(150.0, 150.0, 100.0, 100.0, 0xFF10B981);
                StudioController().refreshLayers();
              }),
              _buildQuickAsset(Icons.remove, 'Line', () {
                NativeApi.addLine(
                  150.0,
                  150.0,
                  300.0,
                  200.0,
                  0xFFEF4444,
                  thickness: 3.0,
                );
                StudioController().refreshLayers();
              }),
              _buildQuickAsset(Icons.text_fields, 'Text', () {
                NativeApi.addText(150.0, 150.0, 'Your text', 0xFF1A1A1A, 24.0);
                StudioController().refreshLayers();
              }),
            ],
          ),

          const SizedBox(height: 20),

          // TODO: Show uploaded images thumbnails
          _buildSectionHeader('Uploads'),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Your uploads will appear here',
              style: TextStyle(color: Colors.white.withAlpha(77), fontSize: 11),
            ),
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

  Widget _buildQuickAsset(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF3C3C3C),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.white60),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagesTab() {
    return ValueListenableBuilder<List<DocumentPage>>(
      valueListenable: PageManager().pagesNotifier,
      builder: (context, pages, _) {
        return ValueListenableBuilder<int>(
          valueListenable: PageManager().currentPageNotifier,
          builder: (context, currentIndex, _) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Add page button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        PageManager().addPage();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Page'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Color(0xFF4A4A4A)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Page list
                  Expanded(
                    child: ListView.builder(
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        final page = pages[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildPageThumbnail(
                            index,
                            page.name,
                            isSelected: index == currentIndex,
                            onTap: () => PageManager().goToPage(index),
                            onDelete: pages.length > 1
                                ? () => PageManager().removePage(index)
                                : null,
                            onDuplicate: () =>
                                PageManager().duplicatePage(index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPageThumbnail(
    int index,
    String label, {
    bool isSelected = false,
    VoidCallback? onTap,
    VoidCallback? onDelete,
    VoidCallback? onDuplicate,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4F46E5).withAlpha(51)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFF4F46E5))
              : Border.all(color: const Color(0xFF4A4A4A)),
        ),
        child: Row(
          children: [
            // Page number
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF3C3C3C),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Page preview
            Container(
              width: 48,
              height: 27,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 12),

            // Page info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '1920 × 1080',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withAlpha(77),
                    ),
                  ),
                ],
              ),
            ),

            // Context menu
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                size: 16,
                color: Colors.white38,
              ),
              color: const Color(0xFF2D2D2D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (value) {
                if (value == 'duplicate') onDuplicate?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.copy, size: 16, color: Colors.white60),
                      SizedBox(width: 12),
                      Text(
                        'Duplicate',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
