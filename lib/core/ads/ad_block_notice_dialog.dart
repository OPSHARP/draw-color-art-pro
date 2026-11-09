import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../audio/sound_effect_service.dart';
import '../constants/design_tokens.dart';
import 'ad_block_detector_service.dart';

/// Polite, beautifully designed dialog alerting the user about an active ad-blocker.
class AdBlockNoticeDialog extends StatefulWidget {
  const AdBlockNoticeDialog({super.key});

  /// Presents the ad-blocker notice dialog if needed.
  static Future<void> show(BuildContext context) async {
    if (!context.mounted) return;
    AdBlockDetectorService.instance.markNoticeShown();
    HapticFeedback.mediumImpact();
    SoundEffectService.instance.playPop();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AdBlockNoticeDialog(),
    );
  }

  @override
  State<AdBlockNoticeDialog> createState() => _AdBlockNoticeDialogState();
}

class _AdBlockNoticeDialogState extends State<AdBlockNoticeDialog> {
  bool _isRechecking = false;
  String? _statusMessage;

  Future<void> _handleRecheck() async {
    setState(() {
      _isRechecking = true;
      _statusMessage = null;
    });

    HapticFeedback.lightImpact();
    final isBlocked = await AdBlockDetectorService.instance.checkAdBlocker();

    if (!mounted) return;

    setState(() {
      _isRechecking = false;
    });

    if (!isBlocked) {
      SoundEffectService.instance.playCelebration();
      setState(() {
        _statusMessage = 'Thank you! Ad blocker is turned off.';
      });
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      SoundEffectService.instance.playPop();
      setState(() {
        _statusMessage = 'Ad blocker is still detected. Please whitelist our app.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? const Color(0xFF3B3B5C) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Header Badge with subtle glowing gradient
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7675), Color(0xFFFF6B9D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Ad Blocker Detected',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Subtitle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Draw Color Art Pro is 100% Free',
                style: TextStyle(
                  color: Color(0xFF6C5CE7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Explanation body
            Text(
              'We noticed an ad blocker is running. Our app provides free brushes, anime templates, and canvas tools thanks to a few polite ads.\n\nPlease consider turning off your ad blocker or whitelisting our app to help us keep updating new art features!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.45,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.contains('Thank you')
                      ? const Color(0xFF00B894)
                      : const Color(0xFFFF7675),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                // Continue Anyway (Secondary)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF3B3B5C) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Recheck Status (Primary)
                Expanded(
                  child: FilledButton(
                    onPressed: _isRechecking ? null : _handleRecheck,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _isRechecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Recheck',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
