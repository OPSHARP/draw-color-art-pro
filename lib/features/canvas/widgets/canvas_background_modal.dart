import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';
import '../providers/canvas_providers.dart';

/// Representation of a preset canvas background option.
class CanvasBackgroundPreset {
  const CanvasBackgroundPreset({
    required this.name,
    required this.description,
    required this.color,
    this.isTransparent = false,
    this.icon,
  });

  final String name;
  final String description;
  final Color color;
  final bool isTransparent;
  final IconData? icon;

  static const List<CanvasBackgroundPreset> allPresets = [
    CanvasBackgroundPreset(
      name: 'Pure White',
      description: 'Clean sketchbook paper',
      color: Color(0xFFFFFFFF),
      icon: Icons.note_rounded,
    ),
    CanvasBackgroundPreset(
      name: 'Warm Cream',
      description: 'Fine art drawing paper',
      color: Color(0xFFFDFBF7),
      icon: Icons.brush_rounded,
    ),
    CanvasBackgroundPreset(
      name: 'Vintage Parchment',
      description: 'Antique craft parchment',
      color: Color(0xFFF5E6CA),
      icon: Icons.history_edu_rounded,
    ),
    CanvasBackgroundPreset(
      name: 'Warm Neutral Gray',
      description: 'Value sketch & toning',
      color: Color(0xFFE2E8F0),
      icon: Icons.palette_outlined,
    ),
    CanvasBackgroundPreset(
      name: 'Chalkboard Dark',
      description: 'Glow, neon & chalk',
      color: Color(0xFF1E1E2E),
      icon: Icons.dark_mode_rounded,
    ),
    CanvasBackgroundPreset(
      name: 'Pitch Black',
      description: 'High contrast & inking',
      color: Color(0xFF000000),
      icon: Icons.brightness_1_rounded,
    ),
    CanvasBackgroundPreset(
      name: 'Blueprint Blue',
      description: 'Architectural & drafting',
      color: Color(0xFF1E3A8A),
      icon: Icons.architecture_rounded,
    ),
    CanvasBackgroundPreset(
      name: 'Pastel Peach',
      description: 'Warm portrait & soft tone',
      color: Color(0xFFFFE5D9),
      icon: Icons.face_rounded,
    ),
    CanvasBackgroundPreset(
      name: 'Soft Mint',
      description: 'Botanical & nature art',
      color: Color(0xFFE6F4EA),
      icon: Icons.eco_rounded,
    ),
    CanvasBackgroundPreset(
      name: 'Pastel Sky',
      description: 'Airbrush & scenery',
      color: Color(0xFFE0F2FE),
      icon: Icons.cloud_rounded,
    ),
    CanvasBackgroundPreset(
      name: 'Pastel Lavender',
      description: 'Fantasy, anime & dreams',
      color: Color(0xFFF3E8FF),
      icon: Icons.auto_awesome_rounded,
    ),
    CanvasBackgroundPreset(
      name: 'Transparent',
      description: 'Checkerboard for stickers & PNG',
      color: Colors.transparent,
      isTransparent: true,
      icon: Icons.grid_on_rounded,
    ),
  ];
}

/// Modal bottom sheet allowing users to pick or change the canvas background.
class CanvasBackgroundModal extends ConsumerStatefulWidget {
  const CanvasBackgroundModal({
    super.key,
    this.initialColor = const Color(0xFFFFFFFF),
    this.initialTransparent = false,
    this.onSelect,
  });

  final Color initialColor;
  final bool initialTransparent;
  final void Function(Color color, bool isTransparent)? onSelect;

  /// Show the background modal for an active drawing session.
  static void show(
    BuildContext context,
    WidgetRef ref, {
    Color? initialColor,
    bool? initialTransparent,
    void Function(Color color, bool isTransparent)? onSelect,
  }) {
    SoundEffectService.instance.playPop();
    final doc = ref.read(canvasDocumentProvider);
    final color = initialColor ?? doc.backgroundColor;
    final transparent = initialTransparent ?? doc.isTransparentBackground;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CanvasBackgroundModal(
        initialColor: color,
        initialTransparent: transparent,
        onSelect: onSelect ??
            (selectedColor, isTransparent) {
              ref.read(canvasDocumentProvider.notifier).setBackgroundColor(
                    selectedColor,
                    transparent: isTransparent,
                  );
            },
      ),
    );
  }

  @override
  ConsumerState<CanvasBackgroundModal> createState() => _CanvasBackgroundModalState();
}

class _CanvasBackgroundModalState extends ConsumerState<CanvasBackgroundModal> {
  late Color _currentColor;
  late bool _isTransparent;

