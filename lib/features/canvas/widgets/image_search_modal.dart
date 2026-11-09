import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/tools.dart';
import '../providers/canvas_providers.dart';
import '../providers/image_import_providers.dart';
import '../services/image_search_service.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// Full-screen modal for searching free stock images and importing them to the canvas.
class ImageSearchModal extends ConsumerStatefulWidget {
  const ImageSearchModal({super.key});

  static void show(BuildContext context) {
    SoundEffectService.instance.playPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ImageSearchModal(),
    );
  }

  @override
  ConsumerState<ImageSearchModal> createState() => _ImageSearchModalState();
}

class _ImageSearchModalState extends ConsumerState<ImageSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchImageResult> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _selectedCategory = 'trending';
  Timer? _debounce;

  static const _categories = [
    ('trending', Icons.trending_up_rounded, 'Trending'),
    ('nature', Icons.landscape_rounded, 'Nature'),
    ('business', Icons.business_center_rounded, 'Business'),
    ('technology', Icons.devices_rounded, 'Technology'),
    ('people', Icons.people_rounded, 'People'),
    ('food', Icons.restaurant_rounded, 'Food'),
    ('architecture', Icons.apartment_rounded, 'Architecture'),
    ('abstract', Icons.auto_awesome_rounded, 'Abstract'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurated();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCurated() async {
    setState(() => _isLoading = true);
    try {
      final results = await ImageSearchService.instance.getCuratedImages();
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchImages(String query) async {
    if (query.trim().isEmpty) {
      _loadCurated();
      return;
    }
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    try {
      final results = await ImageSearchService.instance.searchImages(query.trim());
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchImages(value);
    });
  }

  void _onCategoryTap(String category) {
    SoundEffectService.instance.playPop();
    setState(() => _selectedCategory = category);
    if (category == 'trending') {
      _searchController.clear();
      _loadCurated();
    } else {
      _searchController.text = category;
      _searchImages(category);
    }
  }

  Future<void> _importImage(SearchImageResult image) async {
    HapticFeedback.mediumImpact();
    SoundEffectService.instance.playWhoosh();

    // Show loading indicator
    if (!mounted) return;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoActivityIndicator(radius: 16),
                SizedBox(height: 12),
                Text('Downloading image...', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Download the image
      final response = await http.get(Uri.parse(image.regularUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        if (mounted) {
          nav.pop(); // dismiss dialog
          messenger.showSnackBar(
            const SnackBar(content: Text('Failed to download image. Please try again.')),
          );
        }
        return;
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/search_${image.id}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Decode the image
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;

      // Get canvas document size for positioning
      final doc = ref.read(canvasDocumentProvider);
      final imgW = uiImage.width.toDouble();
      final imgH = uiImage.height.toDouble();

      // Scale to fit canvas (max 80% of canvas dimensions)
      final maxW = doc.width * 0.8;
      final maxH = doc.height * 0.8;
      final scale = (imgW / maxW > imgH / maxH) ? maxW / imgW : maxH / imgH;
      final finalW = imgW * (scale < 1.0 ? scale : 1.0);
      final finalH = imgH * (scale < 1.0 ? scale : 1.0);

      // Center on canvas
      final posX = (doc.width - finalW) / 2;
      final posY = (doc.height - finalH) / 2;

      // Place the image via existing flow
      ref.read(placedImageProvider.notifier).state = PlacedImageData(
        file: file,
        path: filePath,
        image: uiImage,
        position: Offset(posX, posY),
        size: Size(finalW, finalH),
      );

      ref.read(activeToolProvider.notifier).selectTool(DrawingTool.image);

      if (mounted) {
        nav.pop(); // dismiss loading
        nav.pop(); // dismiss search modal
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ImageSearchModal: Import failed: $e');
      }
      if (mounted) {
        nav.pop(); // dismiss loading
        messenger.showSnackBar(
          const SnackBar(content: Text('Failed to import image. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.92,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18182E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        children: [
          // ── Drag Handle ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.sm, 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.image_search_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Free Stock Images',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Search and import beautiful images',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search images...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _loadCurated();
                        },
                        icon: const Icon(Icons.clear_rounded, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF22223D) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // ── Category Chips ──
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final (key, icon, label) = _categories[index];
                final isSelected = _selectedCategory == key;
                return GestureDetector(
                  onTap: () => _onCategoryTap(key),
                  child: AnimatedContainer(
                    duration: AppAnimation.standard,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00B894)
                          : (isDark ? const Color(0xFF22223D) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00B894)
                            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Results Grid ──
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator(radius: 14))
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _hasSearched ? Icons.search_off_rounded : Icons.image_search_rounded,
                              size: 48,
                              color: isDark ? Colors.white30 : const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _hasSearched ? 'No images found' : 'Search for images to get started',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final img = _results[index];
                          return _ImageResultCard(
                            image: img,
                            isDark: isDark,
                            onImport: () => _importImage(img),
                          );
                        },
                      ),
          ),

          // ── Attribution Footer ──
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              MediaQuery.paddingOf(context).bottom > 0
                  ? MediaQuery.paddingOf(context).bottom + AppSpacing.xs
                  : AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18182E) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 14,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text(
                  'Images provided by Pexels · Free to use',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual image result card with hover effect and import button.
class _ImageResultCard extends StatelessWidget {
  const _ImageResultCard({
    required this.image,
    required this.isDark,
    required this.onImport,
  });

  final SearchImageResult image;
  final bool isDark;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          CachedNetworkImage(
            imageUrl: image.thumbUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: isDark ? const Color(0xFF22223D) : const Color(0xFFF1F5F9),
              child: const Center(child: CupertinoActivityIndicator(radius: 10)),
            ),
            errorWidget: (_, __, ___) => Container(
              color: isDark ? const Color(0xFF22223D) : const Color(0xFFF1F5F9),
              child: Icon(
                Icons.broken_image_rounded,
                color: isDark ? Colors.white30 : const Color(0xFFCBD5E1),
              ),
            ),
          ),

          // Gradient overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      image.photographer,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: onImport,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B894),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'Use',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
