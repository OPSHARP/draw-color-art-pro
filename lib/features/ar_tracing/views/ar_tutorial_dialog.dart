import 'package:flutter/material.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// Modal dialog showing the 3-step guide on how to trace in AR onto real paper.
class ArTutorialDialog extends StatelessWidget {
  const ArTutorialDialog({super.key});

  static void show(BuildContext context) {
    SoundEffectService.instance.playPop();
    showDialog(
      context: context,
      builder: (_) => const ArTutorialDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      backgroundColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to Trace in AR',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Trace sketches onto physical paper',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
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
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),

              // Steps
              _buildStep(
                context,
                stepNumber: '1',
                title: 'Elevate Your Phone',
                desc: 'Rest your phone horizontally on a coffee mug, glass, or tripod stand, pointing the camera down at blank paper.',
                icon: Icons.coffee_rounded,
                color: const Color(0xFF00B894),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildStep(
                context,
                stepNumber: '2',
                title: 'Align & Lock',
                desc: 'Use pinch-to-zoom, rotate, and drag to fit the template onto your paper. Then tap the Lock icon so it stays frozen.',
                icon: Icons.lock_outline_rounded,
                color: const Color(0xFF0984E3),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildStep(
                context,
                stepNumber: '3',
                title: 'Trace with Pen or Pencil',
                desc: 'Look through your screen and sketch along the lines directly onto the real paper! Adjust opacity anytime.',
                icon: Icons.draw_rounded,
                color: const Color(0xFFE17055),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Tip Box
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Pro Tip: Turn on the Flashlight if your paper is in a shadow!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Button
              ElevatedButton.icon(
                onPressed: () {
                  SoundEffectService.instance.playPop();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Got it, Start Tracing!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step $stepNumber: $title',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
