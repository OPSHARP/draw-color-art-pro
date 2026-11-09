import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../projects/services/project_storage_service.dart';

/// Canvas size preset model.
class CanvasSizePreset {
  final String id;
  final String name;
  final int width;
  final int height;

  const CanvasSizePreset({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
  });

  static const List<CanvasSizePreset> presets = [
    CanvasSizePreset(
      id: 'portrait_hd',
      name: 'Portrait HD (1080 × 1920)',
      width: 1080,
      height: 1920,
    ),
    CanvasSizePreset(
      id: 'landscape_hd',
      name: 'Landscape HD (1920 × 1080)',
      width: 1920,
      height: 1080,
    ),
    CanvasSizePreset(
      id: 'square',
      name: 'Square 1:1 (2048 × 2048)',
      width: 2048,
      height: 2048,
    ),
    CanvasSizePreset(
      id: 'qhd_2k',
      name: '2K QHD (1440 × 2560)',
      width: 1440,
      height: 2560,
    ),
    CanvasSizePreset(
      id: 'uhd_4k',
      name: '4K UHD (2160 × 3840)',
      width: 2160,
      height: 3840,
    ),
    CanvasSizePreset(
      id: 'a4_print',
      name: 'A4 Print (2480 × 3508)',
      width: 2480,
      height: 3508,
    ),
  ];

  static const CanvasSizePreset defaultPreset = CanvasSizePreset(
    id: 'portrait_hd',
    name: 'Portrait HD (1080 × 1920)',
    width: 1080,
    height: 1920,
  );
}

/// Manages default canvas size preset with SharedPreferences persistence.
class DefaultCanvasSizeNotifier extends StateNotifier<CanvasSizePreset> {
  DefaultCanvasSizeNotifier() : super(CanvasSizePreset.defaultPreset) {
    _load();
  }

  static const String _keyWidth = 'pref_default_canvas_width';
  static const String _keyHeight = 'pref_default_canvas_height';
  static const String _keyName = 'pref_default_canvas_name';
  static const String _keyId = 'pref_default_canvas_id';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final width = prefs.getInt(_keyWidth);
      final height = prefs.getInt(_keyHeight);
      final name = prefs.getString(_keyName);
      final id = prefs.getString(_keyId);

      if (width != null && height != null && name != null && id != null) {
        state = CanvasSizePreset(id: id, name: name, width: width, height: height);
      }
    } catch (_) {}
  }

  Future<void> setPreset(CanvasSizePreset preset) async {
    state = preset;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyId, preset.id);
      await prefs.setString(_keyName, preset.name);
      await prefs.setInt(_keyWidth, preset.width);
      await prefs.setInt(_keyHeight, preset.height);
    } catch (_) {}
  }

  Future<void> setCustom(int width, int height) async {
    final preset = CanvasSizePreset(
      id: 'custom',
      name: 'Custom ($width × $height)',
      width: width,
      height: height,
    );
    await setPreset(preset);
  }
}

final defaultCanvasSizeProvider =
    StateNotifierProvider<DefaultCanvasSizeNotifier, CanvasSizePreset>((ref) {
  return DefaultCanvasSizeNotifier();
});

/// Manages canvas grid visibility toggle.
class ShowGridNotifier extends StateNotifier<bool> {
  ShowGridNotifier() : super(false) {
    _load();
  }

  static const String _key = 'pref_canvas_show_grid';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? false;
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, state);
    } catch (_) {}
  }

  Future<void> setGrid(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
  }
}

final showGridProvider = StateNotifierProvider<ShowGridNotifier, bool>((ref) {
  return ShowGridNotifier();
});

/// Manages grid step size in pixels (16, 32, 64, 128).
class GridSizeNotifier extends StateNotifier<double> {
  GridSizeNotifier() : super(32.0) {
    _load();
  }

  static const String _key = 'pref_canvas_grid_size';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getDouble(_key) ?? 32.0;
    } catch (_) {}
  }

  Future<void> setGridSize(double size) async {
    state = size;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_key, size);
    } catch (_) {}
  }
}

final gridSizeProvider = StateNotifierProvider<GridSizeNotifier, double>((ref) {
  return GridSizeNotifier();
});

/// Touch gestures configuration model.
class GestureSettings {
  final bool twoFingerTapUndo;
  final bool threeFingerTapRedo;
  final bool allowCanvasRotation;
  final bool doubleTapZoomReset;
  final bool stylusOnlyDrawing;

  const GestureSettings({
    this.twoFingerTapUndo = true,
    this.threeFingerTapRedo = true,
    this.allowCanvasRotation = true,
    this.doubleTapZoomReset = true,
    this.stylusOnlyDrawing = false,
  });

