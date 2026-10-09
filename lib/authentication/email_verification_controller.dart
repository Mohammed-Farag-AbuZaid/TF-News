// lib/authentication/email_verification_controller.dart
import 'package:get/get.dart';
import 'package:tf_news/authentication/authentication_repository.dart';
import 'package:tf_news/utils/helpers/network_manager.dart';
import 'package:tf_news/utils/popups/full_screen_loader.dart';
import 'package:tf_news/utils/popups/loaders.dart';

class EmailVerificationController extends GetxController {
  static EmailVerificationController get instance => Get.find();

  Future<void> resendEmailVerificationEmail(String email) async {
    try {
      TFuelScreenLoader.openLoadingDialog(
        'Sending verification email...',
        'assets/loading/loading.json',
      );

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFuelScreenLoader.stopLoading();
        TLoaders.warningSnackBar(
          title: 'No Connection',
          message: 'Please check your internet connection.',
        );
        return;
      }

      await AuthenticationRepository.instance.sendEmailVerification();

      TFuelScreenLoader.stopLoading();
      TLoaders.warningSnackBar(
        title: 'Email Verification',
        message:
            'A verification email has been sent to $email. Please check your inbox.',
      );
    } catch (e) {
      TFuelScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Error', message: e.toString());
    }
  }
}