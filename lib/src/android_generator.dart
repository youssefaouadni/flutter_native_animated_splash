// ignore_for_file: avoid_print

import 'dart:io';

import 'package:native_animated_splash/native_animated_splash.dart';
import 'package:path/path.dart' as p;

/// Generates Android splash screen assets and configurations based on provided settings.
///
/// This class handles copying splash images, branding images, and animations to the
/// appropriate Android resource directories, and patches XML configuration files
/// (colors.xml, styles.xml, and AndroidManifest.xml) to apply the splash screen settings.
class AndroidSplashGenerator {
  /// Generates the Android splash screen assets and configurations.
  ///
  /// Copies the splash image, branding image (if provided), and animation file (if provided)
  /// to the Android resource directory, and updates the necessary XML files.
  ///
  /// [config] The splash screen configuration containing image paths and color settings.
  static void generate(SplashConfig config) {
    final androidMain = Directory(
      p.join(Directory.current.path, 'android', 'app', 'src', 'main'),
    );
    if (!androidMain.existsSync()) {
      print('❌ Could not find android/app/src/main');
      return;
    }

    final resDir = Directory(p.join(androidMain.path, 'res', 'drawable'));
    resDir.createSync(recursive: true);

    // 1. Copy splash image if available
    final splashImage = File(config.image);
    if (!splashImage.existsSync()) {
      print('❌ Splash image not found: ${config.image}');
      return;
    }
    splashImage.copySync(p.join(resDir.path, 'splash_image.png'));
    print('✅ Copied splash_image.png');

    // 2. Copy branding image if available
    if (config.brandingImage != null) {
      final brandingImage = File(config.brandingImage!);
      if (!brandingImage.existsSync()) {
        print('❌ Branding image not found: ${config.brandingImage}');
        return;
      }
      brandingImage.copySync(p.join(resDir.path, 'branding_image.png'));
      print('✅ Copied branding_image.png');
    }

    // 3. Copy animation file if provided
    if (config.androidAnimation != null) {
      final animFile = File(config.androidAnimation!);
      if (!animFile.existsSync()) {
        print('❌ Animation file not found: ${config.androidAnimation}');
        return;
      }
      animFile.copySync(p.join(resDir.path, 'splash_animation.xml'));
      print('✅ Copied splash_animation.xml');
    }

    // 4. Patch required XML files
    _patchColorsXml(androidMain, config);
    _patchStylesXml(androidMain, config);
    _patchManifest(androidMain, config);
  }

  /// Updates colors.xml files for both light and night themes with splash screen colors.
  ///
  /// Creates or modifies colors.xml in the 'values' and 'values-night' directories to
  /// include the splash screen background and icon background colors.
  ///
  /// [androidMain] The Android main directory (android/app/src/main).
  /// [config] The splash screen configuration with color settings.
  static void _patchColorsXml(Directory androidMain, SplashConfig config) {
    // Light theme (default)
    final lightFile = File(p.join(androidMain.path, 'res', 'values', 'colors.xml'));
    if (!lightFile.existsSync()) {
      lightFile.createSync(recursive: true);
      lightFile.writeAsStringSync('<resources>\n</resources>');
    }
    var lightContent = lightFile.readAsStringSync();
    lightContent = _replaceOrAddColor(lightContent, 'splash_color', config.color);
    lightContent = _replaceOrAddColor(lightContent, 'splash_icon_background', config.splashIconBackgroundColor!);
    lightFile.writeAsStringSync(lightContent);
    print('🎨 Patched light colors.xml');

    // Night theme
    final nightFile = File(p.join(androidMain.path, 'res', 'values-night', 'colors.xml'));
    if (!nightFile.existsSync()) {
      nightFile.createSync(recursive: true);
      nightFile.writeAsStringSync('<resources>\n</resources>');
    }
    var nightContent = nightFile.readAsStringSync();
    nightContent = _replaceOrAddColor(nightContent, 'splash_color', '#121212');
    nightContent = _replaceOrAddColor(nightContent, 'splash_icon_background', config.splashIconBackgroundColor!);
    nightFile.writeAsStringSync(nightContent);
    print('🌙 Patched night colors.xml');
  }

  /// Replaces or adds a color entry in the colors.xml content.
  ///
  /// If the color [name] exists, its value is updated; otherwise, a new color entry
  /// is added before the closing </resources> tag.
  ///
  /// [content] The current content of the colors.xml file.
  /// [name] The name of the color resource.
  /// [value] The color value (e.g., '#FFFFFF').
  /// Returns the updated content with the color entry.
  static String _replaceOrAddColor(String content, String name, String value) {
    final regex = RegExp('<color name="$name">.*?</color>');
    if (regex.hasMatch(content)) {
      return content.replaceAll(regex, '<color name="$name">$value</color>');
    } else {
      return content.replaceFirst(
        '</resources>',
        '  <color name="$name">$value</color>\n</resources>',
      );
    }
  }

