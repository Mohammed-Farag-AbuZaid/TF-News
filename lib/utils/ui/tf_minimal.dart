// lib/utils/ui/tf_minimal.dart
// Shared UI primitives for tf_news (TF Oxford & Stone architectural system):
// Deep Oxford Navy masthead, Warm Architectural Stone canvas (#ECEAE4),
// Crisp White widget ledgers (#FFFFFF) bordered by Stone Hairlines (#CFCBC2),
// Royal Cobalt (#14388C) primary actions, and Academic Brass (#C88A14) marks.
import 'package:flutter/material.dart';
import 'package:tf_news/utils/constants/colors.dart';
import 'package:tf_news/utils/ui/tf_ui.dart'
    show tfGoBack, tfGoHome, tfSidePadding, TfBreakpoints, Pulse, SkeletonBox;

// ---------------------------------------------------------------------------
// Colors (TF Oxford & Stone)
// ---------------------------------------------------------------------------

const Color tfInk = Color(0xFF12161F);
const Color tfMuted = Color(0xFF4A5262);
const Color tfTile = Color(0xFFE2DFD7);
const Color tfHair = Color(0xFFCFCBC2);
const Color tfAccent = TColors.primary; // #14388C Royal Cobalt
const Color tfUrgent = Color(0xFFB91C1C);
const Color tfGood = Color(0xFF15803D);

const Color tfNavy = Color(0xFF0A1931);
const Color tfNavyAlt = Color(0xFF102447);
const Color tfNavyLine = Color(0xFF1E3A6D);
const Color tfGold = Color(0xFFC88A14);
const Color tfCanvas = Color(0xFFECEAE4);
const Color tfPaper = Color(0xFFFFFFFF);

// ---------------------------------------------------------------------------
// Layout helper
// ---------------------------------------------------------------------------

class TfLayout {
  final double pad;
  final bool small;
  final bool wide;
  const TfLayout(this.pad, this.small, this.wide);

