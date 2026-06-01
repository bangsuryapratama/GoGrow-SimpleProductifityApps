import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/search_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class GrowMindScreen extends StatefulWidget {
  const GrowMindScreen({super.key});

  @override
  State<GrowMindScreen> createState() => _GrowMindScreenState();
}

class _GrowMindScreenState extends State<GrowMindScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<VideoResult> _videos = [];
  List<ArticleResult> _articles = [];

  bool _loadingVideos = false;
  bool _loadingArticles = false;
  bool _hasSearched = false;
  String _lastQuery = '';

  // Kurated topics untuk chips
  static const List<String> _suggestedTopics = [
    'Stoikisme', 'Atomic Habits', 'Deep Work', 'Mindset',
    'Produktivitas', 'Meditasi', 'Growth Mindset', 'Keuangan',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChange);
    // Load konten awal
    _performSearch('pengembangan diri');
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging && _lastQuery.isNotEmpty) {
      // Tidak perlu re-search, data sudah di-load
    }
  }

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    _lastQuery = q;
    _searchCtrl.text = q;
    _searchFocus.unfocus();

    setState(() {
      _loadingVideos = true;
      _loadingArticles = true;
      _hasSearched = true;
    });

    // Paralel request
    final videosFuture = SearchService.searchYouTube(q);
    final articlesFuture = SearchService.searchArticles(q);

    final videos = await videosFuture;
    if (mounted) setState(() { _videos = videos; _loadingVideos = false; });

    final articles = await articlesFuture;
    if (mounted) setState(() { _articles = articles; _loadingArticles = false; });
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showUrlError();
      }
    } catch (_) {
      _showUrlError();
    }
  }

  void _showUrlError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tidak dapat membuka link. Cek koneksi internet Anda.'),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  void _showVideoDetail(VideoResult video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Thumbnail
            Stack(
              alignment: Alignment.center,
              children: [
                NetImage(
                  video.thumbnail,
                  height: 180,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _openUrl(video.url);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xCC000000),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: AppTheme.accent, size: 36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(video.title, style: AppTheme.headingMedium),
            const SizedBox(height: 6),
            Text(video.channelName, style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600)),
            if (video.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                video.description,
                style: AppTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Tonton di YouTube',
              icon: Icons.play_circle_outline,
              onTap: () {
                Navigator.pop(ctx);
                _openUrl(video.url);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showArticleDetail(ArticleResult article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (article.imageUrl.isNotEmpty) ...[
                NetImage(
                  article.imageUrl,
                  height: 160,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                ),
                const SizedBox(height: 16),
              ],
              AccentChip(label: article.source),
              const SizedBox(height: 10),
              Text(article.title, style: AppTheme.headingMedium),
              const SizedBox(height: 14),
              Text(article.description, style: AppTheme.bodyMedium),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Baca Selengkapnya',
                icon: Icons.open_in_new,
                onTap: () {
                  Navigator.pop(ctx);
                  _openUrl(article.url);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.fromLTRB(AppTheme.pagePadding, 20, AppTheme.pagePadding, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GrowMind', style: AppTheme.headingLarge),
                  SizedBox(height: 4),
                  Text('Edukasi pengembangan diri dari YouTube & internet.', style: AppTheme.bodyMedium),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textInputAction: TextInputAction.search,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Cari topik (stoik, habit, produktif)...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                  suffixIcon: (_loadingVideos || _loadingArticles)
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send_rounded, color: AppTheme.accent, size: 18),
                          onPressed: () => _performSearch(_searchCtrl.text),
                        ),
                ),
              ),
            ),

            // Topic Chips
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestedTopics.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _performSearch(_suggestedTopics[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _lastQuery.toLowerCase() == _suggestedTopics[i].toLowerCase()
                          ? AppTheme.accentDim
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: _lastQuery.toLowerCase() == _suggestedTopics[i].toLowerCase()
                            ? AppTheme.accent
                            : AppTheme.borderSubtle,
                      ),
                    ),
                    child: Text(
                      _suggestedTopics[i],
                      style: TextStyle(
                        color: _lastQuery.toLowerCase() == _suggestedTopics[i].toLowerCase()
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.black,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  tabs: const [
                    Tab(child: Text('Video', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Tab(child: Text('Artikel & Buku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVideoTab(),
                  _buildArticleTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Video Tab ──────────────────────────────────────────────────────────────
  Widget _buildVideoTab() {
    if (_loadingVideos) return const LoadingState();
    if (_videos.isEmpty) return const EmptyState(
      icon: Icons.videocam_off_outlined,
      message: 'Tidak ada video ditemukan.',
      subtitle: 'Coba kata kunci lain di atas.',
    );

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      itemCount: _videos.length,
      itemBuilder: (_, i) => _VideoCard(video: _videos[i], onTap: () => _showVideoDetail(_videos[i])),
    );
  }

  // ─── Article Tab ────────────────────────────────────────────────────────────
  Widget _buildArticleTab() {
    if (_loadingArticles) return const LoadingState();
    if (_articles.isEmpty) return const EmptyState(
      icon: Icons.article_outlined,
      message: 'Tidak ada artikel ditemukan.',
      subtitle: 'Coba kata kunci lain di atas.',
    );

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      itemCount: _articles.length,
      itemBuilder: (_, i) => _ArticleCard(article: _articles[i], onTap: () => _showArticleDetail(_articles[i])),
    );
  }
}

// ─── Video Card Widget ──────────────────────────────────────────────────────────
class _VideoCard extends StatelessWidget {
  final VideoResult video;
  final VoidCallback onTap;
  const _VideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: AppTheme.itemSpacing),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          // Thumbnail
          Stack(
            alignment: Alignment.center,
            children: [
              NetImage(
                video.thumbnail,
                width: 100,
                height: 76,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppTheme.radiusL)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xAA000000), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: AppTheme.accent, size: 18),
              ),
            ],
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    video.channelName,
                    style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
          ),
        ],
      ),
    ),
  );
}

// ─── Article Card Widget ────────────────────────────────────────────────────────
class _ArticleCard extends StatelessWidget {
  final ArticleResult article;
  final VoidCallback onTap;
  const _ArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: AppTheme.itemSpacing),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.imageUrl.isNotEmpty) ...[
            NetImage(
              article.imageUrl,
              width: 58,
              height: 58,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccentChip(label: article.source),
                const SizedBox(height: 6),
                Text(
                  article.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  article.description,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.open_in_new, color: AppTheme.textMuted, size: 16),
        ],
      ),
    ),
  );
}