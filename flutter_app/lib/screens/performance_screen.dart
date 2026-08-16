import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/performance_service.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final PerformanceService _service = PerformanceService();
  final List<PerformanceMetrics> _history = [];
  PerformanceMetrics _current = PerformanceMetrics.empty();

  @override
  void initState() {
    super.initState();
    _service.start();
    _service.stream.listen((metrics) {
      if (mounted) {
        setState(() {
          _current = metrics;
          _history.add(metrics);
          if (_history.length > 60) _history.removeAt(0);
        });
      }
    });
  }

  @override
  void dispose() {
    _service.stop();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Performance Monitor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMetricCard(
            theme,
            title: 'Memory',
            subtitle: '${_current.memoryUsedMB} MB / ${_current.memoryTotalMB} MB',
            percent: _current.memoryPercent / 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            theme,
            title: 'Disk',
            subtitle: '${_current.diskUsedMB} MB / ${_current.diskTotalMB} MB',
            percent: _current.diskPercent / 100,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            theme,
            title: 'Load Average',
            subtitle: _current.loadAverage.toStringAsFixed(2),
            percent: (_current.loadAverage / 4.0).clamp(0.0, 1.0),
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
          if (_history.length > 1)
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _history.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.memoryPercent);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required double percent,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 4),
            Text('${(percent * 100).toStringAsFixed(1)}%', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}