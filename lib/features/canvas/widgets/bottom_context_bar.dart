import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stroke.dart';
import '../models/tools.dart';
import '../providers/canvas_providers.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// Bottom context bar that adapts dynamically to the currently selected tool.
class BottomContextBar extends ConsumerWidget {
  const BottomContextBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
    final brush = ref.watch(activeBrushProvider);
    final undoRedo = ref.watch(undoRedoProvider);
    final theme = Theme.of(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: switch (activeTool) {
                  DrawingTool.shape => _ShapeContextBar(),
                  DrawingTool.fill => _FillContextBar(),
                  DrawingTool.eyedropper => _EyedropperContextBar(),
                  DrawingTool.pencil => _PencilContextBar(brush: brush),
                  DrawingTool.marker => _MarkerContextBar(brush: brush),
                  DrawingTool.eraser => _EraserContextBar(brush: brush),
                  DrawingTool.pen => _PenContextBar(brush: brush),
                  _ => _BrushContextBar(brush: brush),
                },
              ),
            ),
            const VerticalDivider(
              width: 16,
              thickness: 1,
              indent: 12,
              endIndent: 12,
              color: Color(0xFFE5E7EB),
            ),
            // Quick feature Undo button
            IconButton(
              icon: Icon(
                Icons.undo_rounded,
                size: 20,
                color: undoRedo.canUndo
                    ? theme.colorScheme.primary
                    : const Color(0xFFD1D5DB),
              ),
              tooltip: 'Undo (Ctrl+Z)',
              visualDensity: VisualDensity.compact,
              onPressed: undoRedo.canUndo
                  ? () {
                      SoundEffectService.instance.playWhoosh();
                      ref.read(undoRedoProvider.notifier).undo();
                    }
                  : null,
            ),
            // Quick feature Redo button
            IconButton(
              icon: Icon(
                Icons.redo_rounded,
                size: 20,
                color: undoRedo.canRedo
                    ? theme.colorScheme.primary
                    : const Color(0xFFD1D5DB),
              ),
              tooltip: 'Redo (Ctrl+Y)',
              visualDensity: VisualDensity.compact,
              onPressed: undoRedo.canRedo
                  ? () {
                      SoundEffectService.instance.playPop();
                      ref.read(undoRedoProvider.notifier).redo();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Specialized context bar for Geometric Shapes.
class _ShapeContextBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeShape = ref.watch(activeShapeProvider);
    final isFilled = ref.watch(isShapeFilledProvider);
    final brush = ref.watch(activeBrushProvider);
    final theme = Theme.of(context);

    final shapes = [
      (ShapeType.rectangle, Icons.crop_square_rounded, 'Rectangle'),
      (ShapeType.roundedRectangle, Icons.rounded_corner_rounded, 'Rounded Rect'),
      (ShapeType.circle, Icons.circle_outlined, 'Circle'),
      (ShapeType.line, Icons.horizontal_rule_rounded, 'Line'),
      (ShapeType.triangle, Icons.change_history_rounded, 'Triangle'),
      (ShapeType.star, Icons.star_border_rounded, 'Star'),
      (ShapeType.heart, Icons.favorite_rounded, 'Heart'),
      (ShapeType.hexagon, Icons.hexagon_outlined, 'Hexagon'),
      (ShapeType.pentagon, Icons.pentagon_outlined, 'Pentagon'),
      (ShapeType.octagon, Icons.stop_rounded, 'Octagon'),
      (ShapeType.diamond, Icons.diamond_outlined, 'Diamond'),
      (ShapeType.ring, Icons.panorama_fish_eye_rounded, 'Ring'),
      (ShapeType.cross, Icons.add_rounded, 'Cross'),
      (ShapeType.crescent, Icons.dark_mode_outlined, 'Crescent'),
      (ShapeType.arrow, Icons.arrow_forward_rounded, 'Arrow'),
      (ShapeType.chevron, Icons.chevron_right_rounded, 'Chevron'),
      (ShapeType.speechBubble, Icons.chat_bubble_outline_rounded, 'Speech Bubble'),
      (ShapeType.playButton, Icons.play_circle_outline_rounded, 'Play Button'),
      (ShapeType.musicNote, Icons.music_note_rounded, 'Music Note'),
      (ShapeType.crown, Icons.workspace_premium_rounded, 'Crown'),
      (ShapeType.cloud, Icons.cloud_outlined, 'Cloud'),
      (ShapeType.banner, Icons.flag_rounded, 'Banner'),
      (ShapeType.starburst, Icons.auto_awesome_rounded, 'Starburst'),
      (ShapeType.shield, Icons.shield_outlined, 'Shield'),
    ];

    final effectiveValue = shapes.any((s) => s.$1 == activeShape) ? activeShape : shapes.first.$1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Shape selector dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ShapeType>(
              value: effectiveValue,
              isDense: true,
              icon: const Icon(Icons.expand_more_rounded, size: 16),
              items: shapes.map((s) {
                return DropdownMenuItem<ShapeType>(
                  value: s.$1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s.$2, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(s.$3, style: theme.textTheme.labelMedium),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (shape) {
                if (shape != null) {
                  SoundEffectService.instance.playPop();
                  ref.read(activeShapeProvider.notifier).state = shape;
                }
              },
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // Fill toggle button
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          onTap: () {
            SoundEffectService.instance.playPop();
            ref.read(isShapeFilledProvider.notifier).state = !isFilled;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isFilled
                  ? theme.colorScheme.secondaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFilled ? Icons.format_color_fill_rounded : Icons.crop_square_outlined,
                  size: 16,
                  color: isFilled
                      ? theme.colorScheme.secondary
                      : theme.iconTheme.color,
                ),
                const SizedBox(width: 4),
                Text(
                  isFilled ? 'Filled' : 'Outline',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isFilled ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // Line width slider
        _SliderControl(
          icon: Icons.line_weight_rounded,
          label: 'Border',
          value: brush.size,
          min: 1.0,
          max: 50.0,
          displayValue: '${brush.size.round()}px',
          onChanged: (v) => ref.read(activeBrushProvider.notifier).setSize(v),
        ),
      ],
    );
  }
}

/// Specialized context bar for Flood Bucket Fill.
class _FillContextBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tolerance = ref.watch(fillToleranceProvider);
    final activeColor = ref.watch(activeColorProvider);
    final theme = Theme.of(context);

    return Row(
      children: [
        // Bucket badge with current color
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Bucket Fill',
                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        // Fill Tolerance slider
        _SliderControl(
          icon: Icons.tune_rounded,
          label: 'Tolerance',
          value: tolerance.toDouble(),
          min: 5.0,
          max: 95.0,
          displayValue: '$tolerance%',
          onChanged: (v) {
            ref.read(fillToleranceProvider.notifier).state = v.round();
          },
        ),

        const SizedBox(width: AppSpacing.md),

        // Tap tip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_rounded, size: 15, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                'Tap to Fill Area',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Specialized context bar for Eyedropper Color Sampler.
class _EyedropperContextBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeColor = ref.watch(activeColorProvider);
    final theme = Theme.of(context);
    final hexString =
        '#${(activeColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.colorize_rounded, size: 16),
              const SizedBox(width: 6),
              Text(
                'Eyedropper',
                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        // Color sample preview swatch
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activeColor,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          hexString,
          style: theme.textTheme.labelMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // Tip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swipe_rounded, size: 15, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                'Drag canvas to sample',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Specialized context bar for Graphite Pencil.
class _PencilContextBar extends ConsumerWidget {
  const _PencilContextBar({required this.brush});
  final BrushPreset brush;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const _ToolBadge(icon: Icons.create_rounded, label: 'Pencil (Graphite)'),
        const SizedBox(width: AppSpacing.sm),
        _SliderControl(
          icon: Icons.line_weight_rounded,
          label: 'Lead',
          value: brush.size,
          min: 1.0,
          max: 20.0,
          displayValue: '${brush.size.toStringAsFixed(1)}px',
          onChanged: (v) => ref.read(activeBrushProvider.notifier).setSize(v),
        ),
        const SizedBox(width: AppSpacing.sm),
        _SliderControl(
          icon: Icons.grain_rounded,
          label: 'Hardness',
          value: brush.hardness,
          min: 0.1,
          max: 1.0,
          displayValue: '${(brush.hardness * 100).round()}%',
          onChanged: (v) => ref.read(activeBrushProvider.notifier).setHardness(v),
        ),
        const SizedBox(width: AppSpacing.sm),
        _SliderControl(
          icon: Icons.opacity_rounded,
          label: 'Opacity',
          value: brush.opacity,
          min: 0.1,
          max: 1.0,
          displayValue: '${(brush.opacity * 100).round()}%',
          onChanged: (v) => ref.read(activeBrushProvider.notifier).setOpacity(v),
        ),
      ],
    );
  }
}

/// Specialized context bar for Chisel Marker.
class _MarkerContextBar extends ConsumerWidget {
  const _MarkerContextBar({required this.brush});
  final BrushPreset brush;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const _ToolBadge(icon: Icons.format_paint_rounded, label: 'Marker (Glaze)'),
        const SizedBox(width: AppSpacing.sm),
        _SliderControl(
          icon: Icons.brush_rounded,
          label: 'Chisel Width',
          value: brush.size,
          min: 8.0,
          max: 80.0,
          displayValue: '${brush.size.round()}px',
          onChanged: (v) => ref.read(activeBrushProvider.notifier).setSize(v),
        ),
        const SizedBox(width: AppSpacing.sm),
        _SliderControl(
          icon: Icons.opacity_rounded,
          label: 'Ink Glaze',
          value: brush.opacity,
          min: 0.1,
          max: 0.9,
          displayValue: '${(brush.opacity * 100).round()}%',
          onChanged: (v) => ref.read(activeBrushProvider.notifier).setOpacity(v),
        ),
      ],
    );
  }
}

