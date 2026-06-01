import 'dart:convert';
import 'package:http/http.dart' as http;

/// SearchService — Pencarian konten edukasi untuk GrowMind.
/// Menggunakan YouTube Data API v3 untuk video dan DuckDuckGo Instant Answer
/// sebagai fallback gratis tanpa API key untuk artikel/buku.
class SearchService {
  // ── YOUTUBE ──────────────────────────────────────────────────────────────────
  // Ganti dengan API key YouTube Data v3 Anda dari Google Cloud Console.
  // Cara mendapatkan: https://console.developers.google.com/
  static const String _ytApiKey = 'YOUR_YOUTUBE_API_KEY_HERE';
  static const String _ytBaseUrl = 'https://www.googleapis.com/youtube/v3';

  /// Mencari video YouTube berdasarkan query. Menambahkan kata kunci
  /// pengembangan diri agar hasil lebih relevan.
  static Future<List<VideoResult>> searchYouTube(String query) async {
    if (query.trim().isEmpty) return [];

    final enrichedQuery = '$query pengembangan diri motivasi';
    final uri = Uri.parse(
      '$_ytBaseUrl/search?part=snippet&q=${Uri.encodeComponent(enrichedQuery)}'
      '&type=video&maxResults=10&relevanceLanguage=id'
      '&key=$_ytApiKey',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return _fallbackVideos(query);

      final data = jsonDecode(response.body);
      final items = data['items'] as List? ?? [];

      return items.map((item) {
        final snippet = item['snippet'];
        final videoId = item['id']['videoId'];
        return VideoResult(
          videoId: videoId,
          title: snippet['title'] ?? '',
          channelName: snippet['channelTitle'] ?? '',
          thumbnail: snippet['thumbnails']['medium']['url'] ?? '',
          description: snippet['description'] ?? '',
          url: 'https://www.youtube.com/watch?v=$videoId',
          publishedAt: snippet['publishedAt'] ?? '',
        );
      }).toList();
    } catch (_) {
      return _fallbackVideos(query);
    }
  }

  // ── ARTIKEL & BUKU ─────────────────────────────────────────────────────────────
  /// Mencari artikel menggunakan DuckDuckGo Instant Answer API (gratis, tanpa key).
  static Future<List<ArticleResult>> searchArticles(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      'https://api.duckduckgo.com/?q=${Uri.encodeComponent(query + " buku pengembangan diri")}'
      '&format=json&no_html=1&skip_disambig=1',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return _fallbackArticles(query);

      final data = jsonDecode(response.body);
      final List<ArticleResult> results = [];

      // Related Topics
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

      // Abstract
      if (data['Abstract'] != null && (data['Abstract'] as String).isNotEmpty) {
        results.insert(0, ArticleResult(
          title: data['Heading'] ?? query,
          description: data['Abstract'] ?? '',
          url: data['AbstractURL'] ?? '',
          source: data['AbstractSource'] ?? 'Wikipedia',
          imageUrl: data['Image'] ?? '',
        ));
      }

      if (results.isEmpty) return _fallbackArticles(query);
      return results;
    } catch (_) {
      return _fallbackArticles(query);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  static String _extractTitle(String text) {
    if (text.length <= 60) return text;
    final parts = text.split(' - ');
    if (parts.length > 1) return parts.first;
    return '${text.substring(0, 57)}...';
  }

  // ── Fallback Data (Kurated) ───────────────────────────────────────────────────
  static List<VideoResult> _fallbackVideos(String query) => [
    VideoResult(
      videoId: 'dQw4w9WgXcQ',
      title: 'Atomic Habits: Cara Membangun Kebiasaan yang Bertahan',
      channelName: 'Otak Produktif',
      thumbnail: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=320',
      description: 'Strategi James Clear tentang perubahan 1% setiap hari yang menciptakan hasil luar biasa.',
      url: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}',
      publishedAt: '',
    ),
    VideoResult(
      videoId: 'abc123',
      title: 'Stoikisme Modern: Cara Tenang di Tengah Kekacauan',
      channelName: 'Filsafat Hidup Praktis',
      thumbnail: 'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=320',
      description: 'Prinsip Marcus Aurelius yang relevan untuk kehidupan digital masa kini.',
      url: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query + " stoik")}',
      publishedAt: '',
    ),
    VideoResult(
      videoId: 'def456',
      title: 'Deep Work: Fokus Total di Era Distraksi',
      channelName: 'Akselerasi Finansial',
      thumbnail: 'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?w=320',
      description: 'Metode Cal Newport untuk mencapai pekerjaan berkualitas tinggi tanpa gangguan.',
      url: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query + " deep work")}',
      publishedAt: '',
    ),
  ];

  static List<ArticleResult> _fallbackArticles(String query) => [
    ArticleResult(
      title: 'Meditations — Marcus Aurelius',
      description: 'Logika kuno tentang membedakan apa yang bisa dikendalikan dan apa yang tidak. '
          'Panduan stoikisme untuk ketahanan mental dan ketenangan batin.',
      url: 'https://en.wikisource.org/wiki/The_Meditations_of_the_Emperor_Marcus_Antoninus',
      source: 'Wikisource (Bebas)',
      imageUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=320',
    ),
    ArticleResult(
      title: 'As a Man Thinketh — James Allen',
      description: 'Bagaimana pola pikir membentuk karakter, kebiasaan, dan kesuksesan finansial masa depan.',
      url: 'https://www.gutenberg.org/ebooks/4507',
      source: 'Project Gutenberg (Gratis)',
      imageUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=320',
    ),
    ArticleResult(
      title: 'The Art of War — Sun Tzu',
      description: 'Strategi menaklukkan diri sendiri dan memenangkan persaingan tanpa merusak kesehatan mental.',
      url: 'https://www.gutenberg.org/ebooks/132',
      source: 'Project Gutenberg (Gratis)',
      imageUrl: 'https://images.unsplash.com/photo-1531988042231-d39a9cc12a9a?w=320',
    ),
  ];
}

// ─── Model Classes ──────────────────────────────────────────────────────────────

class VideoResult {
  final String videoId;
  final String title;
  final String channelName;
  final String thumbnail;
  final String description;
  final String url;
  final String publishedAt;

  VideoResult({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.thumbnail,
    required this.description,
    required this.url,
    required this.publishedAt,
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