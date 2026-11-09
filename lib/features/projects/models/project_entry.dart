import 'package:equatable/equatable.dart';

/// Metadata entry for a saved project shown in galleries, recents, and project manager.
class ProjectEntry extends Equatable {
  const ProjectEntry({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.layerCount,
    required this.strokeCount,
    this.thumbnailPath,
    this.isFavorite = false,
    this.isTrash = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int width;
  final int height;
  final int layerCount;
  final int strokeCount;
  final String? thumbnailPath;
  final bool isFavorite;
  final bool isTrash;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectEntry copyWith({
    String? name,
    int? width,
    int? height,
    int? layerCount,
    int? strokeCount,
    String? thumbnailPath,
    bool? isFavorite,
    bool? isTrash,
    DateTime? updatedAt,
  }) {
    return ProjectEntry(
      id: id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      layerCount: layerCount ?? this.layerCount,
      strokeCount: strokeCount ?? this.strokeCount,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isFavorite: isFavorite ?? this.isFavorite,
      isTrash: isTrash ?? this.isTrash,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'width': width,
    'height': height,
    'layerCount': layerCount,
    'strokeCount': strokeCount,
    'thumbnailPath': thumbnailPath,
    'isFavorite': isFavorite,
    'isTrash': isTrash,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ProjectEntry.fromJson(Map<String, dynamic> json) => ProjectEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    width: json['width'] as int,
    height: json['height'] as int,
    layerCount: json['layerCount'] as int? ?? 1,
    strokeCount: json['strokeCount'] as int? ?? 0,
    thumbnailPath: json['thumbnailPath'] as String?,
    isFavorite: json['isFavorite'] as bool? ?? false,
    isTrash: json['isTrash'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  @override
  List<Object?> get props => [
    id,
    name,
    width,
    height,
    layerCount,
    strokeCount,
    thumbnailPath,
    isFavorite,
    isTrash,
    createdAt,
    updatedAt,
  ];
}
