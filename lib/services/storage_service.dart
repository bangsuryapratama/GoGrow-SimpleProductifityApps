import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StorageService — Penyimpanan lokal dengan IN-MEMORY CACHE.
/// SharedPreferences hanya dibaca SEKALI saat init, setelah itu semua
/// operasi baca langsung dari cache (_cache) di RAM.
///
/// Data structures supported:
/// - Tasks: title, isDone, priority, subtasks (List<Map>), tags (List<String>),
///          deadline (String ISO), status ('todo'|'inprogress'|'done')
/// - Habits: title, time, icon, color, category, bestStreak, completedDates
/// - Bookmarks: type, title, url, thumbnail, source
/// - Pomodoro Sessions: date, taskId, duration (minutes)
/// - Achievements: List<String> of unlocked achievement IDs
/// - XP History: List<Map> {date (ISO date), xp} for last 30 days
class StorageService {
  static const String _keyTasks          = 'gogrow_tasks_v4';
  static const String _keyHabits         = 'gogrow_habits_v4';
  static const String _keyXP             = 'gogrow_xp_v4';
  static const String _keyUserName       = 'gogrow_username_v4';
  static const String _keyHasOnboarded   = 'gogrow_has_onboarded';
  static const String _keyAvatar         = 'gogrow_avatar_v1';
  static const String _keyBookmarks      = 'bookmarks';
  static const String _keyPomodoro       = 'pomodoro_sessions';
  static const String _keyAchievements   = 'achievements';
  static const String _keyXPHistory      = 'xp_history';

  // ─── In-Memory Cache ──────────────────────────────────────────────────────
  static SharedPreferences? _prefs;
  static List<Map<String, dynamic>> _tasksCache     = [];
  static List<Map<String, dynamic>> _habitsCache    = [];
  static int    _xpCache        = 0;
  static String _nameCache      = 'Pengguna Hebat';
  static bool   _initialized    = false;
  static bool   _hasOnboarded   = false;
  static int    _avatarIndex    = 0;

  // New caches
  static List<Map<String, dynamic>> _bookmarksCache    = [];
  static List<Map<String, dynamic>> _pomodoroCache     = [];
  static List<String>               _achievementsCache = [];
  static List<Map<String, dynamic>> _xpHistoryCache    = [];

  /// Dipanggil SEKALI di main() sebelum runApp.
  static Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    _xpCache       = _prefs!.getInt(_keyXP) ?? 0;
    _nameCache     = _prefs!.getString(_keyUserName) ?? 'Pengguna Hebat';
    _hasOnboarded  = _prefs!.getBool(_keyHasOnboarded) ?? false;
    _avatarIndex   = _prefs!.getInt(_keyAvatar) ?? 0;

    final tasksJson      = _prefs!.getString(_keyTasks);
    final habitsJson     = _prefs!.getString(_keyHabits);
    final bookmarksJson  = _prefs!.getString(_keyBookmarks);
    final pomodoroJson   = _prefs!.getString(_keyPomodoro);
    final achieveJson    = _prefs!.getString(_keyAchievements);
    final xpHistoryJson  = _prefs!.getString(_keyXPHistory);

