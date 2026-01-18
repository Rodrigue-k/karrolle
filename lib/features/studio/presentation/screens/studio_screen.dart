import 'package:flutter/material.dart';
import 'package:karrolle/features/studio/presentation/widgets/studio_toolbar.dart';
import 'package:karrolle/features/studio/presentation/widgets/studio_left_sidebar.dart';
import 'package:karrolle/features/studio/presentation/widgets/studio_right_sidebar.dart';
import 'package:karrolle/features/studio/presentation/widgets/studio_canvas.dart';
import 'package:karrolle/features/studio/presentation/widgets/studio_top_bar.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  // Document state
  final double _documentWidth = 1920;
  final double _documentHeight = 1080;
  final Color _documentBackground = Colors.white;

  // Zoom/Pan state
  final TransformationController _transformController =
      TransformationController();
  double _currentZoom = 1.0;

  // Panels visibility
  bool _showLeftSidebar = true;
  bool _showRightSidebar = true;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if (scale != _currentZoom) {
      setState(() => _currentZoom = scale);
    }
  }

  void _setZoom(double zoom) {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final newMatrix = _transformController.value.clone();
    newMatrix.scale(zoom / currentScale, zoom / currentScale, 1.0);
    _transformController.value = newMatrix;
  }

  void _fitToScreen() {
    // Calculate scale to fit document in viewport
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewportWidth =
          MediaQuery.of(context).size.width -
          (_showLeftSidebar ? 300 : 0) -
          (_showRightSidebar ? 280 : 0) -
          48; // toolbar width
      final viewportHeight =
          MediaQuery.of(context).size.height - 48 - 32; // topbar + bottom bar

      final scaleX = viewportWidth / _documentWidth;
      final scaleY = viewportHeight / _documentHeight;
      final scale =
          (scaleX < scaleY ? scaleX : scaleY) * 0.9; // 90% to add margin

      _setZoom(scale);
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          // Top Bar
          StudioTopBar(
            documentName: 'Untitled Design',
            onToggleLeftSidebar: () =>
                setState(() => _showLeftSidebar = !_showLeftSidebar),
            onToggleRightSidebar: () =>
                setState(() => _showRightSidebar = !_showRightSidebar),
          ),

          // Main Workspace
          Expanded(
            child: Row(
              children: [
                // Vertical Toolbar (Figma-style)
                const StudioToolbar(),

                // Left Sidebar (Layers, Assets, Pages)
                if (_showLeftSidebar) const StudioLeftSidebar(),

                // Canvas Area
                Expanded(
                  child: StudioCanvas(
                    transformController: _transformController,
                    documentWidth: _documentWidth,
                    documentHeight: _documentHeight,
                    documentBackground: _documentBackground,
                  ),
                ),

                // Right Sidebar (Properties)
                if (_showRightSidebar) const StudioRightSidebar(),
              ],
            ),
          ),

          // Bottom Status Bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF252526),
        border: Border(top: BorderSide(color: Color(0xFF3C3C3C))),
      ),
      child: Row(
        children: [
          // Document info
          Text(
            '${_documentWidth.toInt()} × ${_documentHeight.toInt()} px',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const Spacer(),

          // Zoom controls
          IconButton(
            onPressed: () => _setZoom(_currentZoom * 0.8),
            icon: const Icon(Icons.remove, size: 14, color: Colors.white54),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          GestureDetector(
            onTap: _fitToScreen,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3C3C3C),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(_currentZoom * 100).toInt()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _setZoom(_currentZoom * 1.25),
            icon: const Icon(Icons.add, size: 14, color: Colors.white54),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}
