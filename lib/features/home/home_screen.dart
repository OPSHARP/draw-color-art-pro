import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../core/ads/ad_service.dart';
import '../../core/ads/ad_block_detector_service.dart';
import '../../core/services/in_app_update_service.dart';
import '../canvas/models/symmetry.dart';
import '../canvas/models/tools.dart';
import '../canvas/models/drawing_guides.dart';
import '../canvas/models/paper_texture.dart';
import '../canvas/views/drawing_screen.dart';
import '../canvas/providers/canvas_providers.dart';
import '../canvas/providers/image_import_providers.dart';
import '../projects/models/project_entry.dart';
import '../projects/providers/project_providers.dart';
import '../projects/services/project_storage_service.dart';
import '../projects/views/project_manager_screen.dart';
import '../projects/views/project_actions_bottom_sheet.dart';
import '../settings/providers/settings_providers.dart';
import '../settings/settings_screen.dart';
import '../templates/models/coloring_template.dart';
import '../templates/services/coloring_catalog_service.dart';
import '../templates/views/coloring_templates_modal.dart';
import '../templates/widgets/template_thumbnail_painter.dart';
import '../templates/views/design_preview_modal.dart';
import '../canvas/widgets/canvas_size_picker_modal.dart';
import '../ar_tracing/views/ar_tracing_screen.dart';
import '../../app.dart';

