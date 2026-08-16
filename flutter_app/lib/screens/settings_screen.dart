import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app.dart';
import '../constants.dart';
import '../providers/node_provider.dart';
import '../services/biometric_service.dart';
import '../services/clipboard_sync_service.dart';
import '../services/native_bridge.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/theme_service.dart';
import '../services/update_service.dart';
import 'backup_restore_screen.dart';
import 'diagnostics_screen.dart';
import 'node_screen.dart';
import 'performance_screen.dart';
import 'setup_wizard_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prefs = PreferencesService();
  bool _autoStart = false;
  bool _nodeEnabled = false;
  bool _batteryOptimized = true;
  String _arch = '';
  String _prootPath = '';
  Map<String, dynamic> _status = {};
  bool _loading = true;
  bool _goInstalled = false;
  bool _brewInstalled = false;
  bool _sshInstalled = false;
  bool _storageGranted = false;
  bool _checkingUpdate = false;

  bool _biometricEnabled = false;
  bool _clipboardSyncEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _prefs.init();
    _autoStart = _prefs.autoStartGateway;
    _nodeEnabled = _prefs.nodeEnabled;

    _biometricEnabled = await BiometricService.isEnabled;
    _clipboardSyncEnabled = await ClipboardSyncService.isEnabled;
    _biometricAvailable = await BiometricService.isAvailable();

    await NotificationService.init();

    try {
      final arch = await NativeBridge.getArch();
      final prootPath = await NativeBridge.getProotPath();
      final status = await NativeBridge.getBootstrapStatus();
      final batteryOptimized = await NativeBridge.isBatteryOptimized();

      final storageGranted = await NativeBridge.hasStoragePermission();

      final filesDir = await NativeBridge.getFilesDir();
      final rootfs = '$filesDir/rootfs/ubuntu';
      final goInstalled = File('$rootfs/usr/bin/go').existsSync();
      final brewInstalled =
          File('$rootfs/home/linuxbrew/.linuxbrew/bin/brew').existsSync();
      final sshInstalled = File('$rootfs/usr/bin/ssh').existsSync();

      setState(() {
        _batteryOptimized = batteryOptimized;
        _storageGranted = storageGranted;
        _arch = arch;
        _prootPath = prootPath;
        _status = status;
        _goInstalled = goInstalled;
        _brewInstalled = brewInstalled;
        _sshInstalled = sshInstalled;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _sectionHeader(theme, 'APPEARANCE'),
                _buildThemeSection(theme),
                const Divider(),
                _sectionHeader(theme, 'TERMINAL'),
                _buildTerminalSection(theme),
                const Divider(),
                _sectionHeader(theme, 'SECURITY'),
                _buildSecuritySection(theme),
                const Divider(),
                _sectionHeader(theme, 'GENERAL'),
                SwitchListTile(
                  title: const Text('Auto-start gateway'),
                  subtitle: const Text('Start the gateway when the app opens'),
                  value: _autoStart,
                  onChanged: (value) {
                    setState(() => _autoStart = value);
                    _prefs.autoStartGateway = value;
                  },
                ),
                ListTile(
                  title: const Text('Battery Optimization'),
                  subtitle: Text(_batteryOptimized
                      ? 'Optimized (may kill background sessions)'
                      : 'Unrestricted (recommended)'),
                  leading: const Icon(Icons.battery_alert),
                  trailing: _batteryOptimized
                      ? const Icon(Icons.warning, color: AppColors.statusAmber)
                      : const Icon(Icons.check_circle, color: AppColors.statusGreen),
                  onTap: () async {
                    await NativeBridge.requestBatteryOptimization();
                    final optimized = await NativeBridge.isBatteryOptimized();
                    setState(() => _batteryOptimized = optimized);
                  },
                ),
                ListTile(
                  title: const Text('Setup Storage'),
                  subtitle: Text(_storageGranted
                      ? 'Granted — proot can access /sdcard. Revoke if not needed.'
                      : 'Not granted (recommended) — tap to grant only if needed'),
                  leading: const Icon(Icons.sd_storage),
                  trailing: _storageGranted
                      ? const Icon(Icons.warning_amber, color: AppColors.statusAmber)
                      : const Icon(Icons.check_circle, color: AppColors.statusGreen),
                  onTap: () async {
                    await NativeBridge.requestStoragePermission();
                    final granted = await NativeBridge.hasStoragePermission();
                    setState(() => _storageGranted = granted);
                  },
                ),
                const Divider(),
                _sectionHeader(theme, 'NODE'),
                SwitchListTile(
                  title: const Text('Enable Node'),
                  subtitle: const Text('Provide device capabilities to the gateway'),
                  value: _nodeEnabled,
                  onChanged: (value) {
                    setState(() => _nodeEnabled = value);
                    _prefs.nodeEnabled = value;
                    final nodeProvider = context.read<NodeProvider>();
                    if (value) {
                      nodeProvider.enable();
                    } else {
                      nodeProvider.disable();
                    }
                  },
                ),
                ListTile(
                  title: const Text('Node Configuration'),
                  subtitle: const Text('Connection, pairing, and capabilities'),
                  leading: const Icon(Icons.devices),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NodeScreen()),
                  ),
                ),
                const Divider(),
                _sectionHeader(theme, 'NOTIFICATIONS'),
                _buildNotificationSection(theme),
                const Divider(),
                _sectionHeader(theme, 'TOOLS'),
                ListTile(
                  title: const Text('Performance Monitor'),
                  subtitle: const Text('Real-time CPU, memory, disk, and load metrics'),
                  leading: const Icon(Icons.speed),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PerformanceScreen()),
                  ),
                ),
                ListTile(
                  title: const Text('Diagnostics'),
                  subtitle: const Text('Network, PRoot, bootstrap, and gateway health checks'),
                  leading: const Icon(Icons.network_check),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
                  ),
                ),
                ListTile(
                  title: const Text('Terminal Sessions'),
                  subtitle: const Text('Save, manage, and launch terminal sessions'),
                  leading: const Icon(Icons.terminal),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terminal Sessions screen coming soon')),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Backup & Restore'),
                  subtitle: const Text('Export/import all settings and provider configs'),
                  leading: const Icon(Icons.backup),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
                  ),
                ),
                const Divider(),
                _sectionHeader(theme, 'SYSTEM INFO'),
                ListTile(
                  title: const Text('Architecture'),
                  subtitle: Text(_arch),
                  leading: const Icon(Icons.memory),
                ),
                ListTile(
                  title: const Text('PRoot path'),
                  subtitle: Text(_prootPath),
                  leading: const Icon(Icons.folder),
                ),
                ListTile(
                  title: const Text('Rootfs'),
                  subtitle: Text(_status['rootfsExists'] == true
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.storage),
                ),
                ListTile(
                  title: const Text('Node.js'),
                  subtitle: Text(_status['nodeInstalled'] == true
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.code),
                ),
                ListTile(
                  title: const Text('OpenClaw'),
                  subtitle: Text(_status['openclawInstalled'] == true
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.cloud),
                ),
                ListTile(
                  title: const Text('Go (Golang)'),
                  subtitle: Text(_goInstalled
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.integration_instructions),
                ),
                ListTile(
                  title: const Text('Homebrew'),
                  subtitle: Text(_brewInstalled
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.science),
                ),
                ListTile(
                  title: const Text('OpenSSH'),
                  subtitle: Text(_sshInstalled
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.vpn_key),
                ),
                const Divider(),
                _sectionHeader(theme, 'MAINTENANCE'),
                ListTile(
                  title: const Text('Export Snapshot (Legacy)'),
                  subtitle: const Text('Backup config to Downloads'),
                  leading: const Icon(Icons.upload_file),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportSnapshot,
                ),
                ListTile(
                  title: const Text('Import Snapshot (Legacy)'),
                  subtitle: const Text('Restore config from backup'),
                  leading: const Icon(Icons.download),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _importSnapshot,
                ),
                ListTile(
                  title: const Text('Re-run setup'),
                  subtitle: const Text('Reinstall or repair the environment'),
                  leading: const Icon(Icons.build),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const SetupWizardScreen(),
                    ),
                  ),
                ),
                const Divider(),
                _sectionHeader(theme, 'ABOUT'),
                const ListTile(
                  title: Text('OpenClaw'),
                  subtitle: Text(
                    'AI Gateway for Android\nVersion ${AppConstants.version}',
                  ),
                  leading: Icon(Icons.info_outline),
                  isThreeLine: true,
                ),
                ListTile(
                  title: const Text('Check for Updates'),
                  subtitle: const Text('Check GitHub for a newer release'),
                  leading: _checkingUpdate
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.system_update),
                  onTap: _checkingUpdate ? null : _checkForUpdates,
                ),
                const ListTile(
                  title: Text('Developer'),
                  subtitle: Text(AppConstants.authorName),
                  leading: Icon(Icons.person),
                ),
                ListTile(
                  title: const Text('GitHub'),
                  subtitle: const Text('mithun50/openclaw-termux'),
                  leading: const Icon(Icons.code),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse(AppConstants.githubUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(
                  title: const Text('Contact'),
                  subtitle: const Text(AppConstants.authorEmail),
                  leading: const Icon(Icons.email),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse('mailto:${AppConstants.authorEmail}'),
                  ),
                ),
                const ListTile(
                  title: Text('License'),
                  subtitle: Text(AppConstants.license),
                  leading: Icon(Icons.description),
                ),
                const Divider(),
                _sectionHeader(theme, AppConstants.orgName.toUpperCase()),
                ListTile(
                  title: const Text('Instagram'),
                  subtitle: const Text('@nexgenxplorer_nxg'),
                  leading: const Icon(Icons.camera_alt),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse(AppConstants.instagramUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(
                  title: const Text('YouTube'),
                  subtitle: const Text('@nexgenxplorer'),
                  leading: const Icon(Icons.play_circle_fill),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse(AppConstants.youtubeUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(
                  title: const Text('Play Store'),
                  subtitle: const Text('NextGenX Apps'),
                  leading: const Icon(Icons.shop),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse(AppConstants.playStoreUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(
                  title: const Text('Email'),
                  subtitle: const Text(AppConstants.orgEmail),
                  leading: const Icon(Icons.email_outlined),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse('mailto:${AppConstants.orgEmail}'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildThemeSection(ThemeData theme) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return Column(
          children: [
            ListTile(
              title: const Text('Theme Mode'),
              subtitle: Text(_themeModeLabel(themeService.themeMode)),
              leading: const Icon(Icons.palette),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemeModeDialog(themeService),
            ),
            ListTile(
              title: const Text('Accent Color'),
              subtitle: Text(AppConstants.accentColorNames[
                  AppConstants.accentColors.indexOf(themeService.accentColor)]),
              leading: const Icon(Icons.color_lens),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAccentColorDialog(themeService),
            ),
            SwitchListTile(
              title: const Text('AMOLED Black'),
              subtitle: const Text('Use pure black background (saves battery on OLED)'),
              value: themeService.useAmoledBlack,
              onChanged: (value) => themeService.setUseAmoledBlack(value),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTerminalSection(ThemeData theme) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return Column(
          children: [
            ListTile(
              title: const Text('Font Size'),
              subtitle: Text('${themeService.terminalFontSize.toStringAsFixed(1)} pt'),
              leading: const Icon(Icons.text_fields),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showFontSizeDialog(themeService),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecuritySection(ThemeData theme) {
    if (!_biometricAvailable) {
      return Column(
        children: [
          const ListTile(
            leading: Icon(Icons.fingerprint, color: AppColors.statusGrey),
            title: Text('Biometric Authentication'),
            subtitle: Text('Not available on this device'),
          ),
          SwitchListTile(
            title: const Text('Clipboard Sync'),
            subtitle: const Text('Sync clipboard between Android and PRoot'),
            value: _clipboardSyncEnabled,
            onChanged: (value) async {
              await ClipboardSyncService.setEnabled(value);
              setState(() => _clipboardSyncEnabled = value);
            },
          ),
        ],
      );
    }

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Biometric Authentication'),
          subtitle: const Text('Require fingerprint/face to access sensitive settings'),
          value: _biometricEnabled,
          onChanged: (value) async {
            if (value) {
              final auth = await BiometricService.authenticate(reason: 'Enable biometric lock');
              if (!auth) return;
            }
            await BiometricService.setEnabled(value);
            setState(() => _biometricEnabled = value);
          },
        ),
        SwitchListTile(
          title: const Text('Clipboard Sync'),
          subtitle: const Text('Sync clipboard between Android and PRoot'),
          value: _clipboardSyncEnabled,
          onChanged: (value) async {
            await ClipboardSyncService.setEnabled(value);
            setState(() => _clipboardSyncEnabled = value);
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSection(ThemeData theme) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Gateway Status'),
          subtitle: const Text('Show ongoing notification when gateway is running'),
          value: NotificationService.gatewayStatusNotifications,
          onChanged: (value) => NotificationService.setGatewayStatusNotifications(value),
        ),
        SwitchListTile(
          title: const Text('Gateway Errors'),
          subtitle: const Text('Notify when gateway encounters an error'),
          value: NotificationService.errorNotifications,
          onChanged: (value) => NotificationService.setErrorNotifications(value),
        ),
        SwitchListTile(
          title: const Text('Node Events'),
          subtitle: const Text('Notify when nodes pair or disconnect'),
          value: NotificationService.nodeNotifications,
          onChanged: (value) => NotificationService.setNodeNotifications(value),
        ),
      ],
    );
  }

  String _themeModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'System Default';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeModeDialog(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Text(_themeModeLabel(mode)),
              value: mode,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeService.setThemeMode(value);
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAccentColorDialog(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accent Color'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppConstants.accentColors.length,
            itemBuilder: (_, index) {
              final color = AppConstants.accentColors[index];
              final name = AppConstants.accentColorNames[index];
              final selected = color == themeService.accentColor;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  child: selected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
                title: Text(name),
                trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  themeService.setAccentColor(color);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFontSizeDialog(ThemeService themeService) {
    double tempSize = themeService.terminalFontSize;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Terminal Font Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${tempSize.toStringAsFixed(1)} pt', style: Theme.of(ctx).textTheme.headlineSmall),
              Slider(
                value: tempSize,
                min: AppConstants.terminalFontSizeMin,
                max: AppConstants.terminalFontSizeMax,
                divisions: ((AppConstants.terminalFontSizeMax - AppConstants.terminalFontSizeMin) / 0.5).round(),
                label: '${tempSize.toStringAsFixed(1)} pt',
                onChanged: (value) => setState(() => tempSize = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                themeService.setTerminalFontSize(tempSize);
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getSnapshotPath() async {
    final hasPermission = await NativeBridge.hasStoragePermission();
    if (hasPermission) {
      final sdcard = await NativeBridge.getExternalStoragePath();
      final downloadDir = Directory('$sdcard/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return '$sdcard/Download/openclaw-snapshot.json';
    }
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/openclaw-snapshot.json';
  }

  Future<void> _exportSnapshot() async {
    try {
      final openclawJson = await NativeBridge.readRootfsFile('root/.openclaw/openclaw.json');
      final snapshot = {
        'version': AppConstants.version,
        'timestamp': DateTime.now().toIso8601String(),
        'openclawConfig': openclawJson,
        'dashboardUrl': _prefs.dashboardUrl,
        'autoStart': _prefs.autoStartGateway,
        'nodeEnabled': _prefs.nodeEnabled,
        'nodeDeviceToken': _prefs.nodeDeviceToken,
        'nodeGatewayHost': _prefs.nodeGatewayHost,
        'nodeGatewayPort': _prefs.nodeGatewayPort,
        'nodeGatewayToken': _prefs.nodeGatewayToken,
      };

      final path = await _getSnapshotPath();
      final file = File(path);
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(snapshot));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Snapshot saved to $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importSnapshot() async {
    try {
      final path = await _getSnapshotPath();
      final file = File(path);

      if (!await file.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No snapshot found at $path')),
        );
        return;
      }

      final content = await file.readAsString();
      final snapshot = jsonDecode(content) as Map<String, dynamic>;

      final openclawConfig = snapshot['openclawConfig'] as String?;
      if (openclawConfig != null) {
        await NativeBridge.writeRootfsFile('root/.openclaw/openclaw.json', openclawConfig);
      }

      if (snapshot['dashboardUrl'] != null) {
        _prefs.dashboardUrl = snapshot['dashboardUrl'] as String;
      }
      if (snapshot['autoStart'] != null) {
        _prefs.autoStartGateway = snapshot['autoStart'] as bool;
      }
      if (snapshot['nodeEnabled'] != null) {
        _prefs.nodeEnabled = snapshot['nodeEnabled'] as bool;
      }
      if (snapshot['nodeDeviceToken'] != null) {
        _prefs.nodeDeviceToken = snapshot['nodeDeviceToken'] as String;
      }
      if (snapshot['nodeGatewayHost'] != null) {
        _prefs.nodeGatewayHost = snapshot['nodeGatewayHost'] as String;
      }
      if (snapshot['nodeGatewayPort'] != null) {
        _prefs.nodeGatewayPort = snapshot['nodeGatewayPort'] as int;
      }
      if (snapshot['nodeGatewayToken'] != null) {
        _prefs.nodeGatewayToken = snapshot['nodeGatewayToken'] as String;
      }

      await _loadSettings();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snapshot restored successfully. Restart the gateway to apply.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checkingUpdate = true);
    try {
      final result = await UpdateService.check();
      if (!mounted) return;
      if (result.available) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Update Available'),
            content: Text(
              'A new version is available.\n\n'
              'Current: ${AppConstants.version}\n'
              'Latest: ${result.latest}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  launchUrl(
                    Uri.parse(result.url),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: const Text('Download'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You're on the latest version")),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not check for updates')),
      );
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}