  /// Updates styles.xml files for both light and night themes with splash screen styles.
  ///
  /// Creates or modifies styles.xml in the 'values' and 'values-night' directories to
  /// define the LaunchTheme with splash screen background, icon, and branding settings.
  ///
  /// [androidMain] The Android main directory (android/app/src/main).
  /// [config] The splash screen configuration with animation and branding settings.
  static void _patchStylesXml(Directory androidMain, SplashConfig config) {
    /// Writes the LaunchTheme style to the specified styles.xml file.
    void writeStyles(File file) {
      if (!file.existsSync()) {
        file.createSync(recursive: true);
        file.writeAsStringSync('<resources>\n</resources>');
      }

      final background = '@color/splash_color';
      final icon = config.androidAnimation != null
          ? '@drawable/splash_animation'
          : '@drawable/splash_image';
      final brandingIcon = config.brandingImage != null
          ? '@drawable/branding_image'
          : null;

      final splashTheme = '''
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowSplashScreenBackground">$background</item>
        <item name="android:windowSplashScreenAnimatedIcon">$icon</item>
        <item name="android:windowSplashScreenIconBackgroundColor">@color/splash_icon_background</item>
        ${brandingIcon != null ? '<item name="android:windowSplashScreenBrandingImage">$brandingIcon</item>' : ''}
    </style>
''';

      var content = file.readAsStringSync();

      // Remove any previous LaunchTheme and insert the updated one
      final launchThemeRegex = RegExp(
        r'<style name="LaunchTheme"[\s\S]*?</style>',
        multiLine: true,
      );
      content = content.replaceAll(launchThemeRegex, '');

      content = content.replaceFirst('</resources>', '$splashTheme\n</resources>');

      file.writeAsStringSync(content);
    }

    final lightStylesFile = File(p.join(androidMain.path, 'res', 'values', 'styles.xml'));
    writeStyles(lightStylesFile);

    final darkStylesFile = File(p.join(androidMain.path, 'res', 'values-night', 'styles.xml'));
    writeStyles(darkStylesFile);

    print('🖌️ Replaced LaunchTheme in styles.xml and styles-night.xml');
  }

  /// Updates AndroidManifest.xml to include splash screen metadata.
  ///
  /// Adds metadata tags for the splash screen icon, background, and branding image
  /// to the MainActivity in AndroidManifest.xml.
  ///
  /// [androidMain] The Android main directory (android/app/src/main).
  /// [config] The splash screen configuration with animation and branding settings.
  static void _patchManifest(Directory androidMain, SplashConfig config) {
    final file = File(p.join(androidMain.path, 'AndroidManifest.xml'));
    if (!file.existsSync()) {
      print('❌ AndroidManifest.xml not found.');
      return;
    }

    var content = file.readAsStringSync();
    final icon = config.androidAnimation != null
        ? 'splash_animation'
        : 'splash_image';

    var metaData = '''
        <meta-data
            android:name="android.windowSplashScreenAnimatedIcon"
            android:resource="@drawable/$icon" />
        <meta-data
            android:name="android.windowSplashScreenBackground"
            android:resource="@color/splash_color" />
        <meta-data
            android:name="android.windowSplashScreenIconBackground"
            android:resource="@color/splash_icon_background" />
''';

    if (config.brandingImage != null) {
      metaData += '''
        <meta-data
            android:name="android.windowSplashScreenBrandingImage"
            android:resource="@drawable/branding_image" />
      ''';
    }

    final activityRegex = RegExp(
      r'<activity[^>]*android:name="[^"]*MainActivity"[^>]*>',
      multiLine: true,
    );

    if (activityRegex.hasMatch(content)) {
      final match = activityRegex.firstMatch(content)!;
      final activityTag = match.group(0)!;

      if (!activityTag.contains('android.windowSplashScreenAnimatedIcon')) {
        final modified = activityTag + metaData;
        content = content.replaceFirst(activityTag, modified);
        file.writeAsStringSync(content);
        print('📝 Patched AndroidManifest.xml');
      } else {
        print('⚠️ Manifest already contains splash <meta-data>');
      }
    } else {
      print('❌ Could not find MainActivity tag in AndroidManifest.xml');
    }
  }
}