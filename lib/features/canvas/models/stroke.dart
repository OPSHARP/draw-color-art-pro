import 'dart:ui';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// A single point in a stroke with pressure/tilt metadata.
class StrokePoint extends Equatable {
  const StrokePoint({
    required this.x,
    required this.y,
    this.pressure = 1.0,
    this.tilt = 0.0,
    this.timestamp,
  });

  final double x;
  final double y;
  final double pressure;
  final double tilt;
  final int? timestamp;

  Offset get offset => Offset(x, y);

  StrokePoint copyWith({
    double? x,
    double? y,
    double? pressure,
    double? tilt,
    int? timestamp,
  }) {
    return StrokePoint(
      x: x ?? this.x,
      y: y ?? this.y,
      pressure: pressure ?? this.pressure,
      tilt: tilt ?? this.tilt,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'pressure': pressure,
    'tilt': tilt,
    'timestamp': timestamp,
  };

  factory StrokePoint.fromJson(Map<String, dynamic> json) => StrokePoint(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    pressure: (json['pressure'] as num?)?.toDouble() ?? 1.0,
    tilt: (json['tilt'] as num?)?.toDouble() ?? 0.0,
    timestamp: json['timestamp'] as int?,
  );

  @override
  List<Object?> get props => [x, y, pressure, tilt, timestamp];
}

/// Blend modes supported by the drawing engine.
enum DrawBlendMode {
  normal('Normal'),
  multiply('Multiply'),
  screen('Screen'),
  overlay('Overlay'),
  softLight('Soft Light'),
  hardLight('Hard Light'),
  darken('Darken'),
  lighten('Lighten'),
  difference('Difference'),
  colorBlend('Color'),
  hue('Hue'),
  saturation('Saturation');

  const DrawBlendMode(this.label);
  final String label;

  BlendMode toFlutterBlendMode() {
    return switch (this) {
      DrawBlendMode.normal => BlendMode.srcOver,
      DrawBlendMode.multiply => BlendMode.multiply,
      DrawBlendMode.screen => BlendMode.screen,
      DrawBlendMode.overlay => BlendMode.overlay,
      DrawBlendMode.softLight => BlendMode.softLight,
      DrawBlendMode.hardLight => BlendMode.hardLight,
      DrawBlendMode.darken => BlendMode.darken,
      DrawBlendMode.lighten => BlendMode.lighten,
      DrawBlendMode.difference => BlendMode.difference,
      DrawBlendMode.colorBlend => BlendMode.color,
      DrawBlendMode.hue => BlendMode.hue,
      DrawBlendMode.saturation => BlendMode.saturation,
    };
  }
}

/// Brush stabilization modes.
enum StabilizationMode {
  off('Off'),
  basic('Basic'),
  smooth('Smooth'),
  strong('Strong'),
  professional('Professional');

  const StabilizationMode(this.label);
  final String label;

  double get strength => switch (this) {
    StabilizationMode.off => 0.0,
    StabilizationMode.basic => 0.2,
    StabilizationMode.smooth => 0.5,
    StabilizationMode.strong => 0.75,
    StabilizationMode.professional => 0.9,
  };
}

/// Brush category for library organization.
enum BrushCategory {
  basic('Basic'),
  sketching('Sketching'),
  ink('Ink'),
  painting('Painting'),
  texture('Texture'),
  effects('Effects'),
  coloring('Coloring'),
  pixel('Pixel'),
  favorites('Favorites'),
  recent('Recent');

  const BrushCategory(this.label);
  final String label;
}

/// Pattern shapes for the Pattern Stamp tool.
enum PatternStampType {
  star('Star'),
  heart('Heart'),
  flower('Flower'),
  diamond('Diamond'),
  spiral('Spiral'),
  leaf('Leaf');

  const PatternStampType(this.label);
  final String label;
}

/// Type of gradient fill.
enum GradientType {
  linear('Linear'),
  radial('Radial');

  const GradientType(this.label);
  final String label;
}

/// Dynamic color theme for Rainbow brush.
enum RainbowMode {
  spectrum('Spectrum'),
  pastel('Pastel'),
  neon('Neon'),
  sunset('Sunset');

