import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void main() {
  group('Google Play Console Photo Picker Compliance Tests', () {
    test('ImagePickerAndroid has useAndroidPhotoPicker enabled for ACTION_PICK_IMAGES', () {
      final androidPicker = ImagePickerAndroid();
      // Ensure default or configured state supports enabling Photo Picker contract
      androidPicker.useAndroidPhotoPicker = true;
      expect(androidPicker.useAndroidPhotoPicker, isTrue);

      ImagePickerPlatform.instance = androidPicker;
      final currentPlatform = ImagePickerPlatform.instance;
      expect(currentPlatform, isA<ImagePickerAndroid>());
      if (currentPlatform is ImagePickerAndroid) {
        currentPlatform.useAndroidPhotoPicker = true;
        expect(currentPlatform.useAndroidPhotoPicker, isTrue);
      }
    });

    test('AndroidManifest.xml strictly complies with Play Console Photo & Video permissions policy', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue, reason: 'AndroidManifest.xml must exist');

      final content = manifestFile.readAsStringSync();

      // 1. Must NOT contain deprecated requestLegacyExternalStorage
      expect(
        content.contains('requestLegacyExternalStorage'),
        isFalse,
        reason: 'android:requestLegacyExternalStorage must be removed for Play Console compliance',
      );

      // 2. Broad storage and media permissions must be explicitly removed with tools:node="remove"
      expect(
        content.contains('<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" tools:node="remove"/>'),
        isTrue,
        reason: 'READ_MEDIA_IMAGES must be stripped via tools:node="remove"',
      );
      expect(
        content.contains('<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" tools:node="remove"/>'),
        isTrue,
        reason: 'READ_MEDIA_VIDEO must be stripped via tools:node="remove"',
      );
      expect(
        content.contains('<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" tools:node="remove"/>'),
        isTrue,
        reason: 'READ_EXTERNAL_STORAGE must be stripped via tools:node="remove"',
      );
    });
  });
}
