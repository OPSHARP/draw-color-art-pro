import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coloring_template.dart';
import '../services/coloring_catalog_service.dart';
import '../services/template_procedural_generator.dart';
import '../../canvas/providers/canvas_providers.dart';
import '../../canvas/views/drawing_screen.dart';
import '../../ar_tracing/views/ar_tracing_screen.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../app.dart';
import '../../canvas/models/tools.dart';
import '../widgets/template_thumbnail_painter.dart';
import 'design_preview_modal.dart';

/// Modal bottom sheet to browse, search, and pick from 1,200+ procedural coloring templates.
class ColoringTemplatesModal extends ConsumerStatefulWidget {
  const ColoringTemplatesModal({super.key, this.onSelectTemplate});

  final void Function(ColoringTemplate template)? onSelectTemplate;

  static void show(BuildContext context, {void Function(ColoringTemplate template)? onSelect}) {
    SoundEffectService.instance.playPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ColoringTemplatesModal(onSelectTemplate: onSelect),
    );
  }

  @override
  ConsumerState<ColoringTemplatesModal> createState() => _ColoringTemplatesModalState();
}

class _ColoringTemplatesModalState extends ConsumerState<ColoringTemplatesModal> {
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';
  String _searchQuery = '';
  bool _onlyFavorites = false;
  final TextEditingController _searchController = TextEditingController();

  List<ColoringTemplate> _filteredTemplates = [];

  @override
  void initState() {
    super.initState();
    _applyFilter();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    setState(() {
      _filteredTemplates = ColoringCatalogService.instance.filter(
        categoryLabel: _selectedCategory,
        difficulty: _selectedDifficulty,
        query: _searchQuery,
        onlyFavorites: _onlyFavorites,
      );
    });
  }

  void _onSurpriseMe() {
    SoundEffectService.instance.playCelebration();
    final randomTemplate = ColoringCatalogService.instance.getRandomTemplate();

    if (widget.onSelectTemplate != null) {
      widget.onSelectTemplate!(randomTemplate);
      return;
    }

    final navigator = Navigator.of(context);
    navigator.pop();
    final doc = randomTemplate.createDocument();
    ref.read(canvasDocumentProvider.notifier).loadDocument(doc);
    ref.read(activeToolProvider.notifier).selectTool(DrawingTool.fill);
    ref.read(autoFitToScreenProvider.notifier).state = true;
    navigator.push(
      IOSPageRoute(builder: (_) => const DrawingScreen()),
    );
  }

  void _startColoring(ColoringTemplate template) {
    SoundEffectService.instance.playCelebration();
    final navigator = Navigator.of(context);
    navigator.pop();

    final doc = template.createDocument();
    ref.read(canvasDocumentProvider.notifier).loadDocument(doc);
    ref.read(activeToolProvider.notifier).selectTool(DrawingTool.fill);
    ref.read(autoFitToScreenProvider.notifier).state = true;

    navigator.push(
      IOSPageRoute(builder: (_) => const DrawingScreen()),
    );
  }