  Widget box(Widget child) => SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: child,
        ),
      );

  Widget gap(double h) => SliverToBoxAdapter(child: SizedBox(height: h));

  Widget rows(int count, IndexedWidgetBuilder builder) => SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: pad),
        sliver: SliverList.builder(
          itemCount: count,
          itemBuilder: (context, i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: tfPaper,
              border: Border(
                left: const BorderSide(color: tfHair),
                right: const BorderSide(color: tfHair),
                top: i == 0 ? const BorderSide(color: tfHair) : BorderSide.none,
                bottom: i == count - 1
                    ? const BorderSide(color: tfHair)
                    : BorderSide.none,
              ),
            ),
            child: builder(context, i),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Page shell
// ---------------------------------------------------------------------------

class TfPage extends StatelessWidget {
  final String? backLabel; // null = no back link
  final List<Widget> Function(BuildContext context, TfLayout l) slivers;
  final Widget? Function(TfLayout l)? bottomBar;
  final ScrollController? controller;
  final double maxWidth;

  const TfPage({
    super.key,
    required this.slivers,
    this.backLabel,
    this.bottomBar,
    this.controller,
    this.maxWidth = 1040,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tfCanvas,
      bottomNavigationBar: bottomBar == null
          ? null
          : LayoutBuilder(
              builder: (_, c) {
                final l = _layoutFor(c.maxWidth);
                return bottomBar!(l) ?? const SizedBox.shrink();
              },
            ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final l = _layoutFor(c.maxWidth);
            return Column(
              children: [
                // Full-width Deep Oxford Navy masthead matching www.tfunions.com
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: tfNavy,
                    border: Border(
                      bottom: BorderSide(color: tfNavyLine, width: 1),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: l.pad),
                      child: TfTopBar(backLabel: backLabel),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: CustomScrollView(
                        controller: controller,
                        slivers: [
                          ...slivers(context, l),
                          const SliverToBoxAdapter(child: SizedBox(height: 64)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  TfLayout _layoutFor(double w) => TfLayout(
        tfSidePadding(w) + (w < 700 ? 0 : 8),
        w < TfBreakpoints.mobile,
        w >= 900,
      );
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class TfTopBar extends StatelessWidget {
  final String? backLabel;
  const TfTopBar({super.key, this.backLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          if (backLabel != null)
            InkWell(
              onTap: () => tfGoBack(context),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: tfNavyAlt,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: tfNavyLine),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      backLabel!,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          const Spacer(),
          InkWell(
            onTap: tfGoHome,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tfNavyAlt,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: tfGold, width: 1.5),
                    ),
                    child: const Text(
                      'TF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'TF News',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page title
// ---------------------------------------------------------------------------

class TfTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool small;
  const TfTitle({super.key, required this.title, this.subtitle, required this.small});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(small ? 18 : 24),
      decoration: BoxDecoration(
        color: tfPaper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tfHair),
        boxShadow: const [
          BoxShadow(color: Color(0x0D0A1931), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 3,
            color: tfGold,
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              title,
              style: TextStyle(
                fontSize: small ? 28 : 40,
                fontWeight: FontWeight.w700,
                color: tfNavy,
                letterSpacing: -0.9,
                height: 1.08,
              ),
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 15.5,
                color: tfMuted,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontal text tabs
// ---------------------------------------------------------------------------

class TfTabs extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelected;
  const TfTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: tfPaper,
        border: Border(
          top: BorderSide(color: tfHair),
          left: BorderSide(color: tfHair),
          right: BorderSide(color: tfHair),
          bottom: BorderSide(color: tfHair),
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: items.length,
        separatorBuilder: (_, i) => const SizedBox(width: 22),
        itemBuilder: (_, i) {
          final item = items[i];
          final active = item == selected;
          return InkWell(
            onTap: () => onSelected(item),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? tfAccent : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? tfNavy : tfMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Segmented control
// ---------------------------------------------------------------------------

class TfSegmented extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelected;
  const TfSegmented({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tfTile,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tfHair),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            InkWell(
              onTap: () => onSelected(item),
              borderRadius: BorderRadius.circular(4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: item == selected ? tfPaper : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: item == selected ? tfHair : Colors.transparent,
                  ),
                  boxShadow: item == selected
                      ? const [
                          BoxShadow(
                            color: Color(0x140A1931),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        item == selected ? FontWeight.w700 : FontWeight.w600,
                    color: item == selected ? tfNavy : tfMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Text dropdown menu
// ---------------------------------------------------------------------------

class TfMenu extends StatelessWidget {
  final String label;
  final String valueLabel;
  final String value;
  final Map<String, String> options; // key -> shown text
  final ValueChanged<String> onSelected;

  const TfMenu({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: tfPaper,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: tfHair),
      ),
      itemBuilder: (_) => [
        for (final e in options.entries)
          PopupMenuItem(
            value: e.key,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  child: e.key == value
                      ? const Icon(Icons.check, size: 15, color: tfAccent)
                      : null,
                ),
                Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 14,
                    color: tfInk,
                    fontWeight: e.key == value ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tfPaper,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: tfHair),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: const TextStyle(fontSize: 13, color: tfMuted, fontWeight: FontWeight.w500),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                fontSize: 13,
                color: tfNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: tfInk),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class TfSearch extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const TfSearch({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: tfInk, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: tfMuted),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: tfMuted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded, size: 16, color: tfMuted),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        isDense: true,
        filled: true,
        fillColor: tfPaper,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: tfHair),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: tfHair),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: tfAccent, width: 1.5),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

class TfPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  const TfPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: tfAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 16),
          ],
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class TfTextAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const TfTextAction({super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: tfAccent,
        backgroundColor: tfPaper,
        side: const BorderSide(color: tfHair),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty + skeleton
// ---------------------------------------------------------------------------

class TfEmpty extends StatelessWidget {
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TfEmpty({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: tfPaper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tfHair),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 3,
            color: tfGold,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tfNavy,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: tfMuted,
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            TfTextAction(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

class TfRowSkeletons extends StatelessWidget {
  final int count;
  const TfRowSkeletons({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: tfPaper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tfHair),
      ),
      child: Pulse(
        child: Column(
          children: [
            for (var i = 0; i < count; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: i == count - 1
                        ? BorderSide.none
                        : const BorderSide(color: tfHair, width: 0.7),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 16, width: i.isEven ? 240 : 190),
                    const SizedBox(height: 8),
                    const SkeletonBox(height: 12, width: double.infinity),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
