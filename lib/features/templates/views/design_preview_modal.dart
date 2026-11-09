import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../app.dart';
import '../../canvas/models/tools.dart';
import '../../canvas/providers/canvas_providers.dart';
import '../../canvas/views/drawing_screen.dart';
import '../../ar_tracing/views/ar_tracing_screen.dart';
import '../models/coloring_template.dart';
import '../services/coloring_catalog_service.dart';
import '../widgets/template_thumbnail_painter.dart';

/// Modal dialog showing an accurate, high-resolution vector preview of any coloring design
/// before starting to color or trace, with Line Art and Color Preview modes.
class DesignPreviewModal extends ConsumerStatefulWidget {
  const DesignPreviewModal({
    super.key,
    required this.template,
    this.onSelectTemplate,
  });

  final ColoringTemplate template;
  final void Function(ColoringTemplate template)? onSelectTemplate;

  static void show(
    BuildContext context, {
    required ColoringTemplate template,
    void Function(ColoringTemplate template)? onSelect,
  }) {
    SoundEffectService.instance.playPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DesignPreviewModal(
        template: template,
        onSelectTemplate: onSelect,
      ),
    );
  }

  @override
  ConsumerState<DesignPreviewModal> createState() => _DesignPreviewModalState();
}

class _DesignPreviewModalState extends ConsumerState<DesignPreviewModal> {
  bool _showColoredPreview = false;
  int _selectedPaletteIndex = 0;
  late final TransformationController _transformationController;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _isFavorite = ColoringCatalogService.instance.isFavorite(widget.template.id);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    SoundEffectService.instance.playPop();
    _transformationController.value = Matrix4.identity();
  }

  void _zoomBy(double factor) {
    SoundEffectService.instance.playPop();
    final matrix = _transformationController.value.clone();
    matrix.scaleByDouble(factor, factor, 1.0, 1.0);
    _transformationController.value = matrix;
  }

  void _toggleFavorite() {
    SoundEffectService.instance.playPop();
    setState(() {
      _isFavorite = ColoringCatalogService.instance.toggleFavorite(widget.template.id);
    });
  }

  void _startColoring() {
    SoundEffectService.instance.playCelebration();
    Navigator.of(context).pop();

    if (widget.onSelectTemplate != null) {
      widget.onSelectTemplate!(widget.template);
      return;
    }

    final doc = widget.template.createDocument();
    ref.read(canvasDocumentProvider.notifier).loadDocument(doc);

    // Set active color to the user's chosen recommended palette color
    final palette = _getRecommendedPalette();
    if (palette.isNotEmpty) {
      final selectedColor = palette[_selectedPaletteIndex.clamp(0, palette.length - 1)];
      ref.read(activeColorProvider.notifier).setColor(selectedColor);
    }

    // Default to Fill tool so user can tap right into coloring!
    ref.read(activeToolProvider.notifier).selectTool(DrawingTool.fill);
    ref.read(autoFitToScreenProvider.notifier).state = true;

    Navigator.of(context).push(
      IOSPageRoute(builder: (_) => const DrawingScreen()),
    );
  }

  void _startArTracing() {
    SoundEffectService.instance.playCelebration();
    Navigator.of(context).pop();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArTracingScreen(initialTemplate: widget.template),
      ),
    );
  }

  List<Color> _getRecommendedPalette() {
    final t = widget.template;
    if (t.category.contains('Kids')) {
      return const [
        Color(0xFFFF5252), // Candy Red
        Color(0xFFFFB142), // Mango Yellow
        Color(0xFF2ED573), // Bright Green
        Color(0xFF1E90FF), // Sky Blue
        Color(0xFFFF69B4), // Bubblegum Pink
      ];
    } else if (t.category.contains('Nature')) {
      return const [
        Color(0xFF2E7D32),
        Color(0xFF81C784),
        Color(0xFFFFB300),
        Color(0xFF8D6E63),
        Color(0xFFE91E63),
      ];
    } else if (t.category.contains('Mandala')) {
      return const [
        Color(0xFF6C5CE7),
        Color(0xFF00CEC9),
        Color(0xFFFF7675),
        Color(0xFFFDCB6E),
        Color(0xFFE84393),
      ];
    } else if (t.category.contains('Space')) {
      return const [
        Color(0xFF0984E3),
        Color(0xFF6C5CE7),
        Color(0xFFFF7675),
        Color(0xFFFDCB6E),
        Color(0xFFDFE6E9),
      ];
    } else if (t.category.contains('Birds')) {
      return const [
        Color(0xFF00CEC9),
        Color(0xFF0984E3),
        Color(0xFFFF7675),
        Color(0xFFFDCB6E),
        Color(0xFF6C5CE7),
      ];
    } else if (t.category.contains('Flowers')) {
      return const [
        Color(0xFFFF6B9D),
        Color(0xFFFF7675),
        Color(0xFFFFA94D),
        Color(0xFF00B894),
        Color(0xFF55EFC4),
      ];
    }
    return [
      t.gradient.first,
      t.gradient.last,
      const Color(0xFFFF9F43),
      const Color(0xFF10AC84),
      const Color(0xFF54A0FF),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final previewBoxSize = min(size.width * 0.85, 340.0);
    final compiledPath = TemplateThumbnailWidget.getCompiledPath(widget.template);
    final palette = _getRecommendedPalette();
    final template = widget.template;

    return Container(
      height: size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18182E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        children: [
          // ── Drag Handle ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Top Header with Favorite & Close ──
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.sm, 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: template.gradient),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    boxShadow: [
                      BoxShadow(
                        color: template.gradient.first.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(template.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${template.category} · ${template.difficulty}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: template.gradient.first,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Favorite Heart Button
                IconButton(
                  onPressed: _toggleFavorite,
                  tooltip: _isFavorite ? 'Remove Favorite' : 'Add to Favorites',
                  icon: Icon(
                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isFavorite ? const Color(0xFFFF6B9D) : Colors.grey,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Main Content Scrollable ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // ── Mode Switcher: Line Art vs Color Preview ──
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF22223D) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PreviewModeTab(
                          label: 'Line Art',
                          icon: Icons.edit_outlined,
                          isSelected: !_showColoredPreview,
                          onTap: () {
                            SoundEffectService.instance.playPop();
                            setState(() => _showColoredPreview = false);
                          },
                        ),
                        _PreviewModeTab(
                          label: 'Color Preview',
                          icon: Icons.auto_awesome_rounded,
                          isSelected: _showColoredPreview,
                          activeGradient: template.gradient,
                          onTap: () {
                            SoundEffectService.instance.playCelebration();
                            setState(() => _showColoredPreview = true);
                          },
                        ),
                      ],
                    ),
                  ),

                  // ── Accurate Vector Line-Art Preview Box ──
                  Container(
                    width: previewBoxSize,
                    height: previewBoxSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: _showColoredPreview
                            ? template.gradient.first.withValues(alpha: 0.5)
                            : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _showColoredPreview
                              ? template.gradient.first.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Pinch to zoom and inspect design details
                        InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 0.8,
                          maxScale: 6.0,
                          child: SizedBox.expand(
                            child: CustomPaint(
                              painter: _HighResDesignPainter(
                                path: compiledPath,
                                inkColor: _showColoredPreview
                                    ? template.gradient.first
                                    : const Color(0xFF1E293B),
                                isColored: _showColoredPreview,
                                gradient: template.gradient,
                              ),
                            ),
                          ),
                        ),

                        // Floating Zoom Controls (+, -, Reset)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                                  onPressed: () => _zoomBy(1.25),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Zoom In',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.zoom_out_rounded, color: Colors.white, size: 16),
                                  onPressed: () => _zoomBy(0.8),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Zoom Out',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 16),
                                  onPressed: _resetZoom,
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Reset View',
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Zoom hint badge
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.pinch_rounded, color: Colors.white70, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Pinch to inspect',
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Design Metadata Stats ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const _StatBadge(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Infinite Vector',
                        color: Color(0xFF6C5CE7),
                      ),
                      _StatBadge(
                        icon: Icons.timer_outlined,
                        label: template.difficulty == 'Easy'
                            ? '~10-15 min'
                            : (template.difficulty == 'Medium' ? '~20-30 min' : '~35-50 min'),
                        color: const Color(0xFF00B894),
                      ),
                      _StatBadge(
                        icon: Icons.auto_awesome_rounded,
                        label: template.difficulty,
                        color: const Color(0xFFFF6B9D),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Recommended Palette Inspiration ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF22223D) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.palette_outlined, size: 16, color: Color(0xFF6C5CE7)),
                            const SizedBox(width: 6),
                            Text(
                              'Recommended Color Palette',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Tap to pick starting color',
                              style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(palette.length, (idx) {
                            final c = palette[idx];
                            final isSelected = _selectedPaletteIndex == idx;
                            return GestureDetector(
                              onTap: () {
                                SoundEffectService.instance.playPop();
                                setState(() => _selectedPaletteIndex = idx);
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                                    width: isSelected ? 3.5 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: c.withValues(alpha: isSelected ? 0.6 : 0.35),
                                      blurRadius: isSelected ? 8 : 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    template.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Dual Action Bar (Protected from Navigation Keys) ──
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              MediaQuery.paddingOf(context).bottom > 0
                  ? MediaQuery.paddingOf(context).bottom + AppSpacing.xs
                  : AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18182E) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                // Start Coloring Button
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _startColoring,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.brush_rounded, size: 20),
                    label: const Text(
                      'Start Coloring',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // AR Tracing Button
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _startArTracing,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF6C5CE7) : const Color(0xFF6C5CE7),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18, color: Color(0xFF6C5CE7)),
                    label: const Text(
                      'AR Trace',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
}

class _PreviewModeTab extends StatelessWidget {
  const _PreviewModeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.activeGradient,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Color>? activeGradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected && activeGradient == null ? Colors.white : (isSelected ? null : Colors.transparent),
          gradient: isSelected && activeGradient != null ? LinearGradient(colors: activeGradient!) : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? (activeGradient != null ? Colors.white : const Color(0xFF6C5CE7))
                  : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (activeGradient != null ? Colors.white : const Color(0xFF0F172A))
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighResDesignPainter extends CustomPainter {
  const _HighResDesignPainter({
    required this.path,
    required this.inkColor,
    this.gradient,
    this.isColored = false,
  });

  final Path path;
  final Color inkColor;
  final List<Color>? gradient;
  final bool isColored;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final scaleX = size.width / 1000.0;
    final scaleY = size.height / 1000.0;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    canvas.save();
    final offsetX = (size.width - 1000.0 * scale) / 2;
    final offsetY = (size.height - 1000.0 * scale) / 2;
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

    if (isColored && gradient != null && gradient!.isNotEmpty) {
      // Soft ambient gradient glow for colored preview
      const rect = Rect.fromLTWH(0, 0, 1000, 1000);
      final bgPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradient!.first.withValues(alpha: 0.16),
            gradient!.last.withValues(alpha: 0.08),
          ],
        ).createShader(rect);
      canvas.drawRect(rect, bgPaint);
    }

    final strokeWidthInArtSpace = max(2.2, 1.8 / scale);

    final paint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidthInArtSpace
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HighResDesignPainter oldDelegate) =>
      oldDelegate.path != path ||
      oldDelegate.inkColor != inkColor ||
      oldDelegate.isColored != isColored;
}
