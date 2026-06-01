import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/shimmer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _taskCtrl = TextEditingController();
  String _selectedPriority = 'Medium';
  static const List<String> _priorities = ['High', 'Medium', 'Low'];

  // Tidak perlu _loading — data sudah ada di cache saat build pertama.
  // syncNotifier hanya perlu setState() tanpa async.

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    StorageService.syncNotifier.addListener(_onSync);
  }

  @override
  void dispose() {
    StorageService.syncNotifier.removeListener(_onSync);
    _taskCtrl.dispose();
    super.dispose();
  }

  // Sinkron — cukup setState, tidak perlu await apapun
  void _onSync() {
    if (mounted) setState(() {});
  }

  // ─── Actions (semua sinkron ke cache, write ke disk di background) ─────────
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
    NotificationService.showTaskDeleted(title);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi ☀️';
    if (h < 15) return 'Selamat Siang 🌤';
    if (h < 19) return 'Selamat Sore 🌅';
    return 'Selamat Malam 🌙';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Semua getter sinkron dari cache — tidak ada async, tidak ada loading spinner
    final tasks   = StorageService.getTasks();
    final habits  = StorageService.getHabits();
    final xp      = StorageService.getXP();
    final name    = StorageService.getUserName();
    final today   = _today;

    final todayTasks      = tasks.where((t) => t['date'] == today).toList();
    final completedTasks  = todayTasks.where((t) => t['completed'] == true).length;
    final completedHabits = habits.where((h) {
      final List dates = h['completedDates'] ?? [];
      return dates.contains(today);
    }).length;

    final totalItems    = habits.length + todayTasks.length;
    final completedAll  = completedHabits + completedTasks;
    final progress      = totalItems == 0 ? 0.0 : (completedAll / totalItems).clamp(0.0, 1.0);
    final level         = StorageService.calculateLevel(xp);
    final lvlProgress   = StorageService.levelProgress(xp);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(name, xp, _greeting()),
            const SizedBox(height: 16),
            _buildProgressCard(progress, completedAll, totalItems, lvlProgress, level),
            const SizedBox(height: 14),
            if (habits.isNotEmpty) _buildHabitBanner(completedHabits, habits.length),
            if (habits.isNotEmpty) const SizedBox(height: 14),
            _buildInputPanel(),
            const SizedBox(height: 14),
            const SectionLabel('Target Hari Ini'),
            const SizedBox(height: 10),
            Expanded(child: _buildTaskList(todayTasks, tasks)),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(String name, int xp, String greeting) => Padding(
    padding: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 20, AppTheme.pagePadding, 0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 3),
            Text(name, style: AppTheme.headingMedium.copyWith(fontSize: 20)),
          ],
        ),
        XpBadge(xp: xp),
      ],
    ),
  );

  // ─── Progress Card ──────────────────────────────────────────────────────────
  Widget _buildProgressCard(double progress, int completed, int total,
      double lvlProgress, int level) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
    child: SurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Progres Hari Ini',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$completed dari $total aktivitas selesai',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AccentChip(label: 'LEVEL $level'),
                    Text('${(lvlProgress * 100).toInt()}% → LV ${level + 1}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: lvlProgress,
                    minHeight: 5,
                    backgroundColor: AppTheme.surfaceAlt,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 68, height: 68,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: AppTheme.surfaceAlt,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                ),
              ),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    ),
  );

  // ─── Habit Banner ───────────────────────────────────────────────────────────
  Widget _buildHabitBanner(int done, int total) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
    child: SurfaceCard(
      color: AppTheme.accentDim,
      child: Row(
        children: [
          const Icon(Icons.eco, color: AppTheme.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Habit hari ini: $done/$total selesai',
                style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.accent, size: 18),
        ],
      ),
    ),
  );

  // ─── Input Panel ────────────────────────────────────────────────────────────
  Widget _buildInputPanel() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _taskCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Tambah target fokus hari ini...'),
                onSubmitted: (_) => _addTask(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _addTask,
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text('Prioritas:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(width: 10),
            ..._priorities.map((p) {
              final sel = _selectedPriority == p;
              final color = AppTheme.priorityColor(p);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPriority = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel ? color.withOpacity(0.15) : AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(color: sel ? color : AppTheme.borderSubtle, width: 1.5),
                    ),
                    child: Text(p,
                        style: TextStyle(
                          color: sel ? color : AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        )),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    ),
  );

  // ─── Task List ──────────────────────────────────────────────────────────────
  Widget _buildTaskList(List<Map<String, dynamic>> todayTasks,
      List<Map<String, dynamic>> allTasks) {
    if (todayTasks.isEmpty) {
      return const EmptyState(
        icon: Icons.task_alt,
        message: 'Belum ada target hari ini.',
        subtitle: 'Tambahkan tugas di atas untuk mulai!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      itemCount: todayTasks.length,
      itemBuilder: (ctx, idx) {
        final task        = todayTasks[idx];
        final globalIndex = allTasks.indexWhere((t) => t['id'] == task['id']);
        final completed   = task['completed'] == true;
        final priority    = task['priority'] as String? ?? 'Medium';
        final color       = AppTheme.priorityColor(priority);

        return Dismissible(
          key: Key('task_${task['id'] ?? idx}'),
          direction: DismissDirection.endToStart,
          background: const DismissBackground(),
          onDismissed: (_) => _deleteTask(globalIndex),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              onTap: () => _toggleTask(globalIndex),
              leading: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26, height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed ? AppTheme.accent : Colors.transparent,
                  border: Border.all(
                    color: completed ? AppTheme.accent : AppTheme.textMuted,
                    width: 2,
                  ),
                ),
                child: completed
                    ? const Icon(Icons.check, color: Colors.black, size: 14)
                    : null,
              ),
              title: Text(
                task['title'] ?? '',
                style: TextStyle(
                  color: completed ? AppTheme.textMuted : Colors.white,
                  fontSize: 14,
                  decoration: completed ? TextDecoration.lineThrough : null,
                  decorationColor: AppTheme.textMuted,
                ),
              ),
              trailing: AccentChip(label: priority, color: color),
            ),
          ),
        );
      },
    );
  }
}