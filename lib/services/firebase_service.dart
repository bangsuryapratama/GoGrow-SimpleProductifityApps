import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'storage_service.dart';

/// FirebaseService — Handles authentication + Firestore cloud sync.
/// Local cache dari StorageService tetap digunakan untuk kecepatan,
/// Firebase hanya untuk persistensi dan sinkronisasi antar device.
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;
  static String? get uid => _auth.currentUser?.uid;
  static String? get userEmail => _auth.currentUser?.email;
  static String? get userPhotoUrl => _auth.currentUser?.photoURL;

  // ─── Reaktivitas Auth ─────────────────────────────────────────────────────
  static final ValueNotifier<User?> authNotifier = ValueNotifier<User?>(null);

  static void init() {
    _auth.authStateChanges().listen((user) {
      authNotifier.value = user;
    });
  }

  // ─── Google Sign In ───────────────────────────────────────────────────────
  static Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user != null) {
        // Simpan nama dari Google jika belum diatur
        final displayName = user.displayName ?? 'Pengguna GoGrow';
        StorageService.saveUserName(displayName);
        await _ensureUserDoc(user);
        await syncFromCloud(); // Ambil data dari cloud setelah login
      }

      return user;
    } catch (e) {
      debugPrint('[FirebaseService] signInWithGoogle error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─── Firestore User Doc ───────────────────────────────────────────────────
  static Future<void> _ensureUserDoc(User user) async {
    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'displayName': user.displayName ?? 'Pengguna GoGrow',
        'email': user.email,
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'xp': StorageService.getXP(),
      });
    }
  }

  // ─── Sync: Local → Cloud ──────────────────────────────────────────────────
  static Future<void> syncToCloud() async {
    if (!isLoggedIn) return;
    try {
      final docRef = _db.collection('users').doc(uid);
      await docRef.set({
        'xp': StorageService.getXP(),
        'userName': StorageService.getUserName(),
        'tasks': StorageService.getTasks(),
        'habits': StorageService.getHabits(),
        'lastSynced': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[FirebaseService] Synced to cloud ✓');
    } catch (e) {
      debugPrint('[FirebaseService] syncToCloud error: $e');
    }
  }

  // ─── Sync: Cloud → Local ──────────────────────────────────────────────────
  static Future<void> syncFromCloud() async {
    if (!isLoggedIn) return;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final xp = (data['xp'] as num?)?.toInt() ?? 0;
      final name = data['userName'] as String? ?? 'Pengguna GoGrow';
      final tasks = (data['tasks'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      final habits = (data['habits'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      await StorageService.restoreFromCloud(
        xp: xp,
        name: name,
        tasks: tasks,
        habits: habits,
      );
      debugPrint('[FirebaseService] Synced from cloud ✓');
    } catch (e) {
      debugPrint('[FirebaseService] syncFromCloud error: $e');
    }
  }

  // ─── Auto-sync setiap kali ada perubahan lokal ────────────────────────────
  static void setupAutoSync() {
    StorageService.syncNotifier.addListener(() async {
      await syncToCloud();
    });
  }
}
