import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../audio/sound_effect_service.dart';
import '../constants/design_tokens.dart';
import 'ad_block_detector_service.dart';

/// Global overlay widget that wraps the application and displays a recurring
/// 10-second toast notification whenever an active ad blocker or private DNS is detected.
///
/// If no ad blocker is active, NO toast or notice is ever shown and the app runs normally.
class AdBlockToastOverlay extends StatefulWidget {
  const AdBlockToastOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<AdBlockToastOverlay> createState() => _AdBlockToastOverlayState();
}

class _AdBlockToastOverlayState extends State<AdBlockToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  Timer? _autoHideTimer;
  bool _isRechecking = false;
  String? _recheckFeedback;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_animController);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_animController);

    // Listen to changes in ad blocker state
    AdBlockDetectorService.instance.isAdBlockerActiveNotifier.addListener(_onAdBlockStatusChanged);
    AdBlockDetectorService.instance.blockedTickNotifier.addListener(_onBlockedTick);
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    AdBlockDetectorService.instance.isAdBlockerActiveNotifier.removeListener(_onAdBlockStatusChanged);
    AdBlockDetectorService.instance.blockedTickNotifier.removeListener(_onBlockedTick);
    _animController.dispose();
    super.dispose();
  }

  void _onAdBlockStatusChanged() {
    final isBlocked = AdBlockDetectorService.instance.isAdBlockerActiveNotifier.value;
    if (!isBlocked) {
      // Blocker is disabled: IMMEDIATELY dismiss any toast!
      _autoHideTimer?.cancel();
      if (_animController.status != AnimationStatus.dismissed) {
        _animController.reverse();
      }
      setState(() {
        _recheckFeedback = null;
      });
    }
  }

  void _onBlockedTick() {
    final isBlocked = AdBlockDetectorService.instance.isAdBlockerActiveNotifier.value;
    if (!isBlocked) return;

    // Trigger toast display every 10-second tick while blocker is active
    _triggerToast();
  }

  void _triggerToast() {
    if (!mounted) return;
    _autoHideTimer?.cancel();

    // Haptic feedback & sound
    HapticFeedback.lightImpact();

    // Reset feedback text on new tick
    setState(() {
      _recheckFeedback = null;
    });

    _animController.forward();

    // Display for 5.5 seconds, then gracefully slide out until next 10s tick
    _autoHideTimer = Timer(const Duration(milliseconds: 5500), () {
      if (mounted && _animController.status == AnimationStatus.completed) {
        _animController.reverse();
      }
    });
  }

  Future<void> _handleRecheck() async {
    if (_isRechecking) return;

    setState(() {
      _isRechecking = true;
      _recheckFeedback = null;
    });

    HapticFeedback.selectionClick();
    final stillBlocked = await AdBlockDetectorService.instance.recheckNow();

    if (!mounted) return;

    setState(() {
      _isRechecking = false;
    });

    if (!stillBlocked) {
      // Blocker was turned off!
      SoundEffectService.instance.playCelebration();
      setState(() {
        _recheckFeedback = 'Ad blocker disabled. Thank you!';
      });
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        _animController.reverse();
      }
    } else {
      // Still active
      SoundEffectService.instance.playPop();
      HapticFeedback.mediumImpact();
      setState(() {
        _recheckFeedback = 'Still active. Please disable DNS / ad blocker.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main App Content
        widget.child,

        // 10-Second Recurring Toast Banner
        ValueListenableBuilder<bool>(
          valueListenable: AdBlockDetectorService.instance.isAdBlockerActiveNotifier,
          builder: (context, isBlocked, _) {
            if (!isBlocked && _animController.isDismissed) {
              // Ad blocker is disabled: ZERO widget tree overhead, zero notice!
              return const SizedBox.shrink();
            }

            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2E).withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B6B).withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Alert Icon
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7675).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFF7675),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: Color(0xFFFF7675),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Message Details
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ad Blocker / DNS Detected',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _recheckFeedback ??
                                          'Please turn off ad blocker or private DNS to support free art tools.',
                                      style: TextStyle(
                                        color: _recheckFeedback != null && _recheckFeedback!.contains('disabled')
                                            ? const Color(0xFF55EFC4)
                                            : Colors.white.withValues(alpha: 0.8),
                                        fontSize: 11.5,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Recheck Action Button
                              InkWell(
                                onTap: _isRechecking ? null : _handleRecheck,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C5CE7),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: _isRechecking
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Recheck',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(width: 4),
                              // Close cross
                              InkWell(
                                onTap: () {
                                  _autoHideTimer?.cancel();
                                  _animController.reverse();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
