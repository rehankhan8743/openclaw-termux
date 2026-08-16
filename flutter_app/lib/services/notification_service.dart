import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _gatewayStatusNotifications = true;
  static bool _errorNotifications = true;
  static bool _nodeNotifications = true;

  static Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
    final prefs = await SharedPreferences.getInstance();
    _gatewayStatusNotifications = prefs.getBool('notif_gateway_status') ?? true;
    _errorNotifications = prefs.getBool('notif_errors') ?? true;
    _nodeNotifications = prefs.getBool('notif_node') ?? true;
    _initialized = true;
  }

  static Future<void> setGatewayStatusNotifications(bool value) async {
    _gatewayStatusNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_gateway_status', value);
  }

  static Future<void> setErrorNotifications(bool value) async {
    _errorNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_errors', value);
  }

  static Future<void> setNodeNotifications(bool value) async {
    _nodeNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_node', value);
  }

  static bool get gatewayStatusNotifications => _gatewayStatusNotifications;
  static bool get errorNotifications => _errorNotifications;
  static bool get nodeNotifications => _nodeNotifications;

  static Future<void> showGatewayStarted(String url) async {
    if (!_gatewayStatusNotifications) return;
    await _notifications.show(
      1,
      'OpenClaw Gateway Running',
      'Dashboard: $url',
      _buildNotificationDetails(
        channelId: 'gateway_status',
        channelName: 'Gateway Status',
        importance: Importance.low,
        ongoing: true,
        actions: [
          const AndroidNotificationAction('stop', 'Stop', showsUserInterface: true),
        ],
      ),
    );
  }

  static Future<void> showGatewayStopped() async {
    if (!_gatewayStatusNotifications) return;
    await _notifications.show(
      1,
      'OpenClaw Gateway Stopped',
      'The AI gateway has been stopped',
      _buildNotificationDetails(
        channelId: 'gateway_status',
        channelName: 'Gateway Status',
        importance: Importance.low,
      ),
    );
  }

  static Future<void> showGatewayError(String error) async {
    if (!_errorNotifications) return;
    await _notifications.show(
      2,
      'OpenClaw Gateway Error',
      error,
      _buildNotificationDetails(
        channelId: 'gateway_errors',
        channelName: 'Gateway Errors',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
  }

  static Future<void> showNodePaired(String deviceId) async {
    if (!_nodeNotifications) return;
    await _notifications.show(
      3,
      'Node Paired Successfully',
      'Device: ${deviceId.substring(0, 12)}...',
      _buildNotificationDetails(
        channelId: 'node_events',
        channelName: 'Node Events',
        importance: Importance.defaultImportance,
      ),
    );
  }

  static Future<void> showNodeDisconnected() async {
    if (!_nodeNotifications) return;
    await _notifications.show(
      3,
      'Node Disconnected',
      'Connection to gateway lost',
      _buildNotificationDetails(
        channelId: 'node_events',
        channelName: 'Node Events',
        importance: Importance.defaultImportance,
      ),
    );
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  static NotificationDetails _buildNotificationDetails({
    required String channelId,
    required String channelName,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
    bool ongoing = false,
    List<AndroidNotificationAction>? actions,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'OpenClaw $channelName notifications',
        importance: importance,
        priority: priority,
        ongoing: ongoing,
        autoCancel: !ongoing,
        actions: actions,
        styleInformation: const BigTextStyleInformation(''),
      ),
    );
  }
}