import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';
import '../../canvas/providers/canvas_providers.dart';
import '../../canvas/views/drawing_screen.dart';
import '../../export/views/export_dialog.dart';
import '../../export/views/social_share_dialog.dart';
import '../models/project_entry.dart';
import '../providers/project_providers.dart';
import '../services/project_storage_service.dart';

/// Pro bottom sheet shown when a user presses and holds any recent artwork or project.
///
/// Provides instant, safe artwork deletion, opening, sharing, and duplication anytime.
class ProjectActionsBottomSheet extends StatelessWidget {
  const ProjectActionsBottomSheet({
    super.key,
    required this.project,
    required this.ref,
  });

  final ProjectEntry project;
  final WidgetRef ref;

  /// Show the bottom action sheet with haptic feedback and sound.
  static void show(BuildContext context, WidgetRef ref, ProjectEntry project) {
    HapticFeedback.heavyImpact();
    SoundEffectService.instance.playPop();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProjectActionsBottomSheet(project: project, ref: ref),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final theme = Theme.of(context);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Delete Artwork?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${project.name}"?\nThis action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      SoundEffectService.instance.playEraser();
      HapticFeedback.mediumImpact();

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      // Close bottom sheet first
      navigator.pop();

      // Delete from storage permanently
      await ref.read(projectListProvider.notifier).deleteProject(project.id, permanent: true);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          content: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Deleted "${project.name}" permanently.'),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _openArtwork(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    final doc = await ProjectStorageService.instance.loadProject(project.id);
    if (doc != null && navigator.mounted) {
      if (doc.isThumbnail || doc.name.toLowerCase().contains('thumbnail')) {
        ref.read(autoFitToScreenProvider.notifier).state = true;
      }
      ref.read(canvasDocumentProvider.notifier).loadDocument(doc);
      navigator.push(
        MaterialPageRoute(builder: (_) => const DrawingScreen()),
      ).then((_) {
        ref.read(projectListProvider.notifier).loadProjects();
      });
    }
  }

  Future<void> _shareArtwork(BuildContext context) async {
    final hostContext = Navigator.of(context).context;
    Navigator.of(context).pop();
    final doc = await ProjectStorageService.instance.loadProject(project.id);
    if (doc != null && hostContext.mounted) {
      SocialShareDialog.show(hostContext, doc);
    }
  }

  Future<void> _exportArtwork(BuildContext context) async {
    final hostContext = Navigator.of(context).context;
    Navigator.of(context).pop();
    final doc = await ProjectStorageService.instance.loadProject(project.id);
    if (doc != null && hostContext.mounted) {
      ExportDialog.show(hostContext, doc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(project.updatedAt);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Artwork Header Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: project.thumbnailPath != null && File(project.thumbnailPath!).existsSync()
                          ? Image.file(File(project.thumbnailPath!), fit: BoxFit.cover)
                          : Icon(
                              Icons.brush_rounded,
                              size: 28,
                              color: theme.colorScheme.primary.withValues(alpha: 0.6),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Metadata Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${project.width} × ${project.height} px • ${project.layerCount} layers',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Favorite toggle
                  IconButton(
                    icon: Icon(
                      project.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: project.isFavorite ? Colors.amber : Colors.grey,
                      size: 24,
                    ),
                    onPressed: () {
                      SoundEffectService.instance.playPop();
                      ref.read(projectListProvider.notifier).toggleFavorite(project.id);
                      Navigator.of(context).pop();
                    },
                    tooltip: 'Favorite',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Danger Action: Delete Artwork Button (prominently featured for instant hold-to-delete)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _confirmAndDelete(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Artwork',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Remove permanently from your device',
                              style: TextStyle(color: Colors.redAccent, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.red, size: 14),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Action: Open & Edit
            _ActionButton(
              icon: Icons.draw_rounded,
              iconColor: const Color(0xFF6C5CE7),
              title: 'Open & Continue Drawing',
              subtitle: 'Edit strokes, layers, and colors in studio',
              onTap: () => _openArtwork(context),
            ),

            // Action: Share to Social Media
            _ActionButton(
              icon: Icons.share_rounded,
              iconColor: const Color(0xFFFF6B9D),
              title: 'Share Artwork',
              subtitle: 'Post to Instagram, WhatsApp, X, or save to photos',
              onTap: () => _shareArtwork(context),
            ),

            // Action: Export
            _ActionButton(
              icon: Icons.download_rounded,
              iconColor: const Color(0xFF00B894),
              title: 'Export File',
              subtitle: 'Save high-resolution PNG, JPEG, or SVG',
              onTap: () => _exportArtwork(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: InkWell(
        onTap: () {
          SoundEffectService.instance.playPop();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.withValues(alpha: 0.5), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
