import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tools.dart';
import '../providers/canvas_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// Inspiration Studio modal for artists:
/// - Creative drawing prompts & theme ideas
/// - Designer color palettes with one-tap apply
/// - Composition guides reference
class InspirationModal extends ConsumerStatefulWidget {
  const InspirationModal({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    SoundEffectService.instance.playPop();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const InspirationModal(),
    );
  }

  @override
  ConsumerState<InspirationModal> createState() => _InspirationModalState();
}

class _InspirationModalState extends ConsumerState<InspirationModal> {
  int _selectedTab = 0; // 0: Prompts, 1: Palettes, 2: Composition Guides

  static const _prompts = [
    (
      category: 'Cyberpunk & Sci-Fi',
      title: 'Neon Ramen Stall in Rain',
      description: 'Glow brush reflections on wet asphalt with neon signs in Japanese.',
      colors: [Color(0xFF00F0FF), Color(0xFFFF007F), Color(0xFF1E1B4B)],
    ),
    (
      category: 'Cozy & Cute',
      title: 'Boba Tea Kitten',
      description: 'A round tabby kitten peeking out of an iced boba drink with pearls.',
      colors: [Color(0xFFFFB4A2), Color(0xFFE5989B), Color(0xFF6D6875)],
    ),
    (
      category: 'Landscape',
      title: 'Lavender Fields at Sunset',
      description: 'Rolling purple hills under an orange gradient sky with a lone windmill.',
      colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B), Color(0xFF7B2CBF)],
    ),
    (
      category: 'Fantasy',
      title: 'Crystal Dragon Hatchling',
      description: 'Tiny winged creature curled around a glowing amethyst geode.',
      colors: [Color(0xFF9D4EDD), Color(0xFF00B4D8), Color(0xFF90E0EF)],
    ),
    (
      category: 'Food Art',
      title: 'Stack of Fluffy Berry Pancakes',
      description: 'Maple syrup drip, pat of melting butter, fresh blueberries and strawberries.',
      colors: [Color(0xFFD4A373), Color(0xFFFAEDCD), Color(0xFFE63946)],
    ),
    (
      category: 'Abstract & Patterns',
      title: 'Symmetry Sacred Mandala',
      description: 'Use the 8-fold radial symmetry tool to craft an intricate geometric seal.',
      colors: [Color(0xFFE0AAFF), Color(0xFFC77DFF), Color(0xFF240046)],
    ),
  ];

  static const _designerPalettes = [
    (
      name: 'Apple HIG iOS 18',
      colors: [
        Color(0xFF007AFF),
        Color(0xFF34C759),
        Color(0xFFFF9500),
        Color(0xFFFF3B30),
        Color(0xFFAF52DE),
        Color(0xFF5AC8FA),
      ],
    ),
    (
      name: 'Cyberpunk Neon',
      colors: [
        Color(0xFF00F0FF),
        Color(0xFFFF007F),
        Color(0xFF39FF14),
        Color(0xFFFFEE00),
        Color(0xFFBF00FF),
        Color(0xFF0D0221),
      ],
    ),
    (
      name: 'Autumn Woodland',
      colors: [
        Color(0xFF264653),
        Color(0xFF2A9D8F),
        Color(0xFFE9C46A),
        Color(0xFFF4A261),
        Color(0xFFE76F51),
        Color(0xFF6B705C),
      ],
    ),
    (
      name: 'Pastel Dreamscape',
      colors: [
        Color(0xFFFFC6FF),
        Color(0xFFBDB2FF),
        Color(0xFFA0C4FF),
        Color(0xFF9BF6FF),
        Color(0xFFCAFFBF),
        Color(0xFFFDFFB6),
      ],
    ),
    (
      name: 'Tokyo Twilight',
      colors: [
        Color(0xFF2B2D42),
        Color(0xFF8D99AE),
        Color(0xFFEDF2F4),
        Color(0xFFEF233C),
        Color(0xFFD90429),
        Color(0xFF1D3557),
      ],
    ),
    (
      name: 'Golden Hour Desert',
      colors: [
        Color(0xFFF72585),
        Color(0xFF7209B7),
        Color(0xFF3A0CA3),
        Color(0xFF4361EE),
        Color(0xFF4CC9F0),
        Color(0xFFFFD166),
      ],
    ),
  ];

  void _loadPaletteIntoActive(List<Color> colors) {
    HapticFeedback.mediumImpact();
    SoundEffectService.instance.playCelebration();
    for (final c in colors) {
      ref.read(activeColorProvider.notifier).addHistoryColor(c);
    }
    if (colors.isNotEmpty) {
      ref.read(activeColorProvider.notifier).setColor(colors.first);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded ${colors.length} colors into active palette!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: AppBlur.sheet,
        child: Container(
          color: isDark ? IOSColors.darkElevated : IOSColors.lightSurface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // iOS Grabber Handle
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 14),

                // Header
                Row(
                  children: [
                    Text(
                      'Inspiration Studio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(28, 28),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 22,
                        color: isDark ? IOSColors.systemGray : IOSColors.systemGray2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // iOS Sliding Segmented Control
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _selectedTab,
                    children: const {
                      0: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text('Art Prompts'),
                      ),
                      1: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text('Color Palettes'),
                      ),
                      2: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text('Guides'),
                      ),
                    },
                    onValueChanged: (val) {
                      if (val != null) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTab = val);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Tab Content
                Expanded(
                  child: switch (_selectedTab) {
                    0 => _buildPromptsTab(isDark),
                    1 => _buildPalettesTab(isDark),
                    _ => _buildGuidesTab(isDark),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromptsTab(bool isDark) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _prompts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = _prompts[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? IOSColors.darkSurface : IOSColors.systemGray6,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? IOSColors.darkSeparator.withValues(alpha: 0.3) : Colors.black12,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: IOSColors.brandPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.category,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: IOSColors.brandPrimary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Color palette hints
                  for (final c in p.colors)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                p.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? IOSColors.systemGray : IOSColors.systemGray2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPalettesTab(bool isDark) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _designerPalettes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _designerPalettes[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? IOSColors.darkSurface : IOSColors.systemGray6,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? IOSColors.darkSeparator.withValues(alpha: 0.3) : Colors.black12,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(28, 26),
                    color: IOSColors.brandPrimary,
                    borderRadius: BorderRadius.circular(6),
                    onPressed: () => _loadPaletteIntoActive(item.colors),
                    child: const Text(
                      'Use Palette',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: item.colors.map((c) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(activeColorProvider.notifier).setColor(c);
                      },
                      child: Container(
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuidesTab(bool isDark) {
    final showGrid = ref.watch(showGridProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildGuideTile(
          icon: CupertinoIcons.square_grid_2x2,
          title: 'Pixel & Layout Alignment Grid',
          subtitle: 'Enables snapping and proportion reference across entire canvas',
          isActive: showGrid,
          onToggle: (val) {
            HapticFeedback.selectionClick();
            ref.read(showGridProvider.notifier).setGrid(val);
          },
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildGuideTile(
          icon: CupertinoIcons.arrow_right_arrow_left,
          title: 'Symmetry Assistant',
          subtitle: 'Vertical, Horizontal, Radial Mandala, and 4-way kaleidoscope reflection',
          isActive: ref.watch(activeToolProvider) == DrawingTool.symmetry,
          onToggle: (val) {
            HapticFeedback.selectionClick();
            if (val) {
              ref.read(activeToolProvider.notifier).selectTool(DrawingTool.symmetry);
              Navigator.pop(context);
            }
          },
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildGuideTile(
          icon: Icons.straighten_rounded,
          title: 'Ruler & Straight Line Guide',
          subtitle: 'Locks pen movement along perfect lines and angle increments',
          isActive: ref.watch(activeToolProvider) == DrawingTool.ruler,
          onToggle: (val) {
            HapticFeedback.selectionClick();
            if (val) {
              ref.read(activeToolProvider.notifier).selectTool(DrawingTool.ruler);
              Navigator.pop(context);
            }
          },
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildGuideTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required ValueChanged<bool> onToggle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? IOSColors.darkSurface : IOSColors.systemGray6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? IOSColors.darkSeparator.withValues(alpha: 0.3) : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: IOSColors.brandPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: IOSColors.brandPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? IOSColors.systemGray : IOSColors.systemGray2,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: isActive,
            activeTrackColor: IOSColors.systemGreen,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
