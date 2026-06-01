import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StorageService — Penyimpanan lokal dengan IN-MEMORY CACHE.
/// SharedPreferences hanya dibaca SEKALI saat init, setelah itu semua
/// operasi baca langsung dari cache (_cache) di RAM — secepat akses List biasa.
/// Tulis ke disk tetap dilakukan saat save, tapi tidak memblokir UI.
class StorageService {
  static const String _keyTasks    = 'gogrow_tasks_v4';
  static const String _keyHabits   = 'gogrow_habits_v4';
  static const String _keyXP       = 'gogrow_xp_v4';
  static const String _keyUserName = 'gogrow_username_v4';

  // ─── In-Memory Cache ──────────────────────────────────────────────────────
  // Setelah init(), semua read langsung dari sini — O(1), tidak ada async.
  static SharedPreferences? _prefs;
  static List<Map<String, dynamic>> _tasksCache  = [];
  static List<Map<String, dynamic>> _habitsCache = [];
  static int    _xpCache    = 0;
  static String _nameCache  = 'Pengguna Hebat';
  static bool   _initialized = false;

  /// Harus dipanggil SEKALI di main() sebelum runApp.
  /// Memuat semua data ke RAM sekaligus — setelah ini semua getter sinkron.
  static Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    _xpCache   = _prefs!.getInt(_keyXP) ?? 0;
    _nameCache = _prefs!.getString(_keyUserName) ?? 'Pengguna Hebat';

    final tasksJson  = _prefs!.getString(_keyTasks);
    final habitsJson = _prefs!.getString(_keyHabits);

    _tasksCache = tasksJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(tasksJson))
        : [];

    if (habitsJson != null) {
      _habitsCache = List<Map<String, dynamic>>.from(jsonDecode(habitsJson));
    } else {
      _habitsCache = _defaultHabits();
      _prefs!.setString(_keyHabits, jsonEncode(_habitsCache));
    }

    _initialized = true;
  }

  // ─── Reaktivitas Global ───────────────────────────────────────────────────
  static final ValueNotifier<bool> syncNotifier = ValueNotifier<bool>(false);
  static void _triggerSync() => syncNotifier.value = !syncNotifier.value;

  // ─── Getter Sinkron (dari cache, tanpa async) ─────────────────────────────
  static List<Map<String, dynamic>> getTasks()  => List.from(_tasksCache);
  static List<Map<String, dynamic>> getHabits() => List.from(_habitsCache);
  static int    getXP()      => _xpCache;
  static String getUserName() => _nameCache;

  // ─── XP ───────────────────────────────────────────────────────────────────
  static void addXP(int amount) {
    _xpCache = (_xpCache + amount).clamp(0, 999999);
    _prefs?.setInt(_keyXP, _xpCache);
    _triggerSync();
  }

  static int    calculateLevel(int xp) => (xp ~/ 100) + 1;
  static int    xpForNextLevel(int xp)  => (calculateLevel(xp) * 100) - xp;
  static double levelProgress(int xp)   => (xp % 100) / 100.0;

  // ─── Tasks ────────────────────────────────────────────────────────────────
  static void _persistTasks() =>
      _prefs?.setString(_keyTasks, jsonEncode(_tasksCache));

  static void addTask(Map<String, dynamic> task) {
    _tasksCache.insert(0, task);
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

  // ─── Habits ───────────────────────────────────────────────────────────────
  static void _persistHabits() =>
      _prefs?.setString(_keyHabits, jsonEncode(_habitsCache));

  static void saveHabits(List<Map<String, dynamic>> habits) {
    _habitsCache = List.from(habits);
    _persistHabits();
    _triggerSync();
  }

  static void addHabit(Map<String, dynamic> habit) {
    _habitsCache.add(habit);
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

  // ─── Default Habits ───────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _defaultHabits() => [
    {'id': '1', 'title': 'Meditasi Pagi',     'time': '06:00', 'icon': 'spa',      'completedDates': [], 'color': 'green'},
    {'id': '2', 'title': 'Membaca Buku',       'time': '08:00', 'icon': 'book',     'completedDates': [], 'color': 'blue'},
    {'id': '3', 'title': 'Deep Work 90 Menit', 'time': '09:30', 'icon': 'computer', 'completedDates': [], 'color': 'orange'},
  ];
}