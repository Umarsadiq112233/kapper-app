import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/app_bloc.dart';
import '../theme/app_theme.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.size = 72});
  final double size;
  @override
  Widget build(BuildContext context) => Text(
    'Kapper',
    style: TextStyle(
      fontFamily: 'Georgia',
      fontSize: size,
      color: Palette.gold,
      letterSpacing: -2,
      fontWeight: FontWeight.w400,
    ),
  );
}

class Photo extends StatelessWidget {
  const Photo(
    this.name, {
    super.key,
    this.width,
    this.height,
    this.radius = 12,
    this.bytes,
    this.fit = BoxFit.cover,
  });
  final String name;
  final double? width, height;
  final double radius;
  final Uint8List? bytes;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: bytes != null
        ? Image.memory(bytes!, width: width, height: height, fit: fit)
        : Image.asset(
            'assets/images/$name.jpg',
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => Container(
              width: width,
              height: height,
              color: Palette.lavender,
              child: const Icon(Icons.spa_outlined, color: Palette.purple),
            ),
          ),
  );
}

class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    required this.onTap,
    this.gold = false,
    this.color,
    this.icon,
  });
  final String label;
  final VoidCallback? onTap;
  final bool gold;
  final Color? color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? (gold ? Palette.gold : Palette.purple),
        foregroundColor: gold ? Palette.ink : Colors.white,
        elevation: 3,
        shadowColor: Palette.ink.withValues(alpha: .18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}

class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 1 : 0, end: 1),
      duration: Duration(milliseconds: reduce ? 0 : 420),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class Screen extends StatelessWidget {
  const Screen({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.bottom,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottom;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    bottomNavigationBar: bottom,
    body: SafeArea(
      top: false,
      child: Entrance(
        child: Column(
          children: [
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(subtitle!, style: const TextStyle(fontSize: 13)),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

class LocalView extends StatelessWidget {
  const LocalView({super.key, required this.builder});
  final Widget Function(BuildContext, ViewState) builder;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ViewBloc(),
    child: BlocBuilder<ViewBloc, ViewState>(builder: builder),
  );
}

void change(BuildContext context, String key, Object? value) =>
    context.read<ViewBloc>().change(key, value);
void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
Future<T?> modal<T>(BuildContext context, Widget child) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Close dialog',
  barrierColor: Colors.black45,
  transitionDuration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 240),
  pageBuilder: (context, _, _) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
    child: Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Close',
                    icon: const Icon(
                      Icons.cancel,
                      size: 19,
                      color: Palette.ink,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    ),
  ),
  transitionBuilder: (_, animation, _, child) => FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween(
        begin: .94,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ),
);
Future<bool> confirm(BuildContext context, String message) async =>
    await modal<bool>(
      context,
      Builder(
        builder: (context) => Column(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Palette.gold,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    'Yes',
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    'No',
                    color: Palette.pink,
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ) ??
    false;

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Palette.ink.withValues(alpha: .06),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class Segments extends StatelessWidget {
  const Segments(this.labels, this.selected, this.onSelect, {super.key});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      labels.length,
      (i) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: selected == i ? Palette.purple : Colors.transparent,
                border: Border.all(color: Palette.purple),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: selected == i ? Colors.white : Palette.purple,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key, this.icon = Icons.spa_outlined});
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Palette.purple),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.muted),
          ),
        ],
      ),
    ),
  );
}

String? requiredField(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;
String dateLabel(String date) {
  final d = DateTime.parse(date);
  return '${d.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}';
}
