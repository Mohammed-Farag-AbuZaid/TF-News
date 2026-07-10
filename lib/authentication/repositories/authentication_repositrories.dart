import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tf_news/authentication/screens/changeinfo.dart';
import 'package:tf_news/authentication/screens/email_verification.dart';
import 'package:tf_news/authentication/screens/loging/login.dart';
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

  @override
  void onReady() {
    screenRedirect();
  }

  void screenRedirect() async {
    final user = _auth.currentUser;

    if (user != null) {
      if (user.emailVerified) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!doc.exists ||
            (doc.data() ?? {})['firstName'] == null ||
            (doc.data()!['lastName'] as String).isEmpty) {
          Get.offAll(
            () => const ChangeAcademicInfo(
              showBackArrow: false,
              fullMessage: false,
              title: 'Your Account Setup is Incomplete',
              description:
                  'It looks like your account information has not been fully set up yet. This usually happens when you sign in with Google before creating an account on the TF Unions website. Please visit the TF Unions website to complete your registration and account details.',
            ),
          );
        } else {
          Get.offAll(() => const HomeScreen());
        }
      } else {
        Get.offAll(() => const EmailVerification());
      }
    } else {
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
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      await FirebaseAuth.instance.signOut();
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

      final GoogleSignInAccount userAccount = await _googleSignIn.authenticate();

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