  GestureSettings copyWith({
    bool? twoFingerTapUndo,
    bool? threeFingerTapRedo,
    bool? allowCanvasRotation,
    bool? doubleTapZoomReset,
    bool? stylusOnlyDrawing,
  }) {
    return GestureSettings(
      twoFingerTapUndo: twoFingerTapUndo ?? this.twoFingerTapUndo,
      threeFingerTapRedo: threeFingerTapRedo ?? this.threeFingerTapRedo,
      allowCanvasRotation: allowCanvasRotation ?? this.allowCanvasRotation,
      doubleTapZoomReset: doubleTapZoomReset ?? this.doubleTapZoomReset,
      stylusOnlyDrawing: stylusOnlyDrawing ?? this.stylusOnlyDrawing,
    );
  }
}

/// Manages gestures settings with SharedPreferences persistence.
class GestureSettingsNotifier extends StateNotifier<GestureSettings> {
  GestureSettingsNotifier() : super(const GestureSettings()) {
    _load();
  }

  static const String _keyTwoUndo = 'pref_gesture_two_tap_undo';
  static const String _keyThreeRedo = 'pref_gesture_three_tap_redo';
  static const String _keyRotation = 'pref_gesture_allow_rotation';
  static const String _keyDoubleZoom = 'pref_gesture_double_tap_zoom';
  static const String _keyStylusOnly = 'pref_gesture_stylus_only';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = GestureSettings(
        twoFingerTapUndo: prefs.getBool(_keyTwoUndo) ?? true,
        threeFingerTapRedo: prefs.getBool(_keyThreeRedo) ?? true,
        allowCanvasRotation: prefs.getBool(_keyRotation) ?? true,
        doubleTapZoomReset: prefs.getBool(_keyDoubleZoom) ?? true,
        stylusOnlyDrawing: prefs.getBool(_keyStylusOnly) ?? false,
      );
    } catch (_) {}
  }

  Future<void> updateSettings(GestureSettings settings) async {
    state = settings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyTwoUndo, settings.twoFingerTapUndo);
      await prefs.setBool(_keyThreeRedo, settings.threeFingerTapRedo);
      await prefs.setBool(_keyRotation, settings.allowCanvasRotation);
      await prefs.setBool(_keyDoubleZoom, settings.doubleTapZoomReset);
      await prefs.setBool(_keyStylusOnly, settings.stylusOnlyDrawing);
    } catch (_) {}
  }

  Future<void> toggleTwoFingerUndo() =>
      updateSettings(state.copyWith(twoFingerTapUndo: !state.twoFingerTapUndo));

  Future<void> toggleThreeFingerRedo() =>
      updateSettings(state.copyWith(threeFingerTapRedo: !state.threeFingerTapRedo));

  Future<void> toggleAllowRotation() =>
      updateSettings(state.copyWith(allowCanvasRotation: !state.allowCanvasRotation));

  Future<void> toggleDoubleTapZoom() =>
      updateSettings(state.copyWith(doubleTapZoomReset: !state.doubleTapZoomReset));

  Future<void> toggleStylusOnly() =>
      updateSettings(state.copyWith(stylusOnlyDrawing: !state.stylusOnlyDrawing));
}

final gestureSettingsProvider =
    StateNotifierProvider<GestureSettingsNotifier, GestureSettings>((ref) {
  return GestureSettingsNotifier();
});

/// Sound effects reactive notifier linked with SoundEffectService.
class SfxSettingsNotifier extends StateNotifier<bool> {
  SfxSettingsNotifier() : super(SoundEffectService.instance.isSfxEnabled);

  Future<void> toggle() async {
    final next = !state;
    state = next;
    await SoundEffectService.instance.setSfxEnabled(next);
    if (next) {
      SoundEffectService.instance.playPop();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await SoundEffectService.instance.setSfxEnabled(enabled);
    if (enabled) {
      SoundEffectService.instance.playPop();
    }
  }
}

final sfxSettingsProvider =
    StateNotifierProvider<SfxSettingsNotifier, bool>((ref) {
  return SfxSettingsNotifier();
});

/// Storage stats data model.
class StorageStats {
  final int projectsBytes;
  final int cacheBytes;
  final int projectCount;

  const StorageStats({
    required this.projectsBytes,
    required this.cacheBytes,
    required this.projectCount,
  });
}

/// Notifier providing live storage and cache metrics.
class StorageStatsNotifier extends StateNotifier<AsyncValue<StorageStats>> {
  StorageStatsNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final projects = await ProjectStorageService.instance.listProjects();
      final projectsBytes = await ProjectStorageService.instance.getProjectsStorageBytes();
      final cacheBytes = await ProjectStorageService.instance.getCacheBytes();
      state = AsyncValue.data(
        StorageStats(
          projectsBytes: projectsBytes,
          cacheBytes: cacheBytes,
          projectCount: projects.length,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<int> clearCache() async {
    final freed = await ProjectStorageService.instance.clearCache();
    await refresh();
    return freed;
  }
}

final storageStatsProvider =
    StateNotifierProvider<StorageStatsNotifier, AsyncValue<StorageStats>>((ref) {
  return StorageStatsNotifier();
});
