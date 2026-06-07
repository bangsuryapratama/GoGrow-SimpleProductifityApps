import 'dart:convert';
import 'package:http/http.dart' as http;

/// SearchService — Pencarian konten edukasi untuk GrowMind.
/// Menggunakan Invidious API (YouTube proxy gratis, tanpa API key)
/// dan DuckDuckGo Instant Answer untuk artikel.
class SearchService {
  // ── INVIDIOUS INSTANCES (fallback chain jika satu down) ─────────────────────
  static const List<String> _invidiousInstances = [
    'https://invidious.privacyredirect.com',
    'https://inv.nadeko.net',
    'https://yt.artemislena.eu',
  ];

  // Simple in-memory cache
  static final Map<String, List<VideoResult>> _videoCache = {};
  static final Map<String, List<ArticleResult>> _articleCache = {};

  // ── YOUTUBE VIA INVIDIOUS ────────────────────────────────────────────────────
  static Future<List<VideoResult>> searchYouTube(String query, {String? category}) async {
    if (query.trim().isEmpty) return [];

    final cacheKey = '${query}_${category ?? ""}';
    if (_videoCache.containsKey(cacheKey)) return _videoCache[cacheKey]!;

    final enrichedQuery = category != null
        ? '$query $category pengembangan diri'
        : '$query pengembangan diri self improvement';

    for (final instance in _invidiousInstances) {
      try {
        final uri = Uri.parse(
          '$instance/api/v1/search?q=${Uri.encodeComponent(enrichedQuery)}'
          '&type=video&sort_by=relevance&page=1',
        );
        final response = await http.get(uri, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 8));

        if (response.statusCode != 200) continue;

        final List<dynamic> items = jsonDecode(response.body);
        if (items.isEmpty) continue;

        final results = items.take(12).map((item) {
          final videoId = item['videoId'] as String? ?? '';
          final thumbnails = item['videoThumbnails'] as List? ?? [];
          final thumb = thumbnails.isNotEmpty
              ? (thumbnails.firstWhere((t) => t['quality'] == 'medium',
                      orElse: () => thumbnails.first)['url'] as String? ?? '')
              : '';
          final duration = item['lengthSeconds'] as int? ?? 0;
          final durationStr = duration > 0
              ? '${duration ~/ 60}:${(duration % 60).toString().padLeft(2, '0')}'
              : '';
          return VideoResult(
            videoId: videoId,
            title: item['title'] as String? ?? '',
            channelName: item['author'] as String? ?? '',
            thumbnail: thumb.startsWith('//') ? 'https:$thumb' : thumb,
            description: item['description'] as String? ?? '',
            url: 'https://www.youtube.com/watch?v=$videoId',
            publishedAt: '',
            duration: durationStr,
            viewCount: item['viewCount'] as int? ?? 0,
          );
        }).toList();

        _videoCache[cacheKey] = results;
        return results;
      } catch (_) {
        continue; // try next instance
      }
    }

