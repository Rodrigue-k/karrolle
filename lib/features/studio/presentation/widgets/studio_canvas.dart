import 'package:flutter/material.dart';
import 'package:karrolle/features/engine/presentation/engine_view.dart';

/// Canvas area with zoom/pan, checkered background, and document display
class StudioCanvas extends StatefulWidget {
  final TransformationController transformController;
  final double documentWidth;
  final double documentHeight;
  final Color documentBackground;

  const StudioCanvas({
    super.key,
    required this.transformController,
    required this.documentWidth,
    required this.documentHeight,
    required this.documentBackground,
  });

  @override
  State<StudioCanvas> createState() => _StudioCanvasState();
}

class _StudioCanvasState extends State<StudioCanvas> {
  // Track if we're currently dragging an object
  bool _isDraggingObject = false;

  void _onDragStart() {
    setState(() => _isDraggingObject = true);
  }

  void _onDragEnd() {
    setState(() => _isDraggingObject = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Checkered background (infinite canvas feel)
              Positioned.fill(
                child: CustomPaint(painter: _CheckeredBackgroundPainter()),
              ),

              // Interactive canvas with zoom/pan
              // Only allow pan when NOT dragging an object
              InteractiveViewer(
                transformationController: widget.transformController,
                minScale: 0.1,
                maxScale: 5.0,
                // Disable pan when dragging an object
                panEnabled: !_isDraggingObject,
                scaleEnabled: !_isDraggingObject,
                boundaryMargin: EdgeInsets.all(
                  (widget.documentWidth > widget.documentHeight
                          ? widget.documentWidth
                          : widget.documentHeight) *
                      2,
                ),
                child: Center(child: _buildDocument()),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDocument() {
    return Container(
      width: widget.documentWidth,
      height: widget.documentHeight,
      decoration: BoxDecoration(
        color: widget.documentBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(128),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 100,
            spreadRadius: 10,
          ),
        ],
      ),
      child: ClipRect(
        child: EngineView(
          width: widget.documentWidth.toInt(),
          height: widget.documentHeight.toInt(),
          onDragStart: _onDragStart,
          onDragEnd: _onDragEnd,
        ),
      ),
    );
  }
}

/// Checkered/grid background painter for infinite canvas feel
class _CheckeredBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const gridSize = 20.0;
    final paint1 = Paint()..color = const Color(0xFF1E1E1E);
    final paint2 = Paint()..color = const Color(0xFF1A1A1A);

    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        final isEven =
            ((x / gridSize).floor() + (y / gridSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, gridSize, gridSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