  const RainbowMode(this.label);
  final String label;
}

/// Configuration for a brush preset.
class BrushPreset extends Equatable {
  BrushPreset({
    String? id,
    required this.name,
    required this.category,
    this.size = 8.0,
    this.opacity = 1.0,
    this.flow = 1.0,
    this.hardness = 0.8,
    this.spacing = 0.15,
    this.rotation = 0.0,
    this.scatter = 0.0,
    this.jitter = 0.0,
    this.stabilization = StabilizationMode.basic,
    this.streamline = 0.0,
    this.isEraser = false,
    this.isSmudge = false,
    this.isBlur = false,
    this.isGlow = false,
    this.isSpray = false,
    this.isCalligraphy = false,
    this.isCrayon = false,
    this.isDotted = false,
    this.isPatternStamp = false,
    this.isPixel = false,
    this.isHighlighter = false,
    this.isRainbow = false,
    this.isGradient = false,
    this.isFavorite = false,
    this.isCustom = false,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String name;
  final BrushCategory category;
  final double size;
  final double opacity;
  final double flow;
  final double hardness;
  final double spacing;
  final double rotation;
  final double scatter;
  final double jitter;
  final StabilizationMode stabilization;
  final double streamline;
  final bool isEraser;
  final bool isSmudge;
  final bool isBlur;
  final bool isGlow;
  final bool isSpray;
  final bool isCalligraphy;
  final bool isCrayon;
  final bool isDotted;
  final bool isPatternStamp;
  final bool isPixel;
  final bool isHighlighter;
  final bool isRainbow;
  final bool isGradient;
  final bool isFavorite;
  final bool isCustom;

  BrushPreset copyWith({
    String? name,
    BrushCategory? category,
    double? size,
    double? opacity,
    double? flow,
    double? hardness,
    double? spacing,
    double? rotation,
    double? scatter,
    double? jitter,
    StabilizationMode? stabilization,
    double? streamline,
    bool? isEraser,
    bool? isSmudge,
    bool? isBlur,
    bool? isGlow,
    bool? isSpray,
    bool? isCalligraphy,
    bool? isCrayon,
    bool? isDotted,
    bool? isPatternStamp,
    bool? isPixel,
    bool? isHighlighter,
    bool? isRainbow,
    bool? isGradient,
    bool? isFavorite,
    bool? isCustom,
  }) {
    return BrushPreset(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      flow: flow ?? this.flow,
      hardness: hardness ?? this.hardness,
      spacing: spacing ?? this.spacing,
      rotation: rotation ?? this.rotation,
      scatter: scatter ?? this.scatter,
      jitter: jitter ?? this.jitter,
      stabilization: stabilization ?? this.stabilization,
      streamline: streamline ?? this.streamline,
      isEraser: isEraser ?? this.isEraser,
      isSmudge: isSmudge ?? this.isSmudge,
      isBlur: isBlur ?? this.isBlur,
      isGlow: isGlow ?? this.isGlow,
      isSpray: isSpray ?? this.isSpray,
      isCalligraphy: isCalligraphy ?? this.isCalligraphy,
      isCrayon: isCrayon ?? this.isCrayon,
      isDotted: isDotted ?? this.isDotted,
      isPatternStamp: isPatternStamp ?? this.isPatternStamp,
      isPixel: isPixel ?? this.isPixel,
      isHighlighter: isHighlighter ?? this.isHighlighter,
      isRainbow: isRainbow ?? this.isRainbow,
      isGradient: isGradient ?? this.isGradient,
      isFavorite: isFavorite ?? this.isFavorite,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'size': size,
    'opacity': opacity,
    'flow': flow,
    'hardness': hardness,
    'spacing': spacing,
    'rotation': rotation,
    'scatter': scatter,
    'jitter': jitter,
    'stabilization': stabilization.name,
    'streamline': streamline,
    'isEraser': isEraser,
    'isSmudge': isSmudge,
    'isBlur': isBlur,
    'isGlow': isGlow,
    'isSpray': isSpray,
    'isCalligraphy': isCalligraphy,
    'isCrayon': isCrayon,
    'isDotted': isDotted,
    'isPatternStamp': isPatternStamp,
    'isPixel': isPixel,
    'isHighlighter': isHighlighter,
    'isRainbow': isRainbow,
    'isGradient': isGradient,
    'isFavorite': isFavorite,
    'isCustom': isCustom,
  };

  factory BrushPreset.fromJson(Map<String, dynamic> json) => BrushPreset(
    id: json['id'] as String,
    name: json['name'] as String,
    category: BrushCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => BrushCategory.basic,
    ),
    size: (json['size'] as num).toDouble(),
    opacity: (json['opacity'] as num).toDouble(),
    flow: (json['flow'] as num).toDouble(),
    hardness: (json['hardness'] as num).toDouble(),
    spacing: (json['spacing'] as num).toDouble(),
    rotation: (json['rotation'] as num).toDouble(),
    scatter: (json['scatter'] as num).toDouble(),
    jitter: (json['jitter'] as num).toDouble(),
    stabilization: StabilizationMode.values.firstWhere(
      (s) => s.name == json['stabilization'],
      orElse: () => StabilizationMode.basic,
    ),
    streamline: (json['streamline'] as num?)?.toDouble() ?? 0.0,
    isEraser: json['isEraser'] as bool? ?? false,
    isSmudge: json['isSmudge'] as bool? ?? false,
    isBlur: json['isBlur'] as bool? ?? false,
    isGlow: json['isGlow'] as bool? ?? false,
    isSpray: json['isSpray'] as bool? ?? false,
    isCalligraphy: json['isCalligraphy'] as bool? ?? false,
    isCrayon: json['isCrayon'] as bool? ?? false,
    isDotted: json['isDotted'] as bool? ?? false,
    isPatternStamp: json['isPatternStamp'] as bool? ?? false,
    isPixel: json['isPixel'] as bool? ?? false,
    isHighlighter: json['isHighlighter'] as bool? ?? false,
    isRainbow: json['isRainbow'] as bool? ?? false,
    isGradient: json['isGradient'] as bool? ?? false,
    isFavorite: json['isFavorite'] as bool? ?? false,
    isCustom: json['isCustom'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    size,
    opacity,
    flow,
    hardness,
    spacing,
    rotation,
    scatter,
    jitter,
    stabilization,
    streamline,
    isEraser,
    isSmudge,
    isBlur,
    isGlow,
    isSpray,
    isCalligraphy,
    isCrayon,
    isDotted,
    isPatternStamp,
    isPixel,
    isHighlighter,
    isRainbow,
    isGradient,
    isFavorite,
    isCustom,
  ];
}

/// Geometric shapes or fill types that a Stroke can represent.
enum ShapeType {
  none('Freehand'),
  line('Line'),
  rectangle('Rectangle'),
  roundedRectangle('Rounded Rect'),
  circle('Circle'),
  triangle('Triangle'),
  star('Star'),
  heart('Heart'),
  hexagon('Hexagon'),
  diamond('Diamond'),
  arrow('Arrow'),
  cloud('Cloud'),
  speechBubble('Speech Bubble'),
  floodFill('Flood Fill'),
  gradientFill('Gradient Fill'),
  text('Text'),
  image('Photo Image'),
  // New shapes for shapes & icons library
  pentagon('Pentagon'),
  octagon('Octagon'),
  crescent('Crescent'),
  chevron('Chevron'),
  banner('Banner'),
  starburst('Starburst'),
  shield('Shield'),
  ring('Ring'),
  cross('Cross'),
  playButton('Play Button'),
  musicNote('Music Note'),
  crown('Crown');

  const ShapeType(this.label);
  final String label;
}

/// A completed or in-progress stroke on the canvas.
class Stroke extends Equatable {
  Stroke({
    String? id,
    required this.points,
    required this.color,
    required this.brush,
    this.blendMode = DrawBlendMode.normal,
    this.shapeType = ShapeType.none,
    this.isFilled = false,
    this.text,
    this.fontFamily,
    this.fontSize,
    this.isBold = false,
    this.isItalic = false,
    this.imagePath,
    this.imageRotation,
    this.stampType,
    this.secondaryColor,
    this.gradientType,
    this.rainbowMode,
    // Text styling
    this.textAlign,
    this.textDecoration,
    this.hasShadow = false,
    this.textShadowOffsetX = 2.0,
    this.textShadowOffsetY = 2.0,
    this.textShadowBlur = 4.0,
    this.textLineHeight,
    this.textStrokeColor,
    this.textStrokeWidth,
    this.textBackgroundColor,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final List<StrokePoint> points;
  final Color color;
  final BrushPreset brush;
  final DrawBlendMode blendMode;
  final ShapeType shapeType;
  final bool isFilled;
  final String? text;
  final String? fontFamily;
  final double? fontSize;
  final bool isBold;
  final bool isItalic;
  final String? imagePath;
  final double? imageRotation;
  final PatternStampType? stampType;
  final Color? secondaryColor;
  final GradientType? gradientType;
  final RainbowMode? rainbowMode;
  // Text styling fields
  final String? textAlign; // 'left', 'center', 'right'
  final String? textDecoration; // 'underline', 'strikethrough', 'none'
  final bool hasShadow;
  final double textShadowOffsetX;
  final double textShadowOffsetY;
  final double textShadowBlur;
  final double? textLineHeight;
  final Color? textStrokeColor;
  final double? textStrokeWidth;
  final Color? textBackgroundColor;

  Stroke copyWith({
    String? id,
    List<StrokePoint>? points,
    Color? color,
    BrushPreset? brush,
    DrawBlendMode? blendMode,
    ShapeType? shapeType,
    bool? isFilled,
    String? text,
    String? fontFamily,
    double? fontSize,
    bool? isBold,
    bool? isItalic,
    String? imagePath,
    double? imageRotation,
    PatternStampType? stampType,
    Color? secondaryColor,
    GradientType? gradientType,
    RainbowMode? rainbowMode,
    String? textAlign,
    String? textDecoration,
    bool? hasShadow,
    double? textShadowOffsetX,
    double? textShadowOffsetY,
    double? textShadowBlur,
    double? textLineHeight,
    Color? textStrokeColor,
    double? textStrokeWidth,
    Color? textBackgroundColor,
  }) {
    return Stroke(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      brush: brush ?? this.brush,
      blendMode: blendMode ?? this.blendMode,
      shapeType: shapeType ?? this.shapeType,
      isFilled: isFilled ?? this.isFilled,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      imagePath: imagePath ?? this.imagePath,
      imageRotation: imageRotation ?? this.imageRotation,
      stampType: stampType ?? this.stampType,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      gradientType: gradientType ?? this.gradientType,
      rainbowMode: rainbowMode ?? this.rainbowMode,
      textAlign: textAlign ?? this.textAlign,
      textDecoration: textDecoration ?? this.textDecoration,
      hasShadow: hasShadow ?? this.hasShadow,
      textShadowOffsetX: textShadowOffsetX ?? this.textShadowOffsetX,
      textShadowOffsetY: textShadowOffsetY ?? this.textShadowOffsetY,
      textShadowBlur: textShadowBlur ?? this.textShadowBlur,
      textLineHeight: textLineHeight ?? this.textLineHeight,
      textStrokeColor: textStrokeColor ?? this.textStrokeColor,
      textStrokeWidth: textStrokeWidth ?? this.textStrokeWidth,
      textBackgroundColor: textBackgroundColor ?? this.textBackgroundColor,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'points': points.map((p) => p.toJson()).toList(),
    'color': color.toARGB32(),
    'brush': brush.toJson(),
    'blendMode': blendMode.name,
    'shapeType': shapeType.name,
    'isFilled': isFilled,
    'text': text,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'isBold': isBold,
    'isItalic': isItalic,
    'imagePath': imagePath,
    'imageRotation': imageRotation,
    'stampType': stampType?.name,
    'secondaryColor': secondaryColor?.toARGB32(),
    'gradientType': gradientType?.name,
    'rainbowMode': rainbowMode?.name,
    'textAlign': textAlign,
    'textDecoration': textDecoration,
    'hasShadow': hasShadow,
    'textShadowOffsetX': textShadowOffsetX,
    'textShadowOffsetY': textShadowOffsetY,
    'textShadowBlur': textShadowBlur,
    'textLineHeight': textLineHeight,
    'textStrokeColor': textStrokeColor?.toARGB32(),
    'textStrokeWidth': textStrokeWidth,
    'textBackgroundColor': textBackgroundColor?.toARGB32(),
  };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
    id: json['id'] as String,
    points:
        (json['points'] as List)
            .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
            .toList(),
    color: Color(json['color'] as int),
    brush: BrushPreset.fromJson(json['brush'] as Map<String, dynamic>),
    blendMode: DrawBlendMode.values.firstWhere(
      (b) => b.name == json['blendMode'],
      orElse: () => DrawBlendMode.normal,
    ),
    shapeType: ShapeType.values.firstWhere(
      (s) => s.name == json['shapeType'],
      orElse: () => ShapeType.none,
    ),
    isFilled: json['isFilled'] as bool? ?? false,
    text: json['text'] as String?,
    fontFamily: json['fontFamily'] as String?,
    fontSize: (json['fontSize'] as num?)?.toDouble(),
    isBold: json['isBold'] as bool? ?? false,
    isItalic: json['isItalic'] as bool? ?? false,
    imagePath: json['imagePath'] as String?,
    imageRotation: (json['imageRotation'] as num?)?.toDouble(),
    stampType: json['stampType'] != null
        ? PatternStampType.values.firstWhere(
            (s) => s.name == json['stampType'],
            orElse: () => PatternStampType.star,
          )
        : null,
    secondaryColor: json['secondaryColor'] != null ? Color(json['secondaryColor'] as int) : null,
    gradientType: json['gradientType'] != null
        ? GradientType.values.firstWhere(
            (g) => g.name == json['gradientType'],
            orElse: () => GradientType.linear,
          )
        : null,
    rainbowMode: json['rainbowMode'] != null
        ? RainbowMode.values.firstWhere(
            (r) => r.name == json['rainbowMode'],
            orElse: () => RainbowMode.spectrum,
          )
        : null,
    textAlign: json['textAlign'] as String?,
    textDecoration: json['textDecoration'] as String?,
    hasShadow: json['hasShadow'] as bool? ?? false,
    textShadowOffsetX: (json['textShadowOffsetX'] as num?)?.toDouble() ?? 2.0,
    textShadowOffsetY: (json['textShadowOffsetY'] as num?)?.toDouble() ?? 2.0,
    textShadowBlur: (json['textShadowBlur'] as num?)?.toDouble() ?? 4.0,
    textLineHeight: (json['textLineHeight'] as num?)?.toDouble(),
    textStrokeColor: json['textStrokeColor'] != null ? Color(json['textStrokeColor'] as int) : null,
    textStrokeWidth: (json['textStrokeWidth'] as num?)?.toDouble(),
    textBackgroundColor: json['textBackgroundColor'] != null ? Color(json['textBackgroundColor'] as int) : null,
  );

  /// Bounding rectangle enclosing the stroke, padded by half brush size.
  Rect get bounds {
    if (points.isEmpty) return Rect.zero;
    if (shapeType == ShapeType.text) {
      final fSize = fontSize ?? 24.0;
      final textLen = text?.length ?? 5;
      final w = textLen * fSize * 0.65;
      final h = fSize * 1.3;
      return Rect.fromLTWH(points.first.x, points.first.y, w, h);
    }
    double minX = points.first.x;
    double maxX = points.first.x;
    double minY = points.first.y;
    double maxY = points.first.y;

    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final halfWidth = brush.size / 2;
    return Rect.fromLTRB(
      minX - halfWidth,
      minY - halfWidth,
      maxX + halfWidth,
      maxY + halfWidth,
    );
  }

  @override
  List<Object?> get props => [
    id,
    points,
    color,
    brush,
    blendMode,
    shapeType,
    isFilled,
    text,
    fontFamily,
    fontSize,
    isBold,
    isItalic,
    imagePath,
    imageRotation,
    stampType,
    secondaryColor,
    gradientType,
    rainbowMode,
    textAlign,
    textDecoration,
    hasShadow,
    textShadowOffsetX,
    textShadowOffsetY,
    textShadowBlur,
    textLineHeight,
    textStrokeColor,
    textStrokeWidth,
    textBackgroundColor,
  ];
}
