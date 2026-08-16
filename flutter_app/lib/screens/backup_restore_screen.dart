import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _exporting = false;
  bool _importing = false;
  String? _status;

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      await BackupService.shareBackup();
      setState(() => _status = 'Backup shared successfully');
    } catch (e) {
      setState(() => _status = 'Export failed: $e');
    } finally {
      setState(() => _exporting = false);
    }
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        final success = await BackupService.importFromFile(result.files.single.path!);
        setState(() => _status = success ? 'Import successful! Restart app to apply all settings.' : 'Import failed: invalid file');
      }
    } catch (e) {
      setState(() => _status = 'Import failed: $e');
    } finally {
      setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Export Configuration', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Share your settings, API keys, and preferences as a JSON file.', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _exporting ? null : _export,
                      icon: _exporting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload),
                      label: Text(_exporting ? 'Exporting...' : 'Export & Share'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Import Configuration', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Restore settings from a previously exported JSON file.', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _importing ? null : _import,
                      icon: _importing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.download),
                      label: Text(_importing ? 'Importing...' : 'Import from File'),
                    ),
                  ],
                ),
              ),
            ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Text(_status!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}