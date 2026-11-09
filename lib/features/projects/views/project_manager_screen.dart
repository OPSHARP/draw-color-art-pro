import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/ads/ad_service.dart';
import '../../canvas/providers/canvas_providers.dart';
import '../../canvas/views/drawing_screen.dart';
import '../../canvas/widgets/canvas_size_picker_modal.dart';
import '../../export/views/export_dialog.dart';
import '../models/project_entry.dart';
import '../providers/project_providers.dart';
import '../services/project_storage_service.dart';
import 'project_actions_bottom_sheet.dart';

enum ProjectFilter { all, favorites, trash }

/// Dedicated Project Gallery & Management Screen.
class ProjectManagerScreen extends ConsumerStatefulWidget {
  const ProjectManagerScreen({super.key});

  @override
  ConsumerState<ProjectManagerScreen> createState() =>
      _ProjectManagerScreenState();
}

class _ProjectManagerScreenState extends ConsumerState<ProjectManagerScreen> {
  bool _isGridView = true;
  ProjectFilter _filter = ProjectFilter.all;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Artworks'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            tooltip: _isGridView ? 'List view' : 'Grid view',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filters ──
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search artworks...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),

          // ── Filter Chips ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Artworks',
                    isSelected: _filter == ProjectFilter.all,
                    onSelected: () {
                      setState(() => _filter = ProjectFilter.all);
                      ref.read(projectListProvider.notifier).loadProjects(includeTrash: false);
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'Favorites',
                    isSelected: _filter == ProjectFilter.favorites,
                    icon: Icons.star_rounded,
                    onSelected: () {
                      setState(() => _filter = ProjectFilter.favorites);
                      ref.read(projectListProvider.notifier).loadProjects(includeTrash: false);
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'Trash',
                    isSelected: _filter == ProjectFilter.trash,
                    icon: Icons.delete_outline_rounded,
                    onSelected: () {
                      setState(() => _filter = ProjectFilter.trash);
                      ref.read(projectListProvider.notifier).loadProjects(includeTrash: true);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // ── Content ──
          Expanded(
            child: projectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (allProjects) {
                final filtered = allProjects.where((p) {
                  if (_filter == ProjectFilter.trash) {
                    if (!p.isTrash) return false;
                  } else {
                    if (p.isTrash) return false;
                    if (_filter == ProjectFilter.favorites && !p.isFavorite) {
                      return false;
                    }
                  }
                  if (_searchQuery.isNotEmpty &&
                      !p.name.toLowerCase().contains(_searchQuery)) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return _EmptyProjectsView(filter: _filter);
                }

                final bottomListPadding = AppSpacing.xxl + 48 + MediaQuery.paddingOf(context).bottom;

                if (_isGridView) {
                  return GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, bottomListPadding),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final project = filtered[index];
                      return _ProjectGridCard(
                        project: project,
                        onTap: () => _openProject(project),
                        onLongPress: () => ProjectActionsBottomSheet.show(context, ref, project),
                        onFavorite: () => _toggleFavorite(project),
                        onDelete: () => _deleteProject(project),
                        onRestore: () => _restoreProject(project),
                        onExport: () => _exportProject(project),
                      );
                    },
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, bottomListPadding),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final project = filtered[index];
                    return _ProjectListTile(
                      project: project,
                      onTap: () => _openProject(project),
                      onLongPress: () => ProjectActionsBottomSheet.show(context, ref, project),
                      onFavorite: () => _toggleFavorite(project),
                      onDelete: () => _deleteProject(project),
                      onRestore: () => _restoreProject(project),
                      onExport: () => _exportProject(project),
                    );
                  },
                );
              },
            ),
          ),
          // ── AdMob Test Banner ──
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Center(child: AdBannerWidget()),
            ),
          ),
        ],
      ),
      floatingActionButton: _filter != ProjectFilter.trash
          ? FloatingActionButton.extended(
              onPressed: _createNewArtwork,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Artwork'),
            )
          : null,
    );
  }

  void _createNewArtwork() {
    CanvasSizePickerModal.show(context);
  }

  Future<void> _openProject(ProjectEntry entry) async {
    if (entry.isTrash) return;
    final doc = await ProjectStorageService.instance.loadProject(entry.id);
    if (doc != null && mounted) {
      if (doc.isThumbnail || doc.name.toLowerCase().contains('thumbnail')) {
        ref.read(autoFitToScreenProvider.notifier).state = true;
      }
      ref.read(canvasDocumentProvider.notifier).loadDocument(doc);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DrawingScreen()),
      ).then((_) {
        if (mounted) {
          ref.read(projectListProvider.notifier).loadProjects(
                includeTrash: _filter == ProjectFilter.trash,
              );
        }
      });
    }
  }

  void _toggleFavorite(ProjectEntry project) {
    ref.read(projectListProvider.notifier).toggleFavorite(project.id);
  }

  void _deleteProject(ProjectEntry project) {
    final isPermanent = project.isTrash;
    ref.read(projectListProvider.notifier).deleteProject(
          project.id,
          permanent: isPermanent,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPermanent
              ? 'Permanently deleted "${project.name}"'
              : 'Moved "${project.name}" to Trash',
        ),
      ),
    );
  }

  void _restoreProject(ProjectEntry project) {
    ref.read(projectListProvider.notifier).restoreProject(project.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Restored "${project.name}"')),
    );
  }

  Future<void> _exportProject(ProjectEntry entry) async {
    final doc = await ProjectStorageService.instance.loadProject(entry.id);
    if (doc != null && mounted) {
      ExportDialog.show(context, doc);
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      avatar: icon != null
          ? Icon(
              icon,
              size: 16,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            )
          : null,
      onSelected: (_) => onSelected(),
    );
  }
}

