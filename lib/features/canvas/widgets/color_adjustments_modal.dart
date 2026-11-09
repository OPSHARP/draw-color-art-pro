import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stroke.dart';
import '../providers/canvas_providers.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// iOS-styled modal for professional color adjustments and artistic filters.
///
/// Supports Brightness, Contrast, Saturation, Hue Shift, and 6 one-tap curated filters.
class ColorAdjustmentsModal extends ConsumerStatefulWidget {
  const ColorAdjustmentsModal({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    SoundEffectService.instance.playPop();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ColorAdjustmentsModal(),
    );
  }

  @override
  ConsumerState<ColorAdjustmentsModal> createState() => _ColorAdjustmentsModalState();
}

class _ColorAdjustmentsModalState extends ConsumerState<ColorAdjustmentsModal> {
  int _selectedSegment = 0; // 0: Sliders, 1: Presets

  double _brightness = 0.0; // -1.0 to 1.0
  double _contrast = 0.0; // -1.0 to 1.0
  double _saturation = 0.0; // -1.0 to 1.0
  double _hueShift = 0.0; // -180.0 to 180.0

  String? _activePreset;

  void _resetAll() {
    HapticFeedback.selectionClick();
    setState(() {
      _brightness = 0.0;
      _contrast = 0.0;
      _saturation = 0.0;
      _hueShift = 0.0;
      _activePreset = null;
    });
  }

  void _applyPreset(String name) {
    HapticFeedback.selectionClick();
    SoundEffectService.instance.playPop();
    setState(() {
      _activePreset = name;
      switch (name) {
        case 'Vivid':
          _brightness = 0.05;
          _contrast = 0.2;
          _saturation = 0.35;
          _hueShift = 0.0;
          break;
        case 'Monochrome':
          _brightness = 0.0;
          _contrast = 0.15;
          _saturation = -1.0;
          _hueShift = 0.0;
          break;
        case 'Warm Amber':
          _brightness = 0.05;
          _contrast = 0.1;
          _saturation = 0.15;
          _hueShift = 15.0;
          break;
        case 'Cool Cyber':
          _brightness = -0.05;
          _contrast = 0.25;
          _saturation = 0.3;
          _hueShift = -45.0;
          break;
        case 'Noir':
          _brightness = -0.1;
          _contrast = 0.5;
          _saturation = -1.0;
          _hueShift = 0.0;
          break;
        case 'Pastel Soft':
          _brightness = 0.2;
          _contrast = -0.15;
          _saturation = -0.2;
          _hueShift = 0.0;
          break;
      }
    });
  }

  Color _transformColor(Color c) {
    final hsv = HSVColor.fromColor(c);

    // Hue shift
    double newHue = (hsv.hue + _hueShift) % 360.0;
    if (newHue < 0) newHue += 360.0;

    // Saturation
    final newSat = (hsv.saturation + _saturation).clamp(0.0, 1.0);

    // Brightness & Contrast
    double newVal = hsv.value;
    if (_contrast != 0.0) {
      newVal = ((newVal - 0.5) * (1.0 + _contrast)) + 0.5;
    }
    newVal = (newVal + _brightness).clamp(0.0, 1.0);

    return hsv.withHue(newHue).withSaturation(newSat).withValue(newVal).toColor();
  }

  void _commitAdjustments() {
    final docNotifier = ref.read(canvasDocumentProvider.notifier);
    final undoNotifier = ref.read(undoRedoProvider.notifier);
    final doc = ref.read(canvasDocumentProvider);
    final activeLayer = doc.activeLayer;

    if (activeLayer == null || activeLayer.strokes.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final oldStrokes = List<Stroke>.from(activeLayer.strokes);
    final newStrokes = activeLayer.strokes.map((s) {
      final newColor = _transformColor(s.color);
      final newSecondary = s.secondaryColor != null ? _transformColor(s.secondaryColor!) : null;
      return s.copyWith(color: newColor, secondaryColor: newSecondary);
    }).toList();

    docNotifier.updateActiveLayerStrokes(newStrokes);
    undoNotifier.pushAction(
      LayerStrokesAction(
        documentNotifier: docNotifier,
        oldStrokes: oldStrokes,
        newStrokes: newStrokes,
      ),
    );

    HapticFeedback.mediumImpact();
    SoundEffectService.instance.playCelebration();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final doc = ref.watch(canvasDocumentProvider);
    final activeLayer = doc.activeLayer;
    final strokeCount = activeLayer?.strokes.length ?? 0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: AppBlur.sheet,
        child: Container(
          color: isDark ? IOSColors.darkElevated : IOSColors.lightSurface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

                // Title & Action Header
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _resetAll,
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 16,
                          color: IOSColors.systemRed,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Color Adjustments',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: strokeCount > 0 ? _commitAdjustments : null,
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: IOSColors.brandPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // iOS Segmented Control
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _selectedSegment,
                    children: const {
                      0: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Text('Fine Adjust'),
                      ),
                      1: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Text('Artistic Filters'),
                      ),
                    },
                    onValueChanged: (val) {
                      if (val != null) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedSegment = val);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Segment Content
                if (_selectedSegment == 0) ...[
                  _buildSliderRow(
                    label: 'Brightness',
                    value: _brightness,
                    min: -0.8,
                    max: 0.8,
                    display: '${(_brightness * 100).toInt()}%',
                    onChanged: (v) => setState(() => _brightness = v),
                  ),
                  _buildSliderRow(
                    label: 'Contrast',
                    value: _contrast,
                    min: -0.8,
                    max: 0.8,
                    display: '${(_contrast * 100).toInt()}%',
                    onChanged: (v) => setState(() => _contrast = v),
                  ),
                  _buildSliderRow(
                    label: 'Saturation',
                    value: _saturation,
                    min: -1.0,
                    max: 1.0,
                    display: '${(_saturation * 100).toInt()}%',
                    onChanged: (v) => setState(() => _saturation = v),
                  ),
                  _buildSliderRow(
                    label: 'Hue Shift',
                    value: _hueShift,
                    min: -180.0,
                    max: 180.0,
                    display: '${_hueShift.toInt()}°',
                    onChanged: (v) => setState(() => _hueShift = v),
                  ),
                ] else ...[
                  // Presets Grid
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      'Vivid',
                      'Monochrome',
                      'Warm Amber',
                      'Cool Cyber',
                      'Noir',
                      'Pastel Soft',
                    ].map((name) {
                      final isSelected = _activePreset == name;
                      return CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _applyPreset(name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? IOSColors.brandPrimary
                                : (isDark ? IOSColors.darkSurface : IOSColors.systemGray6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? IOSColors.brandPrimary
                                  : (isDark ? Colors.white12 : Colors.black12),
                            ),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // Meta Info Badge
                Text(
                  strokeCount > 0
                      ? 'Will adjust $strokeCount stroke(s) on active layer "${activeLayer?.name ?? 'Layer'}"'
                      : 'Active layer has no strokes to adjust',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? IOSColors.systemGray : IOSColors.systemGray2,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: CupertinoSlider(
              value: value,
              min: min,
              max: max,
              activeColor: IOSColors.brandPrimary,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              display,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