/// Specialized context bar for Eraser.
class _EraserContextBar extends ConsumerWidget {
  const _EraserContextBar({required this.brush});
  final BrushPreset brush;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const _ToolBadge(icon: Icons.auto_fix_high_rounded, label: 'Eraser'),
        const SizedBox(width: AppSpacing.sm),
        _SliderControl(
          icon: Icons.circle,
          label: 'Eraser Size',
          value: brush.size,
          min: 4.0,
          max: 120.0,
          displayValue: '${brush.size.round()}px',
          onChanged: (v) => ref.read(activeBrushProvider.notifier).setSize(v),
        ),
        const SizedBox(width: AppSpacing.sm),
        _SliderControl(
          icon: Icons.blur_on_rounded,
          label: 'Edge Softness',
          value: 1.0 - brush.hardness,
          min: 0.0,
          max: 1.0,
          displayValue: '${((1.0 - brush.hardness) * 100).round()}%',
          onChanged: (v) => ref.read(activeBrushProvider.notifier).setHardness(1.0 - v),
        ),
      ],
    );
  }
}

/// Specialized context bar for Inking Pen.
class _PenContextBar extends ConsumerWidget {
  const _PenContextBar({required this.brush});
  final BrushPreset brush;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const _ToolBadge(icon: Icons.edit_rounded, label: 'Ink Pen'),
        const SizedBox(width: AppSpacing.sm),
        _SliderControl(
          icon: Icons.circle,
          label: 'Nib',
          value: brush.size,
          min: 1.0,
          max: 30.0,
          displayValue: '${brush.size.toStringAsFixed(1)}px',
          onChanged: (v) => ref.read(activeBrushProvider.notifier).setSize(v),
        ),
        const SizedBox(width: AppSpacing.sm),
        _SliderControl(
          icon: Icons.opacity_rounded,
          label: 'Ink Flow',
          value: brush.flow,
          min: 0.1,
          max: 1.0,
          displayValue: '${(brush.flow * 100).round()}%',
          onChanged: (v) => ref.read(activeBrushProvider.notifier).setFlow(v),
        ),
        const SizedBox(width: AppSpacing.sm),
        _StabilizerDropdown(
          mode: brush.stabilization,
          onChanged: (mode) =>
              ref.read(activeBrushProvider.notifier).setStabilization(mode),
        ),
      ],
    );
  }
}

