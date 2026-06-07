import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final TextEditingController _taskCtrl = TextEditingController();
  String _selectedPriority = 'Medium';
  static const List<String> _priorities = ['High', 'Medium', 'Low'];

  late AnimationController _headerAnim;
  late AnimationController _listAnim;
  late Animation<double> _headerFade;

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  // Motivasi harian
  static const List<String> _motivations = [
    'Setiap hari adalah kesempatan baru untuk menjadi lebih baik. 💪',
    'Konsistensi kecil menghasilkan perubahan besar. 🌱',
    'Satu langkah kecil hari ini, satu mil lebih jauh esok. 🚀',
    'Jangan bandingkan perjalananmu dengan orang lain. 🎯',
    'Fokus pada prosesnya, hasilnya akan mengikuti. ⚡',
  ];

  String get _todayMotivation {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _motivations[dayOfYear % _motivations.length];
  }

  @override
  void initState() {
    super.initState();
    StorageService.syncNotifier.addListener(_onSync);

    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerAnim.forward();

    _listAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _listAnim.forward();
  }

  @override
  void dispose() {
    StorageService.syncNotifier.removeListener(_onSync);
    _taskCtrl.dispose();
    _headerAnim.dispose();
    _listAnim.dispose();
    super.dispose();
  }

  void _onSync() {
    if (mounted) setState(() {});
  }

  void _addTask() {
    final title = _taskCtrl.text.trim();
    if (title.isEmpty) return;

    StorageService.addTask({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'completed': false,
      'priority': _selectedPriority,
      'date': _today,
    });

    _taskCtrl.clear();
    setState(() => _selectedPriority = 'Medium');
    HapticFeedback.lightImpact();
    NotificationService.showTaskAdded(title);
  }

  void _toggleTask(int globalIndex) {
    final tasks = StorageService.getTasks();
    if (globalIndex < 0 || globalIndex >= tasks.length) return;
    final task = tasks[globalIndex];
    final wasCompleted = task['completed'] == true;
    StorageService.updateTaskAt(globalIndex, {...task, 'completed': !wasCompleted});
    if (!wasCompleted) {
      StorageService.addXP(15);
      HapticFeedback.mediumImpact();
      NotificationService.showXP(15);
    } else {
      StorageService.addXP(-15);
    }
  }

  void _deleteTask(int globalIndex) {
    final tasks = StorageService.getTasks();
    if (globalIndex < 0 || globalIndex >= tasks.length) return;
    final title = tasks[globalIndex]['title'] as String? ?? '';
    StorageService.deleteTask(globalIndex);
    HapticFeedback.lightImpact();
    NotificationService.showTaskDeleted(title);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi ☀️';
    if (h < 15) return 'Selamat Siang 🌤';
    if (h < 19) return 'Selamat Sore 🌅';
    return 'Selamat Malam 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final tasks   = StorageService.getTasks();
    final habits  = StorageService.getHabits();
    final xp      = StorageService.getXP();
    final name    = StorageService.getUserName();
    final today   = _today;

    final todayTasks     = tasks.where((t) => t['date'] == today).toList();
    final completedTasks = todayTasks.where((t) => t['completed'] == true).length;
    final completedHabits = habits.where((h) {
      final List dates = h['completedDates'] ?? [];
      return dates.contains(today);
    }).length;

    final totalItems   = habits.length + todayTasks.length;
    final completedAll = completedHabits + completedTasks;
    final progress     = totalItems == 0 ? 0.0 : (completedAll / totalItems).clamp(0.0, 1.0);
    final level        = StorageService.calculateLevel(xp);
    final lvlProgress  = StorageService.levelProgress(xp);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(), style: AppTheme.bodySmall),
                          const SizedBox(height: 2),
                          Text(name, style: AppTheme.headingLarge),
                        ],
                      ),
                      XpBadge(xp: xp),
                    ],
                  ),
                ),
              ),
            ),

            // ── Progress Card ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.surface, AppTheme.surfaceAlt],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    border: Border.all(color: AppTheme.borderSubtle),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      // Left side
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Progres Hari Ini', style: AppTheme.headingMedium.copyWith(fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(
                              '$completedAll dari $totalItems aktivitas selesai',
                              style: AppTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            // XP Level Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AccentChip(label: 'LEVEL $level'),
                                Text(
                                  '${(lvlProgress * 100).toInt()}% → LV ${level + 1}',
                                  style: AppTheme.captionStyle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: lvlProgress),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) => LinearProgressIndicator(
                                  value: v,
                                  minHeight: 5,
                                  backgroundColor: AppTheme.surfaceHigh,
                                  valueColor: AlwaysStoppedAnimation(AppTheme.accent),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Animated ring
                      AnimatedProgressRing(
                        progress: progress,
                        size: 72,
                        strokeWidth: 5,
                        center: Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Habit Banner ───────────────────────────────────────────────
            if (habits.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.accentDim, AppTheme.accentDim.withOpacity(0.5)],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppTheme.accentGlow, shape: BoxShape.circle),
                          child: const Icon(Icons.eco_outlined, color: AppTheme.accent, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Habit hari ini: $completedHabits/${habits.length} selesai 🔥',
                            style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.accent, size: 18),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Daily Motivation ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppTheme.warning, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _todayMotivation,
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Input Panel ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _taskCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Tambah target fokus hari ini...',
                              prefixIcon: Icon(Icons.add_task, color: AppTheme.accent, size: 20),
                            ),
                            onSubmitted: (_) => _addTask(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _addTask,
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              boxShadow: AppTheme.glowShadow(AppTheme.accent, blur: 12),
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.black, size: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Prioritas:', style: AppTheme.captionStyle),
                        const SizedBox(width: 10),
                        ..._priorities.map((p) {
                          final sel = _selectedPriority == p;
                          final color = AppTheme.priorityColor(p);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedPriority = p),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: sel ? color.withOpacity(0.15) : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                  border: Border.all(color: sel ? color : AppTheme.borderSubtle, width: 1.5),
                                ),
                                child: Text(
                                  p,
                                  style: TextStyle(
                                    color: sel ? color : AppTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Task List Header ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TARGET HARI INI', style: AppTheme.labelSmall),
                    Text('$completedTasks/${todayTasks.length}', style: AppTheme.captionStyle),
                  ],
                ),
              ),
            ),

            // ── Task List ──────────────────────────────────────────────────
            todayTasks.isEmpty
                ? SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.task_alt,
                      message: 'Belum ada target hari ini.',
                      subtitle: 'Tambahkan tugas di atas untuk mulai!',
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, idx) {
                          final task        = todayTasks[idx];
                          final globalIndex = tasks.indexWhere((t) => t['id'] == task['id']);
                          final completed   = task['completed'] == true;
                          final priority    = task['priority'] as String? ?? 'Medium';
                          final color       = AppTheme.priorityColor(priority);

                          return TweenAnimationBuilder<double>(
                            key: Key('task_anim_${task['id']}'),
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 300 + idx * 60),
                            curve: Curves.easeOut,
                            builder: (_, v, child) => Opacity(
                              opacity: v,
                              child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
                            ),
                            child: Dismissible(
                              key: Key('task_${task['id'] ?? idx}'),
                              direction: DismissDirection.endToStart,
                              background: const DismissBackground(),
                              onDismissed: (_) => _deleteTask(globalIndex),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                                  border: Border.all(
                                    color: completed ? AppTheme.accent.withOpacity(0.3) : AppTheme.borderSubtle,
                                  ),
                                  boxShadow: completed ? AppTheme.glowShadow(AppTheme.accent, blur: 10) : null,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                  onTap: () => _toggleTask(globalIndex),
                                  leading: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    width: 26, height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: completed ? AppTheme.accentGradient : null,
                                      color: completed ? null : Colors.transparent,
                                      border: Border.all(
                                        color: completed ? AppTheme.accent : AppTheme.textMuted,
                                        width: 2,
                                      ),
                                      boxShadow: completed ? AppTheme.glowShadow(AppTheme.accent, blur: 8) : null,
                                    ),
                                    child: completed
                                        ? const Icon(Icons.check_rounded, color: Colors.black, size: 14)
                                        : null,
                                  ),
                                  title: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      color: completed ? AppTheme.textMuted : AppTheme.textPrimary,
                                      fontSize: 14,
                                      decoration: completed ? TextDecoration.lineThrough : null,
                                      decorationColor: AppTheme.textMuted,
                                    ),
                                    child: Text(task['title'] ?? ''),
                                  ),
                                  trailing: AccentChip(label: priority, color: color),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: todayTasks.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}