import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Represents a single image result from the search API.
class SearchImageResult {
  const SearchImageResult({
    required this.id,
    required this.thumbUrl,
    required this.regularUrl,
    required this.fullUrl,
    required this.photographer,
    required this.photographerUrl,
    required this.description,
    required this.width,
    required this.height,
  });

  final String id;
  final String thumbUrl;
  final String regularUrl;
  final String fullUrl;
  final String photographer;
  final String photographerUrl;
  final String description;
  final int width;
  final int height;

  double get aspectRatio => width / height;

  factory SearchImageResult.fromPexelsJson(Map<String, dynamic> photo) {
    final src = photo['src'] as Map<String, dynamic>? ?? {};
    return SearchImageResult(
      id: photo['id'].toString(),
      thumbUrl: src['small'] as String? ?? src['tiny'] as String? ?? src['medium'] as String? ?? '',
      regularUrl: src['medium'] as String? ?? src['large'] as String? ?? '',
      fullUrl: src['original'] as String? ?? src['large2x'] as String? ?? '',
      photographer: photo['photographer'] as String? ?? 'Unknown',
      photographerUrl: photo['photographer_url'] as String? ?? '',
      description: photo['alt'] as String? ?? '',
      width: photo['width'] as int? ?? 1920,
      height: photo['height'] as int? ?? 1080,
    );
  }
}

/// Service for searching free stock images using Pexels API.
///
/// Pexels is used because it provides a generous free tier and
/// no API key is required for evaluation (fallback to curated endpoint).
/// For production, set your API key via [ImageSearchService.apiKey].
class ImageSearchService {
  ImageSearchService._();
  static final ImageSearchService instance = ImageSearchService._();

  /// Set your Pexels API key here.
  /// Get one for free at https://www.pexels.com/api/
  static String apiKey = '';

  static const String _baseUrl = 'https://api.pexels.com/v1';

  Map<String, String> get _headers => {
    'Authorization': apiKey,
  };

  /// Search images by query string.
  Future<List<SearchImageResult>> searchImages(
    String query, {
    int page = 1,
    int perPage = 30,
  }) async {
    if (apiKey.isEmpty) {
      return _getFallbackResults(query);
    }

    try {
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'query': query,
          'page': page.toString(),
          'per_page': perPage.toString(),
          'orientation': 'landscape',
        },
      );

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final photos = data['photos'] as List? ?? [];
        return photos.map((p) => _parsePhoto(p as Map<String, dynamic>)).toList();
      } else {
        if (kDebugMode) {
          debugPrint('ImageSearchService: API error ${response.statusCode}');
        }
        return _getFallbackResults(query);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ImageSearchService: Network error: $e');
      }
      return _getFallbackResults(query);
    }
  }

  /// Get curated / trending images.
  Future<List<SearchImageResult>> getCuratedImages({
    int page = 1,
    int perPage = 20,
  }) async {
    if (apiKey.isEmpty) {
      return _getFallbackResults('nature');
    }

    try {
      final uri = Uri.parse('$_baseUrl/curated').replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final photos = data['photos'] as List? ?? [];
        return photos.map((p) => _parsePhoto(p as Map<String, dynamic>)).toList();
      } else {
        return _getFallbackResults('nature');
      }
    } catch (e) {
      debugPrint('ImageSearchService: Network error: $e');
      return _getFallbackResults('nature');
    }
  }

  SearchImageResult _parsePhoto(Map<String, dynamic> photo) {
    final src = photo['src'] as Map<String, dynamic>? ?? {};
    return SearchImageResult(
      id: photo['id'].toString(),
      thumbUrl: src['small'] as String? ?? src['tiny'] as String? ?? '',
      regularUrl: src['medium'] as String? ?? src['large'] as String? ?? '',
      fullUrl: src['original'] as String? ?? src['large2x'] as String? ?? '',
      photographer: photo['photographer'] as String? ?? 'Unknown',
      photographerUrl: photo['photographer_url'] as String? ?? '',
      description: photo['alt'] as String? ?? '',
      width: photo['width'] as int? ?? 1920,
      height: photo['height'] as int? ?? 1080,
    );
  }

  /// Fallback: Generate placeholder image URLs using Lorem Picsum (no API key needed).
  List<SearchImageResult> _getFallbackResults(String query) {
    final categories = <String, List<int>>{
      'nature': [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21],
      'business': [180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191],
      'technology': [60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71],
      'people': [64, 65, 91, 92, 177, 219, 237, 275, 338, 342, 349, 399],
      'food': [292, 312, 326, 376, 429, 431, 488, 493, 999, 1041, 1060, 1080],
      'architecture': [101, 104, 164, 165, 199, 256, 260, 274, 313, 366, 368, 388],
      'abstract': [24, 47, 48, 59, 80, 130, 135, 139, 201, 250, 278, 281],
    };

    // Find a matching category or fallback to generic IDs
    final ids = categories.entries
        .firstWhere(
          (e) => query.toLowerCase().contains(e.key),
          orElse: () => MapEntry('default', List.generate(12, (i) => (i + 1) * 50)),
        )
        .value;

    return ids.map((id) => SearchImageResult(
      id: 'picsum_$id',
      thumbUrl: 'https://picsum.photos/id/$id/300/200',
      regularUrl: 'https://picsum.photos/id/$id/800/600',
      fullUrl: 'https://picsum.photos/id/$id/1920/1080',
      photographer: 'Lorem Picsum',
      photographerUrl: 'https://picsum.photos',
      description: '$query image #$id',
      width: 1920,
      height: 1080,
    )).toList();
  }
}
