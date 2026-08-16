import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'provider_config_service.dart';

class BackupService {
  static Future<Map<String, dynamic>> exportConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final providerConfig = await ProviderConfigService.readConfig();
    final backup = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'preferences': {
        'theme_mode': prefs.getInt('theme_mode'),
        'accent_color_index': prefs.getInt('accent_color_index'),
        'terminal_font_size': prefs.getDouble('terminal_font_size'),
        'use_amoled_black': prefs.getBool('use_amoled_black'),
        'auto_start_gateway': prefs.getBool('auto_start_gateway'),
        'node_enabled': prefs.getBool('node_enabled'),
        'node_gateway_host': prefs.getString('node_gateway_host'),
        'node_gateway_port': prefs.getInt('node_gateway_port'),
        'node_gateway_token': prefs.getString('node_gateway_token'),
        'biometric_enabled': prefs.getBool('biometric_enabled'),
        'clipboard_sync': prefs.getBool('clipboard_sync'),
        'notif_gateway_status': prefs.getBool('notif_gateway_status'),
        'notif_errors': prefs.getBool('notif_errors'),
        'notif_node': prefs.getBool('notif_node'),
      },
      'provider_config': providerConfig,
    };
    return backup;
  }

  static Future<XFile> exportToFile() async {
    final backup = await exportConfiguration();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/openclaw_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    return XFile(file.path);
  }

  static Future<void> shareBackup() async {
    final file = await exportToFile();
    await Share.shareXFiles([file], text: 'OpenClaw Configuration Backup');
  }

  static Future<bool> importConfiguration(String jsonStr) async {
    try {
      final backup = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (backup['version'] == null) return false;
      final prefs = await SharedPreferences.getInstance();
      final preferences = backup['preferences'] as Map<String, dynamic>?;
      if (preferences != null) {
        for (final entry in preferences.entries) {
          if (entry.value == null) continue;
          if (entry.value is int) {
            await prefs.setInt(entry.key, entry.value as int);
          } else if (entry.value is double) {
            await prefs.setDouble(entry.key, entry.value as double);
          } else if (entry.value is bool) {
            await prefs.setBool(entry.key, entry.value as bool);
          } else if (entry.value is String) {
            await prefs.setString(entry.key, entry.value as String);
          }
        }
      }
      final providerConfig = backup['provider_config'] as Map<String, dynamic>?;
      if (providerConfig != null) {
        await ProviderConfigService.writeConfig(providerConfig);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> importFromFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) return false;
    final content = await file.readAsString();
    return importConfiguration(content);
  }
}