// lib/utils/ui/tf_minimal.dart
// Shared parts for the minimal TF News style: one accent colour, hairlines,
// large type, no shadows. Every redesigned page is built from these.
import 'package:flutter/material.dart';
import 'package:tf_news/utils/constants/colors.dart';
import 'package:tf_news/utils/ui/tf_ui.dart'
    show tfGoBack, tfGoHome, tfSidePadding, TfBreakpoints, Pulse, SkeletonBox;

// ---------------------------------------------------------------------------
// Tokens
// ---------------------------------------------------------------------------

const Color tfInk = Color(0xFF1D1D1F);
const Color tfMuted = Color(0xFF6E6E73);
const Color tfTile = Color(0xFFF5F5F7);
const Color tfHair = Color(0xFFD2D2D7);
const Color tfAccent = TColors.primary;
const Color tfUrgent = Color(0xFFB91C1C);
const Color tfGood = Color(0xFF15803D);

// ---------------------------------------------------------------------------
// Page frame
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
        sliver: SliverList.builder(itemCount: count, itemBuilder: builder),
      );
}

/// White page, thin top bar, centred content column, bottom breathing room.
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
    this.maxWidth = 1000,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final small = c.maxWidth < TfBreakpoints.mobile;
      final l = TfLayout(
        tfSidePadding(c.maxWidth) + (small ? 0 : 8),
        small,
        c.maxWidth >= 820,
      );
      return Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: bottomBar?.call(l),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  l.box(TfTopBar(backLabel: backLabel)),
                  ...slivers(context, l),
                  l.gap(72),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class TfTopBar extends StatelessWidget {
  final String? backLabel;
  const TfTopBar({super.key, this.backLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: tfHair, width: 0.5)),
      ),
      child: Row(
        children: [
          if (backLabel != null)
            Semantics(
              button: true,
              label: 'Go back',
              child: InkWell(
                onTap: () => tfGoBack(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chevron_left, color: tfAccent, size: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          backLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: tfAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Spacer(),
          InkWell(
            onTap: tfGoHome,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Text(
                'TF News',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: tfInk,
                  letterSpacing: -0.2,
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
// Type
// ---------------------------------------------------------------------------

class TfTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool small;
  const TfTitle({super.key, required this.title, this.subtitle, required this.small});

  @override
  Widget build(BuildContext context) {
    // Fluid size: grows smoothly with the window instead of jumping at one width.
    final size =
        (MediaQuery.sizeOf(context).width * 0.05).clamp(32.0, 52.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: TextStyle(
              color: tfInk,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: -size * 0.03,
              fontSize: size,
            ),
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(subtitle!,
              style: const TextStyle(color: tfMuted, fontSize: 17, height: 1.45)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Controls
// ---------------------------------------------------------------------------

/// Text tabs with an underline on the selected one (scrolls sideways on phones).
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
    final tabs = <Widget>[
          for (final t in items)
            Semantics(
              button: true,
              selected: t == selected,
              child: InkWell(
                onTap: () => onSelected(t),
                child: Container(
                  margin: const EdgeInsets.only(right: 28),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: t == selected ? tfInk : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t == selected ? tfInk : tfMuted,
                    ),
                  ),
                ),
              ),
            ),
    ];
    // Laptops: tabs wrap onto a second line (a mouse wheel cannot scroll sideways).
    // Phones: one swipeable row.
    return MediaQuery.sizeOf(context).width >= 700
        ? Wrap(children: tabs)
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: tabs),
          );
  }
}

/// Small grey switch for 2 to 3 mutually exclusive options.
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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tfTile,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final t in items)
            Semantics(
              button: true,
              selected: t == selected,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: t == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: t == selected ? tfHair : Colors.transparent,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t == selected ? tfInk : tfMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Label: value v" button that opens a plain menu.
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
      tooltip: label,
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final e in options.entries)
          PopupMenuItem<String>(
            value: e.key,
            child: Row(
              children: [
                Expanded(
                  child: Text(e.value,
                      style: const TextStyle(fontSize: 14, color: tfInk)),
                ),
                if (e.key == value)
                  const Icon(Icons.check, size: 18, color: tfAccent),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tfTile,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label  ',
                style: const TextStyle(color: tfMuted, fontSize: 13)),
            Text(valueLabel,
                style: const TextStyle(
                    color: tfInk, fontSize: 13, fontWeight: FontWeight.w600)),
            const Icon(Icons.expand_more, size: 18, color: tfMuted),
          ],
        ),
      ),
    );
  }
}

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
    OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: c == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: c, width: w),
        );
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, v, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 15, color: tfInk),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: tfMuted, fontSize: 15),
          prefixIcon: const Icon(Icons.search, size: 20, color: tfMuted),
          suffixIcon: v.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close, size: 18, color: tfMuted),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          filled: true,
          fillColor: tfTile,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: b(Colors.transparent, 0),
          enabledBorder: b(Colors.transparent, 0),
          focusedBorder: b(tfAccent, 1.5),
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
    final style = FilledButton.styleFrom(
      backgroundColor: tfAccent,
      foregroundColor: Colors.white,
      disabledBackgroundColor: tfTile,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
    final button = icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Quiet blue text action ("Copy link", "Show all").
class TfTextAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const TfTextAction({super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      foregroundColor: tfAccent,
      minimumSize: const Size(0, 44),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
    return icon == null
        ? TextButton(onPressed: onPressed, style: style, child: Text(label))
        : TextButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
  }
}

// ---------------------------------------------------------------------------
// States
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: tfInk,
                      letterSpacing: -0.3)),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: tfMuted, height: 1.5)),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 12),
                TfTextAction(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TfRowSkeletons extends StatelessWidget {
  final int count;
  const TfRowSkeletons({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Pulse(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: tfHair, width: 0.5)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 90, height: 10),
                  SizedBox(height: 10),
                  SkeletonBox(height: 16),
                  SizedBox(height: 8),
                  SkeletonBox(width: 220, height: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }
}