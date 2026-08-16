import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/gateway_provider.dart';
import '../providers/node_provider.dart';
import '../services/performance_service.dart';
import '../widgets/gateway_controls.dart';
import '../widgets/dashboard_webview.dart';
import '../widgets/status_card.dart';
import 'node_screen.dart';
import 'configure_screen.dart';
import 'onboarding_screen.dart';
import 'terminal_screen.dart';
import 'logs_screen.dart';
import 'packages_screen.dart';
import 'providers_screen.dart';
import 'performance_screen.dart';
import 'settings_screen.dart';
import 'ssh_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenClaw'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GatewayControls(),
            const SizedBox(height: 16),
            _WebDashboardEmbed(),
            const SizedBox(height: 20),
            StreamBuilder<PerformanceMetrics>(
              stream: PerformanceService().stream,
              builder: (context, snapshot) {
                final metrics = snapshot.data;
                if (metrics == null) return const SizedBox.shrink();
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PerformanceScreen()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _perfItem('Memory', '${metrics.memoryPercent.toStringAsFixed(0)}%', metrics.memoryPercent / 100, theme),
                          ),
                          Expanded(
                            child: _perfItem('Disk', '${metrics.diskPercent.toStringAsFixed(0)}%', metrics.diskPercent / 100, theme),
                          ),
                          Expanded(
                            child: _perfItem('Load', metrics.loadAverage.toStringAsFixed(1), (metrics.loadAverage / 4).clamp(0, 1), theme),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'QUICK ACTIONS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            StatusCard(
              title: 'Terminal',
              subtitle: 'Open Ubuntu shell with OpenClaw',
              icon: Icons.terminal,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TerminalScreen()),
              ),
            ),
            StatusCard(
              title: 'Onboarding',
              subtitle: 'Configure API keys and binding',
              icon: Icons.vpn_key,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              ),
            ),
            StatusCard(
              title: 'Configure',
              subtitle: 'Manage gateway settings',
              icon: Icons.tune,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConfigureScreen()),
              ),
            ),
            StatusCard(
              title: 'AI Providers',
              subtitle: 'Configure models and API keys',
              icon: Icons.model_training,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProvidersScreen()),
              ),
            ),
            StatusCard(
              title: 'Packages',
              subtitle: 'Install optional tools (Go, Homebrew, SSH)',
              icon: Icons.extension,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PackagesScreen()),
              ),
            ),
            StatusCard(
              title: 'SSH Access',
              subtitle: 'Remote terminal access via SSH',
              icon: Icons.terminal,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SshScreen()),
              ),
            ),
            StatusCard(
              title: 'Logs',
              subtitle: 'View gateway output and errors',
              icon: Icons.article_outlined,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LogsScreen()),
              ),
            ),
            StatusCard(
              title: 'Snapshot',
              subtitle: 'Backup or restore your config',
              icon: Icons.backup,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            Consumer<NodeProvider>(
              builder: (context, nodeProvider, _) {
                final nodeState = nodeProvider.state;
                return StatusCard(
                  title: 'Node',
                  subtitle: nodeState.isPaired
                      ? 'Connected to gateway'
                      : nodeState.isDisabled
                          ? 'Device capabilities for AI'
                          : nodeState.statusText,
                  icon: Icons.devices,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NodeScreen()),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    'OpenClaw v${AppConstants.version}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'by ${AppConstants.authorName} | ${AppConstants.orgName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _perfItem(String label, String value, double progress, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(value, style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class _WebDashboardEmbed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GatewayProvider>(
      builder: (context, provider, _) {
        final url = provider.state.dashboardUrl;
        if (!provider.state.isRunning || url == null || url.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.dashboard_outlined,
                    size: 36,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start the gateway to load the web dashboard here.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LIVE DASHBOARD',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dashboard URL copied')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Copy URL'),
                ),
              ],
            ),
            DashboardWebView(url: url),
          ],
        );
      },
    );
  }
}