    _tasksCache = tasksJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(tasksJson))
        : [];

    if (habitsJson != null) {
      _habitsCache = List<Map<String, dynamic>>.from(jsonDecode(habitsJson));
    } else {
      _habitsCache = _defaultHabits();
      _prefs!.setString(_keyHabits, jsonEncode(_habitsCache));
    }

    _bookmarksCache = bookmarksJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(bookmarksJson))
        : [];

    _pomodoroCache = pomodoroJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(pomodoroJson))
        : [];

    _achievementsCache = achieveJson != null
        ? List<String>.from(jsonDecode(achieveJson))
        : [];

    _xpHistoryCache = xpHistoryJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(xpHistoryJson))
        : [];

    _initialized = true;
  }

  // ─── Reaktivitas Global ───────────────────────────────────────────────────
  static final ValueNotifier<bool> syncNotifier = ValueNotifier<bool>(false);
  static void _triggerSync() => syncNotifier.value = !syncNotifier.value;

  // ─── Getter Sinkron ───────────────────────────────────────────────────────
  static List<Map<String, dynamic>> getTasks()  => List.from(_tasksCache);
  static List<Map<String, dynamic>> getHabits() => List.from(_habitsCache);
  static int    getXP()          => _xpCache;
  static String getUserName()    => _nameCache;
  static bool   hasOnboarded()   => _hasOnboarded;
  static int    getAvatarIndex() => _avatarIndex;

  // ─── Onboarding ───────────────────────────────────────────────────────────
  static void setOnboarded() {
    _hasOnboarded = true;
    _prefs?.setBool(_keyHasOnboarded, true);
  }

  static void setAvatarIndex(int index) {
    _avatarIndex = index;
    _prefs?.setInt(_keyAvatar, index);
    _triggerSync();
  }

  // ─── XP ───────────────────────────────────────────────────────────────────
  static void addXP(int amount) {
    _xpCache = (_xpCache + amount).clamp(0, 999999);
    _prefs?.setInt(_keyXP, _xpCache);
    recordXP(amount);
    _triggerSync();
  }

  static int    calculateLevel(int xp) => (xp ~/ 100) + 1;
  static int    xpForNextLevel(int xp)  => (calculateLevel(xp) * 100) - xp;
  static double levelProgress(int xp)   => (xp % 100) / 100.0;

  // ─── Tasks ────────────────────────────────────────────────────────────────
  static void _persistTasks() =>
      _prefs?.setString(_keyTasks, jsonEncode(_tasksCache));

  static void addTask(Map<String, dynamic> task) {
    // Ensure new fields have defaults
    final enriched = {
      'subtasks': <Map<String, dynamic>>[],
      'tags': <String>[],
      'deadline': null,
      'status': 'todo',
      ...task,
    };
    _tasksCache.insert(0, enriched);
    _persistTasks();
    _triggerSync();
  }

  static void saveTasks(List<Map<String, dynamic>> tasks) {
    _tasksCache = List.from(tasks);
    _persistTasks();
    _triggerSync();
  }

  static void deleteTask(int index) {
    if (index >= 0 && index < _tasksCache.length) {
      _tasksCache.removeAt(index);
      _persistTasks();
      _triggerSync();
    }
  }

  static void updateTaskAt(int index, Map<String, dynamic> task) {
    if (index >= 0 && index < _tasksCache.length) {
      _tasksCache[index] = task;
      _persistTasks();
      _triggerSync();
    }
  }

  /// Returns tasks filtered by status ('todo', 'inprogress', 'done').
  /// Also treats legacy isDone==true as status 'done'.
  static List<Map<String, dynamic>> getTasksByStatus(String status) {
    return _tasksCache.where((t) {
      final taskStatus = _resolveTaskStatus(t);
      return taskStatus == status;
    }).toList();
  }

  /// Updates task status and keeps legacy isDone in sync.
  static void updateTaskStatus(int index, String status) {
    if (index < 0 || index >= _tasksCache.length) return;
    final updated = Map<String, dynamic>.from(_tasksCache[index]);
    updated['status'] = status;
    updated['isDone'] = (status == 'done');
    _tasksCache[index] = updated;
    _persistTasks();
    _triggerSync();
  }

  static String _resolveTaskStatus(Map<String, dynamic> task) {
    // Prefer 'status' field; fall back to legacy isDone
    if (task.containsKey('status') && task['status'] != null) {
      return task['status'] as String;
    }
    return (task['isDone'] == true) ? 'done' : 'todo';
  }

  // ─── Habits ───────────────────────────────────────────────────────────────
  static void _persistHabits() =>
      _prefs?.setString(_keyHabits, jsonEncode(_habitsCache));

  static void saveHabits(List<Map<String, dynamic>> habits) {
    _habitsCache = List.from(habits);
    _persistHabits();
    _triggerSync();
  }

  static void addHabit(Map<String, dynamic> habit) {
    final enriched = {
      'category': 'General',
      'bestStreak': 0,
      ...habit,
    };
    _habitsCache.add(enriched);
    _persistHabits();
    _triggerSync();
  }

  static void deleteHabit(int index) {
    if (index >= 0 && index < _habitsCache.length) {
      _habitsCache.removeAt(index);
      _persistHabits();
      _triggerSync();
    }
  }

  /// Returns true jika baru selesai, false jika di-untoggle.
  static bool toggleHabitDay(int index, String dayKey) {
    if (index < 0 || index >= _habitsCache.length) return false;
    final dates = List<dynamic>.from(_habitsCache[index]['completedDates'] ?? []);
    final wasDone = dates.contains(dayKey);
    wasDone ? dates.remove(dayKey) : dates.add(dayKey);
    _habitsCache[index] = {..._habitsCache[index], 'completedDates': dates};

    // Update bestStreak if toggling ON
    if (!wasDone) {
      final streak = habitStreak(_habitsCache[index]);
      final best = (_habitsCache[index]['bestStreak'] as int?) ?? 0;
      if (streak > best) {
        _habitsCache[index] = {..._habitsCache[index], 'bestStreak': streak};
      }
    }

    _persistHabits();
    _triggerSync();
    return !wasDone;
  }

  // ─── User ─────────────────────────────────────────────────────────────────
  static void saveUserName(String name) {
    _nameCache = name;
    _prefs?.setString(_keyUserName, name);
    _triggerSync();
  }

  // ─── Statistik ────────────────────────────────────────────────────────────
  static int habitStreak(Map<String, dynamic> habit) {
    final dates = habit['completedDates'] as List? ?? [];
    if (dates.isEmpty) return 0;
    int streak = 0;
    DateTime day = DateTime.now();
    while (dates.contains(day.toIso8601String().substring(0, 10))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ─── Bookmarks ────────────────────────────────────────────────────────────
  static void _persistBookmarks() =>
      _prefs?.setString(_keyBookmarks, jsonEncode(_bookmarksCache));

  /// Returns all saved bookmarks.
  static List<Map<String, dynamic>> getBookmarks() {
    final raw = _bookmarksCache;
    return List<Map<String, dynamic>>.from(raw);
  }

  /// Adds a bookmark. item should have: type, title, url, thumbnail, source.
  static void addBookmark(Map<String, dynamic> item) {
    // Avoid duplicates by URL
    final url = item['url'] as String? ?? '';
    if (url.isNotEmpty && _bookmarksCache.any((b) => b['url'] == url)) return;
    _bookmarksCache.insert(0, {
      'savedAt': DateTime.now().toIso8601String(),
      ...item,
    });
    _persistBookmarks();
    _triggerSync();
  }

  /// Removes a bookmark by its URL.
  static void removeBookmark(String url) {
    _bookmarksCache.removeWhere((b) => b['url'] == url);
    _persistBookmarks();
    _triggerSync();
  }

  /// Returns true if the given URL is already bookmarked.
  static bool isBookmarked(String url) =>
      _bookmarksCache.any((b) => b['url'] == url);

  // ─── Achievements ─────────────────────────────────────────────────────────
  static void _persistAchievements() =>
      _prefs?.setString(_keyAchievements, jsonEncode(_achievementsCache));

  /// Returns list of unlocked achievement IDs.
  static List<String> getAchievements() => List.from(_achievementsCache);

  /// Unlocks an achievement by ID (no-op if already unlocked).
  static void unlockAchievement(String id) {
    if (_achievementsCache.contains(id)) return;
    _achievementsCache.add(id);
    _persistAchievements();
    _triggerSync();
  }

  /// Returns true if the given achievement is already unlocked.
  static bool hasAchievement(String id) => _achievementsCache.contains(id);

  /// Auto-checks all achievement conditions and unlocks applicable ones.
  /// Expand this list as new achievements are added to the app.
  static void checkAndUnlockAchievements() {
    final xp = _xpCache;
    final tasks = _tasksCache;
    final habits = _habitsCache;
    final doneTasks = tasks.where((t) => _resolveTaskStatus(t) == 'done').length;
    final pomodoroToday = getTodayPomodoros().length;
    final bookmarkCount = _bookmarksCache.length;

    // XP milestones
    if (xp >= 100)   unlockAchievement('xp_100');
    if (xp >= 500)   unlockAchievement('xp_500');
    if (xp >= 1000)  unlockAchievement('xp_1000');
    if (xp >= 5000)  unlockAchievement('xp_5000');

    // Task milestones
    if (doneTasks >= 1)   unlockAchievement('first_task_done');
    if (doneTasks >= 10)  unlockAchievement('tasks_10_done');
    if (doneTasks >= 50)  unlockAchievement('tasks_50_done');
    if (doneTasks >= 100) unlockAchievement('tasks_100_done');

    // Habit streaks
    for (final habit in habits) {
      final streak = habitStreak(habit);
      if (streak >= 3)  unlockAchievement('streak_3');
      if (streak >= 7)  unlockAchievement('streak_7');
      if (streak >= 30) unlockAchievement('streak_30');
    }

    // Pomodoro focus
    if (pomodoroToday >= 1) unlockAchievement('first_pomodoro');
    if (pomodoroToday >= 4) unlockAchievement('pomodoro_4_today');

    // Bookmarks
    if (bookmarkCount >= 1)  unlockAchievement('first_bookmark');
    if (bookmarkCount >= 10) unlockAchievement('bookmark_10');

    // Level milestones
    final level = calculateLevel(xp);
    if (level >= 5)  unlockAchievement('level_5');
    if (level >= 10) unlockAchievement('level_10');
    if (level >= 20) unlockAchievement('level_20');
  }

  // ─── XP History ───────────────────────────────────────────────────────────
  static void _persistXPHistory() =>
      _prefs?.setString(_keyXPHistory, jsonEncode(_xpHistoryCache));

  /// Records XP earned today. Accumulates into today's entry.
  /// Keeps only the last 30 days of history.
  static void recordXP(int amount) {
    if (amount <= 0) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final idx = _xpHistoryCache.indexWhere((e) => e['date'] == today);
    if (idx >= 0) {
      final existing = (_xpHistoryCache[idx]['xp'] as int?) ?? 0;
      _xpHistoryCache[idx] = {'date': today, 'xp': existing + amount};
    } else {
      _xpHistoryCache.add({'date': today, 'xp': amount});
    }

    // Trim to last 30 days
    if (_xpHistoryCache.length > 30) {
      _xpHistoryCache = _xpHistoryCache.sublist(_xpHistoryCache.length - 30);
    }

    _persistXPHistory();
  }

  /// Returns XP history for the last 30 days. Each entry: {date, xp}.
  static List<Map<String, dynamic>> getXPHistory() {
    final raw = _xpHistoryCache;
    return List<Map<String, dynamic>>.from(raw);
  }

  // ─── Pomodoro ─────────────────────────────────────────────────────────────
  static void _persistPomodoro() =>
      _prefs?.setString(_keyPomodoro, jsonEncode(_pomodoroCache));

  /// Records a completed Pomodoro session.
  static void recordPomodoroSession(String taskId, int minutes) {
    _pomodoroCache.add({
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'taskId': taskId,
      'duration': minutes,
      'completedAt': DateTime.now().toIso8601String(),
    });
    _persistPomodoro();
    _triggerSync();
  }

  /// Returns all Pomodoro sessions recorded today.
  static List<Map<String, dynamic>> getTodayPomodoros() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return _pomodoroCache
        .where((s) => s['date'] == today)
        .toList();
  }

  /// Returns all Pomodoro sessions (full history).
  static List<Map<String, dynamic>> getAllPomodoros() =>
      List<Map<String, dynamic>>.from(_pomodoroCache);

  // ─── Cloud Restore ────────────────────────────────────────────────────────
  /// Dipanggil oleh FirebaseService setelah sync dari cloud.
  static Future<void> restoreFromCloud({
    required int xp,
    required String name,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> habits,
  }) async {
    _xpCache     = xp;
    _nameCache   = name;
    _tasksCache  = tasks;
    _habitsCache = habits.isNotEmpty ? habits : _defaultHabits();

    _prefs?.setInt(_keyXP, xp);
    _prefs?.setString(_keyUserName, name);
    _prefs?.setString(_keyTasks, jsonEncode(_tasksCache));
    _prefs?.setString(_keyHabits, jsonEncode(_habitsCache));
    _triggerSync();
  }

  // ─── Export / Import JSON (Backup Manual) ─────────────────────────────────
  static Map<String, dynamic> exportToJson() => {
    'version': 2,
    'exportedAt': DateTime.now().toIso8601String(),
    'xp': _xpCache,
    'userName': _nameCache,
    'tasks': _tasksCache,
    'habits': _habitsCache,
    'bookmarks': _bookmarksCache,
    'achievements': _achievementsCache,
    'xp_history': _xpHistoryCache,
    'pomodoro_sessions': _pomodoroCache,
  };

  static Future<bool> importFromJson(Map<String, dynamic> data) async {
    try {
      await restoreFromCloud(
        xp: (data['xp'] as num?)?.toInt() ?? 0,
        name: data['userName'] as String? ?? 'Pengguna Hebat',
        tasks: (data['tasks'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
        habits: (data['habits'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
      );

      if (data['bookmarks'] != null) {
        _bookmarksCache = List<Map<String, dynamic>>.from(
          (data['bookmarks'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        _persistBookmarks();
      }

      if (data['achievements'] != null) {
        _achievementsCache = List<String>.from(data['achievements'] as List);
        _persistAchievements();
      }

      if (data['xp_history'] != null) {
        _xpHistoryCache = List<Map<String, dynamic>>.from(
          (data['xp_history'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        _persistXPHistory();
      }

      if (data['pomodoro_sessions'] != null) {
        _pomodoroCache = List<Map<String, dynamic>>.from(
          (data['pomodoro_sessions'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        _persistPomodoro();
      }

      _triggerSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Default Habits ───────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _defaultHabits() => [
    {
      'id': '1',
      'title': 'Meditasi Pagi',
      'time': '06:00',
      'icon': 'spa',
      'completedDates': [],
      'color': 'green',
      'category': 'Mindfulness',
      'bestStreak': 0,
    },
    {
      'id': '2',
      'title': 'Membaca Buku',
      'time': '08:00',
      'icon': 'book',
      'completedDates': [],
      'color': 'blue',
      'category': 'Learning',
      'bestStreak': 0,
    },
    {
      'id': '3',
      'title': 'Deep Work 90 Menit',
      'time': '09:30',
      'icon': 'computer',
      'completedDates': [],
      'color': 'orange',
      'category': 'Productivity',
      'bestStreak': 0,
    },
  ];
}