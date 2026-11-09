import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';
import '../models/drawing_guides.dart';
import '../models/paper_texture.dart';
import '../models/symmetry.dart';
import '../models/tools.dart';
import '../providers/canvas_providers.dart';
import '../providers/image_import_providers.dart';
import '../views/drawing_screen.dart';
import 'canvas_background_modal.dart';
import '../../settings/providers/settings_providers.dart';

/// Modal dialog that allows users to choose from premade canvas presets
/// or configure exact custom pixel dimensions for a new artwork.
class CanvasSizePickerModal extends ConsumerStatefulWidget {
  const CanvasSizePickerModal({super.key, this.initialName});

  final String? initialName;

  static void show(BuildContext context, {String? initialName}) {
    SoundEffectService.instance.playPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CanvasSizePickerModal(initialName: initialName),
    );
  }

  @override
  ConsumerState<CanvasSizePickerModal> createState() =>
      _CanvasSizePickerModalState();
}

class _CanvasSizePickerModalState extends ConsumerState<CanvasSizePickerModal> {
  late CanvasPreset _selectedPreset;
  late TextEditingController _nameController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  bool _isCustom = false;
  Color _selectedBgColor = const Color(0xFFFFFFFF);
  bool _isTransparentBg = false;
  int _presetTab = 0; // 0 = Art & General, 1 = Social Media

  List<CanvasPreset> get _currentPresets =>
      _presetTab == 0 ? CanvasPreset.artPresets : CanvasPreset.socialPresets;