  final List<Color> _customSwatches = const [
    Color(0xFFFF7675),
    Color(0xFFFF9F43),
    Color(0xFFFECA57),
    Color(0xFF1DD1A1),
    Color(0xFF48DBFB),
    Color(0xFF54A0FF),
    Color(0xFF5F27CD),
    Color(0xFFFF6B6B),
    Color(0xFF00D2D3),
    Color(0xFF341F97),
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _isTransparent = widget.initialTransparent;
  }

  void _selectPreset(CanvasBackgroundPreset preset) {
    SoundEffectService.instance.playPop();
    setState(() {
      _isTransparent = preset.isTransparent;
      if (!preset.isTransparent) {
        _currentColor = preset.color;
      }
    });
  }

  void _selectColor(Color color) {
    SoundEffectService.instance.playPop();
    setState(() {
      _isTransparent = false;
      _currentColor = color;
    });
  }

  void _applyAndClose() {
    SoundEffectService.instance.playCelebration();
    widget.onSelect?.call(_currentColor, _isTransparent);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18182E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                        colors: [Color(0xFF6C5CE7), Color(0xFFFF7675)],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.wallpaper_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Canvas Background',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Paper tones, solid shades, or transparent checkerboard',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
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

            const Divider(height: 1),

            // ── Scrollable Body ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Live Canvas Preview Card ──
                    Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_isTransparent)
                            CustomPaint(painter: _CheckerboardPainter())
                          else
                            Container(color: _currentColor),

                          // Subtle artistic guide demo overlay
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isTransparent
                                      ? Icons.grid_on_rounded
                                      : Icons.brush_rounded,
                                  size: 28,
                                  color: _isTransparent
                                      ? const Color(0xFF6C5CE7)
                                      : (_currentColor.computeLuminance() > 0.5
                                          ? const Color(0xFF1E293B)
                                          : Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isTransparent
                                      ? 'Transparent Canvas (PNG Alpha)'
                                      : 'Background: #${_currentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isTransparent
                                        ? const Color(0xFF1E293B)
                                        : (_currentColor.computeLuminance() > 0.5
                                            ? const Color(0xFF1E293B)
                                            : Colors.white),
                                    shadows: [
                                      if (_isTransparent)
                                        const Shadow(color: Colors.white, blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Section 1: Paper & Tone Presets ──
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF6C5CE7)),
                        const SizedBox(width: 6),
                        Text(
                          'Curated Paper & Canvas Presets',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.6,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: CanvasBackgroundPreset.allPresets.length,
                      itemBuilder: (context, index) {
                        final preset = CanvasBackgroundPreset.allPresets[index];
                        final isSelected = preset.isTransparent
                            ? _isTransparent
                            : (!_isTransparent && _currentColor == preset.color);

                        return InkWell(
                          onTap: () => _selectPreset(preset),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF22223D) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6C5CE7)
                                    : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                width: isSelected ? 2.5 : 1.0,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                                    blurRadius: 6,
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade400, width: 0.8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: preset.isTransparent
                                      ? CustomPaint(painter: _CheckerboardPainter())
                                      : Container(color: preset.color),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        preset.name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        preset.description,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF6C5CE7), size: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Section 2: Quick Custom Tint Swatches ──
                    Row(
                      children: [
                        const Icon(Icons.color_lens_rounded, size: 16, color: Color(0xFFFF6B9D)),
                        const SizedBox(width: 6),
                        Text(
                          'Quick Tint Swatches',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          for (final col in _customSwatches)
                            GestureDetector(
                              onTap: () => _selectColor(col),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: col,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: (!_isTransparent && _currentColor == col)
                                        ? const Color(0xFF6C5CE7)
                                        : Colors.white,
                                    width: (!_isTransparent && _currentColor == col) ? 3 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: col.withValues(alpha: 0.35),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: (!_isTransparent && _currentColor == col)
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Action Button (Protected from Navigation Keys) ──
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                bottomInset > 0 ? bottomInset + AppSpacing.xs : AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18182E) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _applyAndClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    _isTransparent
                        ? 'Set Transparent Background'
                        : 'Set Background (${CanvasBackgroundPreset.allPresets.where((p) => !p.isTransparent && p.color == _currentColor).firstOrNull?.name ?? "Custom"})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

/// Draws an alternating gray and white checkerboard pattern representing alpha/transparency.
class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 6.0;
    final lightPaint = Paint()..color = const Color(0xFFEEEEEE);
    final darkPaint = Paint()..color = const Color(0xFFCCCCCC);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lightPaint);

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isEven = ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        if (isEven) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, squareSize, squareSize),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
