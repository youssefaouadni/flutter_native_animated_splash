
import 'package:native_animated_splash/native_animated_splash.dart';
import 'dart:io';
import 'package:yaml/yaml.dart';


void main(List<String> arguments) {
  // Check if the command is correct
/*  if (arguments.isEmpty || arguments[0] != 'create') {
    print('Usage: dart run flutter_animated_splash:create');
    return;
  }*/

  // Path to the current project's pubspec.yaml
  final pubspecPath = 'pubspec.yaml';

  // Check if the file exists
  final pubspecFile = File(pubspecPath);
  if (!pubspecFile.existsSync()) {
    print("❌ Could not find pubspec.yaml in the current project.");
    return;
  }

  // Read and parse the pubspec.yaml
  final yaml = loadYaml(pubspecFile.readAsStringSync());

  // Get splash config from pubspec.yaml
  final splashConfig = yaml['flutter_animated_splash'];

  if (splashConfig == null) {
    print("❌ Splash config not found in pubspec.yaml");
    return;
  }


  // Parse the splash config
  final config = SplashConfig(
    color: splashConfig['color'] ?? '#FFFFFF',  // Default color
    image: splashConfig['image'],
    androidAnimation: splashConfig['animation']?['android'],
    iosAnimation: splashConfig['animation']?['ios'],
    splashIconBackgroundColor: splashConfig['splash_icon_background'] ??'#FFFFFF',
    brandingImage: splashConfig['branding_image']
  );

  // Generate splash screens for Android and iOS based on config
  print("📦 Generating splash screen...");

  // Run Android splash generator
  AndroidSplashGenerator.generate(config);
  // Run iOS splash generator (if applicable)
  IOSSplashGenerator.generate(config);
  print('✅ Splash screen generation complete!');
}
