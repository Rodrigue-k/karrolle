import 'package:flutter/material.dart';
import '../../domain/models/karrolle_element.dart';
import '../../domain/models/karrolle_scene.dart';

class KarrollePlayer extends StatelessWidget {
  final KarrolleScene scene;
  final Size referenceSize;

  const KarrollePlayer({
    super.key,
    required this.scene,
    this.referenceSize = const Size(1920, 1080),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(scene.backgroundColor),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaleX = constraints.maxWidth / referenceSize.width;
          final scaleY = constraints.maxHeight / referenceSize.height;

          // Sort elements by zIndex
          final sortedElements = List<KarrolleElement>.from(scene.elements)
            ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

          return Stack(
            children: sortedElements.map((element) {
              return Positioned(
                left: element.x * scaleX,
                top: element.y * scaleY,
                width: element.width * scaleX,
                height: element.height * scaleY,
                child: Transform.rotate(
                  angle: element.rotation,
                  child: _buildElement(element),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildElement(KarrolleElement element) {
    return switch (element) {
      TextElement() => _buildText(element),
      ImageElement() => _buildImage(element),
      ShapeElement() => _buildShape(element),
    };
  }

  Widget _buildText(TextElement element) {
    return Text(
      element.content,
      style: TextStyle(
        fontSize: element.fontSize,
        color: Color(element.color),
        fontFamily: element.fontFamily,
      ),
    );
  }

  Widget _buildImage(ImageElement element) {
    if (element.url != null) {
      return Image.network(element.url!, fit: BoxFit.cover);
    } else if (element.localPath != null) {
      // In a real desktop app, we might use FileImage
      // For now, let's assume assets or handle gracefully
      return Image.asset(
        element.localPath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    }
    return const Placeholder();
  }

  Widget _buildShape(ShapeElement element) {
    return Container(
      decoration: BoxDecoration(
        color: Color(element.color),
        shape: element.shapeType == 'circle'
            ? BoxShape.circle
            : BoxShape.rectangle,
      ),
    );
  }
}
