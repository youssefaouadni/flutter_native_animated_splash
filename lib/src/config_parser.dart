import 'dart:io';

import 'package:yaml/yaml.dart';

/// Represents the configuration for a splash screen.
///
/// This class holds the settings for splash screen appearance, including colors,
/// images, and optional animations for Android and iOS platforms.
class SplashConfig {
  /// The background color of the splash screen (e.g., '#FFFFFF').
  final String color;

  /// The path to the splash screen image.
  final String image;

  /// The path to the Android-specific animation file, if any.
  final String? androidAnimation;

  /// The path to the iOS-specific animation file, if any.
  final String? iosAnimation;

  /// The background color for the splash screen icon, if specified.
  final String? splashIconBackgroundColor;

  /// The path to the branding image, if specified.
  final String? brandingImage;

  /// Creates a [SplashConfig] with the specified settings.
  ///
  /// [color] The background color of the splash screen.
  /// [image] The path to the splash screen image.
  /// [androidAnimation] Optional path to the Android animation file.
  /// [iosAnimation] Optional path to the iOS animation file.
  /// [splashIconBackgroundColor] Optional background color for the splash icon.
  /// [brandingImage] Optional path to the branding image.
  SplashConfig({
    required this.color,
    required this.image,
    this.androidAnimation,
    this.iosAnimation,
    this.splashIconBackgroundColor,
    this.brandingImage,
  });
}

/// Parses a YAML file to create a [SplashConfig] instance.
///
/// This class provides a method to load splash screen configuration from a YAML file.
class SplashConfigParser {
  /// Loads and parses a YAML file to create a [SplashConfig].
  ///
  /// Reads the YAML file at [path] and extracts splash screen settings. Provides
  /// default values for missing fields (e.g., '#FFFFFF' for colors).
  ///
  /// [path] The file path to the YAML configuration file.
  /// Returns a [SplashConfig] instance with the parsed settings.
  /// Throws a [FileSystemException] if the file cannot be read.
  static SplashConfig loadFromFile(String path) {
    final file = File(path);
    final content = loadYaml(file.readAsStringSync()) as YamlMap;

    return SplashConfig(
      color: content['color'] ?? '#FFFFFF',
      splashIconBackgroundColor: content['splash_icon_background'] ?? '#FFFFFF',
      image: content['image'],
      androidAnimation: content['animation']?['android'],
      iosAnimation: content['animation']?['ios'],
      brandingImage: content['branding_image'],
    );
  }
}