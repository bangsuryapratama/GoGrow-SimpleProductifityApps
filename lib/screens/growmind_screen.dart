import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/search_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class GrowMindScreen extends StatefulWidget {
  const GrowMindScreen({super.key});
  @override
  State<GrowMindScreen> createState() => _GrowMindScreenState();
}

class _GrowMindScreenState extends State<GrowMindScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  // YouTube state
  List<VideoResult> _videos = [];
  bool _ytLoading = false;
  String _ytQuery = 'pengembangan diri motivasi';

  // TikTok WebView
  WebViewController? _tikTokController;
  bool _tikTokLoaded = false;
  String _tikTokTopic = 'pengembangandir';

  // Article state
  List<ArticleResult> _articles = [];
  bool _artLoading = false;

  // Category
  String _activeCategory = 'Semua';

  static const List<Map<String, dynamic>> _categories = [
    {'id': 'Semua', 'icon': Icons.apps_rounded, 'color': AppTheme.accent, 'tiktok': 'selfimprovement', 'yt': 'pengembangan diri motivasi'},
    {'id': 'Produktivitas', 'icon': Icons.bolt_rounded, 'color': AppTheme.warning, 'tiktok': 'produktivitas', 'yt': 'produktivitas deep work'},
    {'id': 'Mindfulness', 'icon': Icons.spa_rounded, 'color': AppTheme.cyan, 'tiktok': 'mindfulness', 'yt': 'meditasi mindfulness stoik'},
    {'id': 'Belajar', 'icon': Icons.menu_book_rounded, 'color': AppTheme.blue, 'tiktok': 'belajar', 'yt': 'belajar efektif buku rekomendasi'},
    {'id': 'Finansial', 'icon': Icons.trending_up_rounded, 'color': AppTheme.purple, 'tiktok': 'investasi', 'yt': 'investasi keuangan finansial'},
    {'id': 'Kesehatan', 'icon': Icons.favorite_rounded, 'color': AppTheme.danger, 'tiktok': 'kesehatanmental', 'yt': 'kesehatan mental olahraga'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
      if (_tabController.index == 1 && !_tikTokLoaded) {
        _initTikTok();
      }
    });
    _loadYouTube(_ytQuery);
    _loadArticles('pengembangan diri');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initTikTok() {
    final url = 'https://www.tiktok.com/search?q=%23$_tikTokTopic';
    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF080B10))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _tikTokLoaded = true);
          // Inject dark background CSS
          _tikTokController?.runJavaScript(
            "document.body.style.backgroundColor='#080B10';"
          );
        },
      ))
      ..loadRequest(Uri.parse(url));
    setState(() {
      _tikTokController = ctrl;
    });
  }

  Future<void> _loadYouTube(String query) async {
    setState(() => _ytLoading = true);
    try {
      final cat = _activeCategory == 'Semua' ? null : _activeCategory;
      final results = await SearchService.searchYouTube(query, category: cat);
      if (mounted) setState(() { _videos = results; _ytLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _ytLoading = false);
    }
  }

  Future<void> _loadArticles(String query) async {
    setState(() => _artLoading = true);
    try {
      final results = await SearchService.searchArticles(query);
      if (mounted) setState(() { _articles = results; _artLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _artLoading = false);
    }
  }

  void _onCategoryTap(Map<String, dynamic> cat) {
    setState(() => _activeCategory = cat['id'] as String);
    HapticFeedback.selectionClick();
    final ytQ = cat['yt'] as String;
    final tikTokTag = cat['tiktok'] as String;
    _ytQuery = ytQ;
    _tikTokTopic = tikTokTag;
    _loadYouTube(ytQ);
    _loadArticles(ytQ);

    if (_tabController.index == 1) {
      _tikTokController?.loadRequest(
        Uri.parse('https://www.tiktok.com/search?q=%23$tikTokTag')
      );
    }
  }

  void _onSearch(String q) {
    if (q.trim().isEmpty) return;
    _ytQuery = q;
    _loadYouTube(q);
    _loadArticles(q);
    if (_tabController.index == 1 && _tikTokController != null) {
      _tikTokController!.loadRequest(
        Uri.parse('https://www.tiktok.com/search?q=${Uri.encodeComponent(q)}')
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _toggleBookmark(String type, String title, String url, String thumb, String source) {
    final bookmarks = StorageService.getBookmarks();
    final isBookmarked = StorageService.isBookmarked(url);
    if (isBookmarked) {
      StorageService.removeBookmark(url);
    } else {
      StorageService.addBookmark({'type': type, 'title': title, 'url': url, 'thumbnail': thumb, 'source': source});
    }
    HapticFeedback.selectionClick();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.purpleGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          boxShadow: AppTheme.glowShadow(AppTheme.purple, blur: 16),
                        ),
                        child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GrowMind', style: AppTheme.headingMedium),
                          Text('Konten pengembangan dirimu', style: AppTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          onSubmitted: _onSearch,
                          decoration: InputDecoration(
                            hintText: 'Cari topik, channel, buku...',
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () { _searchCtrl.clear(); setState(() {}); },
                                    child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _onSearch(_searchCtrl.text),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppTheme.purpleGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            boxShadow: AppTheme.glowShadow(AppTheme.purple, blur: 10),
                          ),
                          child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Category Chips ──────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isSel = _activeCategory == cat['id'];
                  final color = cat['color'] as Color;
                  return GestureDetector(
                    onTap: () => _onCategoryTap(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? color.withValues(alpha: 0.15) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSel ? color : AppTheme.borderSubtle, width: isSel ? 1.5 : 1),
                        boxShadow: isSel ? AppTheme.glowShadow(color, blur: 8) : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat['icon'] as IconData, size: 13, color: isSel ? color : AppTheme.textMuted),
                          const SizedBox(width: 5),
                          Text(cat['id'] as String,
                            style: TextStyle(
                              color: isSel ? color : AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Tab Bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    gradient: AppTheme.purpleGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textMuted,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  tabs: const [
                    Tab(icon: Icon(Icons.play_circle_outline_rounded, size: 16), text: 'YouTube'),
                    Tab(icon: Icon(Icons.music_note_rounded, size: 16), text: 'TikTok'),
                    Tab(icon: Icon(Icons.article_outlined, size: 16), text: 'Artikel'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Content ──────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildYouTubeTab(),
                  _buildTikTokTab(),
                  _buildArticleTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── YouTube Tab ────────────────────────────────────────────────────────────
  Widget _buildYouTubeTab() {
    if (_ytLoading) return _buildShimmerList();
    if (_videos.isEmpty) {
      return EmptyState(
        icon: Icons.video_library_outlined,
        message: 'Tidak ada video ditemukan',
        subtitle: 'Coba kata kunci lain',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _videos.length,
      itemBuilder: (_, i) => _buildVideoCard(_videos[i], i),
    );
  }

  Widget _buildVideoCard(VideoResult v, int index) {
    final isBookmarked = StorageService.isBookmarked(v.url);
    return TweenAnimationBuilder<double>(
      key: Key('v_$index'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + index * 40),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 12 * (1 - val)), child: child)),
      child: GestureDetector(
        onTap: () => _openUrl(v.url),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusL),
                  bottomLeft: Radius.circular(AppTheme.radiusL),
                ),
                child: Stack(
                  children: [
                    NetImage(v.thumbnail, width: 116, height: 80, fit: BoxFit.cover),
                    // Duration
                    if (v.duration.isNotEmpty)
                      Positioned(bottom: 4, right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(4)),
                          child: Text(v.duration, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    // Play overlay
                    Positioned.fill(child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                      ),
                    )),
                  ],
                ),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.play_circle_filled_rounded, color: AppTheme.danger, size: 11),
                          const SizedBox(width: 3),
                          Expanded(child: Text(v.channelName, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: AppTheme.captionStyle)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Bookmark
              GestureDetector(
                onTap: () => _toggleBookmark('video', v.title, v.url, v.thumbnail, v.channelName),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
                  child: Icon(
                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    color: isBookmarked ? AppTheme.accent : AppTheme.textMuted,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TikTok Tab ─────────────────────────────────────────────────────────────
  Widget _buildTikTokTab() {
    if (_tikTokController == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.purpleGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.glowShadow(AppTheme.purple, blur: 24),
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Buka TikTok Self-Development', style: AppTheme.headingSmall),
            const SizedBox(height: 8),
            Text('Konten #pengembangandir langsung\ndi dalam app', style: AppTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () { _tabController.animateTo(1); _initTikTok(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  boxShadow: AppTheme.glowShadow(AppTheme.purple, blur: 16),
                ),
                child: const Text('Buka TikTok', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _tikTokController!),
        // Topic quick-switch bar
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            color: AppTheme.bg.withValues(alpha: 0.9),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _tikTokChip('pengembangan diri', 'selfimprovement'),
                  _tikTokChip('motivasi', 'motivasi'),
                  _tikTokChip('produktivitas', 'produktivitas'),
                  _tikTokChip('mindfulness', 'mindfulness'),
                  _tikTokChip('investasi', 'investasi'),
                  _tikTokChip('belajar', 'belajar'),
                ],
              ),
            ),
          ),
        ),
        if (!_tikTokLoaded)
          Container(
            color: AppTheme.bg,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 36, height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.purple)),
                  const SizedBox(height: 16),
                  Text('Memuat TikTok...', style: AppTheme.bodyMedium),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _tikTokChip(String label, String tag) {
    return GestureDetector(
      onTap: () {
        _tikTokController?.loadRequest(Uri.parse('https://www.tiktok.com/search?q=%23$tag'));
        setState(() { _tikTokLoaded = false; _tikTokTopic = tag; });
        HapticFeedback.selectionClick();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: _tikTokTopic == tag ? AppTheme.purpleDim : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _tikTokTopic == tag ? AppTheme.purple : AppTheme.borderSubtle),
        ),
        child: Text('#$label', style: TextStyle(
          color: _tikTokTopic == tag ? AppTheme.purple : AppTheme.textSecondary,
          fontSize: 11, fontWeight: FontWeight.w600,
        )),
      ),
    );
  }

  // ── Article Tab ────────────────────────────────────────────────────────────
  Widget _buildArticleTab() {
    if (_artLoading) return _buildShimmerList();
    if (_articles.isEmpty) {
      return EmptyState(icon: Icons.article_outlined, message: 'Tidak ada artikel', subtitle: 'Coba kata kunci lain');
    }

    // Add bookmarks section at top
    final bookmarks = StorageService.getBookmarks();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (bookmarks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('TERSIMPAN', style: AppTheme.labelSmall),
          ),
          ...bookmarks.take(3).map((b) => _buildArticleCard(
            ArticleResult(title: b['title'] ?? '', description: '', url: b['url'] ?? '', source: b['source'] ?? '', imageUrl: ''),
            -1, isBookmarked: true,
          )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('ARTIKEL & BUKU', style: AppTheme.labelSmall),
          ),
        ],
        ..._articles.asMap().entries.map((e) => _buildArticleCard(e.value, e.key)),
      ],
    );
  }

  Widget _buildArticleCard(ArticleResult a, int index, {bool isBookmarked = false}) {
    if (a.title.isEmpty) return const SizedBox.shrink();
    final bookmarked = isBookmarked || StorageService.isBookmarked(a.url);
    return GestureDetector(
      onTap: () => _openUrl(a.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: AppTheme.purpleDim, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.article_rounded, color: AppTheme.purple, size: 12),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(a.source, style: AppTheme.captionStyle.copyWith(color: AppTheme.purple))),
                GestureDetector(
                  onTap: () => _toggleBookmark('article', a.title, a.url, '', a.source),
                  child: Icon(bookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    color: bookmarked ? AppTheme.accent : AppTheme.textMuted, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(a.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            if (a.description.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(a.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: AppTheme.bodySmall.copyWith(height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
    children: List.generate(5, (i) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ShimmerLoading(width: 116, height: 80, radius: AppTheme.radiusL),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShimmerLoading(width: double.infinity, height: 14),
            const SizedBox(height: 6),
            ShimmerLoading(width: 140, height: 12),
          ])),
        ],
      ),
    )),
  );
}