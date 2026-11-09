import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';
import '../../brushes/default_brushes.dart';
import '../models/drawing_guides.dart';
import '../models/stroke.dart';
import '../models/thumbnail_palette.dart';
import '../providers/canvas_providers.dart';
import 'thumbnail_save_modal.dart';

/// Advanced Creator Toolkit for Thumbnails: Quick Palette Switcher,
/// Instant Badge Stamping, Multi-Platform Safe Zones, and Direct Save to Gallery.
class ThumbnailToolsModal extends ConsumerStatefulWidget {
  final BuildContext? parentContext;
  const ThumbnailToolsModal({super.key, this.parentContext});

  static void show(BuildContext context) {
    SoundEffectService.instance.playPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ThumbnailToolsModal(parentContext: context),
    );
  }

  @override
  ConsumerState<ThumbnailToolsModal> createState() => _ThumbnailToolsModalState();
}

class _ThumbnailToolsModalState extends ConsumerState<ThumbnailToolsModal> {
  int _selectedTab = 0; // 0 = Color Palettes, 1 = Creator Badges, 2 = Safe Guides

  void _applyPalette(ThumbnailColorPalette palette) {
    SoundEffectService.instance.playCelebration();
    HapticFeedback.mediumImpact();

    final doc = ref.read(canvasDocumentProvider);

    final updatedLayers = doc.layers.map((layer) {
      if (layer.name.toLowerCase().contains('background')) {
        final newStrokes = layer.strokes.map((s) {
          if (s.shapeType == ShapeType.gradientFill) {
            return s.copyWith(
              color: palette.background1,
              secondaryColor: palette.background2,
            );
          }
          return s;
        }).toList();
        return layer.copyWith(strokes: newStrokes);
      } else if (layer.name.toLowerCase().contains('typography') ||
          layer.name.toLowerCase().contains('text')) {
        final newStrokes = layer.strokes.map((s) {
          if (s.text != null && s.text!.isNotEmpty) {
            return s.copyWith(
              color: palette.headlineColor,
              textBackgroundColor: palette.pillColor,
            );
          }
          return s;
        }).toList();
        return layer.copyWith(strokes: newStrokes);
      }
      return layer;
    }).toList();

    ref.read(canvasDocumentProvider.notifier).loadDocument(
          doc.copyWith(
            backgroundColor: palette.background1,
            layers: updatedLayers,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF181B2A),
        content: Text('Applied ${palette.name} Palette!'),
      ),
    );
  }

  void _stampBadge(String text, Color bg, Color textCol, ShapeType shape) {
    SoundEffectService.instance.playPop();
    HapticFeedback.mediumImpact();

    final doc = ref.read(canvasDocumentProvider);
    final width = doc.width.toDouble();
    final height = doc.height.toDouble();

    // Place badge at prominent upper right or center top position
    final cx = width * 0.82;
    final cy = height * 0.22;
    final fontSize = (height * 0.08).clamp(24.0, 56.0);

    final badgeStroke = Stroke(
      points: [StrokePoint(x: cx, y: cy)],
      color: textCol,
      brush: DefaultBrushes.hardBrush,
      text: text,
      fontFamily: 'Inter',
      fontSize: fontSize,
      isBold: true,
      textAlign: 'center',
      textStrokeColor: Colors.black,
      textStrokeWidth: 4.5,
      textBackgroundColor: bg,
      hasShadow: true,
      textShadowBlur: 8.0,
    );

    // Look for Badges layer, or use active layer
    final badgeLayerIndex = doc.layers.indexWhere(
      (l) => l.name.toLowerCase().contains('badge'),
    );

    if (badgeLayerIndex != -1) {
      ref.read(canvasDocumentProvider.notifier).setActiveLayer(badgeLayerIndex);
    }
    ref.read(canvasDocumentProvider.notifier).addStroke(badgeStroke);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
        backgroundColor: const Color(0xFF181B2A),
        content: Text('Stamped "$text" Badge onto canvas!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final doc = ref.watch(canvasDocumentProvider);
    final guide = ref.watch(drawingGuideProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18182E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.sm, 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF007F), Color(0xFFFF5F00)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Thumbnail Pro Suite',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF007F).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ADVANCED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF007F),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Palettes, Badges, Safe Zones & Instant Export',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          // Segmented Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF22223D) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabItem(0, 'Color Palettes', Icons.palette_rounded),
                  _buildTabItem(1, 'Creator Badges', Icons.stars_rounded),
                  _buildTabItem(2, 'Safe Zones', Icons.grid_view_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Tab content
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildPalettesTab(isDark),
                _buildBadgesTab(isDark),
                _buildSafeZonesTab(isDark, guide),
              ],
            ),
          ),

          // Bottom Bar with Quick Save JPG / PNG
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              MediaQuery.paddingOf(context).bottom > 0
                  ? MediaQuery.paddingOf(context).bottom + AppSpacing.xs
                  : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141426) : const Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ThumbnailSaveModal.show(widget.parentContext ?? context, doc);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF007F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text(
                      'Save to Gallery (JPG / PNG)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 36),
        onPressed: () {
          SoundEffectService.instance.playPop();
          setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: AppAnimation.standard,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF007F) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPalettesTab(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: ThumbnailColorPalette.curatedPalettes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final palette = ThumbnailColorPalette.curatedPalettes[index];
        return GestureDetector(
          onTap: () => _applyPalette(palette),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF22223D) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      palette.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B894).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${palette.ctrScore}% CTR',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00B894),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      palette.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 5 Swatch strip
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: palette.swatches.map((color) {
                      return Expanded(
                        child: Container(
                          height: 28,
                          color: color,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  palette.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgesTab(bool isDark) {
    final badges = [
      (text: 'NEW!', bg: const Color(0xFFFF003C), textCol: Colors.white, shape: ShapeType.starburst),
      (text: 'VS', bg: const Color(0xFF1E3C72), textCol: Colors.white, shape: ShapeType.shield),
      (text: 'TOP 10', bg: const Color(0xFFFFD700), textCol: Colors.black, shape: ShapeType.banner),
      (text: 'ALERT', bg: const Color(0xFFD63031), textCol: Colors.white, shape: ShapeType.triangle),
      (text: 'LIVE', bg: const Color(0xFFFF0055), textCol: Colors.white, shape: ShapeType.circle),
      (text: '4K ULTRA', bg: const Color(0xFF00B894), textCol: Colors.white, shape: ShapeType.diamond),
      (text: 'SALE', bg: const Color(0xFFFF7675), textCol: Colors.white, shape: ShapeType.starburst),
      (text: 'WATCH!', bg: const Color(0xFF6C5CE7), textCol: Colors.white, shape: ShapeType.banner),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final b = badges[index];
        return GestureDetector(
          onTap: () => _stampBadge(b.text, b.bg, b.textCol, b.shape),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [b.bg, b.bg.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: b.bg.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                b.text,
                style: TextStyle(
                  color: b.textCol,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSafeZonesTab(bool isDark, DrawingGuideConfig currentGuide) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildGuideOption(
          title: 'YouTube 16:9 Safe Zone',
          subtitle: 'Timestamp corner safety zone, 5% edge margins & rule of thirds',
          icon: Icons.play_circle_fill_rounded,
          color: Colors.red,
          isSelected: currentGuide.type == DrawingGuideType.thumbnailSafeZone,
          isDark: isDark,
          onTap: () {
            ref.read(drawingGuideProvider.notifier).state = const DrawingGuideConfig(
              type: DrawingGuideType.thumbnailSafeZone,
              opacity: 0.85,
            );
          },
        ),
        const SizedBox(height: 10),
        _buildGuideOption(
          title: 'Rule of Thirds (3×3 Grid)',
          subtitle: 'Focal power-points for eye-catching subject placement',
          icon: Icons.grid_3x3_rounded,
          color: const Color(0xFF6C5CE7),
          isSelected: currentGuide.type == DrawingGuideType.ruleOfThirds,
          isDark: isDark,
          onTap: () {
            ref.read(drawingGuideProvider.notifier).state = const DrawingGuideConfig(
              type: DrawingGuideType.ruleOfThirds,
              opacity: 0.75,
            );
          },
        ),
        const SizedBox(height: 10),
        _buildGuideOption(
          title: 'Guides Off',
          subtitle: 'Clear canvas overlay for unrestricted view',
          icon: Icons.hide_image_rounded,
          color: Colors.grey,
          isSelected: currentGuide.type == DrawingGuideType.none,
          isDark: isDark,
          onTap: () {
            ref.read(drawingGuideProvider.notifier).state = const DrawingGuideConfig(
              type: DrawingGuideType.none,
            );
          },
        ),
      ],
    );
  }

  Widget _buildGuideOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        SoundEffectService.instance.playPop();
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppAnimation.standard,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.2 : 0.08)
              : (isDark ? const Color(0xFF22223D) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? color : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
