// lib/authentication/login_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tf_news/authentication/authentication_repository.dart';
import 'package:tf_news/authentication/user_controller.dart';
import 'package:tf_news/authentication/user_model.dart';
import 'package:tf_news/authentication/user_repository.dart';
import 'package:tf_news/utils/helpers/network_manager.dart';
import 'package:tf_news/utils/popups/full_screen_loader.dart';
import 'package:tf_news/utils/popups/loaders.dart';

class LoginController extends GetxController {
  final hidePassword = true.obs;
  final rememberMe = true.obs;
  final isRegisterMode = false.obs;
  final localStorage = GetStorage();

  final email = TextEditingController();
  final password = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final school = TextEditingController();

  final academicLevel = 'STEM'.obs;
  final grade = 'Grade 11'.obs;
  final savedAccounts = <Map<String, dynamic>>[].obs;

  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final userController = Get.find<UserController>();

  @override
  void onInit() {
    super.onInit();
    email.text = localStorage.read('Remember_Me_Email') ?? '';
    refreshSavedAccounts();
  }

  void refreshSavedAccounts() {
    savedAccounts.assignAll(AuthenticationRepository.instance.getSavedAccounts());
  }

  Future<void> quickLoginWithSavedAccount(Map<String, dynamic> acc) async {
    final savedEmail = (acc['email'] ?? '').toString().trim();
    final savedPw = (acc['password'] ?? '').toString();
    if (savedEmail.isEmpty) return;

    isRegisterMode.value = false;
    email.text = savedEmail;

    if (savedPw.isNotEmpty) {
      password.text = savedPw;
      await emailAndPasswordLogin();
      return;
    }

    password.clear();
    TLoaders.warningSnackBar(
      title: 'Account selected',
      message: 'Enter your password or tap "Continue with Google" to sign in as $savedEmail.',
    );
  }

  Future<void> removeSavedAccount(String accountEmail) async {
    await AuthenticationRepository.instance.removeSavedAccount(accountEmail);
    refreshSavedAccounts();
  }

  Future<void> emailAndPasswordLogin() async {
    try {
      TFuelScreenLoader.openLoadingDialog(
        'Logging in...',
        'assets/loading/loading.json',
      );

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFuelScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: 'No Connection',
          message: 'Please check your internet connection.',
        );
        return;
      }

      if (!loginFormKey.currentState!.validate()) {
        TFuelScreenLoader.stopLoading();
        return;
      }

      final trimmedEmail = email.text.trim();
      final trimmedPassword = password.text.trim();

      if (rememberMe.value) {
        localStorage.write('Remember_Me_Email', trimmedEmail);
      }

      final cred =
          await AuthenticationRepository.instance.loginWithEmailAndPassword(
        trimmedEmail,
        trimmedPassword,
      );

      await AuthenticationRepository.instance.saveAccountLocally(
        email: trimmedEmail,
        name: cred.user?.displayName ?? '',
        photoUrl: cred.user?.photoURL ?? '',
        password: rememberMe.value ? trimmedPassword : null,
        uid: cred.user?.uid,
      );
      refreshSavedAccounts();

      TFuelScreenLoader.stopLoading();
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFuelScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Login Failed', message: e.toString());
    }
  }

  Future<void> registerAccount() async {
    try {
      TFuelScreenLoader.openLoadingDialog(
        'Creating your TF Passport...',
        'assets/loading/loading.json',
      );

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFuelScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: 'No Connection',
          message: 'Please check your internet connection.',
        );
        return;
      }

      if (!loginFormKey.currentState!.validate()) {
        TFuelScreenLoader.stopLoading();
        return;
      }

      final trimmedEmail = email.text.trim();
      final trimmedPassword = password.text.trim();
      final fName = firstName.text.trim();
      final lName = lastName.text.trim();
      final fullName = '$fName $lName'.trim();

      final cred =
          await AuthenticationRepository.instance.registerWithEmailAndPassword(
        trimmedEmail,
        trimmedPassword,
      );

      if (cred.user != null && fullName.isNotEmpty) {
        try {
          await cred.user!.updateDisplayName(fullName);
        } catch (_) {}
      }

      final uid = cred.user?.uid ?? '';
      if (uid.isNotEmpty) {
        final newUser = UserModel(
          id: uid,
          firstName: fName.isNotEmpty ? fName : trimmedEmail.split('@').first,
          lastName: lName,
          username: fullName.isNotEmpty ? fullName : trimmedEmail.split('@').first,
          email: trimmedEmail.toLowerCase(),
          phone: phone.text.trim(),
          profilePicture: '',
          academicLevel: academicLevel.value,
          grade: grade.value,
          stemSchool: school.text.trim(),
        );
        await UserRepository.instance.saveUserRecord(newUser);
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'id': uid,
          'fullName': fullName,
          'level': academicLevel.value,
          'school': school.text.trim(),
          'role': 'student',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      try {
        await AuthenticationRepository.instance.sendEmailVerification();
      } catch (_) {}

      if (rememberMe.value) {
        localStorage.write('Remember_Me_Email', trimmedEmail);
      }

      await AuthenticationRepository.instance.saveAccountLocally(
        email: trimmedEmail,
        name: fullName,
        password: rememberMe.value ? trimmedPassword : null,
        uid: uid,
      );
      refreshSavedAccounts();

      TFuelScreenLoader.stopLoading();
      TLoaders.successSnackBar(
        title: 'Welcome to TF Unions',
        message: 'Your TF Passport is ready.',
      );
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFuelScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
        title: 'Registration Failed',
        message: e.toString(),
      );
    }
  }

  Future<void> googleLogin() async {
    try {
      TFuelScreenLoader.openLoadingDialog(
        'Signing in with Google...',
        'assets/loading/loading.json',
      );

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFuelScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: 'No Connection',
          message: 'Please check your internet connection.',
        );
        return;
      }
      final userCredentials =
          await AuthenticationRepository.instance.signInWithGoogle();
      if (userCredentials == null) {
        TFuelScreenLoader.stopLoading();
        return;
      }

      await userController.saveUserRecord(userCredentials);

      final u = userCredentials.user;
      if (u != null) {
        await AuthenticationRepository.instance.saveAccountLocally(
          email: u.email ?? '',
          name: u.displayName ?? '',
          photoUrl: u.photoURL ?? '',
          uid: u.uid,
        );
        refreshSavedAccounts();
      }

      TFuelScreenLoader.stopLoading();
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFuelScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Login Failed', message: e.toString());
    }
  }
}