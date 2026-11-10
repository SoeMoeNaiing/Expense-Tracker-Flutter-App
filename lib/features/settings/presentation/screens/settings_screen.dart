import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/mesh_background.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../data/backup_file_io.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref.read(exportExpensesCsvProvider)();
      if (!mounted) return;
      if (result.isFailure) {
        _snack(result.messageOrNull ?? 'Export failed');
        return;
      }
      final csv = result.valueOrNull;
      if (csv == null) return;
      final io = await ref
          .read(backupFileIOProvider)
          .saveAndShareCsv(csv, _fileName());
      if (!mounted) return;
      if (io.isFailure) {
        _snack(io.messageOrNull ?? 'Save failed');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await ref.read(backupFileIOProvider).pickCsv();
      if (!mounted) return;
      if (picked.isFailure) {
        _snack(picked.messageOrNull ?? 'Failed to open file');
        return;
      }
      final content = picked.valueOrNull;
      if (content == null) return; // user cancelled

      // Preview
      final previewResult = await ref
          .read(importExpensesCsvProvider)
          .preview(content);
      if (!mounted) return;
      if (previewResult.isFailure) {
        _snack(previewResult.messageOrNull ?? 'Preview failed');
        return;
      }
      final preview = previewResult.valueOrNull;
      if (preview == null) return;

      final confirmed = await _showConfirmDialog(
        validCount: preview.imported,
        errorCount: preview.errors.length,
      );
      if (!mounted || confirmed != true) return;

      // Commit
      final importResult = await ref.read(importExpensesCsvProvider)(content);
      if (!mounted) return;
      if (importResult.isFailure) {
        _snack(importResult.messageOrNull ?? 'Import failed');
        return;
      }
      final summary = importResult.valueOrNull;
      if (summary == null) return;

      ref.invalidate(expensesProvider);

      final msg = summary.errors.isEmpty
          ? 'Imported ${summary.imported} expenses'
          : 'Imported ${summary.imported} · ${summary.failed} errors';
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.bgRaised,
          behavior: SnackBarBehavior.floating,
          action: summary.errors.isEmpty
              ? null
              : SnackBarAction(
                  label: 'Details',
                  textColor: AppColors.primary,
                  onPressed: () => _showErrorsDialog(summary.errors),
                ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fileName() {
    final now = DateTime.now();
    String p2(int v) => v.toString().padLeft(2, '0');
    return 'ledger-${now.year}${p2(now.month)}${p2(now.day)}-'
        '${p2(now.hour)}${p2(now.minute)}${p2(now.second)}.csv';
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.bgRaised,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<bool?> _showConfirmDialog({
    required int validCount,
    required int errorCount,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgRaised,
        title: const Text('Import CSV?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$validCount valid row${validCount == 1 ? '' : 's'} found.'),
            if (errorCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$errorCount row${errorCount == 1 ? '' : 's'} will be skipped.',
                style: const TextStyle(color: AppColors.amber),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Import',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorsDialog(List<String> errors) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgRaised,
        title: const Text('Import errors'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: errors.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) =>
                Text(errors[i], style: const TextStyle(fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 24, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text('Settings', style: text.headlineLarge),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('DATA', style: text.labelSmall),
              ),
              const SizedBox(height: 10),
              _Row(
                key: const Key('export_button'),
                icon: Icons.upload_file,
                title: 'Export CSV',
                subtitle: 'Share your expenses as a CSV file',
                busy: _busy,
                onTap: _busy ? null : _export,
              ),
              const SizedBox(height: 8),
              _Row(
                key: const Key('import_button'),
                icon: Icons.download,
                title: 'Import CSV',
                subtitle: 'Restore expenses from a backup file',
                busy: _busy,
                onTap: _busy ? null : _import,
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('ABOUT', style: text.labelSmall),
              ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppGradients.glass,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text('Ledger · v0.1.0', style: text.bodyMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback? onTap;

  const _Row({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppGradients.glass,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(38),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.bodyLarge),
                      const SizedBox(height: 2),
                      Text(subtitle, style: text.labelSmall),
                    ],
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