    // All instances failed → gunakan curated fallback
    return _fallbackVideos(query);
  }

  // ── ARTIKEL VIA DUCKDUCKGO ──────────────────────────────────────────────────
  static Future<List<ArticleResult>> searchArticles(String query) async {
    if (query.trim().isEmpty) return [];

    if (_articleCache.containsKey(query)) return _articleCache[query]!;

    final uri = Uri.parse(
      'https://api.duckduckgo.com/?q=${Uri.encodeComponent("$query pengembangan diri")}'
      '&format=json&no_html=1&skip_disambig=1',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return _fallbackArticles(query);

      final data = jsonDecode(response.body);
      final List<ArticleResult> results = [];

      if (data['Abstract'] != null && (data['Abstract'] as String).isNotEmpty) {
        results.insert(0, ArticleResult(
          title: data['Heading'] ?? query,
          description: data['Abstract'] ?? '',
          url: data['AbstractURL'] ?? '',
          source: data['AbstractSource'] ?? 'Wikipedia',
          imageUrl: data['Image'] ?? '',
        ));
      }

      final relatedTopics = data['RelatedTopics'] as List? ?? [];
      for (final topic in relatedTopics.take(6)) {
        if (topic is Map && topic['Text'] != null) {
          results.add(ArticleResult(
            title: _extractTitle(topic['Text'] ?? ''),
            description: topic['Text'] ?? '',
            url: topic['FirstURL'] ?? '',
            source: 'DuckDuckGo',
            imageUrl: topic['Icon']?['URL'] ?? '',
          ));
        }
      }

      if (results.isEmpty) return _fallbackArticles(query);
      _articleCache[query] = results;
      return results;
    } catch (_) {
      return _fallbackArticles(query);
    }
  }

  // ── Trending / Featured ─────────────────────────────────────────────────────
  /// Konten unggulan berdasarkan kategori fokus user
  static List<VideoResult> getFeaturedByGoal(String goal) {
    final goalMap = {
      'productivity': _fallbackVideos('deep work produktivitas'),
      'health': _fallbackVideos('olahraga kesehatan mental'),
      'learning': _fallbackVideos('belajar buku self improvement'),
      'mindfulness': _fallbackVideos('meditasi stoik mindfulness'),
      'finance': _fallbackVideos('investasi finansial kebebasan'),
    };
    return goalMap[goal] ?? _fallbackVideos('pengembangan diri');
  }

  static String _extractTitle(String text) {
    if (text.length <= 60) return text;
    final parts = text.split(' - ');
    if (parts.length > 1) return parts.first;
    return '${text.substring(0, 57)}...';
  }

  // ── Curated Fallback ────────────────────────────────────────────────────────
  static List<VideoResult> _fallbackVideos(String query) => [
    VideoResult(
      videoId: 'dK9BNWTb8M4',
      title: 'Atomic Habits: Cara Membangun Kebiasaan yang Bertahan',
      channelName: 'Otak Produktif',
      thumbnail: 'https://i.ytimg.com/vi/dK9BNWTb8M4/mqdefault.jpg',
      description: 'Strategi James Clear tentang perubahan 1% setiap hari.',
      url: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}',
      publishedAt: '',
      duration: '12:34',
      viewCount: 0,
    ),
    VideoResult(
      videoId: 'WD440CY2vak',
      title: 'Stoikisme Modern: Cara Tenang di Tengah Kekacauan',
      channelName: 'Filsafat Hidup',
      thumbnail: 'https://i.ytimg.com/vi/WD440CY2vak/mqdefault.jpg',
      description: 'Prinsip Marcus Aurelius yang relevan untuk kehidupan digital.',
      url: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent("$query stoik")}',
      publishedAt: '',
      duration: '8:20',
      viewCount: 0,
    ),
    VideoResult(
      videoId: 'ZD7dXfdDPfg',
      title: 'Deep Work: Fokus Total di Era Distraksi',
      channelName: 'Akselerasi Diri',
      thumbnail: 'https://i.ytimg.com/vi/ZD7dXfdDPfg/mqdefault.jpg',
      description: 'Metode Cal Newport untuk mencapai pekerjaan berkualitas tanpa gangguan.',
      url: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent("$query deep work")}',
      publishedAt: '',
      duration: '15:02',
      viewCount: 0,
    ),
  ];

  static List<ArticleResult> _fallbackArticles(String query) => [
    ArticleResult(
      title: 'Meditations — Marcus Aurelius',
      description: 'Panduan stoikisme untuk ketahanan mental dan ketenangan batin. Logika kuno tentang apa yang bisa dikendalikan.',
      url: 'https://en.wikisource.org/wiki/The_Meditations_of_the_Emperor_Marcus_Antoninus',
      source: 'Wikisource (Gratis)',
      imageUrl: '',
    ),
    ArticleResult(
      title: 'As a Man Thinketh — James Allen',
      description: 'Bagaimana pola pikir membentuk karakter, kebiasaan, dan kesuksesan masa depan.',
      url: 'https://www.gutenberg.org/ebooks/4507',
      source: 'Project Gutenberg (Gratis)',
      imageUrl: '',
    ),
    ArticleResult(
      title: 'The Obstacle Is the Way — Ryan Holiday',
      description: 'Cara mengubah hambatan menjadi keberhasilan dengan filosofi Stoic modern.',
      url: 'https://en.wikipedia.org/wiki/The_Obstacle_Is_the_Way',
      source: 'Wikipedia',
      imageUrl: '',
    ),
  ];
}

// ─── Model Classes ─────────────────────────────────────────────────────────────
class VideoResult {
  final String videoId;
  final String title;
  final String channelName;
  final String thumbnail;
  final String description;
  final String url;
  final String publishedAt;
  final String duration;
  final int viewCount;

  VideoResult({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.thumbnail,
    required this.description,
    required this.url,
    required this.publishedAt,
    this.duration = '',
    this.viewCount = 0,
  });
}

class ArticleResult {
  final String title;
  final String description;
  final String url;
  final String source;
  final String imageUrl;

  ArticleResult({
    required this.title,
    required this.description,
    required this.url,
    required this.source,
    required this.imageUrl,
  });
}