class _ProjectGridCard extends StatelessWidget {
  const _ProjectGridCard({
    required this.project,
    required this.onTap,
    this.onLongPress,
    required this.onFavorite,
    required this.onDelete,
    required this.onRestore,
    required this.onExport,
  });

  final ProjectEntry project;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final VoidCallback onRestore;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy').format(project.updatedAt);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: theme.dividerTheme.color ?? Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Thumbnail / Preview ──
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
                child: project.thumbnailPath != null &&
                        File(project.thumbnailPath!).existsSync()
                    ? Image.file(
                        File(project.thumbnailPath!),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.brush_rounded,
                            size: 36,
                            color: theme.colorScheme.primary.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
              ),
            ),

            // ── Details ──
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!project.isTrash)
                        IconButton(
                          icon: Icon(
                            project.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 18,
                            color: project.isFavorite ? Colors.amber : null,
                          ),
                          onPressed: onFavorite,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (val) {
                          if (val == 'export') onExport();
                          if (val == 'delete') onDelete();
                          if (val == 'restore') onRestore();
                        },
                        itemBuilder: (ctx) => [
                          if (!project.isTrash) ...[
                            const PopupMenuItem(
                              value: 'export',
                              child: Row(
                                children: [
                                  Icon(Icons.ios_share_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Export'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Move to Trash'),
                                ],
                              ),
                            ),
                          ] else ...[
                            const PopupMenuItem(
                              value: 'restore',
                              child: Row(
                                children: [
                                  Icon(Icons.restore_from_trash_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Restore'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_forever_rounded, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete Permanently', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${project.width} × ${project.height} • $dateStr',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectListTile extends StatelessWidget {
  const _ProjectListTile({
    required this.project,
    required this.onTap,
    this.onLongPress,
    required this.onFavorite,
    required this.onDelete,
    required this.onRestore,
    required this.onExport,
  });

  final ProjectEntry project;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final VoidCallback onRestore;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy').format(project.updatedAt);

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: SizedBox(
          width: 48,
          height: 48,
          child: project.thumbnailPath != null &&
                  File(project.thumbnailPath!).existsSync()
              ? Image.file(File(project.thumbnailPath!), fit: BoxFit.cover)
              : Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.brush_rounded,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
        ),
      ),
      title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${project.width} × ${project.height} • ${project.layerCount} layers • $dateStr',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!project.isTrash)
            IconButton(
              icon: Icon(
                project.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: project.isFavorite ? Colors.amber : null,
              ),
              onPressed: onFavorite,
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'export') onExport();
              if (val == 'delete') onDelete();
              if (val == 'restore') onRestore();
            },
            itemBuilder: (ctx) => [
              if (!project.isTrash) ...[
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.ios_share_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Export'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Move to Trash'),
                    ],
                  ),
                ),
              ] else ...[
                const PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.restore_from_trash_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Restore'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_rounded, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Permanently', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyProjectsView extends StatelessWidget {
  const _EmptyProjectsView({required this.filter});
  final ProjectFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, text) = switch (filter) {
      ProjectFilter.all => (Icons.palette_outlined, 'No artworks found. Tap + to create one!'),
      ProjectFilter.favorites => (Icons.star_outline_rounded, 'No favorite artworks yet.'),
      ProjectFilter.trash => (Icons.delete_outline_rounded, 'Trash is empty.'),
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
