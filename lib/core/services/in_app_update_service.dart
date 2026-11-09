import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import '../audio/sound_effect_service.dart';

/// Service managing Google Play In-App Flexible Updates.
/// Allows users to download updates quietly in the background while using the app,
/// and restart once download finishes.
class InAppUpdateService {
  InAppUpdateService._();
  static final InAppUpdateService instance = InAppUpdateService._();

  AppUpdateInfo? _updateInfo;
  bool _isChecking = false;
  bool _isUpdateAvailable = false;
  bool _isDownloading = false;

  AppUpdateInfo? get updateInfo => _updateInfo;
  bool get isChecking => _isChecking;
  bool get isUpdateAvailable => _isUpdateAvailable;
  bool get isDownloading => _isDownloading;

  /// Check Google Play Store for flexible in-app updates and start background download if available.
  Future<void> checkForFlexibleUpdate(BuildContext context) async {
    // In-app updates are exclusive to Android Google Play installations
    if (kIsWeb || !Platform.isAndroid) return;

    if (_isChecking || _isDownloading) return;

    _isChecking = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      _updateInfo = info;
      _isChecking = false;

      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.flexibleUpdateAllowed) {
        _isUpdateAvailable = true;
        _isDownloading = true;
        if (kDebugMode) {
          debugPrint('InAppUpdateService: Flexible update available (v${info.availableVersionCode}). Starting download...');
        }

        // Start flexible background download
        final result = await InAppUpdate.startFlexibleUpdate();
        _isDownloading = false;

        if (result == AppUpdateResult.success && context.mounted) {
          SoundEffectService.instance.playCelebration();
          _showUpdateDownloadedSnackBar(context);
        }
      }
    } catch (e) {
      _isChecking = false;
      _isDownloading = false;
      // In development/debug builds or devices without Play Store, this is expected
      if (kDebugMode) {
        debugPrint('InAppUpdateService check note: $e');
      }
    }
  }

  /// Displays a non-intrusive SnackBar allowing the user to complete installation when ready.
  void _showUpdateDownloadedSnackBar(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(days: 1), // Persists until user interacts
        backgroundColor: const Color(0xFF1E1E2E),
        content: const Row(
          children: [
            Icon(Icons.system_update_rounded, color: Color(0xFF00B894), size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'New version downloaded! Restart to complete update.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Restart Now',
          textColor: const Color(0xFFFFD166),
          onPressed: () {
            InAppUpdate.completeFlexibleUpdate().catchError((e) {
              if (kDebugMode) {
                debugPrint('InAppUpdateService completeFlexibleUpdate error: $e');
              }
            });
          },
        ),
      ),
    );
  }
}
