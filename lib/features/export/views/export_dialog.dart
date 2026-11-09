import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../canvas/models/canvas_document.dart';
import '../services/export_service.dart';

/// Modal bottom sheet or dialog for exporting artwork with options.
class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({super.key, required this.document});

  final CanvasDocument document;

  static Future<void> show(BuildContext context, CanvasDocument document) {
    SoundEffectService.instance.playPop();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportDialog(document: document),
    );
  }

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  ExportFormat _format = ExportFormat.png;
  double _scale = 1.0;
  int _quality = 90;
  bool _includeBackground = true;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetW = (widget.document.width * _scale).round();
    final targetH = (widget.document.height * _scale).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header
            Row(
              children: [
                const Icon(Icons.ios_share_rounded, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Export Artwork',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Format Selection
            Text(
              'FORMAT',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<ExportFormat>(
              segments: ExportFormat.values
                  .map(
                    (f) => ButtonSegment(
                      value: f,
                      label: Text(f.label),
                    ),
                  )
                  .toList(),
              selected: {_format},
              onSelectionChanged: (selected) {
                SoundEffectService.instance.playPop();
                setState(() => _format = selected.first);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Resolution Scale
            Text(
              'RESOLUTION ($targetW × $targetH px)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 1.0, label: Text('1x Standard')),
                ButtonSegment(value: 2.0, label: Text('2x High-Res')),
                ButtonSegment(value: 4.0, label: Text('4x Ultra')),
              ],
              selected: {_scale},
              onSelectionChanged: (selected) {
                SoundEffectService.instance.playPop();
                setState(() => _scale = selected.first);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Format-specific options
            if (_format == ExportFormat.png) ...[
              SwitchListTile.adaptive(
                title: const Text('Include Background Color'),
                subtitle: Text(
                  _includeBackground
                      ? 'Solid background color preserved'
                      : 'Transparent background',
                  style: theme.textTheme.bodySmall,
                ),
                value: _includeBackground,
                onChanged: (v) => setState(() => _includeBackground = v),
                contentPadding: EdgeInsets.zero,
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quality', style: theme.textTheme.bodyMedium),
                  Text('$_quality%', style: theme.textTheme.bodySmall),
                ],
              ),
              Slider.adaptive(
                value: _quality.toDouble(),
                min: 30,
                max: 100,
                divisions: 14,
                label: '$_quality%',
                onChanged: (v) => setState(() => _quality = v.round()),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // ── Save to Phone Storage Button ──
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              onPressed: _isExporting ? null : _handleSaveToPhone,
              child: _isExporting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, size: 20),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          'Save to Phone Storage',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // ── Share via Apps Button ──
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              onPressed: _isExporting ? null : _handleShare,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share_rounded, size: 18),
                  SizedBox(width: AppSpacing.xs),
                  Text('Share via Apps'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSaveToPhone() async {
    setState(() => _isExporting = true);
    try {
      final config = ExportConfig(
        format: _format,
        scale: _scale,
        quality: _quality,
        includeBackground: _includeBackground,
      );
      final savedPath = await ExportService.instance.saveToPhoneStorage(
        widget.document,
        config,
      );
      SoundEffectService.instance.playCelebration();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2ED573),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Drawing saved to phone storage!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        savedPath,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handleShare() async {
    setState(() => _isExporting = true);
    try {
      final config = ExportConfig(
        format: _format,
        scale: _scale,
        quality: _quality,
        includeBackground: _includeBackground,
      );
      await ExportService.instance.exportAndShare(widget.document, config);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
