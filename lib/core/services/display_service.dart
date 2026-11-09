import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to detect and unlock maximum hardware display refresh rate (e.g. 90Hz, 120Hz ProMotion, 144Hz, 165Hz).
class DisplayRefreshRateService {
  DisplayRefreshRateService._();
  static final DisplayRefreshRateService instance = DisplayRefreshRateService._();

  static const MethodChannel _channel = MethodChannel('com.drawcolor.artpro/display');

  double _currentFps = 60.0;
  List<double> _supportedRates = const [60.0];
  bool _initialized = false;

  double get currentFps => _currentFps;
  List<double> get supportedRates => _supportedRates;
  bool get isHighRefreshRateActive => _currentFps > 60.0;

  /// Automatically requests and sets the device's highest supported refresh rate.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _currentFps = 60.0;
      return;
    }

    if (Platform.isAndroid) {
      try {
        final double maxRate = await _channel.invokeMethod<double>('setHighestRefreshRate') ?? 60.0;
        _currentFps = maxRate;

        final List<dynamic>? rates = await _channel.invokeMethod<List<dynamic>>('getSupportedRefreshRates');
        if (rates != null && rates.isNotEmpty) {
          _supportedRates = rates.map((r) => (r as num).toDouble()).toList();
        }
        if (kDebugMode) {
          debugPrint('DrawColorArtPro: High refresh rate mode set to ${_currentFps.toStringAsFixed(0)} Hz');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('DrawColorArtPro: DisplayRefreshRateService init warning: $e');
        }
      }
    } else if (Platform.isIOS) {
      // On iOS, CADisableMinimumFrameDurationOnPhone: true in Info.plist automatically enables 120Hz ProMotion.
      _currentFps = 120.0;
      _supportedRates = const [60.0, 120.0];
    }
  }

  /// Manually trigger highest refresh rate request
  Future<double> requestHighestRate() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final double maxRate = await _channel.invokeMethod<double>('setHighestRefreshRate') ?? 60.0;
        _currentFps = maxRate;
        return maxRate;
      } catch (_) {}
    }
    return _currentFps;
  }
}
