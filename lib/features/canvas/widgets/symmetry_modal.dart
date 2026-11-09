import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/symmetry.dart';
import '../models/paper_texture.dart';
import '../providers/canvas_providers.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// Modal bottom sheet allowing users to configure Symmetry / Mandala mode and Canvas Paper Texture.
class SymmetryModal extends ConsumerWidget {
  const SymmetryModal({super.key});

  static void show(BuildContext context) {
    SoundEffectService.instance.playPop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const SymmetryModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symmetry = ref.watch(symmetryProvider);
    final paperTexture = ref.watch(paperTextureProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        border: Border(
          top: BorderSide(
            color: theme.dividerTheme.color ?? Colors.grey.shade800,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFFFF6B9D)],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.filter_vintage_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Symmetry & Mandala Studio',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      SoundEffectService.instance.playPop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Mode Selector ──
              Text(
                'Symmetry Modes (100% Free)',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: SymmetryMode.values.map((mode) {
                  final isSelected = symmetry.mode == mode;
                  final icon = switch (mode) {
                    SymmetryMode.off => Icons.block_rounded,
                    SymmetryMode.vertical => Icons.splitscreen_rounded,
                    SymmetryMode.horizontal => Icons.horizontal_distribute_rounded,
                    SymmetryMode.dual => Icons.grid_view_rounded,
                    SymmetryMode.radial => Icons.filter_vintage_rounded,
                  };

                  return ChoiceChip(
                    avatar: Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : theme.iconTheme.color,
                    ),
                    label: Text(mode.label),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      SoundEffectService.instance.playPop();
                      ref.read(symmetryProvider.notifier).state =
                          symmetry.copyWith(mode: mode);
                    },
                  );
                }).toList(),
              ),

              // ── Mandala Segment Slider (only if radial) ──
              if (symmetry.mode == SymmetryMode.radial) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mandala Segments: ${symmetry.segments}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${symmetry.segments}-fold symmetry',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: symmetry.segments.toDouble(),
                  min: 4,
                  max: 16,
                  divisions: 6, // 4, 6, 8, 10, 12, 14, 16
                  label: '${symmetry.segments}',
                  onChanged: (val) {
                    ref.read(symmetryProvider.notifier).state =
                        symmetry.copyWith(segments: val.round());
                  },
                ),
              ],

              // ── Guide Lines Toggle ──
              if (symmetry.isEnabled) ...[
                const SizedBox(height: AppSpacing.xs),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show Symmetry Guide Lines'),
                  subtitle: const Text('Displays center axis and radial rays on canvas'),
                  value: symmetry.showGuides,
                  activeTrackColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    SoundEffectService.instance.playPop();
                    ref.read(symmetryProvider.notifier).state =
                        symmetry.copyWith(showGuides: val);
                  },
                ),
              ],

              const Divider(height: AppSpacing.xl),

              // ── Canvas Paper Texture ──
              Text(
                'Canvas Paper Texture',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: CanvasPaperTexture.values.map((tex) {
                  final isSelected = paperTexture == tex;
                  return ChoiceChip(
                    avatar: Icon(
                      tex.icon,
                      size: 16,
                      color: isSelected ? Colors.white : theme.iconTheme.color,
                    ),
                    label: Text(tex.label),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      SoundEffectService.instance.playPop();
                      ref.read(paperTextureProvider.notifier).state = tex;
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
