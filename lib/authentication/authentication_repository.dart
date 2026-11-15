// lib/authentication/authentication_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tf_news/authentication/change_academic_info_screen.dart';
import 'package:tf_news/authentication/email_verification_screen.dart';
import 'package:tf_news/authentication/login_screen.dart';
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

  bool get isSignedIn => _auth.currentUser != null;

  /// Where to go after the app opens or after login.
  Future<void> screenRedirect() async {
    var user = _auth.currentUser;

    if (user != null) {
      try {
        await user.reload();
        user = _auth.currentUser;
      } catch (_) {}
    }

    if (user != null) {
      if (user.emailVerified) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data() ?? <String, dynamic>{};

        await Future.microtask(() {});

        final firstName = (data['firstName'] as String?)?.trim() ?? '';
        final fullName = (data['fullName'] as String?)?.trim() ?? '';

        if (!doc.exists || (firstName.isEmpty && fullName.isEmpty)) {
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
        Get.offAll(() => const EmailVerification());
      }
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
      return await _auth.signInWithEmailAndPassword(
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
        return await _auth.signInWithPopup(provider);
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
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      if (kDebugMode) print('Something went wrong: $e');
      return null;
    }
  }
}
