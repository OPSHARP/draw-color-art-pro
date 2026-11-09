import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app.dart';
import '../../core/constants/design_tokens.dart';
import '../home/home_screen.dart';

/// iOS-styled onboarding flow with smooth typography, pill buttons, and native haptics.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String _onboardingKey = 'onboarding_complete';

  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen._onboardingKey, true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        IOSPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? IOSColors.darkBackground : IOSColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button (iOS Style) ──
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? IOSColors.systemGray : IOSColors.brandPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),

            // ── Pages ──
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (page) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentPage = page);
                },
                children: const [
                  _OnboardingPage(
                    icon: CupertinoIcons.paintbrush_fill,
                    title: 'Draw Without\nLimits',
                    subtitle:
                        'A powerful studio canvas with professional brushes, layers, '
                        'and drawing tools — refined with Apple HIG elegance.',
                    gradient: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                  ),
                  _OnboardingPage(
                    icon: CupertinoIcons.color_filter,
                    title: 'Create Your\nWay',
                    subtitle:
                        'From expressive sketches to finished digital paintings. '
                        'Color adjustments, symmetry, and 100+ typography fonts.',
                    gradient: [Color(0xFFFF6B9D), Color(0xFFFF8FB1)],
                  ),
                  _OnboardingPage(
                    icon: CupertinoIcons.sparkles,
                    title: 'Everything\nYou Need',
                    subtitle:
                        'Coloring templates, ASMR audio soundscapes, AR tracing, '
                        'and local private storage — 100% free forever.',
                    gradient: [Color(0xFFFFA94D), Color(0xFFFFCC00)],
                  ),
                ],
              ),
            ),

            // ── Page indicator (iOS Smooth Pills) ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final isSelected = _currentPage == index;
                  return AnimatedContainer(
                    duration: AppAnimation.standard,
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? IOSColors.brandPrimary
                          : (isDark ? Colors.white24 : Colors.black12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // ── CTA Button (iOS Rounded Pill) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: CupertinoButton(
                  color: IOSColors.brandPrimary,
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (_currentPage == 2) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: AppAnimation.slow,
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  child: Text(
                    _currentPage == 2 ? 'Start Drawing' : 'Continue',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single onboarding page with Apple HIG iconography, large title, and smooth description.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient circle & subtle elevation
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 52,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 36),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.15,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          const SizedBox(height: 14),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: isDark ? IOSColors.systemGray : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
