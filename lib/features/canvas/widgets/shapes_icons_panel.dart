import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stroke.dart';
import '../models/tools.dart';
import '../providers/canvas_providers.dart';
import '../../brushes/default_brushes.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// Shape category for tab grouping in the shapes panel.
enum ShapeCategory {
  basic('Basic Shapes', Icons.crop_square_rounded),
  arrows('Arrows & Lines', Icons.arrow_forward_rounded),
  social('Social & Common', Icons.favorite_rounded),
  decorative('Decorative', Icons.auto_awesome_rounded),
  badges('Creator Badges', Icons.verified_rounded);

  const ShapeCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Definition of a shape entry in the library.
class ShapeEntry {
  const ShapeEntry({
    required this.shapeType,
    required this.label,
    required this.icon,
    required this.category,
    this.badgeText,
    this.badgeColor,
  });

  final ShapeType shapeType;
  final String label;
  final IconData icon;
  final ShapeCategory category;
  final String? badgeText;
  final Color? badgeColor;
}

/// All available shapes organized by category.
const List<ShapeEntry> _allShapes = [
  // ── Basic Shapes ──
  ShapeEntry(shapeType: ShapeType.rectangle, label: 'Rectangle', icon: Icons.crop_square_rounded, category: ShapeCategory.basic),
  ShapeEntry(shapeType: ShapeType.roundedRectangle, label: 'Rounded Rect', icon: Icons.rounded_corner_rounded, category: ShapeCategory.basic),
  ShapeEntry(shapeType: ShapeType.circle, label: 'Circle', icon: Icons.circle_outlined, category: ShapeCategory.basic),
  ShapeEntry(shapeType: ShapeType.triangle, label: 'Triangle', icon: Icons.change_history_rounded, category: ShapeCategory.basic),
  ShapeEntry(shapeType: ShapeType.star, label: 'Star', icon: Icons.star_border_rounded, category: ShapeCategory.basic),
  ShapeEntry(shapeType: ShapeType.heart, label: 'Heart', icon: Icons.favorite_border_rounded, category: ShapeCategory.basic),
  ShapeEntry(shapeType: ShapeType.hexagon, label: 'Hexagon', icon: Icons.hexagon_outlined, category: ShapeCategory.basic),
  ShapeEntry(shapeType: ShapeType.pentagon, label: 'Pentagon', icon: Icons.pentagon_outlined, category: ShapeCategory.basic),
  ShapeEntry(shapeType: ShapeType.octagon, label: 'Octagon', icon: Icons.stop_rounded, category: ShapeCategory.basic),
  ShapeEntry(shapeType: ShapeType.diamond, label: 'Diamond', icon: Icons.diamond_outlined, category: ShapeCategory.basic),
  ShapeEntry(shapeType: ShapeType.ring, label: 'Ring / Donut', icon: Icons.panorama_fish_eye_rounded, category: ShapeCategory.basic),
  ShapeEntry(shapeType: ShapeType.cross, label: 'Cross', icon: Icons.add_rounded, category: ShapeCategory.basic),
  ShapeEntry(shapeType: ShapeType.crescent, label: 'Crescent', icon: Icons.dark_mode_outlined, category: ShapeCategory.basic),

  // ── Arrows & Lines ──
  ShapeEntry(shapeType: ShapeType.line, label: 'Line', icon: Icons.horizontal_rule_rounded, category: ShapeCategory.arrows),
  ShapeEntry(shapeType: ShapeType.arrow, label: 'Arrow', icon: Icons.arrow_forward_rounded, category: ShapeCategory.arrows),
  ShapeEntry(shapeType: ShapeType.chevron, label: 'Chevron', icon: Icons.chevron_right_rounded, category: ShapeCategory.arrows),

  // ── Creator Badges & Stickers ──
  ShapeEntry(shapeType: ShapeType.starburst, label: 'NEW!', icon: Icons.auto_awesome_rounded, category: ShapeCategory.badges, badgeText: 'NEW!', badgeColor: Color(0xFFFF3366)),
  ShapeEntry(shapeType: ShapeType.shield, label: 'VS', icon: Icons.shield_rounded, category: ShapeCategory.badges, badgeText: 'VS', badgeColor: Color(0xFF6C5CE7)),
  ShapeEntry(shapeType: ShapeType.crown, label: 'TOP 10', icon: Icons.workspace_premium_rounded, category: ShapeCategory.badges, badgeText: 'TOP 10', badgeColor: Color(0xFFFFB300)),
  ShapeEntry(shapeType: ShapeType.roundedRectangle, label: 'LIVE', icon: Icons.sensors_rounded, category: ShapeCategory.badges, badgeText: 'LIVE', badgeColor: Color(0xFFE74C3C)),
  ShapeEntry(shapeType: ShapeType.banner, label: 'HOW TO', icon: Icons.flag_rounded, category: ShapeCategory.badges, badgeText: 'HOW TO', badgeColor: Color(0xFF007AFF)),
  ShapeEntry(shapeType: ShapeType.diamond, label: '4K ULTRA', icon: Icons.hd_rounded, category: ShapeCategory.badges, badgeText: '4K', badgeColor: Color(0xFF00CEC9)),
  ShapeEntry(shapeType: ShapeType.shield, label: 'PRO', icon: Icons.verified_rounded, category: ShapeCategory.badges, badgeText: 'PRO', badgeColor: Color(0xFF8E44AD)),
  ShapeEntry(shapeType: ShapeType.starburst, label: 'SALE', icon: Icons.local_offer_rounded, category: ShapeCategory.badges, badgeText: 'SALE', badgeColor: Color(0xFFFF5722)),
  ShapeEntry(shapeType: ShapeType.triangle, label: 'ALERT', icon: Icons.warning_amber_rounded, category: ShapeCategory.badges, badgeText: 'ALERT', badgeColor: Color(0xFFD32F2F)),
  ShapeEntry(shapeType: ShapeType.arrow, label: 'Focus Arrow', icon: Icons.near_me_rounded, category: ShapeCategory.badges, badgeText: 'HERE!', badgeColor: Color(0xFFFFD600)),

  // ── Social & Common ──
  ShapeEntry(shapeType: ShapeType.speechBubble, label: 'Speech Bubble', icon: Icons.chat_bubble_outline_rounded, category: ShapeCategory.social),
  ShapeEntry(shapeType: ShapeType.playButton, label: 'Play Button', icon: Icons.play_circle_outline_rounded, category: ShapeCategory.social),
  ShapeEntry(shapeType: ShapeType.musicNote, label: 'Music Note', icon: Icons.music_note_rounded, category: ShapeCategory.social),
  ShapeEntry(shapeType: ShapeType.crown, label: 'Crown', icon: Icons.workspace_premium_rounded, category: ShapeCategory.social),
  ShapeEntry(shapeType: ShapeType.cloud, label: 'Cloud', icon: Icons.cloud_outlined, category: ShapeCategory.social),

  // ── Decorative ──
  ShapeEntry(shapeType: ShapeType.banner, label: 'Banner', icon: Icons.flag_rounded, category: ShapeCategory.decorative),
  ShapeEntry(shapeType: ShapeType.starburst, label: 'Starburst', icon: Icons.auto_awesome_rounded, category: ShapeCategory.decorative),
  ShapeEntry(shapeType: ShapeType.shield, label: 'Shield', icon: Icons.shield_outlined, category: ShapeCategory.decorative),
];

/// Modal panel for browsing and inserting shapes into the canvas.
class ShapesIconsPanel extends ConsumerStatefulWidget {
  const ShapesIconsPanel({super.key});

