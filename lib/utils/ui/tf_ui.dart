// lib/utils/ui/tf_ui.dart
// Shared UI kit for TF News: colours, responsive helpers, loading / empty / error
// states, search box, sort menu, hover effect. No new packages needed.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:tf_news/utils/constants/colors.dart';

// ---------------------------------------------------------------------------
// Colours (all pass WCAG AA contrast on white)
// ---------------------------------------------------------------------------

const Color kInk = Color(0xFF111827); // main text
const Color kMuted = Color(0xFF6B7280); // secondary text (4.8:1 on white)
const Color kBorder = Color(0xFFE5E7EB);
const Color kSurface = Color(0xFFF9FAFB);
const Color kGood = Color(0xFF15803D); // green: open / full coverage
const Color kWarn = Color(0xFFB45309); // amber: closing soon / partial
const Color kBad = Color(0xFFB91C1C); // red: urgent / must-know

// ---------------------------------------------------------------------------
// Responsive helpers
// ---------------------------------------------------------------------------

class TfBreakpoints {
  static const double mobile = 700; // below = phone layout
  static const double desktop = 900; // above = side panel layout
  static const double maxContent = 1280;
}

double tfSidePadding(double width) => width < TfBreakpoints.mobile ? 16 : 24;

/// Grid card height that grows when the user enlarges text, so nothing overflows.
double tfScaledExtent(BuildContext context, double base) {
  final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
  return base * scale.clamp(1.0, 1.5).toDouble();
}

/// Lets mouse users drag horizontal lists (filter chips) on the web.
class TfScrollBehavior extends MaterialScrollBehavior {
  const TfScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

// ---------------------------------------------------------------------------
// Navigation helpers
// ---------------------------------------------------------------------------

void tfGoHome() => Get.offAllNamed('/HomeScreen');

/// Back if there is a page to go back to, otherwise home
/// (a shared link opens a page with no history).
void tfGoBack(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    Get.back();
  } else {
    tfGoHome();
  }
}

class TfBackLink extends StatelessWidget {
  final String label;
  const TfBackLink({super.key, this.label = 'Back'});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: 'Go back',
        child: InkWell(
          onTap: () => tfGoBack(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios_new, size: 14, color: kMuted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kMuted, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hover lift (cards rise slightly under the mouse on the web)
// ---------------------------------------------------------------------------

class HoverLift extends StatefulWidget {
  final Widget child;
  final double radius;
  const HoverLift({super.key, required this.child, this.radius = 12});

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hover = false;

  /// The mouse "exit" event fires while a page is being removed (for example
  /// right after the card was tapped). Calling setState at that moment throws
  /// "Looking up a deactivated widget's ancestor is unsafe", so skip it when
  /// we are no longer mounted and wait for the frame to finish if we are mid-build.
  void _setHover(bool value) {
    if (!mounted || _hover == value) return;
    final building =
        SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks;
    if (building) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _hover != value) setState(() => _hover = value);
      });
    } else {
      setState(() => _hover = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: _hover
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small pill / badge
// ---------------------------------------------------------------------------

class TfPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const TfPill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeletons
// ---------------------------------------------------------------------------

/// Gently pulses its child. Does nothing if the user asked for reduced motion.
class Pulse extends StatefulWidget {
  final Widget child;
  const Pulse({super.key, required this.child});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  // Created in initState. (It used to be created lazily, so when reduced motion
  // was on it was first created inside dispose(), which crashed the widget tree.)
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1.0).animate(_c),
      child: widget.child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Pulse(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 120, height: 10),
            SizedBox(height: 18),
            SkeletonBox(height: 16),
            SizedBox(height: 8),
            SkeletonBox(width: 180, height: 16),
            SizedBox(height: 16),
            SkeletonBox(height: 11),
            SizedBox(height: 8),
            SkeletonBox(height: 11),
            Spacer(),
            SkeletonBox(width: 110, height: 11),
            SizedBox(height: 14),
            SkeletonBox(height: 38, radius: 8),
          ],
        ),
      ),
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  final int count;
  final double extent;
  final double maxCrossAxisExtent;
  const SkeletonGrid({
    super.key,
    this.count = 6,
    required this.extent,
    this.maxCrossAxisExtent = 480,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        mainAxisExtent: extent,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty and error states
// ---------------------------------------------------------------------------

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = Icons.search_off,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: TColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: TColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: kInk),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kMuted, height: 1.5),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly failure message. The technical error is only written to the log.
class ErrorState extends StatelessWidget {
  final VoidCallback? onRetry;
  final String title;
  final String message;

  const ErrorState({
    super.key,
    this.onRetry,
    this.title = 'We could not load this',
    this.message = 'Check your connection and try again.',
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: title,
      message: message,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
    );
  }
}

// ---------------------------------------------------------------------------
// Search box (waits 250 ms after typing so long lists stay fast)
// ---------------------------------------------------------------------------

class TfSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const TfSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  @override
  State<TfSearchField> createState() => _TfSearchFieldState();
}

class _TfSearchFieldState extends State<TfSearchField> {
  late final TextEditingController _c =
      widget.controller ?? TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.controller == null) _c.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _c,
      builder: (context, value, _) {
        return TextField(
          controller: _c,
          textInputAction: TextInputAction.search,
          onChanged: (s) {
            _timer?.cancel();
            _timer = Timer(
              const Duration(milliseconds: 250),
              () => widget.onChanged(s),
            );
          },
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            hintText: widget.hint,
            hintStyle: const TextStyle(color: kMuted),
            prefixIcon: const Icon(Icons.search, size: 20, color: kMuted),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _timer?.cancel();
                      _c.clear();
                      widget.onChanged('');
                    },
                  ),
            border: _border(kBorder),
            enabledBorder: _border(kBorder),
            focusedBorder: _border(TColors.primary),
          ),
        );
      },
    );
  }
}

class TfSortMenu extends StatelessWidget {
  final String value;
  final Map<String, String> options; // key -> label
  final ValueChanged<String> onSelected;

  const TfSortMenu({
    super.key,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Change how the list is ordered',
      onSelected: onSelected,
      itemBuilder: (_) => options.entries
          .map((e) => CheckedPopupMenuItem<String>(
                value: e.key,
                checked: e.key == value,
                child: Text(e.value),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 18, color: kMuted),
            const SizedBox(width: 6),
            Text(
              options[value] ?? '',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: kInk),
            ),
            const Icon(Icons.arrow_drop_down, color: kMuted),
          ],
        ),
      ),
    );
  }
}

/// "Filters" button for phones (opens a bottom sheet). [activeCount] shows a badge.
class TfFilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;
  const TfFilterButton({super.key, required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: activeCount > 0
              ? TColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          border: Border.all(
              color: activeCount > 0 ? TColors.primary : kBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: 18, color: TColors.primary),
            const SizedBox(width: 6),
            Text(
              activeCount > 0 ? 'Filters ($activeCount)' : 'Filters',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom bar with one main action, shown on phones so "Apply" is always reachable.
class TfStickyActionBar extends StatelessWidget {
  final Widget child;
  const TfStickyActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: child,
        ),
      ),
    );
  }
}

/// Small shortcut for a consistent confirmation message.
void tfToast(String title, String message) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
    maxWidth: 420,
    duration: const Duration(seconds: 2),
  );
}