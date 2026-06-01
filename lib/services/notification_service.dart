import 'package:flutter/material.dart';

/// NotificationService — Wrapper notifikasi in-app untuk GoGrow.
/// Menggunakan SnackBar sebagai notifikasi karena flutter_local_notifications
/// memerlukan setup platform native yang lebih kompleks.
/// Untuk push notification real device, tambahkan konfigurasi AndroidManifest & Info.plist.
class NotificationService {
  static GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show({
    required String title,
    required String message,
    Color accentColor = const Color(0xFF00C853),
    IconData icon = Icons.notifications_active,
    Duration duration = const Duration(seconds: 3),
  }) {
    messengerKey.currentState?.clearSnackBars();
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF161616),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentColor, width: 1.5),
        ),
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: accentColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showXP(int amount) {
    show(
      title: amount > 0 ? '+$amount XP Diperoleh! 🎉' : '$amount XP',
      message: amount > 0
          ? 'Keren! Terus pertahankan konsistensimu.'
          : 'Tugas dibatalkan, XP dikurangi.',
      icon: Icons.bolt,
      accentColor: amount > 0 ? const Color(0xFF00C853) : Colors.orangeAccent,
    );
  }

  static void showTaskAdded(String taskTitle) {
    show(
      title: 'Target Baru Ditambahkan 🎯',
      message: 'Jangan lupa selesaikan: $taskTitle',
      icon: Icons.add_task,
    );
  }

  static void showTaskDeleted(String taskTitle) {
    show(
      title: 'Tugas Dihapus',
      message: "'$taskTitle' telah dihapus dari daftar.",
      icon: Icons.delete_outline,
      accentColor: Colors.redAccent,
    );
  }

  static void showHabitDone(String habitTitle) {
    show(
      title: 'Habit Tercapai! 🌿',
      message: "'$habitTitle' selesai. Pertahankan konsistensimu!",
      icon: Icons.eco,
    );
  }

  static void showHabitAdded(String habitTitle) {
    show(
      title: 'Habit Baru Ditanam 🌱',
      message: "'$habitTitle' sudah masuk jadwal harianmu.",
      icon: Icons.spa,
    );
  }
}