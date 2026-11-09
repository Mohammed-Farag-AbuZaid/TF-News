// lib/authentication/authentication_repository.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:tf_news/authentication/change_academic_info_screen.dart';
import 'package:tf_news/authentication/login_screen.dart';
import 'package:tf_news/authentication/user_controller.dart';
import 'package:tf_news/authentication/user_model.dart';
import 'package:tf_news/data/opportunity.dart' show kTfApiBaseUrl;
import 'package:tf_news/pages/home_page.dart';
import 'package:tf_news/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:tf_news/utils/exceptions/firebase_exceptions.dart';
import 'package:tf_news/utils/exceptions/formate_exceptions.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  final deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  User? get authUser => _auth.currentUser;

  Map<String, dynamic>? get vpsSessionUser {
    final raw = deviceStorage.read('tf_vps_user');
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  bool get isSignedIn => _auth.currentUser != null || vpsSessionUser != null;

  /// Where to go after the app opens or after login.
  void screenRedirect() async {
    final vpsUser = vpsSessionUser;
    if (vpsUser != null) {
      await Future.microtask(() {});
      try {
        final ctrl = Get.find<UserController>();
        final fullName = (vpsUser['full_name'] ?? vpsUser['firstName'] ?? '').toString();
        final parts = UserModel.nameParts(fullName);
        ctrl.user(UserModel(
          id: (vpsUser['id'] ?? '').toString(),
          firstName: (vpsUser['firstName'] ?? (parts.isNotEmpty ? parts[0] : '')).toString(),
          lastName: (vpsUser['lastName'] ?? (parts.length > 1 ? parts.sublist(1).join(' ') : '')).toString(),
          username: (vpsUser['username'] ?? fullName).toString(),
          email: (vpsUser['email'] ?? '').toString(),
          phone: (vpsUser['phone'] ?? '').toString(),
          profilePicture: (vpsUser['profilePicture'] ?? '').toString(),
          academicLevel: (vpsUser['academicLevel'] ?? '').toString(),
          grade: (vpsUser['grade'] ?? '').toString(),
          stemSchool: (vpsUser['stemSchool'] ?? vpsUser['school_chapter'] ?? '').toString(),
        ));
      } catch (_) {}
      Get.offAll(() => const HomeScreen());
      return;
    }

    final user = _auth.currentUser;

    if (user != null) {
      Map<String, dynamic> data = <String, dynamic>{};
      bool exists = false;
      try {
        final res = await http
            .get(Uri.parse('$kTfApiBaseUrl/api/collections/users/${user.uid}'))
            .timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          data = (body['data'] as Map<String, dynamic>?) ?? body;
          exists = true;
        }
      } catch (_) {}

      if (!exists) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        exists = doc.exists;
        data = doc.data() ?? <String, dynamic>{};
      }

      await Future.microtask(() {});

      final firstName = data['firstName'];
      final lastName = (data['lastName'] as String?) ?? '';

      if (!exists || firstName == null || lastName.isEmpty) {
        Get.offAll(
          () => const ChangeAcademicInfo(
            showBackArrow: false,
            fullMessage: false,
            title: 'Your Account Setup is Incomplete',
            description:
                'It looks like your account information has not been fully set up yet. Please visit the TF Passport portal to complete your registration and account details.',
          ),
        );
      } else {
        Get.offAll(() => const HomeScreen());
      }
    } else {
      await Future.microtask(() {});
      Get.offAll(() => const LoginScreen());
    }
  }

  Future<UserCredential?> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    // 1. Try VPS SSO API first
    try {
      final res = await http
          .post(
            Uri.parse('$kTfApiBaseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        await deviceStorage.write('tf_vps_token', body['access_token']);
        await deviceStorage.write('tf_vps_user', body['user']);
        return null;
      }
    } catch (_) {}

    // 2. Fallback to Firebase Auth for legacy un-reset passwords
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred;
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code);
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code);
    } on FormatException catch (_) {
      throw const TFormatException();
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
      await deviceStorage.remove('tf_vps_token');
      await deviceStorage.remove('tf_vps_user');
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
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
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      if (kDebugMode) print('Something went wrong: $e');
      return null;
    }
  }
}
