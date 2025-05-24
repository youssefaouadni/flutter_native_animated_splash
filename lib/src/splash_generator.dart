// File: lib/src/splash_generator.dart
import 'package:args/args.dart';

import '../native_animated_splash.dart';

/// Orchestrates the generation of splash screens for Android and iOS platforms.
///
/// This class parses command-line arguments to load a splash screen configuration
/// from a YAML file and triggers the generation of platform-specific assets using
/// [AndroidSplashGenerator] and [IOSSplashGenerator].
class SplashGenerator {
  /// Runs the splash screen generation process based on command-line arguments.
  ///
  /// Parses the provided [args] for a configuration file path, loads the
  /// [SplashConfig] from the specified YAML file, and generates splash screen assets
  /// for Android and iOS. Prints status messages in debug mode.
  ///
  /// [args] The list of command-line arguments, expected to include a `--config` or `-c` option
  /// specifying the path to the YAML configuration file.
  static void run(List<String> args) {
    final parser =
        ArgParser()..addOption(
          'config',
          abbr: 'c',
          help: 'Path to the splash config YAML file',
        );

    final results = parser.parse(args);
    final configPath = results['config'];

    if (configPath == null) {
      print('Please provide a config file using --config or -c.');

      return;
    }

    final config = SplashConfigParser.loadFromFile(configPath);
    AndroidSplashGenerator.generate(config);
    IOSSplashGenerator.generate(config);

    print('✅ Splash screen generation complete!');
  }
}
