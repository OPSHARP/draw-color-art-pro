import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service that detects whether an ad-blocker (DNS, VPN, or hosts file based)
/// is intercepting AdMob / Google ad serving domains on the user's device.
///
/// Supports continuous background monitoring every 10 seconds and exposes
/// a reactive [isAdBlockerActiveNotifier] for immediate UI toast synchronization.
class AdBlockDetectorService {
  AdBlockDetectorService._();
  static final AdBlockDetectorService instance = AdBlockDetectorService._();

  bool _isAdBlockerActive = false;
  bool _hasChecked = false;
  DateTime? _lastPromptTime;
  Timer? _monitoringTimer;

  /// Reactive notifier that updates whenever the ad-blocker status changes.
  final ValueNotifier<bool> isAdBlockerActiveNotifier = ValueNotifier<bool>(false);

  /// Event trigger that fires every time a check confirms the ad blocker is active,
  /// used to trigger recurring toast reminders.
  final ValueNotifier<int> blockedTickNotifier = ValueNotifier<int>(0);

  /// Returns true if an active ad blocker was detected.
  bool get isAdBlockerActive => _isAdBlockerActive;

  /// Returns true if the initial check has completed.
  bool get hasChecked => _hasChecked;

  /// Ad serving hostnames frequently targeted by mobile ad blockers (AdGuard, NextDNS, Pi-hole, hosts).
  static const List<String> _adHosts = [
    'pagead2.googlesyndication.com',
    'googleads.g.doubleclick.net',
    'pubads.g.doubleclick.net',
    'adservice.google.com',
  ];

  /// Neutral domains used to verify general internet reachability.
  static const List<String> _neutralHosts = [
    'google.com',
    'dns.google',
    'cloudflare.com',
  ];

  /// Starts continuous background monitoring.
  /// Runs an immediate check, then repeats every [interval] (defaults to 10 seconds).
  void startContinuousMonitoring({Duration interval = const Duration(seconds: 10)}) {
    _monitoringTimer?.cancel();
    // Run initial check immediately
    unawaited(checkAdBlocker());

    // Repeat every interval (10 seconds)
    _monitoringTimer = Timer.periodic(interval, (_) async {
      await checkAdBlocker();
    });
  }

  /// Stops the background monitoring timer.
  void stopContinuousMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Forces an immediate network re-check.
  Future<bool> recheckNow() async {
    return await checkAdBlocker();
  }

  /// For automated unit and widget testing.
  @visibleForTesting
  void setAdBlockerStateForTesting(bool value) {
    _isAdBlockerActive = value;
    _hasChecked = true;
    isAdBlockerActiveNotifier.value = value;
    if (value) {
      blockedTickNotifier.value++;
    }
  }

  /// Probes network DNS resolution to identify ad-blocking software.
  /// Returns `true` if an ad blocker is detected, `false` otherwise.
  Future<bool> checkAdBlocker({Duration timeout = const Duration(seconds: 3)}) async {
    if (kIsWeb) {
      _updateStatus(false);
      return false;
    }

    try {
      // Step 1: Verify that device actually has general Internet connectivity
      final hasInternet = await _checkHostConnectivity(_neutralHosts, timeout);
      if (!hasInternet) {
        // Device is offline; do NOT flag as ad blocker!
        _updateStatus(false);
        return false;
      }

      // Step 2: Check resolution of AdMob ad delivery domains
      int blockedCount = 0;
      for (final adHost in _adHosts) {
        final isBlocked = await _isHostBlocked(adHost, timeout);
        if (isBlocked) {
          blockedCount++;
        }
      }

      // If at least 2 ad serving domains fail while general internet works, ad blocker is active!
      final detected = blockedCount >= 2;
      _updateStatus(detected);
      return detected;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AdBlockDetectorService check warning: $e');
      }
      _updateStatus(false);
      return false;
    }
  }

  void _updateStatus(bool detected) {
    _isAdBlockerActive = detected;
    _hasChecked = true;
    if (isAdBlockerActiveNotifier.value != detected) {
      isAdBlockerActiveNotifier.value = detected;
    }
    if (detected) {
      // Increment tick to notify listeners (e.g. 10s toast alert)
      blockedTickNotifier.value++;
    }
  }

  /// Checks if the notice should be presented to the user during this session.
  bool shouldShowNotice() {
    if (!_isAdBlockerActive) return false;
    if (_lastPromptTime == null) return true;
    return DateTime.now().difference(_lastPromptTime!) > const Duration(minutes: 30);
  }

  /// Marks that the notice was shown.
  void markNoticeShown() {
    _lastPromptTime = DateTime.now();
  }

  /// Resets state (e.g. for re-checking or test fixtures).
  void reset() {
    _isAdBlockerActive = false;
    _hasChecked = false;
    _lastPromptTime = null;
    isAdBlockerActiveNotifier.value = false;
  }

  Future<bool> _checkHostConnectivity(List<String> hosts, Duration timeout) async {
    for (final host in hosts) {
      try {
        final addresses = await InternetAddress.lookup(host).timeout(timeout);
        if (addresses.isNotEmpty && addresses.any((a) => !a.isLoopback && a.address != '0.0.0.0')) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  Future<bool> _isHostBlocked(String host, Duration timeout) async {
    try {
      final addresses = await InternetAddress.lookup(host).timeout(timeout);
      if (addresses.isEmpty) return true;

      // Ad blockers commonly sinkhole ad domains to 0.0.0.0, 127.0.0.1, or ::1
      for (final addr in addresses) {
        if (addr.isLoopback || addr.address == '0.0.0.0' || addr.address == '::' || addr.address == '::1') {
          return true;
        }
      }
      return false;
    } on SocketException {
      // DNS resolution failed or was actively refused by local DNS ad blocker
      return true;
    } on TimeoutException {
      // Packet dropped by firewall / ad blocker
      return true;
    } catch (_) {
      return true;
    }
  }
}