  static void show(BuildContext context) {
    SoundEffectService.instance.playPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShapesIconsPanel(),
    );
  }

  @override
  ConsumerState<ShapesIconsPanel> createState() => _ShapesIconsPanelState();
}

class _ShapesIconsPanelState extends ConsumerState<ShapesIconsPanel> {
  ShapeCategory _selectedCategory = ShapeCategory.basic;
  bool _isFilled = true;

  List<ShapeEntry> get _filteredShapes =>
      _allShapes.where((s) => s.category == _selectedCategory).toList();

  void _insertShape(ShapeEntry entry) {
    HapticFeedback.mediumImpact();
    SoundEffectService.instance.playWhoosh();

    final doc = ref.read(canvasDocumentProvider);
    final activeColor = ref.read(activeColorProvider);
    final docNotifier = ref.read(canvasDocumentProvider.notifier);
    final undoNotifier = ref.read(undoRedoProvider.notifier);

    // Place shape in the center of the canvas
    final cx = doc.width / 2.0;
    final cy = doc.height / 2.0;
    const shapeSize = 200.0;

    final isBadge = entry.badgeText != null;
    final shapeColor = isBadge ? (entry.badgeColor ?? activeColor) : activeColor;
    final isFilledShape = isBadge ? true : _isFilled;

    final p1 = StrokePoint(
      x: cx - shapeSize / 2,
      y: cy - shapeSize / 2,
      pressure: 1.0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    final p2 = StrokePoint(
      x: cx + shapeSize / 2,
      y: cy + shapeSize / 2,
      pressure: 1.0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    final brush = DefaultBrushes.hardBrush.copyWith(size: 3.0);

    final stroke = Stroke(
      points: [p1, p2],
      color: shapeColor,
      brush: brush,
      shapeType: entry.shapeType,
      isFilled: isFilledShape,
    );

    if (isBadge) {
      final textPoint = StrokePoint(
        x: cx,
        y: cy,
        pressure: 1.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      final badgeTextColor = (entry.badgeColor?.computeLuminance() ?? 0) > 0.55
          ? Colors.black
          : Colors.white;
      final textStroke = Stroke(
        points: [textPoint],
        color: badgeTextColor,
        brush: brush,
        text: entry.badgeText,
        fontFamily: 'Inter',
        fontSize: 34.0,
        isBold: true,
        textAlign: 'center',
        textStrokeColor: badgeTextColor == Colors.white ? Colors.black : Colors.white,
        textStrokeWidth: 3.5,
        hasShadow: true,
        textShadowBlur: 6.0,
      );

      docNotifier.addStroke(stroke);
      docNotifier.addStroke(textStroke);
      undoNotifier.pushAction(
        MultiStrokeAction(documentNotifier: docNotifier, strokes: [stroke, textStroke]),
      );
    } else {
      docNotifier.addStroke(stroke);
      undoNotifier.pushAction(
        StrokeAction(documentNotifier: docNotifier, stroke: stroke),
      );
    }

    // Set active shape & fill mode and switch to shape tool
    ref.read(activeShapeProvider.notifier).state = entry.shapeType;
    ref.read(isShapeFilledProvider.notifier).state = isFilledShape;
    ref.read(activeToolProvider.notifier).selectTool(DrawingTool.shape);
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.7,
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

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.sm, 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.category_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shapes & Icons',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Tap a shape to add it to your canvas',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                // Fill toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isFilled
                        ? const Color(0xFFFF6B9D).withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF22223D) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isFilled ? const Color(0xFFFF6B9D) : Colors.transparent,
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      SoundEffectService.instance.playPop();
                      setState(() => _isFilled = !_isFilled);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isFilled ? Icons.format_color_fill_rounded : Icons.format_color_reset_rounded,
                          size: 16,
                          color: _isFilled ? const Color(0xFFFF6B9D) : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isFilled ? 'Filled' : 'Outline',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _isFilled ? const Color(0xFFFF6B9D) : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
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

          // ── Category Tabs ──
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
              physics: const BouncingScrollPhysics(),
              itemCount: ShapeCategory.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = ShapeCategory.values[index];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    SoundEffectService.instance.playPop();
                    setState(() => _selectedCategory = cat);
                  },
                  child: AnimatedContainer(
                    duration: AppAnimation.standard,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF6B9D)
                          : (isDark ? const Color(0xFF22223D) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.icon,
                          size: 14,
                          color: isSelected ? Colors.white : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Shapes Grid ──
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _filteredShapes.length,
              itemBuilder: (context, index) {
                final shape = _filteredShapes[index];
                return _ShapeGridItem(
                  entry: shape,
                  isDark: isDark,
                  isFilled: _isFilled,
                  onTap: () => _insertShape(shape),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual shape item in the grid.
class _ShapeGridItem extends StatelessWidget {
  const _ShapeGridItem({
    required this.entry,
    required this.isDark,
    required this.isFilled,
    required this.onTap,
  });

  final ShapeEntry entry;
  final bool isDark;
  final bool isFilled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF22223D) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(40, 40),
                    painter: _ShapePreviewPainter(
                      shapeType: entry.shapeType,
                      isFilled: entry.badgeColor != null ? true : isFilled,
                      color: entry.badgeColor ?? (isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                  ),
                  if (entry.badgeText != null)
                    Text(
                      entry.badgeText!,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: (entry.badgeColor?.computeLuminance() ?? 0) > 0.55
                            ? Colors.black
                            : Colors.white,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entry.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter that renders a mini shape preview.
class _ShapePreviewPainter extends CustomPainter {
  _ShapePreviewPainter({
    required this.shapeType,
    required this.isFilled,
    required this.color,
  });

  final ShapeType shapeType;
  final bool isFilled;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.4;

    switch (shapeType) {
      case ShapeType.rectangle:
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 1.5), paint);
      case ShapeType.roundedRectangle:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 1.5),
            Radius.circular(r * 0.3),
          ),
          paint,
        );
      case ShapeType.circle:
        canvas.drawCircle(Offset(cx, cy), r, paint);
      case ShapeType.triangle:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy + r * 0.8)
          ..lineTo(cx - r, cy + r * 0.8)
          ..close();
        canvas.drawPath(path, paint);
      case ShapeType.star:
        _drawStar(canvas, cx, cy, r, 5, paint);
      case ShapeType.heart:
        _drawHeart(canvas, cx, cy, r, paint);
      case ShapeType.hexagon:
        _drawRegularPolygon(canvas, cx, cy, r, 6, paint);
      case ShapeType.pentagon:
        _drawRegularPolygon(canvas, cx, cy, r, 5, paint);
      case ShapeType.octagon:
        _drawRegularPolygon(canvas, cx, cy, r, 8, paint);
      case ShapeType.diamond:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.7, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r * 0.7, cy)
          ..close();
        canvas.drawPath(path, paint);
      case ShapeType.ring:
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = r * 0.35;
        canvas.drawCircle(Offset(cx, cy), r * 0.65, paint);
      case ShapeType.cross:
        final w = r * 0.4;
        final path = Path()
          ..moveTo(cx - w, cy - r)
          ..lineTo(cx + w, cy - r)
          ..lineTo(cx + w, cy - w)
          ..lineTo(cx + r, cy - w)
          ..lineTo(cx + r, cy + w)
          ..lineTo(cx + w, cy + w)
          ..lineTo(cx + w, cy + r)
          ..lineTo(cx - w, cy + r)
          ..lineTo(cx - w, cy + w)
          ..lineTo(cx - r, cy + w)
          ..lineTo(cx - r, cy - w)
          ..lineTo(cx - w, cy - w)
          ..close();
        canvas.drawPath(path, paint);
      case ShapeType.crescent:
        final path = Path();
        path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
        final cutPath = Path()
          ..addOval(Rect.fromCircle(center: Offset(cx + r * 0.5, cy), radius: r * 0.85));
        final crescent = Path.combine(PathOperation.difference, path, cutPath);
        canvas.drawPath(crescent, paint);
      case ShapeType.line:
        canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), paint..style = PaintingStyle.stroke..strokeWidth = 2);
      case ShapeType.arrow:
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), paint);
        canvas.drawLine(Offset(cx + r * 0.5, cy - r * 0.4), Offset(cx + r, cy), paint);
        canvas.drawLine(Offset(cx + r * 0.5, cy + r * 0.4), Offset(cx + r, cy), paint);
      case ShapeType.chevron:
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2.5;
        final path = Path()
          ..moveTo(cx - r * 0.4, cy - r)
          ..lineTo(cx + r * 0.4, cy)
          ..lineTo(cx - r * 0.4, cy + r);
        canvas.drawPath(path, paint);
      case ShapeType.speechBubble:
        final rect = Rect.fromCenter(center: Offset(cx, cy - r * 0.15), width: r * 2, height: r * 1.4);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r * 0.3)), paint);
        final tailPath = Path()
          ..moveTo(cx - r * 0.3, cy + r * 0.55)
          ..lineTo(cx - r * 0.6, cy + r)
          ..lineTo(cx + r * 0.1, cy + r * 0.55);
        canvas.drawPath(tailPath, paint);
      case ShapeType.playButton:
        canvas.drawCircle(Offset(cx, cy), r, paint..style = PaintingStyle.stroke..strokeWidth = 1.8);
        final triPaint = Paint()..color = color..style = PaintingStyle.fill;
        final tri = Path()
          ..moveTo(cx - r * 0.3, cy - r * 0.5)
          ..lineTo(cx + r * 0.55, cy)
          ..lineTo(cx - r * 0.3, cy + r * 0.5)
          ..close();
        canvas.drawPath(tri, triPaint);
      case ShapeType.musicNote:
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        canvas.drawOval(Rect.fromCenter(center: Offset(cx - r * 0.3, cy + r * 0.5), width: r * 0.7, height: r * 0.5), Paint()..color = color..style = PaintingStyle.fill);
        canvas.drawLine(Offset(cx + r * 0.05, cy + r * 0.4), Offset(cx + r * 0.05, cy - r * 0.8), paint);
        canvas.drawLine(Offset(cx + r * 0.05, cy - r * 0.8), Offset(cx + r * 0.5, cy - r * 0.5), paint);
      case ShapeType.crown:
        final path = Path()
          ..moveTo(cx - r, cy + r * 0.5)
          ..lineTo(cx - r, cy - r * 0.2)
          ..lineTo(cx - r * 0.5, cy + r * 0.1)
          ..lineTo(cx, cy - r * 0.7)
          ..lineTo(cx + r * 0.5, cy + r * 0.1)
          ..lineTo(cx + r, cy - r * 0.2)
          ..lineTo(cx + r, cy + r * 0.5)
          ..close();
        canvas.drawPath(path, paint);
      case ShapeType.cloud:
        _drawCloud(canvas, cx, cy, r, paint);
      case ShapeType.banner:
        final path = Path()
          ..moveTo(cx - r, cy - r * 0.5)
          ..lineTo(cx + r, cy - r * 0.5)
          ..lineTo(cx + r, cy + r * 0.5)
          ..lineTo(cx + r * 0.7, cy + r * 0.2)
          ..lineTo(cx + r * 0.4, cy + r * 0.5)
          ..lineTo(cx - r * 0.4, cy + r * 0.5)
          ..lineTo(cx - r * 0.7, cy + r * 0.2)
          ..lineTo(cx - r, cy + r * 0.5)
          ..close();
        canvas.drawPath(path, paint);
      case ShapeType.starburst:
        _drawStar(canvas, cx, cy, r, 12, paint);
      case ShapeType.shield:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy - r * 0.5)
          ..lineTo(cx + r, cy + r * 0.2)
          ..quadraticBezierTo(cx + r * 0.5, cy + r, cx, cy + r)
          ..quadraticBezierTo(cx - r * 0.5, cy + r, cx - r, cy + r * 0.2)
          ..lineTo(cx - r, cy - r * 0.5)
          ..close();
        canvas.drawPath(path, paint);
      default:
        canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  void _drawRegularPolygon(Canvas canvas, double cx, double cy, double r, int sides, Paint paint) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (2 * pi * i / sides) - pi / 2;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, int points, Paint paint) {
    final path = Path();
    final innerR = r * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final angle = (pi * i / points) - pi / 2;
      final rad = i.isEven ? r : innerR;
      final x = cx + rad * cos(angle);
      final y = cy + rad * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    path.moveTo(cx, cy + r * 0.7);
    path.cubicTo(cx - r * 1.5, cy - r * 0.3, cx - r * 0.5, cy - r * 1.2, cx, cy - r * 0.5);
    path.cubicTo(cx + r * 0.5, cy - r * 1.2, cx + r * 1.5, cy - r * 0.3, cx, cy + r * 0.7);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCloud(Canvas canvas, double cx, double cy, double r, Paint paint) {
    canvas.drawCircle(Offset(cx - r * 0.3, cy), r * 0.5, paint);
    canvas.drawCircle(Offset(cx + r * 0.3, cy - r * 0.1), r * 0.45, paint);
    canvas.drawCircle(Offset(cx, cy - r * 0.35), r * 0.55, paint);
    canvas.drawCircle(Offset(cx + r * 0.6, cy + r * 0.1), r * 0.35, paint);
    canvas.drawCircle(Offset(cx - r * 0.6, cy + r * 0.1), r * 0.35, paint);
    canvas.drawRect(Rect.fromLTRB(cx - r * 0.85, cy, cx + r * 0.85, cy + r * 0.35), paint);
  }

  @override
  bool shouldRepaint(covariant _ShapePreviewPainter oldDelegate) =>
      shapeType != oldDelegate.shapeType ||
      isFilled != oldDelegate.isFilled ||
      color != oldDelegate.color;
}
