import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class ClipboardSyncService {
  static const _channel = MethodChannel(AppConstants.channelName);
  static Timer? _timer;
  static String? _lastClipboard;

  static Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('clipboard_sync') ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('clipboard_sync', value);
    if (value) {
      start();
    } else {
      stop();
    }
  }

  static void start() {
    stop();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _sync());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _sync() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text != null && text != _lastClipboard && text.isNotEmpty) {
        _lastClipboard = text;
        // Sync to proot via native bridge
        await _channel.invokeMethod('syncClipboardToProot', {'text': text});
      }
      // Sync from proot to Android
      try {
        final prootText = await _channel.invokeMethod<String>('getClipboardFromProot');
        if (prootText != null && prootText != _lastClipboard && prootText.isNotEmpty) {
          _lastClipboard = prootText;
          await Clipboard.setData(ClipboardData(text: prootText));
        }
      } catch (_) {}
    } catch (_) {}
  }
}