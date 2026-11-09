import 'package:flutter/material.dart';
import '../../canvas/models/canvas_document.dart';
import '../services/export_service.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// Modal dialog for sharing artwork to social media platforms and saving to device.
class SocialShareDialog extends StatefulWidget {
  const SocialShareDialog({super.key, required this.document});

  final CanvasDocument document;

  static void show(BuildContext context, CanvasDocument document) {
    SoundEffectService.instance.playPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SocialShareDialog(document: document),
    );
  }

  @override
  State<SocialShareDialog> createState() => _SocialShareDialogState();
}

class _SocialShareDialogState extends State<SocialShareDialog> {
  bool _isExporting = false;
  String? _statusMessage;

  Future<void> _shareToSocialMedia({String? platformTag}) async {
    setState(() {
      _isExporting = true;
      _statusMessage = 'Preparing artwork for sharing...';
    });
    SoundEffectService.instance.playWhoosh();

    try {
      const config = ExportConfig(
        format: ExportFormat.png,
        scale: 1.0,
        quality: 95,
        includeBackground: true,
      );

      await ExportService.instance.exportAndShare(widget.document, config);
      SoundEffectService.instance.playCelebration();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _statusMessage = 'Error preparing image: $e';
        });
      }
    }
  }

  Future<void> _saveToStorage() async {
    setState(() {
      _isExporting = true;
      _statusMessage = 'Saving directly to Device Gallery...';
    });
    SoundEffectService.instance.playWhoosh();

    try {
      const config = ExportConfig(
        format: ExportFormat.png,
        scale: 1.0,
        quality: 100,
        includeBackground: true,
      );

      final path = await ExportService.instance.saveToGallery(widget.document, config: config);
      SoundEffectService.instance.playCelebration();

      if (mounted) {
        setState(() {
          _isExporting = false;
          _statusMessage = 'Saved successfully to Gallery & Photos!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Artwork saved directly to Gallery & Photos!\n$path')),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _statusMessage = 'Failed to save: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFF6C5CE7)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share Your Masterpiece',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Post directly to Instagram, WhatsApp, X, and more',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    SoundEffectService.instance.playPop();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),

            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    if (_isExporting)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.info_outline_rounded, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Social Media Platform Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SocialIconButton(
                  name: 'Instagram',
                  icon: Icons.camera_alt_rounded,
                  gradient: const [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
                  onTap: () => _shareToSocialMedia(platformTag: '#Instagram'),
                ),
                _SocialIconButton(
                  name: 'WhatsApp',
                  icon: Icons.chat_bubble_rounded,
                  gradient: const [Color(0xFF25D366), Color(0xFF128C7E)],
                  onTap: () => _shareToSocialMedia(platformTag: '#WhatsApp'),
                ),
                _SocialIconButton(
                  name: 'Twitter / X',
                  icon: Icons.tag_rounded,
                  gradient: const [Color(0xFF1E293B), Color(0xFF0F172A)],
                  onTap: () => _shareToSocialMedia(platformTag: '#X'),
                ),
                _SocialIconButton(
                  name: 'Facebook',
                  icon: Icons.thumb_up_rounded,
                  gradient: const [Color(0xFF1877F2), Color(0xFF3B5998)],
                  onTap: () => _shareToSocialMedia(platformTag: '#Facebook'),
                ),
                _SocialIconButton(
                  name: 'Pinterest',
                  icon: Icons.push_pin_rounded,
                  gradient: const [Color(0xFFE60023), Color(0xFFAD081B)],
                  onTap: () => _shareToSocialMedia(platformTag: '#Pinterest'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExporting ? null : _saveToStorage,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Save to Photos'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : () => _shareToSocialMedia(),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Share All Apps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.name,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