/// Context bar for general Brushes (Size, Opacity, Flow, Stabilizer).
class _BrushContextBar extends ConsumerWidget {
  const _BrushContextBar({required this.brush});
  final BrushPreset brush;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const _ToolBadge(icon: Icons.brush_rounded, label: 'Brush'),
        const SizedBox(width: AppSpacing.sm),
        _SliderControl(
          icon: Icons.circle,
          label: 'Size',
          value: brush.size,
          min: CanvasDefaults.minBrushSize,
          max: CanvasDefaults.maxBrushSize,
          displayValue: '${brush.size.round()}',
          onChanged: (v) => ref.read(activeBrushProvider.notifier).setSize(v),
        ),
        const SizedBox(width: AppSpacing.sm),
        _SliderControl(
          icon: Icons.opacity_rounded,
          label: 'Opacity',
          value: brush.opacity,
          min: 0.01,
          max: 1.0,
          displayValue: '${(brush.opacity * 100).round()}%',
          onChanged: (v) => ref.read(activeBrushProvider.notifier).setOpacity(v),
        ),
        const SizedBox(width: AppSpacing.sm),
        _SliderControl(
          icon: Icons.water_drop_rounded,
          label: 'Flow',
          value: brush.flow,
          min: 0.01,
          max: 1.0,
          displayValue: '${(brush.flow * 100).round()}%',
          onChanged: (v) => ref.read(activeBrushProvider.notifier).setFlow(v),
        ),
        const SizedBox(width: AppSpacing.sm),
        _StabilizerDropdown(
          mode: brush.stabilization,
          onChanged: (mode) =>
              ref.read(activeBrushProvider.notifier).setStabilization(mode),
        ),
      ],
    );
  }
}

class _ToolBadge extends StatelessWidget {
  const _ToolBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Compact slider control for brush parameters.
class _SliderControl extends StatelessWidget {
  const _SliderControl({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 130,
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.iconTheme.color),
          const SizedBox(width: 4),
          Expanded(
            child: SliderTheme(
              data: theme.sliderTheme.copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              displayValue,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown for brush stabilization mode.
class _StabilizerDropdown extends StatelessWidget {
  const _StabilizerDropdown({
    required this.mode,
    required this.onChanged,
  });

  final StabilizationMode mode;
  final ValueChanged<StabilizationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StabilizationMode>(
          value: mode,
          isDense: true,
          style: theme.textTheme.labelSmall,
          icon: const Icon(Icons.expand_more, size: 16),
          items:
              StabilizationMode.values
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(m.label, style: theme.textTheme.labelSmall),
                    ),
                  )
                  .toList(),
          onChanged: (v) {
            if (v != null) {
              SoundEffectService.instance.playPop();
              onChanged(v);
            }
          },
        ),
      ),
    );
  }
}

