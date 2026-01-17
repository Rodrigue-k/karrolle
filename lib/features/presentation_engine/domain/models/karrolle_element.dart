sealed class KarrolleElement {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final int zIndex;

  const KarrolleElement({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
    this.zIndex = 0,
  });

  Map<String, dynamic> toJson();

  static KarrolleElement fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'text':
        return TextElement.fromJson(json);
      case 'image':
        return ImageElement.fromJson(json);
      case 'shape':
        return ShapeElement.fromJson(json);
      default:
        throw Exception('Unknown element type: $type');
    }
  }

  KarrolleElement copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? zIndex,
  });
}

class TextElement extends KarrolleElement {
  final String content;
  final String? fontFamily;
  final double fontSize;
  final int color;

  const TextElement({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    super.rotation,
    super.zIndex,
    required this.content,
    this.fontFamily,
    this.fontSize = 14.0,
    this.color = 0xFF000000,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'text',
    'id': id,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': rotation,
    'zIndex': zIndex,
    'content': content,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'color': color,
  };

  factory TextElement.fromJson(Map<String, dynamic> json) => TextElement(
    id: json['id'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
    rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    zIndex: json['zIndex'] as int? ?? 0,
    content: json['content'] as String,
    fontFamily: json['fontFamily'] as String?,
    fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
    color: json['color'] as int? ?? 0xFF000000,
  );

  @override
  TextElement copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? zIndex,
    String? content,
    String? fontFamily,
    double? fontSize,
    int? color,
  }) {
    return TextElement(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      content: content ?? this.content,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
    );
  }
}

class ImageElement extends KarrolleElement {
  final String? localPath;
  final String? url;

  const ImageElement({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    super.rotation,
    super.zIndex,
    this.localPath,
    this.url,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'image',
    'id': id,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': rotation,
    'zIndex': zIndex,
    'localPath': localPath,
    'url': url,
  };

  factory ImageElement.fromJson(Map<String, dynamic> json) => ImageElement(
    id: json['id'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
    rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    zIndex: json['zIndex'] as int? ?? 0,
    localPath: json['localPath'] as String?,
    url: json['url'] as String?,
  );

  @override
  ImageElement copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? zIndex,
    String? localPath,
    String? url,
  }) {
    return ImageElement(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      localPath: localPath ?? this.localPath,
      url: url ?? this.url,
    );
  }
}

class ShapeElement extends KarrolleElement {
  final String shapeType;
  final int color;

  const ShapeElement({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    super.rotation,
    super.zIndex,
    required this.shapeType,
    this.color = 0xFF000000,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'shape',
    'id': id,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': rotation,
    'zIndex': zIndex,
    'shapeType': shapeType,
    'color': color,
  };

  factory ShapeElement.fromJson(Map<String, dynamic> json) => ShapeElement(
    id: json['id'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
    rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    zIndex: json['zIndex'] as int? ?? 0,
    shapeType: json['shapeType'] as String,
    color: json['color'] as int? ?? 0xFF000000,
  );

  @override
  ShapeElement copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? zIndex,
    String? shapeType,
    int? color,
  }) {
    return ShapeElement(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      shapeType: shapeType ?? this.shapeType,
      color: color ?? this.color,
    );
  }
}
