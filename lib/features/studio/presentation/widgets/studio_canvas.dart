import 'package:flutter/material.dart';
import 'package:karrolle/features/engine/presentation/engine_view.dart';

/// Canvas area with zoom/pan, checkered background, and document display
class StudioCanvas extends StatelessWidget {
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
              InteractiveViewer(
                transformationController: transformController,
                minScale: 0.1,
                maxScale: 5.0,
                boundaryMargin: EdgeInsets.all(
                  (documentWidth > documentHeight
                          ? documentWidth
                          : documentHeight) *
                      2,
                ),
                child: Center(child: _buildDocument()),
              ),

              // Rulers (optional - can be toggled)
              // _buildHorizontalRuler(constraints.maxWidth),
              // _buildVerticalRuler(constraints.maxHeight),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDocument() {
    return Container(
      width: documentWidth,
      height: documentHeight,
      decoration: BoxDecoration(
        color: documentBackground,
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
          width: documentWidth.toInt(),
          height: documentHeight.toInt(),
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
