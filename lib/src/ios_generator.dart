import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'config_parser.dart';

/// Generates iOS splash screen assets and configurations based on provided settings.
///
/// This class handles creating splash screen images, branding images, and storyboards
/// for iOS, placing them in the appropriate Assets.xcassets and Base.lproj directories.
class IOSSplashGenerator {
  /// Generates iOS splash screen assets and configurations.
  ///
  /// Creates LaunchBackground.imageset, LaunchImage.imageset, and optionally
  /// BrandingImage.imageset in Assets.xcassets, and generates LaunchScreen.storyboard
  /// in Base.lproj. Uses the provided [config] for colors, images, and branding.
  ///
  /// [config] The splash screen configuration containing image paths and color settings.
  static void generate(SplashConfig config) {
    final iosRunnerAssets = Directory(
      p.join(Directory.current.path, 'ios', 'Runner', 'Assets.xcassets'),
    );
    if (!iosRunnerAssets.existsSync()) {
      print('❌ Could not find ios/Runner/Assets.xcassets');
      return;
    }

    // 1. LaunchBackground.imageset
    final backgroundSet = Directory(p.join(iosRunnerAssets.path, 'LaunchBackground.imageset'));
    backgroundSet.createSync(recursive: true);

    final backgroundImage = img.Image(width: 1, height: 1);
    final bgColor = parseHexRgb(config.color);
    backgroundImage.setPixel(0, 0, bgColor);
    File(p.join(backgroundSet.path, 'background.png')).writeAsBytesSync(img.encodePng(backgroundImage));

    final bgJson = {
      "images": [
        {"filename": "background.png", "idiom": "universal", "scale": "1x"},
        {"idiom": "universal", "scale": "2x"},
        {"idiom": "universal", "scale": "3x"},
      ],
      "info": {"author": "xcode", "version": 1},
    };
    File(p.join(backgroundSet.path, 'Contents.json')).writeAsStringSync(JsonEncoder.withIndent('  ').convert(bgJson));
    print('✅ Created LaunchBackground.imageset');

    // 2. LaunchImage.imageset
    final launchImageSet = Directory(p.join(iosRunnerAssets.path, 'LaunchImage.imageset'));
    launchImageSet.createSync(recursive: true);

    final imageFile = File(config.image);
    if (!imageFile.existsSync()) {
      print('❌ Provided image does not exist: ${imageFile.path}');
      return;
    }

    final decoded = img.decodeImage(imageFile.readAsBytesSync());
    if (decoded == null) {
      print('❌ Failed to decode image: ${imageFile.path}');
      return;
    }

    final sizes = {
      '1x': img.copyResize(decoded, width: 128, height: 128),
      '2x': img.copyResize(decoded, width: 256, height: 256),
      '3x': img.copyResize(decoded, width: 384, height: 384),
    };

    final imageVariants = {
      '1x': 'LaunchImage.png',
      '2x': 'LaunchImage@2x.png',
      '3x': 'LaunchImage@3x.png',
    };

    for (final entry in imageVariants.entries) {
      final imgFile = File(p.join(launchImageSet.path, entry.value));
      imgFile.writeAsBytesSync(img.encodePng(sizes[entry.key]!));
    }

    final launchJson = {
      "images": imageVariants.entries.map((entry) => {
        "filename": entry.value,
        "idiom": "universal",
        "scale": entry.key,
      }).toList(),
      "info": {"author": "xcode", "version": 1},
    };
    File(p.join(launchImageSet.path, 'Contents.json')).writeAsStringSync(JsonEncoder.withIndent('  ').convert(launchJson));
    print('✅ Created LaunchImage.imageset');

    // 3. Optional BrandingImage.imageset
    final showBranding = config.brandingImage != null && config.brandingImage!.isNotEmpty;
    if (showBranding) {
      final brandingSet = Directory(p.join(iosRunnerAssets.path, 'BrandingImage.imageset'));
      brandingSet.createSync(recursive: true);

      final brandingFile = File(config.brandingImage!);
      if (!brandingFile.existsSync()) {
        print('⚠️ Branding image does not exist: ${brandingFile.path}');
      } else {
        final brandingImage = img.decodeImage(brandingFile.readAsBytesSync());
        if (brandingImage != null) {
          final brandingSizes = {
            '1x': img.copyResize(brandingImage, width: 128, height: 128),
            '2x': img.copyResize(brandingImage, width: 256, height: 256),
            '3x': img.copyResize(brandingImage, width: 384, height: 384),
          };

          final brandingVariants = {
            '1x': 'BrandingImage.png',
            '2x': 'BrandingImage@2x.png',
            '3x': 'BrandingImage@3x.png',
          };

          for (final entry in brandingVariants.entries) {
            final imgFile = File(p.join(brandingSet.path, entry.value));
            imgFile.writeAsBytesSync(img.encodePng(brandingSizes[entry.key]!));
          }

          final brandingJson = {
            "images": brandingVariants.entries.map((entry) => {
              "filename": entry.value,
              "idiom": "universal",
              "scale": entry.key,
            }).toList(),
            "info": {"author": "xcode", "version": 1},
          };
          File(p.join(brandingSet.path, 'Contents.json')).writeAsStringSync(JsonEncoder.withIndent('  ').convert(brandingJson));
          print('✅ Created BrandingImage.imageset');
        }
      }
    }

    // 4. LaunchScreen.storyboard
    final storyboardDir = Directory(p.join(Directory.current.path, 'ios', 'Runner', 'Base.lproj'));
    storyboardDir.createSync(recursive: true);

    final storyboardPath = p.join(storyboardDir.path, 'LaunchScreen.storyboard');
    final storyboardContent = generateStoryboardXml(config.color, showBranding);
    File(storyboardPath).writeAsStringSync(storyboardContent);
    print('✅ Created LaunchScreen.storyboard');
  }

