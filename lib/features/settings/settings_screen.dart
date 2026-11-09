import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/audio/sound_effect_service.dart';
import '../projects/services/project_storage_service.dart';
import '../projects/views/project_manager_screen.dart';
import 'providers/settings_providers.dart';
import 'views/privacy_policy_screen.dart';
import 'views/terms_of_service_screen.dart';
import '../../core/constants/app_version.dart';
import '../../core/services/display_service.dart';

/// iOS Settings app aesthetic for Draw Color Art Pro.
///
/// Implements Apple Human Interface Guidelines:
/// - Inset grouped table view sections (`CupertinoListSection.insetGrouped`)
/// - Vibrant squircle icon badges
/// - Native `CupertinoSwitch`, chevrons, and `CupertinoActionSheet` modals
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final canvasPreset = ref.watch(defaultCanvasSizeProvider);
    final showGrid = ref.watch(showGridProvider);
    final gridSize = ref.watch(gridSizeProvider);
    final gestureSettings = ref.watch(gestureSettingsProvider);
    final isSfxEnabled = ref.watch(sfxSettingsProvider);
    final storageStatsAsync = ref.watch(storageStatsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? IOSColors.darkGroupedBackground
        : IOSColors.lightGroupedBackground;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? IOSColors.frostedDark : IOSColors.frostedLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            HapticFeedback.lightImpact();
            SoundEffectService.instance.playPop();
            Navigator.of(context).maybePop();
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.chevron_back, size: 22, color: IOSColors.brandPrimary),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // ── SECTION 1: APPEARANCE ──
          CupertinoListSection.insetGrouped(
            header: const Text('Appearance'),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              CupertinoListTile.notched(
                leading: _buildIconBadge(
                  CupertinoIcons.moon_fill,
                  IOSColors.systemPurple,
                ),
                title: const Text('Theme'),
                additionalInfo: Text(_themeModeLabel(themeMode)),
                trailing: const CupertinoListTileChevron(),
                onTap: () => _showThemePicker(context, ref, themeMode),
              ),
            ],
          ),

          // ── SECTION 2: CANVAS & DRAWING ──
          CupertinoListSection.insetGrouped(
            header: const Text('Canvas'),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              CupertinoListTile.notched(
                leading: _buildIconBadge(
                  CupertinoIcons.crop,
                  IOSColors.systemBlue,
                ),
                title: const Text('Default Canvas Size'),
                additionalInfo: Text(canvasPreset.name),
                trailing: const CupertinoListTileChevron(),
                onTap: () => _showCanvasSizePicker(context, ref, canvasPreset),
              ),
              CupertinoListTile.notched(
                leading: _buildIconBadge(
                  CupertinoIcons.square_grid_2x2,
                  IOSColors.systemTeal,
                ),
                title: const Text('Show Grid'),
                additionalInfo: Text(showGrid ? 'On (${gridSize.toInt()}px grid)' : 'Off'),
                trailing: const CupertinoListTileChevron(),
                onTap: () => _showGridSettings(context, ref, showGrid, gridSize),
              ),
              CupertinoListTile.notched(
                leading: _buildIconBadge(
                  CupertinoIcons.hand_draw,
                  IOSColors.systemOrange,
                ),
                title: const Text('Gestures'),
                additionalInfo: const Text('Configure'),
                trailing: const CupertinoListTileChevron(),
                onTap: () => _showGestureSettings(context, ref, gestureSettings),
              ),
            ],
          ),

          // ── SECTION 3: AUDIO & HAPTICS ──
          CupertinoListSection.insetGrouped(
            header: const Text('Audio & Haptics'),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile.adaptive(
                  secondary: _buildIconBadge(
                    CupertinoIcons.speaker_2_fill,
                    IOSColors.systemPink,
                  ),
                  title: const Text('Sound Effects (SFX) & ASMR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Pencil, brush, & ASMR sounds', style: TextStyle(fontSize: 13)),
                  value: isSfxEnabled,
                  activeTrackColor: IOSColors.systemGreen,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  onChanged: (val) async {
                    HapticFeedback.selectionClick();
                    await ref.read(sfxSettingsProvider.notifier).setEnabled(val);
                  },
                ),
              ),
            ],
          ),

          // ── SECTION 4: STORAGE & CACHE ──
          CupertinoListSection.insetGrouped(
            header: const Text('Storage'),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              storageStatsAsync.when(
                loading: () => CupertinoListTile.notched(
                  leading: _buildIconBadge(
                    CupertinoIcons.folder_fill,
                    IOSColors.systemIndigo,
                  ),
                  title: const Text('Project Storage'),
                  additionalInfo: const Text('Calculating...'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _navigateToProjects(context),
                ),
                error: (_, __) => CupertinoListTile.notched(
                  leading: _buildIconBadge(
                    CupertinoIcons.folder_fill,
                    IOSColors.systemIndigo,
                  ),
                  title: const Text('Project Storage'),
                  additionalInfo: const Text('Manage'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _navigateToProjects(context),
                ),
                data: (stats) => CupertinoListTile.notched(
                  leading: _buildIconBadge(
                    CupertinoIcons.folder_fill,
                    IOSColors.systemIndigo,
                  ),
                  title: const Text('Project Storage'),
                  additionalInfo: Text(
                    '${stats.projectCount} artworks · ${ProjectStorageService.formatBytes(stats.projectsBytes)}',
                  ),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _navigateToProjects(context),
                ),
              ),
              storageStatsAsync.when(
                loading: () => CupertinoListTile.notched(
                  leading: _buildIconBadge(
                    CupertinoIcons.trash_fill,
                    IOSColors.systemRed,
                  ),
                  title: const Text('Clear Cache'),
                  additionalInfo: const Text('Calculating...'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _showClearCacheDialog(context, ref, 0),
                ),
                error: (_, __) => CupertinoListTile.notched(
                  leading: _buildIconBadge(
                    CupertinoIcons.trash_fill,
                    IOSColors.systemRed,
                  ),
                  title: const Text('Clear Cache'),
                  additionalInfo: const Text('Free Space'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _showClearCacheDialog(context, ref, 0),
                ),
                data: (stats) => CupertinoListTile.notched(
                  leading: _buildIconBadge(
                    CupertinoIcons.trash_fill,
                    IOSColors.systemRed,
                  ),
                  title: const Text('Clear Cache'),
                  additionalInfo: Text(
                    ProjectStorageService.formatBytes(stats.cacheBytes),
                  ),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _showClearCacheDialog(context, ref, stats.cacheBytes),
                ),
              ),
            ],
          ),

          // ── SECTION 5: ABOUT & LEGAL ──
          CupertinoListSection.insetGrouped(
            header: const Text('About & Legal'),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              CupertinoListTile.notched(
                leading: _buildIconBadge(
                  CupertinoIcons.app_badge_fill,
                  IOSColors.brandPrimary,
                ),
                title: const Text('Draw Color Art Pro'),
                additionalInfo: const Text(AppVersion.fullVersion),
                trailing: const CupertinoListTileChevron(),
                onTap: () => _showAboutAppDialog(context),
              ),
              CupertinoListTile.notched(
                leading: _buildIconBadge(
                  CupertinoIcons.shield_lefthalf_fill,
                  IOSColors.systemTeal,
                ),
                title: const Text('Privacy Policy'),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  SoundEffectService.instance.playPop();
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
              CupertinoListTile.notched(
                leading: _buildIconBadge(
                  CupertinoIcons.doc_text_fill,
                  IOSColors.systemGray,
                ),
                title: const Text('Terms of Service'),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  SoundEffectService.instance.playPop();
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const TermsOfServiceScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'Draw Color Art Pro · Built with ❤️ for Artists',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? IOSColors.systemGray : IOSColors.systemGray2,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildIconBadge(IconData icon, Color color) {
    return Container(
      width: 29,
      height: 29,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 17,
          color: Colors.white,
        ),
      ),
    );
  }

  void _navigateToProjects(BuildContext context) {
    HapticFeedback.lightImpact();
    SoundEffectService.instance.playPop();
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const ProjectManagerScreen()),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    HapticFeedback.selectionClick();
    SoundEffectService.instance.playPop();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Appearance'),
        message: const Text('Choose your preferred color theme'),
        actions: [
          for (final mode in ThemeMode.values)
            CupertinoActionSheetAction(
              onPressed: () {
                HapticFeedback.selectionClick();
                SoundEffectService.instance.playPop();
                ref.read(themeModeProvider.notifier).setThemeMode(mode);
                Navigator.pop(ctx);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_themeModeLabel(mode)),
                  if (mode == current) ...[
                    const SizedBox(width: 8),
                    const Icon(CupertinoIcons.checkmark, size: 18),
                  ],
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showCanvasSizePicker(
    BuildContext context,
    WidgetRef ref,
    CanvasSizePreset currentPreset,
  ) {
    HapticFeedback.selectionClick();
    SoundEffectService.instance.playPop();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Default Canvas Size'),
        message: const Text('Applied when creating new blank artworks'),
        actions: [
          for (final preset in CanvasSizePreset.presets)
            CupertinoActionSheetAction(
              onPressed: () {
                HapticFeedback.selectionClick();
                SoundEffectService.instance.playPop();
                ref.read(defaultCanvasSizeProvider.notifier).setPreset(preset);
                Navigator.pop(ctx);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(preset.name),
                  if (preset.id == currentPreset.id) ...[
                    const SizedBox(width: 8),
                    const Icon(CupertinoIcons.checkmark, size: 18),
                  ],
                ],
              ),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showCustomSizeDialog(context, ref, currentPreset);
            },
            child: const Text('Custom Dimensions...'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showCustomSizeDialog(
    BuildContext context,
    WidgetRef ref,
    CanvasSizePreset currentPreset,
  ) {
    final widthController =
        TextEditingController(text: currentPreset.width.toString());
    final heightController =
        TextEditingController(text: currentPreset.height.toString());

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Custom Canvas Size'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoTextField(
                controller: widthController,
                placeholder: 'Width (px, e.g. 1920)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: heightController,
                placeholder: 'Height (px, e.g. 1080)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final w = int.tryParse(widthController.text);
              final h = int.tryParse(heightController.text);
              if (w != null && h != null && w > 0 && h > 0) {
                HapticFeedback.mediumImpact();
                SoundEffectService.instance.playPop();
                ref
                    .read(defaultCanvasSizeProvider.notifier)
                    .setCustom(w.clamp(256, 8192), h.clamp(256, 8192));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set Preset'),
          ),
        ],
      ),
    );
  }

  void _showGridSettings(
    BuildContext context,
    WidgetRef ref,
    bool showGrid,
    double gridSize,
  ) {
    HapticFeedback.lightImpact();
    SoundEffectService.instance.playPop();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, consumerRef, _) {
          final isGridOn = consumerRef.watch(showGridProvider);
          final currentSize = consumerRef.watch(gridSizeProvider);
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: BackdropFilter(
              filter: AppBlur.sheet,
              child: Container(
                color: isDark ? IOSColors.darkElevated : IOSColors.lightSurface,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Canvas Grid Settings',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          consumerRef.read(showGridProvider.notifier).setGrid(!isGridOn);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Overlay Grid on Canvas',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                              ),
                              CupertinoSwitch(
                                value: isGridOn,
                                activeTrackColor: IOSColors.systemGreen,
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  consumerRef.read(showGridProvider.notifier).setGrid(val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Grid Cell Size',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (final (label, sz) in [('20 px', 20.0), ('40 px', 40.0), ('64 px', 64.0), ('80 px', 80.0)])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CupertinoButton(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(48, 32),
                                color: (currentSize - sz).abs() < 2
                                    ? IOSColors.brandPrimary
                                    : (isDark ? Colors.white10 : Colors.black12),
                                borderRadius: BorderRadius.circular(8),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  consumerRef.read(gridSizeProvider.notifier).setGridSize(sz);
                                },
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: (currentSize - sz).abs() < 2
                                        ? Colors.white
                                        : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showGestureSettings(
    BuildContext context,
    WidgetRef ref,
    GestureSettings settings,
  ) {
    HapticFeedback.lightImpact();
    SoundEffectService.instance.playPop();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, consumerRef, _) {
          final s = consumerRef.watch(gestureSettingsProvider);
          final notifier = consumerRef.read(gestureSettingsProvider.notifier);
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: BackdropFilter(
              filter: AppBlur.sheet,
              child: Container(
                color: isDark ? IOSColors.darkElevated : IOSColors.lightSurface,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Touch Gestures',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Two-Finger Tap: Undo',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Three-Finger Tap: Redo',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildGestureRow('Two-Finger Canvas Rotation', s.allowCanvasRotation, () {
                        HapticFeedback.selectionClick();
                        notifier.toggleAllowRotation();
                      }),
                      const SizedBox(height: 4),
                      _buildGestureRow('Double-Tap Zoom Toggle', s.doubleTapZoomReset, () {
                        HapticFeedback.selectionClick();
                        notifier.toggleDoubleTapZoom();
                      }),
                      const SizedBox(height: 4),
                      _buildGestureRow('Stylus-Only Drawing Mode', s.stylusOnlyDrawing, () {
                        HapticFeedback.selectionClick();
                        notifier.toggleStylusOnly();
                      }),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGestureRow(String label, bool value, VoidCallback onToggle) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            CupertinoSwitch(
              value: value,
              activeTrackColor: IOSColors.systemGreen,
              onChanged: (_) => onToggle(),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, WidgetRef ref, int cacheBytes) {
    HapticFeedback.heavyImpact();
    SoundEffectService.instance.playPop();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Temporary Cache?'),
        content: Text(
          'This will safely free up ${ProjectStorageService.formatBytes(cacheBytes)} of temporary rendering cache.\n\n'
          'None of your saved projects or layers will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: IOSColors.systemRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              SoundEffectService.instance.playWhoosh();
              ref.read(storageStatsProvider.notifier).clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    SoundEffectService.instance.playPop();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Draw Color Art Pro'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppVersion.versionWithBuild,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Display: ${DisplayRefreshRateService.instance.currentFps.toStringAsFixed(0)} Hz (Ultra-Smooth Pro Mode)',
                style: const TextStyle(fontSize: 12, color: IOSColors.systemGreen, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'A complete, pro-grade digital art & coloring studio designed with Apple Human Interface elegance.',
              ),
              const SizedBox(height: 10),
              const Text('• 100% Free Creative Suite\n• Zero Tracking & Local-First Storage\n• Commercial & Personal License Included\n• Offline ASMR Sound Synthesizer\n• Ultra-High Refresh Rate Support (90/120/144Hz)'),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
