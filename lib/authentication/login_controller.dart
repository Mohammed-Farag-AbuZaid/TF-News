// lib/authentication/login_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tf_news/authentication/authentication_repository.dart';
import 'package:tf_news/authentication/user_controller.dart';
import 'package:tf_news/utils/helpers/network_manager.dart';
import 'package:tf_news/utils/popups/full_screen_loader.dart';
import 'package:tf_news/utils/popups/loaders.dart';

class LoginController extends GetxController {
  final hidePassword = true.obs;
  final rememberMe = true.obs;
  final localStorage = GetStorage();
  final email = TextEditingController();
  final password = TextEditingController();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final userController = Get.find<UserController>();

  @override
  void onInit() {
    super.onInit();
    email.text = localStorage.read('Remember_Me_Email') ?? '';
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

      if (rememberMe.value) {
        localStorage.write('Remember_Me_Email', email.text.trim());
      }

      await AuthenticationRepository.instance.loginWithEmailAndPassword(
        email.text.trim(),
        password.text.trim(),
      );

      TFuelScreenLoader.stopLoading();
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFuelScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Login Failed', message: e.toString());
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
      final isNewUser =
          userCredentials?.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        await userController.saveUserRecord(userCredentials);
      }

      TFuelScreenLoader.stopLoading();
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFuelScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Login Failed', message: e.toString());
    }
  }
}