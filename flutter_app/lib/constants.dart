import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'OpenClaw';
  static const String version = '2.0.0';
  static const String packageName = 'com.nxg.openclawproot';
  static final ansiEscape = RegExp(r'\x1b\[[0-9;]*[a-zA-Z]');
  static const String authorName = 'Mithun Gowda B';
  static const String authorEmail = 'mithungowda.b7411@gmail.com';
  static const String githubUrl = 'https://github.com/mithun50/openclaw-termux';
  static const String license = 'MIT';
  static const String githubApiLatestRelease =
      'https://api.github.com/repos/mithun50/openclaw-termux/releases/latest';
  static const String orgName = 'NextGenX';
  static const String orgEmail = 'nxgextra@gmail.com';
  static const String instagramUrl = 'https://www.instagram.com/nexgenxplorer_nxg';
  static const String youtubeUrl = 'https://youtube.com/@nexgenxplorer?si=UG-wBC8UIyeT4bbw';
  static const String playStoreUrl = 'https://play.google.com/store/apps/dev?id=8262374975871504599';
  static const String gatewayHost = '127.0.0.1';
  static const int gatewayPort = 18789;
  static const String gatewayUrl = 'http://$gatewayHost:$gatewayPort';
  static const String ubuntuRootfsUrl =
      'https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.3-base-';
  static const String rootfsArm64 = '${ubuntuRootfsUrl}arm64.tar.gz';
  static const String rootfsArmhf = '${ubuntuRootfsUrl}armhf.tar.gz';
  static const String rootfsAmd64 = '${ubuntuRootfsUrl}amd64.tar.gz';
  static const String nodeVersion = '22.14.0';
  static const String nodeBaseUrl =
      'https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-linux-';
  static String getNodeTarballUrl(String arch) {
    switch (arch) {
      case 'aarch64':
        return '${nodeBaseUrl}arm64.tar.xz';
      case 'armv7l':
        return '${nodeBaseUrl}armv7l.tar.xz';
      case 'x86_64':
        return '${nodeBaseUrl}x64.tar.xz';
      default:
        return '${nodeBaseUrl}arm64.tar.xz';
    }
  }
  static String getRootfsUrl(String arch) {
    switch (arch) {
      case 'aarch64':
        return rootfsArm64;
      case 'armv7l':
        return rootfsArmhf;
      case 'x86_64':
        return rootfsAmd64;
      default:
        return rootfsArm64;
    }
  }
  static const String channelName = 'com.nxg.openclawproot/channel';
  static const String eventChannelName = 'com.nxg.openclawproot/events';
  static const String logStreamName = 'com.nxg.openclawproot/logs';
  // ENHANCEMENT: Theme options
  static const List<Color> accentColors = [
    Color(0xFFDC2626), // Red (default)
    Color(0xFF2563EB), // Blue
    Color(0xFF16A34A), // Green
    Color(0xFF9333EA), // Purple
    Color(0xFFEA580C), // Orange
    Color(0xFF0891B2), // Cyan
    Color(0xFFDB2777), // Pink
    Color(0xFFEAB308), // Yellow
  ];
  static const List<String> accentColorNames = [
    'Crimson', 'Ocean', 'Forest', 'Royal', 'Sunset', 'Aqua', 'Rose', 'Gold'
  ];
  // ENHANCEMENT: Terminal font sizes
  static const double terminalFontSizeMin = 8.0;
  static const double terminalFontSizeMax = 24.0;
  static const double terminalFontSizeDefault = 14.0;
  // ENHANCEMENT: Performance monitor intervals
  static const Duration performanceUpdateInterval = Duration(seconds: 2);
  static const Duration gatewayHealthCheckInterval = Duration(seconds: 5);
  static const int healthCheckIntervalMs = 5000;
  // Node/WS constants
  static const String nodeRole = 'node-host';
  static const int pairingTimeoutMs = 30000;
  static const int wsReconnectBaseMs = 1000;
  static const num wsReconnectMultiplier = 2;
  static const int wsReconnectCapMs = 60000;
}