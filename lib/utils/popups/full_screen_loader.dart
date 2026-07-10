import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/utils/constants/colors.dart';
import 'package:tf_news/utils/helpers/helper_functions.dart';
import 'package:tf_news/utils/popups/animation_loader.dart';

class TFuelScreenLoader {
  static void openLoadingDialog(String text, String animation) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: THelperFunctions.isDarkMode(Get.context!)
              ? TColors.dark
              : TColors.white,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TAnimationLoaderWidget(text: text, animation: animation),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void stopLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}