  void _startArTracing(ColoringTemplate template) {
    SoundEffectService.instance.playCelebration();
    final navigator = Navigator.of(context);
    navigator.pop();

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ArTracingScreen(initialTemplate: template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCount = ColoringCatalogService.instance.totalCount;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        children: [
          // ── Drag Handle ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.sm, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFFFA94D)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.palette_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Coloring Book Templates',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$totalCount Unique Designs • 100% Free • Multi-Layer Line-Art',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          ),

          // ── "Surprise Me" Random Hero Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: InkWell(
              onTap: _onSurpriseMe,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFFF7675), Color(0xFFFDCB6E)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.casino_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Surprise Me! (Random Template)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Instant pick from $totalCount unique designs',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Roll', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Search Field ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search 184+ vector designs (e.g. Lotus, Lion, Mandala...)',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _applyFilter();
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) {
                _searchQuery = val;
                _applyFilter();
              },
            ),
          ),

          // ── Categories Horizontal Filter Chips ──
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _buildCategoryChip('All', Icons.apps_rounded),
                _buildFavoritesChip(),
                ...TemplateCategory.values.map((cat) => _buildCategoryChip(cat.label, cat.icon)),
              ],
            ),
          ),

          // ── Difficulty Horizontal Filter Chips ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'Difficulty:',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(width: 6),
                  _buildDifficultyChip('All'),
                  const SizedBox(width: 4),
                  _buildDifficultyChip('Easy'),
                  const SizedBox(width: 4),
                  _buildDifficultyChip('Medium'),
                  const SizedBox(width: 4),
                  _buildDifficultyChip('Detailed'),
                  const SizedBox(width: 12),
                  Text(
                    '(${_filteredTemplates.length} matches)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // ── Templates Grid ──
          Expanded(
            child: _filteredTemplates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No templates found matching "$_searchQuery"',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                        ),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            _selectedCategory = 'All';
                            _selectedDifficulty = 'All';
                            _applyFilter();
                          },
                          child: const Text('Reset Filters'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md + MediaQuery.paddingOf(context).bottom,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                    ),
                    itemCount: _filteredTemplates.length,
                    itemBuilder: (context, index) {
                      final template = _filteredTemplates[index];
                      return _TemplateCard(
                        template: template,
                        onFavoriteChanged: _applyFilter,
                        onColor: () {
                          if (widget.onSelectTemplate != null) {
                            widget.onSelectTemplate!(template);
                          } else {
                            _startColoring(template);
                          }
                        },
                        onTraceAr: () {
                          if (widget.onSelectTemplate != null) {
                            widget.onSelectTemplate!(template);
                          } else {
                            _startArTracing(template);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesChip() {
    final isSelected = _onlyFavorites;
    final favCount = ColoringCatalogService.instance.favoriteIds.length;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        avatar: Icon(
          Icons.favorite_rounded,
          size: 16,
          color: isSelected ? Colors.white : const Color(0xFFFF6B9D),
        ),
        label: Text('Favorites ($favCount)'),
        selected: isSelected,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
        selectedColor: const Color(0xFFFF6B9D),
        checkmarkColor: Colors.white,
        showCheckmark: false,
        onSelected: (selected) {
          SoundEffectService.instance.playPop();
          setState(() {
            _onlyFavorites = selected;
            if (selected) {
              _selectedCategory = 'All';
            }
            _applyFilter();
          });
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final isSelected = !_onlyFavorites && _selectedCategory == label;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : theme.colorScheme.primary,
        ),
        label: Text(label),
        selected: isSelected,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
        selectedColor: theme.colorScheme.primary,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        onSelected: (selected) {
          SoundEffectService.instance.playPop();
          setState(() {
            _onlyFavorites = false;
            _selectedCategory = label;
            _applyFilter();
          });
        },
      ),
    );
  }

  Widget _buildDifficultyChip(String diff) {
    final isSelected = _selectedDifficulty == diff;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        SoundEffectService.instance.playPop();
        setState(() {
          _selectedDifficulty = diff;
          _applyFilter();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          diff,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : theme.textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatefulWidget {
  const _TemplateCard({
    required this.template,
    required this.onColor,
    required this.onTraceAr,
    this.onFavoriteChanged,
  });

  final ColoringTemplate template;
  final VoidCallback onColor;
  final VoidCallback onTraceAr;
  final VoidCallback? onFavoriteChanged;

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
  late bool _isFav;

  @override
  void initState() {
    super.initState();
    _isFav = ColoringCatalogService.instance.isFavorite(widget.template.id);
  }

  @override
  void didUpdateWidget(_TemplateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.template.id != widget.template.id) {
      _isFav = ColoringCatalogService.instance.isFavorite(widget.template.id);
    }
  }

  void _toggleFav() {
    SoundEffectService.instance.playPop();
    setState(() {
      _isFav = ColoringCatalogService.instance.toggleFavorite(widget.template.id);
    });
    widget.onFavoriteChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final template = widget.template;

    return InkWell(
      onTap: () {
        DesignPreviewModal.show(context, template: template);
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? const Color(0xFF33334F) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          color: isDark ? const Color(0xFF1E1E34) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Real Vector Thumbnail Preview on Clean Paper Canvas ──
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: TemplateThumbnailWidget(
                        template: template,
                        backgroundColor: Colors.white,
                        showBorderAndShadow: true,
                      ),
                    ),
                  ),
                  // Favorite Heart Button
                  Positioned(
                    top: 5,
                    left: 5,
                    child: GestureDetector(
                      onTap: _toggleFav,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 13,
                          color: _isFav ? const Color(0xFFFF6B9D) : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  // Difficulty Badge
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        template.difficulty,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              template.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              template.category,
              style: theme.textTheme.labelSmall?.copyWith(
                color: template.gradient.first,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Dual Action Buttons: Color & AR Trace
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      DesignPreviewModal.show(context, template: template);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    icon: const Icon(Icons.brush_rounded, size: 12),
                    label: const Text('Color', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: widget.onTraceAr,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.4)),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Color(0xFF6C5CE7),
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
