import 'dart:ui';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'stroke.dart';

/// Types of layers supported by the drawing engine.
enum LayerType {
  paint('Paint'),
  sketch('Sketch'),
  lineArt('Line Art'),
  image('Image'),
  text('Text'),
  adjustment('Adjustment'),
  group('Group');

  const LayerType(this.label);
  final String label;
}

/// A single layer in the canvas document.
class LayerModel extends Equatable {
  LayerModel({
    String? id,
    required this.name,
    this.type = LayerType.paint,
    this.opacity = 1.0,
    this.blendMode = DrawBlendMode.normal,
    this.isVisible = true,
    this.isLocked = false,
    this.isAlphaLocked = false,
    this.isClipping = false,
    List<Stroke>? strokes,
    this.parentGroupId,
  }) : id = id ?? const Uuid().v4(),
       strokes = strokes ?? [];

  final String id;
  final String name;
  final LayerType type;
  final double opacity;
  final DrawBlendMode blendMode;
  final bool isVisible;
  final bool isLocked;
  final bool isAlphaLocked;
  final bool isClipping;
  final List<Stroke> strokes;
  final String? parentGroupId;

  LayerModel copyWith({
    String? name,
    LayerType? type,
    double? opacity,
    DrawBlendMode? blendMode,
    bool? isVisible,
    bool? isLocked,
    bool? isAlphaLocked,
    bool? isClipping,
    List<Stroke>? strokes,
    String? parentGroupId,
    bool clearParentGroupId = false,
  }) {
    return LayerModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      isAlphaLocked: isAlphaLocked ?? this.isAlphaLocked,
      isClipping: isClipping ?? this.isClipping,
      strokes: strokes ?? List.from(this.strokes),
      parentGroupId: clearParentGroupId ? null : (parentGroupId ?? this.parentGroupId),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'opacity': opacity,
    'blendMode': blendMode.name,
    'isVisible': isVisible,
    'isLocked': isLocked,
    'isAlphaLocked': isAlphaLocked,
    'isClipping': isClipping,
    'strokes': strokes.map((s) => s.toJson()).toList(),
    'parentGroupId': parentGroupId,
  };

  factory LayerModel.fromJson(Map<String, dynamic> json) => LayerModel(
    id: json['id'] as String,
    name: json['name'] as String,
    type: LayerType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => LayerType.paint,
    ),
    opacity: (json['opacity'] as num).toDouble(),
    blendMode: DrawBlendMode.values.firstWhere(
      (b) => b.name == json['blendMode'],
      orElse: () => DrawBlendMode.normal,
    ),
    isVisible: json['isVisible'] as bool? ?? true,
    isLocked: json['isLocked'] as bool? ?? false,
    isAlphaLocked: json['isAlphaLocked'] as bool? ?? false,
    isClipping: json['isClipping'] as bool? ?? false,
    strokes:
        (json['strokes'] as List?)
            ?.map((s) => Stroke.fromJson(s as Map<String, dynamic>))
            .toList(),
    parentGroupId: json['parentGroupId'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    opacity,
    blendMode,
    isVisible,
    isLocked,
    isAlphaLocked,
    isClipping,
    strokes,
    parentGroupId,
  ];
}

/// The complete canvas document holding all layers and metadata.
class CanvasDocument extends Equatable {
  CanvasDocument({
    String? id,
    required this.name,
    required this.width,
    required this.height,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.isTransparentBackground = false,
    this.isThumbnail = false,
    List<LayerModel>? layers,
    this.activeLayerIndex = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       layers = layers ?? [LayerModel(name: 'Layer 1')],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final int width;
  final int height;
  final Color backgroundColor;
  final bool isTransparentBackground;
  final bool isThumbnail;
  final List<LayerModel> layers;
  final int activeLayerIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The currently active layer, or null if no layers exist.
  LayerModel? get activeLayer =>
      layers.isNotEmpty && activeLayerIndex < layers.length
          ? layers[activeLayerIndex]
          : null;

  CanvasDocument copyWith({
    String? name,
    int? width,
    int? height,
    Color? backgroundColor,
    bool? isTransparentBackground,
    bool? isThumbnail,
    List<LayerModel>? layers,
    int? activeLayerIndex,
    DateTime? updatedAt,
  }) {
    return CanvasDocument(
      id: id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isTransparentBackground:
          isTransparentBackground ?? this.isTransparentBackground,
      isThumbnail: isThumbnail ?? this.isThumbnail,
      layers: layers ?? this.layers.map((l) => l.copyWith()).toList(),
      activeLayerIndex: activeLayerIndex ?? this.activeLayerIndex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'width': width,
    'height': height,
    'backgroundColor': backgroundColor.toARGB32(),
    'isTransparentBackground': isTransparentBackground,
    'isThumbnail': isThumbnail,
    'layers': layers.map((l) => l.toJson()).toList(),
    'activeLayerIndex': activeLayerIndex,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CanvasDocument.fromJson(Map<String, dynamic> json) =>
      CanvasDocument(
        id: json['id'] as String,
        name: json['name'] as String,
        width: json['width'] as int,
        height: json['height'] as int,
        backgroundColor: Color(json['backgroundColor'] as int),
        isTransparentBackground:
            json['isTransparentBackground'] as bool? ?? false,
        isThumbnail: json['isThumbnail'] as bool? ??
            ((json['name'] as String? ?? '').toLowerCase().contains('thumbnail')),
        layers:
            (json['layers'] as List)
                .map((l) => LayerModel.fromJson(l as Map<String, dynamic>))
                .toList(),
        activeLayerIndex: json['activeLayerIndex'] as int? ?? 0,
        createdAt:
            json['createdAt'] != null
                ? DateTime.parse(json['createdAt'] as String)
                : null,
        updatedAt:
            json['updatedAt'] != null
                ? DateTime.parse(json['updatedAt'] as String)
                : null,
      );

  @override
  List<Object?> get props => [
    id,
    name,
    width,
    height,
    backgroundColor,
    isTransparentBackground,
    isThumbnail,
    layers,
    activeLayerIndex,
    createdAt,
    updatedAt,
  ];
}
