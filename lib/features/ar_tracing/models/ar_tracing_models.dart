import 'package:flutter/material.dart';

/// Visual filter applied to the line-art overlay in AR Tracing.
enum ArFilterMode {
  normal('Normal', Icons.contrast_rounded),
  highContrast('High Contrast', Icons.brightness_medium_rounded),
  neonInvert('Neon Invert', Icons.auto_awesome_rounded),
  charcoalEdge('Charcoal', Icons.brush_rounded);

  const ArFilterMode(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Transform and rendering configuration for the AR Tracing overlay.
class ArTracingConfig {
  const ArTracingConfig({
    this.scale = 1.0,
    this.rotation = 0.0,
    this.offset = Offset.zero,
    this.opacity = 0.65,
    this.isLocked = false,
    this.isFrozen = false,
    this.isFlashOn = false,
    this.filterMode = ArFilterMode.normal,
  });

  final double scale;
  final double rotation;
  final Offset offset;
  final double opacity;
  final bool isLocked;
  final bool isFrozen;
  final bool isFlashOn;
  final ArFilterMode filterMode;

  ArTracingConfig copyWith({
    double? scale,
    double? rotation,
    Offset? offset,
    double? opacity,
    bool? isLocked,
    bool? isFrozen,
    bool? isFlashOn,
    ArFilterMode? filterMode,
  }) {
    return ArTracingConfig(
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      offset: offset ?? this.offset,
      opacity: opacity ?? this.opacity,
      isLocked: isLocked ?? this.isLocked,
      isFrozen: isFrozen ?? this.isFrozen,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      filterMode: filterMode ?? this.filterMode,
    );
  }
}
