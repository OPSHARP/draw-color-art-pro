import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../canvas/providers/canvas_providers.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../core/constants/design_tokens.dart';
import 'models/color_harmonies.dart';
import 'services/palette_extractor_service.dart';

/// HSB Color picker with hue ring, saturation/brightness square, hex input,
/// opacity slider, and color history.
class ColorPickerPanel extends ConsumerStatefulWidget {
  const ColorPickerPanel({super.key, this.onClose});
  final VoidCallback? onClose;

  @override
  ConsumerState<ColorPickerPanel> createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends ConsumerState<ColorPickerPanel> {
  late HSVColor _hsv;
  final _hexController = TextEditingController();
  int _selectedPresetIndex = 0;
  bool _showHarmonies = false;
  HarmonyType _selectedHarmony = HarmonyType.complementary;
  final List<({String name, List<Color> colors})> _customPalettes = [];
  Color? _lastSyncedColor;

  List<({String name, List<Color> colors})> get _allPalettes => [
    ..._customPalettes,
    ..._curatedPalettes,
  ];

  Future<void> _showPaletteExtractOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Extract Palette from Photo', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  _extractPalette(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  _extractPalette(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _extractPalette(ImageSource source) async {
    final result = await PaletteExtractorService.instance.pickAndExtract(source: source);
    if (result != null && mounted) {
      SoundEffectService.instance.playCelebration();
      setState(() {
        _customPalettes.insert(0, (name: result.name, colors: result.colors));
        _selectedPresetIndex = 0;
        _showHarmonies = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Extracted ${result.colors.length} harmonic colors!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final initialColor = ref.read(activeColorProvider);
    _lastSyncedColor = initialColor;
    final hsv = HSVColor.fromColor(initialColor);
    _hsv = (hsv.saturation < 0.01 && hsv.value < 0.01)
        ? HSVColor.fromAHSV(hsv.alpha, 0.0, 1.0, 0.0)
        : hsv;
    _hexController.text = _colorToHex(initialColor);
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _updateFromHSV(HSVColor hsv) {
    final color = hsv.toColor();
    _lastSyncedColor = color;
    setState(() {
      _hsv = hsv;
      _hexController.text = _colorToHex(color);
    });
    ref.read(activeColorProvider.notifier).setColor(color);
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = ref.watch(activeColorProvider);
    final colorHistory = ref.watch(colorHistoryProvider);
    final theme = Theme.of(context);

    // Sync if color changed externally (e.g., toolbar swatches, eyedropper)
    if (_lastSyncedColor == null || _lastSyncedColor!.toARGB32() != currentColor.toARGB32()) {
      _lastSyncedColor = currentColor;
      final currentHSV = HSVColor.fromColor(currentColor);
      final isAchromatic = currentHSV.saturation < 0.02 || currentHSV.value < 0.02;
      _hsv = isAchromatic ? currentHSV.withHue(_hsv.hue) : currentHSV;
      _hexController.text = _colorToHex(currentColor);
    }

    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.7;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: AppBlur.sheet,
            child: Container(
              width: 280,
              constraints: BoxConstraints(maxHeight: maxHeight),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? IOSColors.frostedDark : IOSColors.frostedLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? IOSColors.darkSeparator : IOSColors.lightSeparator,
                  width: 0.5,
                ),
                boxShadow: AppShadow.floating,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              // ── Header ──
              Row(
                children: [
                  Text(
                    'Color',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  // Current color preview
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _hsv.toColor(),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white30 : Colors.black12,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _hsv.toColor().withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onClose != null) ...[
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(26, 26),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onClose?.call();
                      },
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 20,
                        color: isDark ? IOSColors.systemGray : IOSColors.systemGray2,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

          // ── Saturation/Brightness Square ──
          SizedBox(
            height: 180,
            child: _SaturationBrightnessSquare(
              key: const ValueKey('saturation_brightness_square'),
              hue: _hsv.hue,
              saturation: _hsv.saturation,
              value: _hsv.value,
              onChanged: (sat, val) {
                _updateFromHSV(
                  HSVColor.fromAHSV(_hsv.alpha, _hsv.hue, sat, val),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Hue Slider ──
          _HueSlider(
            key: const ValueKey('hue_slider'),
            hue: _hsv.hue,
            onChanged: (hue) {
              final newSat = _hsv.saturation < 0.05 ? 1.0 : _hsv.saturation;
              final newVal = _hsv.value < 0.05 ? 1.0 : _hsv.value;
              _updateFromHSV(
                HSVColor.fromAHSV(
                  _hsv.alpha,
                  hue,
                  newSat,
                  newVal,
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xs),

          // ── Opacity Slider ──
          _OpacitySlider(
            key: const ValueKey('opacity_slider'),
            color: _hsv.toColor(),
            opacity: _hsv.alpha,
            onChanged: (alpha) {
              _updateFromHSV(
                HSVColor.fromAHSV(
                  alpha,
                  _hsv.hue,
                  _hsv.saturation,
                  _hsv.value,
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Hex Input ──
          Row(
            children: [
              Text('HEX', style: theme.textTheme.labelSmall),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _hexController,
                    style: theme.textTheme.labelMedium,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        borderSide: BorderSide(
                          color: theme.dividerTheme.color ?? Colors.grey,
                        ),
                      ),
                    ),
                    onSubmitted: (value) {
                      final hex = value.replaceAll('#', '').trim();
                      if (hex.length == 6) {
                        try {
                          final color = Color(int.parse('FF$hex', radix: 16));
                          _updateFromHSV(HSVColor.fromColor(color));
                        } catch (_) {}
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Color History ──
          if (colorHistory.isNotEmpty) ...[
            Text('Recent', style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.xxs),
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: colorHistory.length,
                separatorBuilder: (_, __) => const SizedBox(width: 5),
                itemBuilder: (context, index) {
                  final c = colorHistory[index];
                  final isSelected = c.toARGB32() == _hsv.toColor().toARGB32();
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      SoundEffectService.instance.playPop();
                      _updateFromHSV(HSVColor.fromColor(c));
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black87)
                              : (theme.dividerTheme.color ?? Colors.grey),
                          width: isSelected ? 2.0 : 0.6,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: c.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: c.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // ── Color Harmonies & Palettes Toggle Header ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    SoundEffectService.instance.playPop();
                    setState(() => _showHarmonies = false);
                  },
                  child: Text(
                    'Palettes',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: !_showHarmonies ? FontWeight.bold : FontWeight.normal,
                      color: !_showHarmonies ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('·', style: theme.textTheme.labelSmall),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    SoundEffectService.instance.playPop();
                    setState(() => _showHarmonies = true);
                  },
                  child: Text(
                    'Harmonies',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: _showHarmonies ? FontWeight.bold : FontWeight.normal,
                      color: _showHarmonies ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _showPaletteExtractOptions(context),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, size: 13, color: theme.colorScheme.primary),
                        const SizedBox(width: 3),
                        Text('Photo', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: theme.colorScheme.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          if (!_showHarmonies) ...[
            // ── Curated & Extracted Palettes ──
            SizedBox(
              height: 26,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _allPalettes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, idx) {
                  final isSelected = _selectedPresetIndex == idx;
                  return ChoiceChip(
                    label: Text(_allPalettes[idx].name),
                    selected: isSelected,
                    labelStyle: TextStyle(
                      fontSize: 9.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : null,
                    ),
                    selectedColor: theme.colorScheme.primary,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) {
                      SoundEffectService.instance.playPop();
                      setState(() => _selectedPresetIndex = idx);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: _allPalettes[_selectedPresetIndex.clamp(0, _allPalettes.length - 1)]
                  .colors
                  .map((c) {
                    final isSelected = c.toARGB32() == _hsv.toColor().toARGB32();
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        SoundEffectService.instance.playPop();
                        _updateFromHSV(HSVColor.fromColor(c));
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black87)
                                : (theme.dividerTheme.color?.withValues(alpha: 0.3) ?? Colors.black12),
                            width: isSelected ? 2.0 : 0.7,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: c.withValues(alpha: 0.45),
                                blurRadius: 5,
                                spreadRadius: 0.5,
                              ),
                          ],
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 14,
                                color: c.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                              )
                            : null,
                      ),
                    );
                  })
                  .toList(),
            ),
          ] else ...[
            // ── Harmonic Color Schemes ──
            SizedBox(
              height: 26,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: HarmonyType.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, idx) {
                  final type = HarmonyType.values[idx];
                  final isSelected = _selectedHarmony == type;
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: isSelected,
                    labelStyle: TextStyle(
                      fontSize: 9.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : null,
                    ),
                    selectedColor: theme.colorScheme.secondary,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) {
                      SoundEffectService.instance.playPop();
                      setState(() => _selectedHarmony = type);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Live calculated harmony swatches
            Builder(
              builder: (context) {
                final harmonyColors = ColorHarmonies.compute(_hsv.toColor(), _selectedHarmony);
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: harmonyColors.map((c) {
                    final isCurrent = c.toARGB32() == _hsv.toColor().toARGB32();
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        SoundEffectService.instance.playPop();
                        _updateFromHSV(HSVColor.fromColor(c));
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          border: Border.all(
                            color: isCurrent
                                ? theme.colorScheme.primary
                                : Colors.black26,
                            width: isCurrent ? 2.0 : 0.8,
                          ),
                          boxShadow: [
                            if (isCurrent)
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                          ],
                        ),
                        child: isCurrent
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    ),
  ),
),
);
},
);
}

  static const _curatedPalettes = [
    (
      name: 'Essential',
      colors: [
        Color(0xFF000000), Color(0xFF333333), Color(0xFF666666),
        Color(0xFF999999), Color(0xFFCCCCCC), Color(0xFFFFFFFF),
        Color(0xFFFF0000), Color(0xFFFF6B00), Color(0xFFFFD700),
        Color(0xFF00C853), Color(0xFF2196F3), Color(0xFF9C27B0),
        Color(0xFFFF4081), Color(0xFF00BCD4), Color(0xFF8BC34A),
        Color(0xFFFF9800), Color(0xFF795548), Color(0xFF607D8B),
      ],
    ),
    (
      name: 'Pastel Dream',
      colors: [
        Color(0xFFFFB3BA), Color(0xFFFFDFBA), Color(0xFFFFFFBA),
        Color(0xFFBAFFC9), Color(0xFFBAE1FF), Color(0xFFD4BAFF),
        Color(0xFFFFC6FF), Color(0xFFBDB2FF), Color(0xFFA0C4FF),
        Color(0xFF9BF6FF), Color(0xFFCAFFBF), Color(0xFFFDFFB6),
        Color(0xFFFFD6A5), Color(0xFFFFADAD), Color(0xFFE8D7F1),
        Color(0xFFD3BCC0), Color(0xFFA5A58D), Color(0xFFB7B7A4),
      ],
    ),
    (
      name: 'Neon Glow',
      colors: [
        Color(0xFF00F0FF), Color(0xFFFF007F), Color(0xFF39FF14),
        Color(0xFFFFEE00), Color(0xFFBF00FF), Color(0xFFFF5F00),
        Color(0xFF00FF66), Color(0xFF00E5FF), Color(0xFFD600FF),
        Color(0xFFFF003C), Color(0xFF7000FF), Color(0xFF00FFC2),
        Color(0xFFFFFF00), Color(0xFFFF0055), Color(0xFF05FFA1),
        Color(0xFFEBEBEB), Color(0xFF1E1E2E), Color(0xFF09090E),
      ],
    ),
    (
      name: 'Nature & Earth',
      colors: [
        Color(0xFF2D5A27), Color(0xFF437A35), Color(0xFF689F38),
        Color(0xFF8BC34A), Color(0xFFAED581), Color(0xFFDCEDC8),
        Color(0xFF5D4037), Color(0xFF795548), Color(0xFF8D6E63),
        Color(0xFFA1887F), Color(0xFFD7CCC8), Color(0xFFEFEBE9),
        Color(0xFFE65100), Color(0xFFEF6C00), Color(0xFFF57C00),
        Color(0xFFFF9800), Color(0xFFFFB74D), Color(0xFFFFE0B2),
      ],
    ),
    (
      name: 'Sunset Horizon',
      colors: [
        Color(0xFF1A1B4B), Color(0xFF2E1A47), Color(0xFF4A154B),
        Color(0xFF6B114D), Color(0xFF8E0E4F), Color(0xFFB31251),
        Color(0xFFD92546), Color(0xFFF04A38), Color(0xFFFF7028),
        Color(0xFFFF9913), Color(0xFFFFC000), Color(0xFFFFE600),
        Color(0xFFFF69B4), Color(0xFFFF1493), Color(0xFFC71585),
        Color(0xFF483D8B), Color(0xFF4B0082), Color(0xFF2F0A3D),
      ],
    ),
    (
      name: 'Ocean Deep',
      colors: [
        Color(0xFF03045E), Color(0xFF023E8A), Color(0xFF0077B6),
        Color(0xFF0096C7), Color(0xFF00B4D8), Color(0xFF48CAE4),
        Color(0xFF90E0EF), Color(0xFFADE8F4), Color(0xFFCAF0F8),
        Color(0xFF007F5F), Color(0xFF2B9348), Color(0xFF55A630),
        Color(0xFF80B918), Color(0xFFAACC00), Color(0xFFBFD200),
        Color(0xFF132A13), Color(0xFF31572C), Color(0xFF4F772D),
      ],
    ),
    (
      name: 'Portrait & Skin',
      colors: [
        Color(0xFFFFF0E8), Color(0xFFFFE3D1), Color(0xFFFFD4B8),
        Color(0xFFFFC59E), Color(0xFFF2B085), Color(0xFFE59C6D),
        Color(0xFFD18654), Color(0xFFB8713D), Color(0xFF9E5C29),
        Color(0xFF854919), Color(0xFF6C370D), Color(0xFF532605),
        Color(0xFF3A1800), Color(0xFFF8A5A5), Color(0xFFE87E8E),
        Color(0xFFB55266), Color(0xFF8C3848), Color(0xFF5C1E2B),
      ],
    ),
  ];
}

/// Saturation/Brightness square picker.
class _SaturationBrightnessSquare extends StatelessWidget {
  const _SaturationBrightnessSquare({
    super.key,
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  final double hue;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _handleTouch(details.localPosition, constraints),
          onPanDown: (details) => _handleTouch(details.localPosition, constraints),
          onPanStart: (details) => _handleTouch(details.localPosition, constraints),
          onPanUpdate: (details) => _handleTouch(details.localPosition, constraints),
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white,
                  HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
              child: CustomPaint(
                painter: _ThumbPainter(
                  x: saturation * constraints.maxWidth,
                  y: (1 - value) * constraints.maxHeight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTouch(Offset position, BoxConstraints constraints) {
    if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) return;
    final sat = (position.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final val = 1 - (position.dy / constraints.maxHeight).clamp(0.0, 1.0);
    onChanged(sat, val);
  }
}

/// Hue slider with rainbow gradient.
class _HueSlider extends StatelessWidget {
  const _HueSlider({super.key, required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        void handleTouch(Offset localPosition) {
          if (constraints.maxWidth <= 0) return;
          final h = (localPosition.dx / constraints.maxWidth * 360).clamp(0.0, 360.0);
          onChanged(h);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => handleTouch(details.localPosition),
          onPanDown: (details) => handleTouch(details.localPosition),
          onPanStart: (details) => handleTouch(details.localPosition),
          onPanUpdate: (details) => handleTouch(details.localPosition),
          child: Container(
            width: constraints.maxWidth,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF00FFFF),
                  Color(0xFF0000FF),
                  Color(0xFFFF00FF),
                  Color(0xFFFF0000),
                ],
              ),
            ),
            child: CustomPaint(
              painter: _ThumbPainter(
                x: hue / 360 * constraints.maxWidth,
                y: 12,
                radius: 8,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Opacity slider.
class _OpacitySlider extends StatelessWidget {
  const _OpacitySlider({
    super.key,
    required this.color,
    required this.opacity,
    required this.onChanged,
  });

  final Color color;
  final double opacity;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        void handleTouch(Offset localPosition) {
          if (constraints.maxWidth <= 0) return;
          final a = (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
          onChanged(a);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => handleTouch(details.localPosition),
          onPanDown: (details) => handleTouch(details.localPosition),
          onPanStart: (details) => handleTouch(details.localPosition),
          onPanUpdate: (details) => handleTouch(details.localPosition),
          child: Container(
            width: constraints.maxWidth,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0),
                  color.withValues(alpha: 1),
                ],
              ),
            ),
            child: CustomPaint(
              painter: _ThumbPainter(
                x: opacity * constraints.maxWidth,
                y: 12,
                radius: 8,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Paints a circular thumb indicator at (x, y).
class _ThumbPainter extends CustomPainter {
  const _ThumbPainter({required this.x, required this.y, this.radius = 7});

  final double x;
  final double y;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(x, y),
      radius + 1,
      Paint()..color = Colors.black54,
    );
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ThumbPainter old) =>
      old.x != x || old.y != y;
}
