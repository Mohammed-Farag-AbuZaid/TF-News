// lib/authentication/forget_password_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/authentication_repository.dart';
import 'package:tf_news/authentication/reset_password_screen.dart';
import 'package:tf_news/utils/helpers/network_manager.dart';
import 'package:tf_news/utils/popups/full_screen_loader.dart';
import 'package:tf_news/utils/popups/loaders.dart';

class ForgetPasswordController extends GetxController {
  static ForgetPasswordController get instance => Get.find();

  final email = TextEditingController();
  final GlobalKey<FormState> forgetPasswordFormKey = GlobalKey<FormState>();

  Future<void> sendPasswordResetEmail() async {
    try {
      TFuelScreenLoader.openLoadingDialog(
        'Sending password reset email...',
        'assets/loading/loading.json',
      );

      if (!await _hasConnection()) return;

      if (!forgetPasswordFormKey.currentState!.validate()) {
        TFuelScreenLoader.stopLoading();
        return;
      }

      final userEmail = email.text.trim();
      await AuthenticationRepository.instance.sendPasswordResetEmail(userEmail);

      TFuelScreenLoader.stopLoading();
      _showSentMessage(userEmail);

      Get.to(() => ResetPassword(email: userEmail));
    } catch (e) {
      TFuelScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Error', message: e.toString());
    }
  }

  Future<void> resendPasswordResetEmail(String email) async {
    try {
      TFuelScreenLoader.openLoadingDialog(
        'Sending password reset email...',
        'assets/loading/loading.json',
      );

      if (!await _hasConnection()) return;

      await AuthenticationRepository.instance.sendPasswordResetEmail(email);

      TFuelScreenLoader.stopLoading();
      _showSentMessage(email);
    } catch (e) {
      TFuelScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Error', message: e.toString());
    }
  }

  /// Stops the loader and warns the user if offline. Returns true if online.
  Future<bool> _hasConnection() async {
    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      TFuelScreenLoader.stopLoading();
      TLoaders.warningSnackBar(
        title: 'No Connection',
        message: 'Please check your internet connection.',
      );
    }
    return isConnected;
  }

  void _showSentMessage(String email) {
    TLoaders.warningSnackBar(
      title: 'Reset Password',
      message:
          'A password reset email has been sent to $email. Please check your inbox.',
    );
  }

  @override
  void onClose() {
    email.dispose();
    super.onClose();
  }
}