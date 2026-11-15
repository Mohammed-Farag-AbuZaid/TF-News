// lib/authentication/authentication_repository.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:tf_news/authentication/login_screen.dart';
import 'package:tf_news/authentication/user_controller.dart';
import 'package:tf_news/data/opportunity.dart' show kTfApiBaseUrl;
import 'package:tf_news/pages/home_page.dart';
import 'package:tf_news/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:tf_news/utils/exceptions/firebase_exceptions.dart';
import 'package:tf_news/utils/exceptions/formate_exceptions.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  static const String _savedAccountsKey = 'tf_saved_accounts';

  final deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  User? get authUser => _auth.currentUser;

  bool get isSignedIn => _auth.currentUser != null;

  List<Map<String, dynamic>> getSavedAccounts() {
    final raw = deviceStorage.read(_savedAccountsKey);
    if (raw is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final email = (m['email'] ?? '').toString().trim();
        if (email.isNotEmpty) out.add(m);
      }
    }
    return out;
  }

  Future<void> saveAccountLocally({
    required String email,
    String name = '',
    String photoUrl = '',
    String? password,
    String? uid,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;

    final current = List<Map<String, dynamic>>.from(getSavedAccounts());
    Map<String, dynamic>? existing;
    current.removeWhere((item) {
      final matches =
          (item['email'] ?? '').toString().trim().toLowerCase() == normalized;
      if (matches) existing = item;
      return matches;
    });

    final entry = <String, dynamic>{
      'email': normalized,
      'name': name.trim().isNotEmpty
          ? name.trim()
          : (existing?['name'] ?? normalized.split('@').first).toString(),
      'photoUrl': photoUrl.trim().isNotEmpty
          ? photoUrl.trim()
          : (existing?['photoUrl'] ?? '').toString(),
      'uid': (uid ?? existing?['uid'] ?? '').toString(),
      if (password != null && password.isNotEmpty)
        'password': password
      else if (existing != null &&
          (existing!['password'] ?? '').toString().isNotEmpty)
        'password': existing!['password'],
      'lastUsed': DateTime.now().toIso8601String(),
    };

    current.insert(0, entry);
    if (current.length > 5) {
      current.removeRange(5, current.length);
    }
    await deviceStorage.write(_savedAccountsKey, current);
  }

  Future<void> removeSavedAccount(String email) async {
    final normalized = email.trim().toLowerCase();
    final current = List<Map<String, dynamic>>.from(getSavedAccounts())
      ..removeWhere(
        (item) =>
            (item['email'] ?? '').toString().trim().toLowerCase() == normalized,
      );
    await deviceStorage.write(_savedAccountsKey, current);
  }

  Future<void> _ensureFirestoreProfile(User user) async {
    try {
      final col = FirebaseFirestore.instance.collection('users');
      final docRef = col.doc(user.uid);
      final doc = await docRef.get();
      final data = doc.data() ?? <String, dynamic>{};

      final first = (data['firstName'] ?? '').toString().trim();
      final full = (data['fullName'] ?? '').toString().trim();

      if (doc.exists && (first.isNotEmpty || full.isNotEmpty)) {
        final display = full.isNotEmpty
            ? full
            : '$first ${(data['lastName'] ?? '').toString()}'.trim();
        await saveAccountLocally(
          email: user.email ?? (data['email'] ?? '').toString(),
          name: display,
          photoUrl: user.photoURL ?? (data['profilePicture'] ?? '').toString(),
          uid: user.uid,
        );
        return;
      }

      // Check if an account record with this email exists under a legacy doc id
      final emailLower = (user.email ?? '').trim().toLowerCase();
      Map<String, dynamic> legacyData = <String, dynamic>{};
      if (emailLower.isNotEmpty) {
        try {
          final byEmail = await col
              .where('email', isEqualTo: emailLower)
              .limit(1)
              .get();
          if (byEmail.docs.isNotEmpty) {
            legacyData = byEmail.docs.first.data();
          }
        } catch (_) {}
      }

      final fallbackName = (legacyData['fullName'] ??
              user.displayName ??
              (emailLower.isNotEmpty ? emailLower.split('@').first : 'Scholar'))
          .toString()
          .trim();
      final parts = fallbackName
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .toList();
      final firstName = (legacyData['firstName'] ??
              (parts.isNotEmpty ? parts.first : fallbackName))
          .toString()
          .trim();
      final lastName = (legacyData['lastName'] ??
              (parts.length > 1 ? parts.sublist(1).join(' ') : ''))
          .toString()
          .trim();

      final payload = <String, dynamic>{
        ...legacyData,
        'id': user.uid,
        'uid': user.uid,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': '$firstName $lastName'.trim(),
        'username': (legacyData['username'] ?? fallbackName).toString(),
        'email': emailLower.isNotEmpty
            ? emailLower
            : (legacyData['email'] ?? '').toString(),
        'phone': (legacyData['phone'] ?? user.phoneNumber ?? '').toString(),
        'profilePicture':
            (legacyData['profilePicture'] ?? user.photoURL ?? '').toString(),
        'academicLevel': (legacyData['academicLevel'] ?? '').toString(),
        'grade': (legacyData['grade'] ?? '').toString(),
        'stemSchool': (legacyData['stemSchool'] ?? '').toString(),
        'role': (legacyData['role'] ?? 'student').toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!doc.exists) {
        payload['registrationDate'] = FieldValue.serverTimestamp();
      }

      await docRef.set(payload, SetOptions(merge: true));
      await saveAccountLocally(
        email: payload['email'] as String,
        name: payload['fullName'] as String,
        photoUrl: payload['profilePicture'] as String,
        uid: user.uid,
      );
    } catch (e) {
      if (kDebugMode) print('Firestore profile sync skipped: $e');
    }
  }

  /// Where to go after the app opens or after login.
  Future<void> screenRedirect() async {
    if (kIsWeb) {
      try {
        final redir = await _auth.getRedirectResult();
        if (redir.user != null) {
          await _ensureFirestoreProfile(redir.user!);
        }
      } catch (_) {}
    }

    var user = _auth.currentUser;
    if (user == null) {
      try {
        user = await _auth.authStateChanges().first.timeout(
              const Duration(seconds: 2),
              onTimeout: () => _auth.currentUser,
            );
      } catch (_) {}
    }

    if (user != null) {
      try {
        await user.reload();
        user = _auth.currentUser ?? user;
      } catch (_) {}
    }

    if (user != null) {
      await _ensureFirestoreProfile(user);
      try {
        await UserController.instance.fetchUserRecord();
      } catch (_) {}
      await Future.microtask(() {});
      Get.offAll(() => const HomeScreen());
    } else {
      await Future.microtask(() {});
      Get.offAll(() => const LoginScreen());
    }
  }

  Future<UserCredential> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        await _ensureFirestoreProfile(cred.user!);
        await saveAccountLocally(
          email: email,
          name: cred.user!.displayName ?? '',
          photoUrl: cred.user!.photoURL ?? '',
          uid: cred.user!.uid,
        );
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        final migrated = await _tryMigrateVpsAccount(email, password);
        if (migrated != null) return migrated;
      }
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException().message;
    } catch (e) {
      if (e is String) rethrow;
      throw 'Something went wrong. Please try again';
    }
  }

  Future<UserCredential?> _tryMigrateVpsAccount(
    String email,
    String password,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kTfApiBaseUrl/api/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final vpsUser =
          (body['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final fullName = (vpsUser['fullName'] ??
              vpsUser['name'] ??
              email.split('@').first)
          .toString()
          .trim();

      try {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (cred.user != null) {
          if (fullName.isNotEmpty) {
            await cred.user!.updateDisplayName(fullName);
          }
          final parts = fullName.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .set({
            'id': cred.user!.uid,
            'uid': cred.user!.uid,
            'firstName': (vpsUser['firstName'] ??
                    (parts.isNotEmpty ? parts.first : fullName))
                .toString(),
            'lastName': (vpsUser['lastName'] ??
                    (parts.length > 1 ? parts.sublist(1).join(' ') : ''))
                .toString(),
            'fullName': fullName,
            'username': fullName,
            'email': email.trim().toLowerCase(),
            'governorate': (vpsUser['governorate'] ?? '').toString(),
            'academicLevel': (vpsUser['educationSystem'] ?? '').toString(),
            'grade': (vpsUser['gradeOrYear'] ?? '').toString(),
            'role': (vpsUser['role'] ?? 'student').toString(),
            'registrationDate': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        return cred;
      } on FirebaseAuthException catch (createErr) {
        if (createErr.code == 'email-already-in-use') {
          throw 'Your TF Passport exists under a different password or Google Sign-In. Tap "Continue with Google" or use "Forgot password?" to set your Firebase password.';
        }
        rethrow;
      }
    } catch (e) {
      if (e is String) rethrow;
      return null;
    }
  }

  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException().message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> logout() async {
    try {
      if (!kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
      }
      await _auth.signOut();
      await Future.microtask(() {});
      Get.offAll(() => const LoginScreen());
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        try {
          return await _auth.signInWithPopup(provider);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'popup-blocked' ||
              e.code == 'operation-not-supported-in-this-environment') {
            await _auth.signInWithRedirect(provider);
            return null;
          }
          if (e.code == 'popup-closed-by-user' ||
              e.code == 'cancelled-popup-request') {
            return null;
          }
          rethrow;
        }
      }

      if (!_googleSignInInitialized) {
        await _googleSignIn.initialize();
        _googleSignInInitialized = true;
      }

      final GoogleSignInAccount userAccount =
          await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = userAccount.authentication;
      final credentials = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credentials);
    } on GoogleSignInException catch (e) {
      if (kDebugMode) print('Google sign-in failed: ${e.code} ${e.description}');
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'unauthorized-domain') {
        throw 'This domain is not yet authorized in Firebase Auth. Please add the domain in Firebase Console -> Authentication -> Settings -> Authorized domains.';
      }
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      if (kDebugMode) print('Something went wrong: $e');
      return null;
    }
  }
}