/// Home screen — iOS HIG-inspired design.
///
/// Clean, spacious layout with frosted glass header, iOS-style sections,
/// and minimal use of color for a premium feel.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppStartServices();
    });
  }

  Future<void> _checkAppStartServices() async {
    // 1. Check for flexible in-app updates in the background (Android Google Play)
    unawaited(InAppUpdateService.instance.checkForFlexibleUpdate(context));

    // 2. Start continuous 10-second ad-blocker & DNS monitoring
    AdBlockDetectorService.instance.startContinuousMonitoring();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final projectsAsync = ref.watch(projectListProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? IOSColors.darkBackground : IOSColors.lightGroupedBackground,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── iOS Large Title Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Draw Color ',
                                  style: theme.textTheme.displayLarge?.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [
                                      IOSColors.brandPrimary,
                                      IOSColors.brandAccent,
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Art Pro',
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sketch, Paint & Create',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? IOSColors.systemGray2 : IOSColors.systemGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ── Settings gear (iOS style) ──
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            IOSPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? IOSColors.darkElevated
                                : IOSColors.systemGray6,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            CupertinoIcons.gear,
                            size: 20,
                            color: isDark
                                ? IOSColors.systemGray
                                : IOSColors.systemGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Create Card (iOS Clean Style) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: _IOSCreateCard(
                    isDark: isDark,
                    onNewDrawing: () {
                      HapticFeedback.lightImpact();
                      SoundEffectService.instance.playPop();
                      ref.read(symmetryProvider.notifier).state =
                          const SymmetryConfig(mode: SymmetryMode.off);
                      CanvasSizePickerModal.show(context);
                    },
                    onStartColoring: () {
                      HapticFeedback.lightImpact();
                      ColoringTemplatesModal.show(context);
                    },
                  ),
                ),
              ),

              // ── Quick Actions Grid (iOS Style) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _IOSQuickActionsGrid(
                    isDark: isDark,
                    ref: ref,
                    context: context,
                  ),
                ),
              ),

              // ── AR Tracing Card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _IOSFeatureCard(
                    isDark: isDark,
                    icon: CupertinoIcons.camera,
                    title: 'AR Tracing Studio',
                    subtitle: 'Project & trace onto real paper with camera',
                    badge: 'NEW',
                    gradient: const [Color(0xFF34C759), Color(0xFF30D158)],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        IOSPageRoute(
                          builder: (_) => const ArTracingScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Recent Art Section ──
              SliverToBoxAdapter(
                child: _IOSSectionHeader(
                  title: 'Recent Art',
                  isDark: isDark,
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context).push(
                        IOSPageRoute(
                          builder: (_) => const ProjectManagerScreen(),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 15,
                            color: IOSColors.brandPrimary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: IOSColors.brandPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Recent Art Carousel ──
              SliverToBoxAdapter(
                child: projectsAsync.when(
                  loading: () => const SizedBox(
                    height: 120,
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                  error: (_, __) => _IOSEmptyState(
                    isDark: isDark,
                    icon: CupertinoIcons.paintbrush,
                    message: 'Your canvas is waiting',
                    actionLabel: 'Create Artwork',
                    onAction: () => _createNewProject(context, ref),
                  ),
                  data: (projects) {
                    final recents =
                        projects.where((p) => !p.isTrash).take(8).toList();
                    if (recents.isEmpty) {
                      return _IOSEmptyState(
                        isDark: isDark,
                        icon: CupertinoIcons.paintbrush,
                        message: 'Your canvas is waiting',
                        actionLabel: 'Create Artwork',
                        onAction: () => _createNewProject(context, ref),
                      );
                    }
                    return SizedBox(
                      height: 185,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: recents.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final p = recents[index];
                          return _IOSRecentProjectCard(
                            project: p,
                            ref: ref,
                            isDark: isDark,
                            onTap: () =>
                                _openExistingProject(context, ref, p),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // ── Coloring Book Section ──
              SliverToBoxAdapter(
                child: _IOSSectionHeader(
                  title: 'Coloring Book',
                  isDark: isDark,
                  subtitle: '180+ Designs',
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => ColoringTemplatesModal.show(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Browse',
                          style: TextStyle(
                            fontSize: 15,
                            color: IOSColors.brandPrimary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: IOSColors.brandPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 190,
                  child: Builder(
                    builder: (context) {
                      final featured =
                          ColoringCatalogService.instance.getFeaturedTemplates();
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: featured.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final t = featured[index];
                          return _IOSTemplateCard(
                            template: t,
                            isDark: isDark,
                            onTap: () {
                              DesignPreviewModal.show(context, template: t);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // ── Start Creating Grid ──
              SliverToBoxAdapter(
                child: _IOSSectionHeader(
                  title: 'Start Creating',
                  isDark: isDark,
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final int crossAxisCount;
                    final double childAspectRatio;

                    if (width >= 1100) {
                      crossAxisCount = 5;
                      childAspectRatio = 1.45;
                    } else if (width >= 800) {
                      crossAxisCount = 4;
                      childAspectRatio = 1.4;
                    } else if (width >= 580) {
                      crossAxisCount = 3;
                      childAspectRatio = 1.35;
                    } else if (width <= 340) {
                      crossAxisCount = 2;
                      childAspectRatio = 1.15;
                    } else {
                      crossAxisCount = 2;
                      childAspectRatio = 1.35;
                    }

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                      ),
                      delegate: SliverChildListDelegate([
                        _IOSCreativeCard(
                          title: 'Blank Canvas',
                          subtitle: 'Custom size & bg',
                          icon: CupertinoIcons.square_stack_3d_up,
                          color: IOSColors.brandPrimary,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(symmetryProvider.notifier).state =
                                const SymmetryConfig(mode: SymmetryMode.off);
                            CanvasSizePickerModal.show(context,
                                initialName: 'Blank Canvas');
                          },
                        ),
                        _IOSCreativeCard(
                          title: 'Mandala Art',
                          subtitle: 'Radial symmetry mode',
                          icon: CupertinoIcons.circle_grid_hex_fill,
                          color: const Color(0xFF9B51E0),
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(symmetryProvider.notifier).state =
                                const SymmetryConfig(
                              mode: SymmetryMode.radial,
                              segments: 8,
                            );
                            ref.read(activeToolProvider.notifier).selectTool(DrawingTool.pen);
                            _createNewProject(context, ref, name: 'Mandala Art');
                          },
                        ),
                        _IOSCreativeCard(
                          title: 'Doodle & Sketch',
                          subtitle: 'Freehand expressive art',
                          icon: CupertinoIcons.paintbrush_fill,
                          color: const Color(0xFFFF9500),
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(symmetryProvider.notifier).state =
                                const SymmetryConfig(mode: SymmetryMode.off);
                            ref.read(activeToolProvider.notifier).selectTool(DrawingTool.brush);
                            _createNewProject(context, ref, name: 'Doodle');
                          },
                        ),
                        _IOSCreativeCard(
                          title: 'Character',
                          subtitle: 'Portrait drawing',
                          icon: CupertinoIcons.person_crop_circle,
                          color: IOSColors.systemPink,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(symmetryProvider.notifier).state =
                                const SymmetryConfig(mode: SymmetryMode.off);
                            ref.read(activeToolProvider.notifier).selectTool(DrawingTool.pen);
                            _createNewProject(context, ref, name: 'Character');
                          },
                        ),
                      ]),
                    );
                  },
                ),
              ),

              // ── AdMob Test Banner ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: AdBannerWidget(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ),
      ),
    );
  }

  void _createNewProject(
    BuildContext context,
    WidgetRef ref, {
    String? name,
    int? width,
    int? height,
  }) {
    final preset = ref.read(defaultCanvasSizeProvider);

    // Ensure completely clean blank state:
    ref.read(undoRedoProvider.notifier).clear();
    ref.read(placedImageProvider.notifier).state = null;
    ref.read(symmetryProvider.notifier).state = const SymmetryConfig(mode: SymmetryMode.off);
    ref.read(showGridProvider.notifier).setGrid(false);
    ref.read(drawingGuideProvider.notifier).state = const DrawingGuideConfig();
    ref.read(paperTextureProvider.notifier).state = CanvasPaperTexture.none;
    ref.read(currentStrokeProvider.notifier).state = null;
    ref.read(activeToolProvider.notifier).selectTool(DrawingTool.brush);
    ref.read(canvasViewProvider.notifier).reset();

    ref.read(canvasDocumentProvider.notifier).createNew(
          name: name ?? 'Untitled',
          width: width ?? preset.width,
          height: height ?? preset.height,
        );
    Navigator.of(context)
        .push(IOSPageRoute(builder: (context) => const DrawingScreen()))
        .then((_) {
      ref.read(projectListProvider.notifier).loadProjects();
    });
  }

  Future<void> _openExistingProject(
    BuildContext context,
    WidgetRef ref,
    ProjectEntry entry,
  ) async {
    final doc = await ProjectStorageService.instance.loadProject(entry.id);
    if (doc != null && context.mounted) {
      if (doc.isThumbnail || doc.name.toLowerCase().contains('thumbnail')) {
        ref.read(autoFitToScreenProvider.notifier).state = true;
      }
      ref.read(canvasDocumentProvider.notifier).loadDocument(doc);
      Navigator.of(context)
          .push(IOSPageRoute(builder: (context) => const DrawingScreen()))
          .then((_) {
        ref.read(projectListProvider.notifier).loadProjects();
      });
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// iOS-Style Components
// ─────────────────────────────────────────────────────────────────────────────

/// iOS-style create card with clean design.
class _IOSCreateCard extends StatelessWidget {
  const _IOSCreateCard({
    required this.isDark,
    required this.onNewDrawing,
    required this.onStartColoring,
  });

  final bool isDark;
  final VoidCallback onNewDrawing;
  final VoidCallback onStartColoring;

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0062E6), // Deep Royal Azure
            Color(0xFF007AFF), // Azure Blue
            Color(0xFF00C6FF), // Electric Cyan
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote from Feature Graphic
          Text(
            'Good Ideas Create Brighter Days ♡',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),

          // Main Header matching feature graphic
          Text(
            'Draw Color Art Pro',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Sketch, Paint & Create',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // 4 Feature Pills from graphic
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeaturePill(CupertinoIcons.paintbrush_fill, 'Draw Freely'),
              _buildFeaturePill(CupertinoIcons.drop_fill, 'Vibrant Colors'),
              _buildFeaturePill(CupertinoIcons.square_stack_3d_up, 'Creative Tools'),
              _buildFeaturePill(CupertinoIcons.heart_fill, 'Bring Ideas to Life'),
            ],
          ),

          const SizedBox(height: 18),

          // Action Buttons
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              // New Drawing — iOS filled button
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.button),
                onPressed: onNewDrawing,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.add, size: 16, color: IOSColors.brandPrimary),
                    SizedBox(width: 6),
                    Text(
                      'New Drawing',
                      style: TextStyle(
                        color: IOSColors.brandPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              // Start Coloring — iOS outline button
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                borderRadius: BorderRadius.circular(AppRadius.button),
                onPressed: onStartColoring,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.75),
                      width: 1.4,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.paintbrush, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Coloring Book',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// iOS-style quick actions grid.
class _IOSQuickActionsGrid extends StatelessWidget {
  const _IOSQuickActionsGrid({
    required this.isDark,
    required this.ref,
    required this.context,
  });

  final bool isDark;
  final WidgetRef ref;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? IOSColors.darkSurface : IOSColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadow.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: _IOSQuickAction(
              icon: CupertinoIcons.pencil,
              label: 'Sketch',
              color: IOSColors.brandPrimary,
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(symmetryProvider.notifier).state =
                    const SymmetryConfig(mode: SymmetryMode.off);
                CanvasSizePickerModal.show(context, initialName: 'Sketch');
              },
            ),
          ),
          Expanded(
            child: _IOSQuickAction(
              icon: CupertinoIcons.paintbrush,
              label: 'Color',
              color: IOSColors.systemPink,
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                ColoringTemplatesModal.show(context);
              },
            ),
          ),
          Expanded(
            child: _IOSQuickAction(
              icon: CupertinoIcons.camera,
              label: 'AR Trace',
              color: IOSColors.systemTeal,
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  IOSPageRoute(builder: (_) => const ArTracingScreen()),
                );
              },
            ),
          ),
          Expanded(
            child: _IOSQuickAction(
              icon: CupertinoIcons.folder,
              label: 'Gallery',
              color: IOSColors.systemGreen,
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  IOSPageRoute(builder: (_) => const ProjectManagerScreen()),
                );
              },
            ),
          ),
          Expanded(
            child: _IOSQuickAction(
              icon: CupertinoIcons.play_circle,
              label: 'Continue',
              color: IOSColors.systemOrange,
              isDark: isDark,
              onTap: () async {
                HapticFeedback.lightImpact();
                final projects =
                    ref.read(projectListProvider).valueOrNull ?? [];
                if (projects.isNotEmpty) {
                  final home = context.findAncestorWidgetOfExactType<HomeScreen>();
                  if (home != null && context.mounted) {
                    final doc = await ProjectStorageService.instance
                        .loadProject(projects.first.id);
                    if (doc != null && context.mounted) {
                      if (doc.isThumbnail || doc.name.toLowerCase().contains('thumbnail')) {
                        ref.read(autoFitToScreenProvider.notifier).state = true;
                      }
                      ref.read(canvasDocumentProvider.notifier).loadDocument(doc);
                      Navigator.of(context).push(
                        IOSPageRoute(builder: (_) => const DrawingScreen()),
                      );
                    }
                  }
                } else {
                  ref.read(symmetryProvider.notifier).state =
                      const SymmetryConfig(mode: SymmetryMode.off);
                  final preset = ref.read(defaultCanvasSizeProvider);
                  ref.read(canvasDocumentProvider.notifier).createNew(
                        name: 'Untitled',
                        width: preset.width,
                        height: preset.height,
                      );
                  Navigator.of(context).push(
                    IOSPageRoute(builder: (_) => const DrawingScreen()),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Single quick action in the grid.
class _IOSQuickAction extends StatelessWidget {
  const _IOSQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? IOSColors.systemGray2 : IOSColors.systemGray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// iOS-style section header with optional subtitle and trailing widget.
class _IOSSectionHeader extends StatelessWidget {
  const _IOSSectionHeader({
    required this.title,
    required this.isDark,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final bool isDark;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: IOSColors.brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
              ),
              child: Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: IOSColors.brandPrimary,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// iOS-style feature promo card.
class _IOSFeatureCard extends StatelessWidget {
  const _IOSFeatureCard({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.badge,
  });

  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? IOSColors.darkSurface : IOSColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadow.card,
          border: Border.all(
            color: gradient.first.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: gradient.first,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? IOSColors.systemGray
                          : IOSColors.systemGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: IOSColors.systemGray3,
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS-style empty state.
class _IOSEmptyState extends StatelessWidget {
  const _IOSEmptyState({
    required this.isDark,
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final bool isDark;
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? IOSColors.darkSurface : IOSColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadow.card,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: IOSColors.systemGray3,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: IOSColors.systemGray,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              borderRadius: BorderRadius.circular(AppRadius.button),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS-style recent project card.
class _IOSRecentProjectCard extends StatelessWidget {
  const _IOSRecentProjectCard({
    required this.project,
    required this.ref,
    required this.isDark,
    required this.onTap,
  });

  final ProjectEntry project;
  final WidgetRef ref;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          ProjectActionsBottomSheet.show(context, ref, project);
        },
        child: Container(
          width: 140,
          decoration: BoxDecoration(
            color: isDark ? IOSColors.darkSurface : IOSColors.lightSurface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadow.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.card),
                  ),
                  child: project.thumbnailPath != null &&
                          File(project.thumbnailPath!).existsSync()
                      ? Image.file(File(project.thumbnailPath!),
                          fit: BoxFit.cover)
                      : Container(
                          color: isDark
                              ? IOSColors.darkElevated
                              : IOSColors.systemGray6,
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.paintbrush,
                              size: 28,
                              color: IOSColors.systemGray3,
                            ),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${project.width}×${project.height}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: IOSColors.systemGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS-style coloring template card.
class _IOSTemplateCard extends StatelessWidget {
  const _IOSTemplateCard({
    required this.template,
    required this.isDark,
    required this.onTap,
  });

  final ColoringTemplate template;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: isDark ? IOSColors.darkSurface : IOSColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: TemplateThumbnailWidget(
                          template: template,
                          showBorderAndShadow: false,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Difficulty pill
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        template.difficulty,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.category,
                    style: const TextStyle(
                      fontSize: 11,
                      color: IOSColors.systemGray,
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
}

/// iOS-style creative category card with fully responsive scaling.
class _IOSCreativeCard extends StatelessWidget {
  const _IOSCreativeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 112 || constraints.maxWidth < 145;
          final iconBoxSize = isCompact ? 30.0 : 36.0;
          final iconSize = isCompact ? 15.0 : 18.0;
          final padding = isCompact ? 10.0 : 14.0;
          final titleSize = isCompact ? 13.0 : 15.0;
          final subtitleSize = isCompact ? 10.5 : 12.0;

          return Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: isDark ? IOSColors.darkSurface : IOSColors.lightSurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadow.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Icon(icon, color: color, size: iconSize),
                    ),
                    Icon(
                      CupertinoIcons.arrow_up_right,
                      size: isCompact ? 12 : 14,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: IOSColors.systemGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
