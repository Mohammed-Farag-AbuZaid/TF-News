// lib/common/common_widgets.dart
// Contains: TSpacingStyle, TAppBar, TTabBar, VisitTFButton,
// TRoundedContainer, TCircularContianer, TCircularIcon,
// TCircularImage, TRoundedImage

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tf_news/utils/constants/colors.dart';
import 'package:tf_news/utils/constants/image_strings.dart';
import 'package:tf_news/utils/constants/sizes.dart';
import 'package:tf_news/utils/device/device_utility.dart';
import 'package:tf_news/utils/helpers/helper_functions.dart';
import 'package:tf_news/utils/popups/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// Styles
// ---------------------------------------------------------------------------

class TSpacingStyle {
  static const EdgeInsetsGeometry paddingWithAppBarHieght = EdgeInsets.only(
    top: TSizes.appBarHeight,
    left: TSizes.defaultSpace,
    right: TSizes.defaultSpace,
    bottom: TSizes.defaultSpace,
  );
}

// ---------------------------------------------------------------------------
// App bar / tab bar / buttons
// ---------------------------------------------------------------------------

class TAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TAppBar({
    super.key,
    this.title,
    this.actions,
    this.leadingIcon,
    this.leadingOnPressed,
    this.showBackArrow = false,
  });

  final Widget? title;
  final bool showBackArrow;
  final IconData? leadingIcon;
  final List<Widget>? actions;
  final VoidCallback? leadingOnPressed;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
      child: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackArrow
            ? IconButton(
                onPressed: () => Get.back(),
                icon: Icon(
                  Iconsax.arrow_left,
                  color: dark ? TColors.white : TColors.dark,
                ),
              )
            : leadingIcon != null
                ? IconButton(
                    onPressed: leadingOnPressed,
                    icon: Icon(leadingIcon),
                  )
                : null,
        title: title,
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(TDeviceUtils.getAppBarHeight());
}

class TTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget> tabs;

  const TTabBar({super.key, required this.tabs});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Material(
      color: dark ? Colors.black : Colors.white,
      child: TabBar(
        isScrollable: true,
        indicatorColor: TColors.primary,
        unselectedLabelColor: TColors.darkGrey,
        labelColor: dark ? Colors.white : Colors.black,
        tabs: tabs,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(TDeviceUtils.getAppBarHeight());
}

class VisitTFButton extends StatelessWidget {
  const VisitTFButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final uri = Uri.parse('https://tfunions.vercel.app/');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: const Text('Visit TF-Unions'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Containers
// ---------------------------------------------------------------------------

class TRoundedContainer extends StatelessWidget {
  const TRoundedContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.showBorder = false,
    this.radius = TSizes.cardRadiusLg,
    this.backgroundColor = TColors.white,
    this.borderColor = TColors.borderPrimary,
  });

  final double? width;
  final double? height;
  final double radius;
  final Widget? child;
  final bool showBorder;
  final Color borderColor;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder ? Border.all(color: borderColor) : null,
      ),
      child: child,
    );
  }
}

/// Kept as-is (same name, same defaults) so existing usages don't break.
/// It is nearly identical to [TRoundedContainer]; the only differences are
/// the parameter name `borderRadius` and the default `TColors.textwhite`.
/// Once you've replaced its usages you can delete it.
class TCircularContianer extends StatelessWidget {
  const TCircularContianer({
    super.key,
    this.width,
    this.height,
    this.padding = EdgeInsets.zero,
    this.borderRadius = TSizes.cardRadiusLg,
    this.backgroundColor = TColors.textwhite,
    this.child,
    this.margin,
    this.showBorder = false,
    this.borderColor = TColors.borderPrimary,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final Color backgroundColor;
  final Widget? child;
  final Color borderColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return TRoundedContainer(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      radius: borderRadius,
      backgroundColor: backgroundColor,
      showBorder: showBorder,
      borderColor: borderColor,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Icons & images
// ---------------------------------------------------------------------------

class TCircularIcon extends StatelessWidget {
  const TCircularIcon({
    super.key,
    required this.icon,
    this.width,
    this.height,
    this.size = TSizes.lg,
    this.onPressed,
    this.color,
    this.backgroundColor,
  });

  final double? width, height, size;
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (dark
                ? TColors.black.withValues(alpha: 0.9)
                : TColors.white.withValues(alpha: 0.9)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: size),
      ),
    );
  }
}

class TCircularImage extends StatelessWidget {
  const TCircularImage({
    super.key,
    required this.imagePath,
    this.borderRadius = TSizes.md,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.applyImageRadius = true,
    this.border,
    this.padding,
    this.isNetworkImage = false,
    this.onPressed,
    this.backgroundColor,
  });

  final String imagePath;
  final double borderRadius;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final bool applyImageRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final bool isNetworkImage;
  final VoidCallback? onPressed;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (THelperFunctions.isDarkMode(context)
                ? TColors.black
                : TColors.white),
        borderRadius: BorderRadius.circular(100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: isNetworkImage
            ? CachedNetworkImage(
                fit: fit,
                color: backgroundColor,
                imageUrl: imagePath,
                progressIndicatorBuilder: (context, url, downloadProgress) =>
                    const TShimerEffect(width: 55, height: 55),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
            : Image(
                fit: fit,
                image: AssetImage(imagePath),
                color: backgroundColor,
              ),
      ),
    );
  }
}

class TRoundedImage extends StatelessWidget {
  const TRoundedImage({
    super.key,
    required this.imagePath,
    this.borderRadius = TSizes.md,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.applyImageRadius = true,
    this.border,
    this.padding,
    this.isNetworkImage = false,
    this.onPressed,
    this.backgroundColor = TColors.light,
  });

  final String imagePath;
  final double borderRadius;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final bool applyImageRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final bool isNetworkImage;
  final VoidCallback? onPressed;
  final Color backgroundColor;

  ImageProvider _resolveImage(String path) {
    if (path.isEmpty) return AssetImage(TImages.google);
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return AssetImage(path);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
          color: backgroundColor,
        ),
        padding: padding,
        child: ClipRRect(
          borderRadius: applyImageRadius
              ? BorderRadius.circular(borderRadius)
              : BorderRadius.zero,
          child: Image(
            image: _resolveImage(imagePath),
            fit: fit,
            width: width,
            height: height,
          ),
        ),
      ),
    );
  }
}