  /// Generates the XML content for LaunchScreen.storyboard.
  ///
  /// Creates a storyboard with a background image, main image, and optional branding
  /// image, using the specified [hexColor] for the background and [showBranding] to
  /// determine if the branding image should be included.
  ///
  /// [hexColor] The hex color code for the background (e.g., '#FFFFFF').
  /// [showBranding] Whether to include the branding image in the storyboard.
  /// Returns the XML content as a string.
  static String generateStoryboardXml(String hexColor, bool showBranding) {
    final rgb = parseHexRgb(hexColor);
    final red = (rgb.r / 255).toStringAsFixed(3);
    final green = (rgb.g / 255).toStringAsFixed(3);
    final blue = (rgb.b / 255).toStringAsFixed(3);

    return '''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="12121" systemVersion="16G29" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <dependencies>
        <deployment identifier="iOS"/>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="12089"/>
    </dependencies>
    <scenes>
        <!--View Controller-->
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <layoutGuides>
                        <viewControllerLayoutGuide type="top" id="Ydg-fD-yQy"/>
                        <viewControllerLayoutGuide type="bottom" id="xbc-2k-c8Z"/>
                    </layoutGuides>
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <imageView contentMode="scaleToFill" image="LaunchBackground" translatesAutoresizingMaskIntoConstraints="NO" id="bgImg"/>
                            <imageView contentMode="center" image="LaunchImage" translatesAutoresizingMaskIntoConstraints="NO" id="mainImg"/>
                            ${showBranding ? '<imageView contentMode="scaleToFill" image="BrandingImage" translatesAutoresizingMaskIntoConstraints="NO" id="brandingImg-unique"/>' : ''}
                        </subviews>
                        <color key="backgroundColor" red="$red" green="$green" blue="$blue" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                        <constraints>
                            <!-- Background image: pinned to all edges -->
                            <constraint firstItem="bgImg" firstAttribute="top" secondItem="Ze5-6b-2t3" secondAttribute="top" id="xPn-NY-SIU"/>
                            <constraint firstItem="bgImg" firstAttribute="bottom" secondItem="Ze5-6b-2t3" secondAttribute="bottom" id="duK-uY-Gun"/>
                            <constraint firstItem="bgImg" firstAttribute="leading" secondItem="Ze5-6b-2t3" secondAttribute="leading" id="kV7-tw-vXt"/>
                            <constraint firstItem="bgImg" firstAttribute="trailing" secondItem="Ze5-6b-2t3" secondAttribute="trailing" id="TQA-XW-tRk"/>
                            <!-- Main image: centered horizontally and vertically -->
                            <constraint firstItem="mainImg" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="3kg-TC-cPP"/>
                            <constraint firstItem="mainImg" firstAttribute="centerY" secondItem="Ze5-6b-2t3" secondAttribute="centerY" id="main-centerY"/>
                            ${showBranding ? '''
                            <!-- Branding image: centered horizontally, pinned to bottom -->
                            <constraint firstItem="brandingImg-unique" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="branding-centerX"/>
                            <constraint firstItem="brandingImg-unique" firstAttribute="bottom" secondItem="Ze5-6b-2t3" secondAttribute="bottom" constant="20" id="branding-bottom"/>
                            ''' : ''}
                        </constraints>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="53" y="375"/>
        </scene>
    </scenes>
    <resources>
        <image name="LaunchImage" width="128" height="128"/>
        <image name="LaunchBackground" width="1" height="1"/>
        ${showBranding ? '<image name="BrandingImage" width="128" height="128"/>' : ''}
    </resources>
</document>
''';
  }

  /// Parses a hex color string into an RGB color object.
  ///
  /// Converts a hex color string (e.g., '#FFFFFF' or 'FFFFFF') into an [img.ColorRgb8].
  ///
  /// [hex] The hex color string (6 characters, RRGGBB format).
  /// Returns an [img.ColorRgb8] with the parsed RGB values.
  /// Throws an [ArgumentError] if the hex string is not 6 characters long.
  static img.ColorRgb8 parseHexRgb(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length != 6) throw ArgumentError('Hex color must be 6 characters (RRGGBB)');
    final r = int.parse(hex.substring(0, 2), radix: 16);
    final g = int.parse(hex.substring(2, 4), radix: 16);
    final b = int.parse(hex.substring(4, 6), radix: 16);
    return img.ColorRgb8(r, g, b);
  }
}