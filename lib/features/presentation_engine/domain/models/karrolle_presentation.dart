import 'karrolle_scene.dart';
import 'karrolle_element.dart';

class KarrollePresentation {
  final String id;
  final KarrolleMetadata metadata;
  final List<KarrolleScene> scenes;

  const KarrollePresentation({
    required this.id,
    required this.metadata,
    this.scenes = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'metadata': metadata.toJson(),
    'scenes': scenes.map((s) => s.toJson()).toList(),
  };

  factory KarrollePresentation.fromJson(Map<String, dynamic> json) =>
      KarrollePresentation(
        id: json['id'] as String,
        metadata: KarrolleMetadata.fromJson(
          json['metadata'] as Map<String, dynamic>,
        ),
        scenes:
            (json['scenes'] as List<dynamic>?)
                ?.map((s) => KarrolleScene.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );

  KarrollePresentation copyWith({
    String? id,
    KarrolleMetadata? metadata,
    List<KarrolleScene>? scenes,
  }) {
    return KarrollePresentation(
      id: id ?? this.id,
      metadata: metadata ?? this.metadata,
      scenes: scenes ?? this.scenes,
    );
  }

  static KarrollePresentation get sample => KarrollePresentation(
    id: 'sample_id',
    metadata: const KarrolleMetadata(version: '1.0.0', author: 'Antigravity'),
    scenes: [
      KarrolleScene(
        id: 'scene_1',
        backgroundColor: 0xFF121212,
        name: 'Introduction',
        elements: [
          const TextElement(
            id: 'txt_1',
            x: 100,
            y: 100,
            width: 800,
            height: 100,
            content: 'Welcome to Karrolle',
            fontSize: 64,
            color: 0xFFFFFFFF,
          ),
          const ShapeElement(
            id: 'shape_1',
            x: 100,
            y: 220,
            width: 200,
            height: 10,
            shapeType: 'rect',
            color: 0xFF00FF00,
          ),
          const TextElement(
            id: 'txt_2',
            x: 100,
            y: 250,
            width: 500,
            height: 50,
            content: 'The future of interactive presentations.',
            fontSize: 24,
            color: 0xFFAAAAAA,
          ),
        ],
      ),
      KarrolleScene(
        id: 'scene_2',
        backgroundColor: 0xFF001F3F,
        name: 'Powerful Features',
        elements: [
          const TextElement(
            id: 'txt_3',
            x: 100,
            y: 100,
            width: 800,
            height: 100,
            content: 'Zero Latency Control',
            fontSize: 48,
            color: 0xFF0074D9,
          ),
        ],
      ),
    ],
  );
}

class KarrolleMetadata {
  final String version;
  final String author;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> extra;

  const KarrolleMetadata({
    required this.version,
    required this.author,
    this.createdAt,
    this.updatedAt,
    this.extra = const {},
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'author': author,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'extra': extra,
  };

  factory KarrolleMetadata.fromJson(Map<String, dynamic> json) =>
      KarrolleMetadata(
        version: json['version'] as String,
        author: json['author'] as String,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        extra: json['extra'] as Map<String, dynamic>? ?? {},
      );

  KarrolleMetadata copyWith({
    String? version,
    String? author,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? extra,
  }) {
    return KarrolleMetadata(
      version: version ?? this.version,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      extra: extra ?? this.extra,
    );
  }
}
