import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../constants.dart';

class PerformanceMetrics {
  final double cpuPercent;
  final int memoryUsedMB;
  final int memoryTotalMB;
  final int diskUsedMB;
  final int diskTotalMB;
  final int uptimeSeconds;
  final int processCount;
  final double loadAverage;

  PerformanceMetrics({
    required this.cpuPercent,
    required this.memoryUsedMB,
    required this.memoryTotalMB,
    required this.diskUsedMB,
    required this.diskTotalMB,
    required this.uptimeSeconds,
    required this.processCount,
    required this.loadAverage,
  });

  double get memoryPercent => memoryTotalMB > 0 ? (memoryUsedMB / memoryTotalMB) * 100 : 0;
  double get diskPercent => diskTotalMB > 0 ? (diskUsedMB / diskTotalMB) * 100 : 0;

  factory PerformanceMetrics.empty() => PerformanceMetrics(
        cpuPercent: 0,
        memoryUsedMB: 0,
        memoryTotalMB: 0,
        diskUsedMB: 0,
        diskTotalMB: 0,
        uptimeSeconds: 0,
        processCount: 0,
        loadAverage: 0,
      );
}

class PerformanceService {
  static const _channel = MethodChannel(AppConstants.channelName);

  static final PerformanceService _instance = PerformanceService._internal();

  factory PerformanceService() => _instance;

  PerformanceService._internal();

  Timer? _timer;
  final _controller = StreamController<PerformanceMetrics>.broadcast();
  PerformanceMetrics _latest = PerformanceMetrics.empty();

  Stream<PerformanceMetrics> get stream => _controller.stream;
  PerformanceMetrics get latest => _latest;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(AppConstants.performanceUpdateInterval, (_) => _fetch());
    _fetch();
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _fetch() async {
    try {
      // Try native first
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getPerformanceMetrics');
      if (result != null) {
        _latest = PerformanceMetrics(
          cpuPercent: (result['cpuPercent'] as num?)?.toDouble() ?? 0,
          memoryUsedMB: (result['memoryUsedMB'] as num?)?.toInt() ?? 0,
          memoryTotalMB: (result['memoryTotalMB'] as num?)?.toInt() ?? 0,
          diskUsedMB: (result['diskUsedMB'] as num?)?.toInt() ?? 0,
          diskTotalMB: (result['diskTotalMB'] as num?)?.toInt() ?? 0,
          uptimeSeconds: (result['uptimeSeconds'] as num?)?.toInt() ?? 0,
          processCount: (result['processCount'] as num?)?.toInt() ?? 0,
          loadAverage: (result['loadAverage'] as num?)?.toDouble() ?? 0,
        );
        _controller.add(_latest);
        return;
      }
    } catch (_) {}
    // Fallback: read from /proc and df inside proot
    try {
      final filesDir = await _channel.invokeMethod<String>('getFilesDir') ?? '';
      final rootfs = '$filesDir/rootfs/ubuntu';
      // Memory from /proc/meminfo
      final meminfo = File('$rootfs/proc/meminfo');
      int memTotal = 0, memAvailable = 0;
      if (meminfo.existsSync()) {
        for (final line in meminfo.readAsLinesSync()) {
          if (line.startsWith('MemTotal:')) {
            memTotal = int.tryParse(line.split(RegExp(r'\s+'))[1]) ?? 0;
          } else if (line.startsWith('MemAvailable:')) {
            memAvailable = int.tryParse(line.split(RegExp(r'\s+'))[1]) ?? 0;
          }
        }
      }
      final memUsed = memTotal - memAvailable;
      // Disk from df
      int diskUsed = 0, diskTotal = 0;
      try {
        final dfResult = await _channel.invokeMethod<String>('runInProot', {
          'command': 'df -m / | tail -1',
          'timeout': 5,
        });
        final parts = dfResult?.trim().split(RegExp(r'\s+')) ?? [];
        if (parts.length >= 4) {
          diskTotal = int.tryParse(parts[1]) ?? 0;
          diskUsed = int.tryParse(parts[2]) ?? 0;
        }
      } catch (_) {}
      // Uptime
      int uptime = 0;
      try {
        final uptimeStr = File('$rootfs/proc/uptime').readAsStringSync();
        uptime = double.tryParse(uptimeStr.split(' ').first)?.toInt() ?? 0;
      } catch (_) {}
      // Load average
      double loadAvg = 0;
      try {
        final loadStr = File('$rootfs/proc/loadavg').readAsStringSync();
        loadAvg = double.tryParse(loadStr.split(' ').first) ?? 0;
      } catch (_) {}
      _latest = PerformanceMetrics(
        cpuPercent: 0, // Would need complex calc from /proc/stat
        memoryUsedMB: memTotal > 0 ? (memUsed ~/ 1024) : 0,
        memoryTotalMB: memTotal ~/ 1024,
        diskUsedMB: diskUsed,
        diskTotalMB: diskTotal,
        uptimeSeconds: uptime,
        processCount: 0,
        loadAverage: loadAvg,
      );
      _controller.add(_latest);
    } catch (_) {}
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}