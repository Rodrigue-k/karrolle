import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../domain/models/karrolle_element.dart';
import '../../domain/models/karrolle_presentation.dart';
import '../../domain/models/karrolle_scene.dart';
import '../../domain/repositories/karrolle_repository.dart';

class KarrolleRepositoryImpl implements KarrolleRepository {
  @override
  Future<KarrollePresentation> loadPresentation(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File not found: $path');
    }

    final jsonString = await file.readAsString();
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return KarrollePresentation.fromJson(jsonMap);
  }

  @override
  Future<void> savePresentation(
    KarrollePresentation presentation,
    String path,
  ) async {
    final file = File(path);
    final jsonString = jsonEncode(presentation.toJson());
    await file.writeAsString(jsonString);
  }

  @override
  Future<KarrollePresentation> importFromImages(List<String> imagePaths) async {
    final scenes = <KarrolleScene>[];

    for (var i = 0; i < imagePaths.length; i++) {
      final path = imagePaths[i];
      final id = 'scene_$i';

      // Basic element creation: one image element filling the scene
      // In a real app, we might want to get actual image dimensions
      final imageElement = ImageElement(
        id: 'img_$i',
        x: 0,
        y: 0,
        width: 1920, // Default reference width
        height: 1080, // Default reference height
        localPath: path,
      );

      scenes.add(
        KarrolleScene(id: id, name: p.basename(path), elements: [imageElement]),
      );
    }

    return KarrollePresentation(
      id: 'import_${DateTime.now().millisecondsSinceEpoch}',
      metadata: KarrolleMetadata(
        version: '1.0.0',
        author: 'User', // Placeholder
        createdAt: DateTime.now(),
      ),
      scenes: scenes,
    );
  }
}