  @override
  void initState() {
    super.initState();
    _selectedPreset = CanvasPreset.portrait;
    _nameController = TextEditingController(
      text: widget.initialName ?? 'Untitled Artwork',
    );
    _widthController = TextEditingController(
      text: _selectedPreset.width.toString(),
    );
    _heightController = TextEditingController(
      text: _selectedPreset.height.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _onSelectPreset(CanvasPreset preset) {
    SoundEffectService.instance.playPop();
    setState(() {
      _selectedPreset = preset;
      _isCustom = false;
      _widthController.text = preset.width.toString();
      _heightController.text = preset.height.toString();
    });
  }

  void _swapDimensions() {
    SoundEffectService.instance.playWhoosh();
    final currentW = int.tryParse(_widthController.text) ?? 1080;
    final currentH = int.tryParse(_heightController.text) ?? 1920;
    setState(() {
      _widthController.text = currentH.toString();
      _heightController.text = currentW.toString();
      _isCustom = true;
    });
  }

  void _createCanvas() {
    SoundEffectService.instance.playCelebration();
    final name = _nameController.text.trim().isEmpty
        ? 'Untitled Artwork'
        : _nameController.text.trim();

    final width = (int.tryParse(_widthController.text) ?? _selectedPreset.width)
        .clamp(100, 8192);
    final height =
        (int.tryParse(_heightController.text) ?? _selectedPreset.height)
            .clamp(100, 8192);

    final isThumbnail = _selectedPreset == CanvasPreset.youtubeThumbnail ||
        name.toLowerCase().contains('thumbnail');

    if (isThumbnail) {
      ref.read(autoFitToScreenProvider.notifier).state = true;
    }

    final nav = Navigator.of(context);
    nav.pop();

    // Ensure completely clean blank state:
    ref.read(undoRedoProvider.notifier).clear();
    ref.read(placedImageProvider.notifier).state = null;
    ref.read(symmetryProvider.notifier).state = const SymmetryConfig(mode: SymmetryMode.off);
    ref.read(showGridProvider.notifier).setGrid(false);
    ref.read(drawingGuideProvider.notifier).state = const DrawingGuideConfig();
    ref.read(paperTextureProvider.notifier).state = CanvasPaperTexture.none;
    ref.read(currentStrokeProvider.notifier).state = null;
    ref.read(activeToolProvider.notifier).selectTool(DrawingTool.brush);
    ref.read(canvasViewProvider.notifier).reset();

    ref.read(canvasDocumentProvider.notifier).createNew(
      name: name,
      width: width,
      height: height,
      backgroundColor: _selectedBgColor,
      transparent: _isTransparentBg,
      isThumbnail: isThumbnail,
    );

    nav.push(
      MaterialPageRoute(builder: (context) => const DrawingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final currentW = int.tryParse(_widthController.text) ?? 1080;
    final currentH = int.tryParse(_heightController.text) ?? 1920;
    final megapixels = (currentW * currentH / 1000000.0).toStringAsFixed(1);

    return Container(
      height: size.height * 0.88,
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
                      colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.aspect_ratio_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Canvas Size',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Select a premade preset or set custom dimensions',
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Artwork Name Input ──
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Artwork Title',
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF22223D) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Section 1: Premade Presets ──
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF6C5CE7)),
                      const SizedBox(width: 6),
                      Text(
                        'Canvas Presets',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // ── Tab Bar: Art & General / Social Media ──
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF22223D) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              SoundEffectService.instance.playPop();
                              setState(() => _presetTab = 0);
                            },
                            child: AnimatedContainer(
                              duration: AppAnimation.standard,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _presetTab == 0
                                    ? (isDark ? const Color(0xFF6C5CE7) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.xs),
                                boxShadow: _presetTab == 0
                                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.palette_rounded,
                                    size: 14,
                                    color: _presetTab == 0
                                        ? (isDark ? Colors.white : const Color(0xFF6C5CE7))
                                        : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Art & General',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: _presetTab == 0 ? FontWeight.bold : FontWeight.w500,
                                      color: _presetTab == 0
                                          ? (isDark ? Colors.white : const Color(0xFF6C5CE7))
                                          : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              SoundEffectService.instance.playPop();
                              setState(() => _presetTab = 1);
                            },
                            child: AnimatedContainer(
                              duration: AppAnimation.standard,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _presetTab == 1
                                    ? (isDark ? const Color(0xFFFF6B9D) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.xs),
                                boxShadow: _presetTab == 1
                                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.smartphone_rounded,
                                    size: 14,
                                    color: _presetTab == 1
                                        ? (isDark ? Colors.white : const Color(0xFFFF6B9D))
                                        : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Social Media',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: _presetTab == 1 ? FontWeight.bold : FontWeight.w500,
                                      color: _presetTab == 1
                                          ? (isDark ? Colors.white : const Color(0xFFFF6B9D))
                                          : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final int cols = w >= 700 ? 5 : (w >= 480 ? 4 : (w <= 310 ? 2 : 3));
                      final double ratio = w <= 310 ? 1.2 : (cols >= 4 ? 1.25 : 1.15);

                      final presets = _currentPresets;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          childAspectRatio: ratio,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: presets.length,
                        itemBuilder: (context, index) {
                          final p = presets[index];
                          final isSelected = !_isCustom && _selectedPreset == p;

                          return InkWell(
                            onTap: () => _onSelectPreset(p),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF6C5CE7).withValues(alpha: isDark ? 0.25 : 0.12)
                                    : (isDark ? const Color(0xFF22223D) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF6C5CE7)
                                      : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getPresetIcon(p),
                                    size: 20,
                                    color: isSelected
                                        ? const Color(0xFF6C5CE7)
                                        : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFF6C5CE7)
                                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${p.width} × ${p.height}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Section 2: Custom Dimensions ──
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF00B894)),
                      const SizedBox(width: 6),
                      Text(
                        'Custom Dimensions (px)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$megapixels MP',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00B894),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  Row(
                    children: [
                      // Width Input
                      Expanded(
                        child: TextField(
                          controller: _widthController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() => _isCustom = true),
                          decoration: InputDecoration(
                            labelText: 'Width (px)',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF22223D) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),

                      // Swap Dimensions Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: IconButton(
                          icon: const Icon(Icons.swap_horiz_rounded),
                          onPressed: _swapDimensions,
                          tooltip: 'Swap Orientation',
                          color: const Color(0xFF6C5CE7),
                        ),
                      ),

                      // Height Input
                      Expanded(
                        child: TextField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() => _isCustom = true),
                          decoration: InputDecoration(
                            labelText: 'Height (px)',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF22223D) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Section 3: Canvas Background ──
                  Row(
                    children: [
                      const Icon(Icons.wallpaper_rounded, size: 16, color: Color(0xFFFF6B9D)),
                      const SizedBox(width: 6),
                      Text(
                        'Canvas Background',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          CanvasBackgroundModal.show(
                            context,
                            ref,
                            initialColor: _selectedBgColor,
                            initialTransparent: _isTransparentBg,
                            onSelect: (color, isTrans) {
                              setState(() {
                                _selectedBgColor = color;
                                _isTransparentBg = isTrans;
                              });
                            },
                          );
                        },
                        icon: const Icon(Icons.tune_rounded, size: 14),
                        label: const Text('More & Custom', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Background Presets Horizontal List
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: CanvasBackgroundPreset.allPresets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final preset = CanvasBackgroundPreset.allPresets[idx];
                        final isSelected = preset.isTransparent
                            ? _isTransparentBg
                            : (!_isTransparentBg && _selectedBgColor == preset.color);

                        return InkWell(
                          onTap: () {
                            SoundEffectService.instance.playPop();
                            setState(() {
                              _isTransparentBg = preset.isTransparent;
                              if (!preset.isTransparent) {
                                _selectedBgColor = preset.color;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF22223D) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6C5CE7)
                                    : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                width: isSelected ? 2.2 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: preset.isTransparent ? Colors.transparent : preset.color,
                                    border: Border.all(color: Colors.grey.shade400, width: 0.8),
                                  ),
                                  child: preset.isTransparent
                                      ? const Icon(Icons.grid_on_rounded, size: 12, color: Colors.blueGrey)
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  preset.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.check_rounded, size: 14, color: Color(0xFF6C5CE7)),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createCanvas,
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
                label: Text(
                  'Create Canvas ($currentW × $currentH)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPresetIcon(CanvasPreset preset) {
    return switch (preset) {
      CanvasPreset.square || CanvasPreset.socialPost || CanvasPreset.instagramPost => Icons.crop_square_rounded,
      CanvasPreset.portrait || CanvasPreset.instagramStory || CanvasPreset.tiktokVideo => Icons.stay_current_portrait_rounded,
      CanvasPreset.landscape => Icons.stay_current_landscape_rounded,
      CanvasPreset.phoneWallpaper => Icons.wallpaper_rounded,
      CanvasPreset.fourK => Icons.tv_rounded,
      CanvasPreset.kidsPad => Icons.child_care_rounded,
      CanvasPreset.comic => Icons.menu_book_rounded,
      CanvasPreset.a4Portrait => Icons.description_outlined,
      CanvasPreset.a4Landscape => Icons.newspaper_outlined,
      CanvasPreset.custom => Icons.tune_rounded,
      // Social Media
      CanvasPreset.youtubeThumbnail || CanvasPreset.youtubeChannelArt => Icons.play_circle_fill_rounded,
      CanvasPreset.facebookCover || CanvasPreset.facebookPost => Icons.facebook_rounded,
      CanvasPreset.twitterHeader || CanvasPreset.twitterPost => Icons.alternate_email_rounded,
      CanvasPreset.linkedInBanner => Icons.business_rounded,
      CanvasPreset.pinterestPin => Icons.push_pin_rounded,
      CanvasPreset.twitchBanner => Icons.videogame_asset_rounded,
    };
  }
}
