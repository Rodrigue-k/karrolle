import 'karrolle_element.dart';

class KarrolleScene {
  final String id;
  final int backgroundColor;
  final List<KarrolleElement> elements;
  final String? name;

  const KarrolleScene({
    required this.id,
    this.backgroundColor = 0xFFFFFFFF,
    this.elements = const [],
    this.name,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'backgroundColor': backgroundColor,
    'elements': elements.map((e) => e.toJson()).toList(),
    'name': name,
  };

  factory KarrolleScene.fromJson(Map<String, dynamic> json) => KarrolleScene(
    id: json['id'] as String,
    backgroundColor: json['backgroundColor'] as int? ?? 0xFFFFFFFF,
    elements:
        (json['elements'] as List<dynamic>?)
            ?.map((e) => KarrolleElement.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    name: json['name'] as String?,
  );

  KarrolleScene copyWith({
    String? id,
    int? backgroundColor,
    List<KarrolleElement>? elements,
    String? name,
  }) {
    return KarrolleScene(
      id: id ?? this.id,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elements: elements ?? this.elements,
      name: name ?? this.name,
    );
  }
}
