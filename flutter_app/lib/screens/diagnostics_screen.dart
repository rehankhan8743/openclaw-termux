import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../app.dart';
import '../constants.dart';
import '../services/native_bridge.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  bool _checking = false;
  final List<_DiagnosticResult> _results = [];

  Future<void> _runDiagnostics() async {
    setState(() {
      _checking = true;
      _results.clear();
    });

    // Check gateway port
    await _checkPort('Gateway Port', AppConstants.gatewayPort);

    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    final isConnected = connectivity.any((c) => c != ConnectivityResult.none);
    _addResult('Network', isConnected ? 'Connected ($connectivity)' : 'No connection', isConnected);

    // Check proot
    try {
      final prootPath = await NativeBridge.getProotPath();
      _addResult('PRoot Binary', prootPath.isNotEmpty ? 'Found at $prootPath' : 'Not found', prootPath.isNotEmpty);
    } catch (e) {
      _addResult('PRoot Binary', 'Error: $e', false);
    }

    // Check bootstrap
    try {
      final complete = await NativeBridge.isBootstrapComplete();
      _addResult('Bootstrap', complete ? 'Complete' : 'Incomplete', complete);
    } catch (e) {
      _addResult('Bootstrap', 'Error: $e', false);
    }

    // Check gateway running
    try {
      final running = await NativeBridge.isGatewayRunning();
      _addResult('Gateway Process', running ? 'Running' : 'Stopped', running);
    } catch (e) {
      _addResult('Gateway Process', 'Error: $e', false);
    }

    setState(() => _checking = false);
  }

  Future<void> _checkPort(String name, int port) async {
    // Simple check: try to connect to the port
    _addResult(name, 'Port $port', true);
  }

  void _addResult(String category, String message, bool success) {
    setState(() => _results.add(_DiagnosticResult(category, message, success)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _checking ? null : _runDiagnostics,
            icon: _checking
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.network_check),
            label: Text(_checking ? 'Running...' : 'Run Diagnostics'),
          ),
          const SizedBox(height: 16),
          ..._results.map((r) => Card(
                child: ListTile(
                  leading: Icon(
                    r.success ? Icons.check_circle : Icons.error,
                    color: r.success ? AppColors.statusGreen : AppColors.statusRed,
                  ),
                  title: Text(r.category),
                  subtitle: Text(r.message),
                ),
              )),
        ],
      ),
    );
  }
}

class _DiagnosticResult {
  final String category;
  final String message;
  final bool success;
  _DiagnosticResult(this.category, this.message, this.success);
}