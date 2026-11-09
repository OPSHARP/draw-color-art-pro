import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drawing_guides.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// Provider for drawing guide configuration.
final drawingGuideProvider = StateProvider<DrawingGuideConfig>(
  (ref) => const DrawingGuideConfig(),
);

/// Modal bottom sheet for configuring drawing and perspective guides.
class DrawingGuidesModal extends ConsumerWidget {
  const DrawingGuidesModal({super.key});

  static Future<void> show(BuildContext context) {
    SoundEffectService.instance.playPop();
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const DrawingGuidesModal(),
    );
  }

  static const _guideColors = [
    Color(0xFF6C5CE7), // Purple
    Color(0xFF00CEC9), // Cyan
    Color(0xFFFF7675), // Coral
    Color(0xFFFDCB6E), // Gold
    Color(0xFF74B9FF), // Sky Blue
    Color(0xFF636E72), // Slate Grey
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guide = ref.watch(drawingGuideProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, bottomInset + AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.grid_4x4_rounded, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Drawing & Perspective Guides', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Isometric, 2D Grid & Vanishing Points', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Guide Mode Selector ──
          Text('Guide Mode', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DrawingGuideType.values.map((type) {
                final isSelected = guide.type == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type.label),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : null,
                    ),
                    onSelected: (val) {
                      SoundEffectService.instance.playPop();
                      ref.read(drawingGuideProvider.notifier).state =
                          guide.copyWith(type: val ? type : DrawingGuideType.none);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            guide.type.description,
            style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white70 : Colors.black54),
          ),

          if (guide.isEnabled) ...[
            const SizedBox(height: AppSpacing.md),

            // ── Opacity Slider ──
            Row(
              children: [
                Text('Opacity: ${(guide.opacity * 100).round()}%', style: theme.textTheme.labelMedium),
                Expanded(
                  child: Slider(
                    value: guide.opacity,
                    min: 0.1,
                    max: 0.9,
                    divisions: 8,
                    onChanged: (val) {
                      ref.read(drawingGuideProvider.notifier).state = guide.copyWith(opacity: val);
                    },
                  ),
                ),
              ],
            ),

            // ── Grid Spacing Slider (for 2D Grid and Isometric) ──
            if (guide.type == DrawingGuideType.grid2D || guide.type == DrawingGuideType.isometric) ...[
              Row(
                children: [
                  Text('Spacing: ${guide.spacing.round()} px', style: theme.textTheme.labelMedium),
                  Expanded(
                    child: Slider(
                      value: guide.spacing,
                      min: 16.0,
                      max: 96.0,
                      divisions: 10,
                      onChanged: (val) {
                        ref.read(drawingGuideProvider.notifier).state = guide.copyWith(spacing: val);
                      },
                    ),
                  ),
                ],
              ),
            ],

            // ── Horizon Ratio Slider (for Perspective) ──
            if (guide.type == DrawingGuideType.perspective1P ||
                guide.type == DrawingGuideType.perspective2P ||
                guide.type == DrawingGuideType.perspective3P) ...[
              Row(
                children: [
                  Text('Horizon: ${(guide.horizonRatio * 100).round()}%', style: theme.textTheme.labelMedium),
                  Expanded(
                    child: Slider(
                      value: guide.horizonRatio,
                      min: 0.2,
                      max: 0.8,
                      onChanged: (val) {
                        ref.read(drawingGuideProvider.notifier).state = guide.copyWith(horizonRatio: val);
                      },
                    ),
                  ),
                ],
              ),
              if (guide.type == DrawingGuideType.perspective3P)
                Row(
                  children: [
                    Text('Vertical VP: ${(guide.vp3Ratio * 100).round()}%', style: theme.textTheme.labelMedium),
                    Expanded(
                      child: Slider(
                        value: guide.vp3Ratio,
                        min: 0.05,
                        max: 0.95,
                        onChanged: (val) {
                          ref.read(drawingGuideProvider.notifier).state = guide.copyWith(vp3Ratio: val);
                        },
                      ),
                    ),
                  ],
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Perspective Assist (Snap Lines)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: const Text('Constrains hand strokes to vanishing point rays', style: TextStyle(fontSize: 11)),
                value: guide.snapToGuide,
                onChanged: (val) {
                  SoundEffectService.instance.playPop();
                  ref.read(drawingGuideProvider.notifier).state = guide.copyWith(snapToGuide: val);
                },
              ),
            ],

            const SizedBox(height: 6),

            // ── Guide Color Swatches ──
            Text('Guide Color', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: _guideColors.map((color) {
                final isSelected = guide.color.toARGB32() == color.toARGB32();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      SoundEffectService.instance.playPop();
                      ref.read(drawingGuideProvider.notifier).state = guide.copyWith(color: color);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                          width: 2.2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
