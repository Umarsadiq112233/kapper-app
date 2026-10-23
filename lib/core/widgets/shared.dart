import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/app_bloc.dart';
import '../../application/customer_backend.dart';
import '../../application/vendor_backend.dart';
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
        : name.startsWith('storage:')
        ? StoragePhoto(
            reference: name.substring(8),
            width: width,
            height: height,
            fit: fit,
          )
        : (name.startsWith('http://') || name.startsWith('https://'))
        ? Image.network(
            name,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => Container(
              width: width,
              height: height,
              color: Palette.lavender,
              child: const Icon(Icons.person_outline, color: Palette.purple),
            ),
          )
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

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.avatar,
    this.bytes,
    this.isVendor = false,
    this.size = 96,
    this.radius,
    this.onTap,
    this.showEditBadge = false,
    this.badgeIcon = Icons.camera_alt_rounded,
    this.borderWidth = 3,
  });
  final String? avatar;
  final Uint8List? bytes;
  final bool isVendor;
  final double size;
  final double? radius;
  final VoidCallback? onTap;
  final bool showEditBadge;
  final IconData badgeIcon;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? (size / 2);
    final fallbackName = isVendor ? 'barber' : 'portrait';
    final photoName = (avatar != null && avatar!.trim().isNotEmpty)
        ? avatar!.trim()
        : fallbackName;

    final imageWidget = Photo(
      photoName,
      bytes: bytes,
      width: size,
      height: size,
      radius: effectiveRadius,
      fit: BoxFit.cover,
    );

    final avatarBox = Container(
      width: size + (borderWidth * 2),
      height: size + (borderWidth * 2),
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: borderWidth > 0
            ? const LinearGradient(
                colors: [Palette.gold, Palette.purple, Palette.orchid],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: borderWidth > 0
            ? [
                BoxShadow(
                  color: Palette.purple.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: imageWidget,
      ),
    );

    if (!showEditBadge) {
      return GestureDetector(onTap: onTap, child: avatarBox);
    }

    final badgeSize = (size * 0.32).clamp(28.0, 38.0);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + (borderWidth * 2),
        height: size + (borderWidth * 2),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: avatarBox),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Palette.purple, Palette.orchid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  badgeIcon,
                  size: badgeSize * 0.52,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppButton extends StatefulWidget {
  const AppButton(
    this.label, {
    super.key,
    required this.onTap,
    this.gold = false,
    this.color,
    this.icon,
  });
  final String label;
  final FutureOr<void> Function()? onTap;
  final bool gold;
  final Color? color;
  final IconData? icon;
  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool busy = false;
  String get label => busy ? 'Please wait…' : widget.label;
  bool get gold => widget.gold;
  Color? get color => widget.color;
  IconData? get icon => widget.icon;
  Future<void> tap() async {
    if (busy || widget.onTap == null) return;
    setState(() => busy = true);
    try {
      await widget.onTap!();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: busy || widget.onTap == null ? null : tap,
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
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
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
    this.titleWidget,
    this.centerTitle = true,
    this.subtitle,
    this.actions,
    this.bottom,
    this.showAppBar = true,
    this.onRefresh,
  });
  final String title;
  final Widget? titleWidget;
  final bool centerTitle;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool showAppBar;

  /// When set, the body supports pull-down-to-refresh.
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: showAppBar
        ? AppBar(
            title:
                titleWidget ??
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'KapperSans',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
            centerTitle: centerTitle,
            actions: actions,
          )
        : null,
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
            Expanded(
              child: onRefresh == null
                  ? child
                  : PullToRefresh(onRefresh: onRefresh!, child: child),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Branded pull-to-refresh. Works with any vertical scrollable child; short
/// lists still respond because primary scroll views are always scrollable.
class PullToRefresh extends StatelessWidget {
  const PullToRefresh({super.key, required this.child, this.onRefresh});
  final Widget child;

  /// Defaults to reloading the signed-in vendor/customer data.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: Palette.gold,
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF241338)
        : Colors.white,
    strokeWidth: 2.6,
    displacement: 36,
    onRefresh: onRefresh ?? () => refreshApp(context),
    child: child,
  );
}

/// Reloads the live backend data for whoever is signed in.
Future<void> refreshApp(BuildContext context) =>
    context.read<AppBloc>().refreshAll();

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                  height: 40,
                  width: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Close',
                    icon: Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: Theme.of(context).colorScheme.onSurface,
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF130C20) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: const Color(0xFF302044), width: .7)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: .2)
                : Palette.ink.withValues(alpha: .06),
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

/// Keeps the user's form open when a remote operation fails.
Future<bool> saveAction(BuildContext context, AppEvent event) async {
  final bloc = context.read<AppBloc>();
  if (bloc.state.saving) return false;
  try {
    await bloc.submit(event);
    return context.mounted;
  } on VendorFailure catch (error) {
    if (context.mounted) toast(context, error.message);
    return false;
  } on CustomerFailure catch (error) {
    if (context.mounted) toast(context, error.message);
    return false;
  }
}

class StoragePhoto extends StatefulWidget {
  const StoragePhoto({
    super.key,
    required this.reference,
    this.width,
    this.height,
    required this.fit,
  });
  final String reference;
  final double? width, height;
  final BoxFit fit;
  @override
  State<StoragePhoto> createState() => _StoragePhotoState();
}

class _SignedImageCacheEntry {
  const _SignedImageCacheEntry(this.future, this.expiresAt);
  final Future<String> future;
  final DateTime expiresAt;
}

const _signedImageCacheTtl = Duration(minutes: 50);
final _signedImageCache = <String, _SignedImageCacheEntry>{};

Future<String> _cachedSignedImageUrl(
  String key,
  Future<String> Function() loader,
) {
  final now = DateTime.now();
  final existing = _signedImageCache[key];
  if (existing != null && existing.expiresAt.isAfter(now)) {
    return existing.future;
  }

  final future = loader();
  final entry = _SignedImageCacheEntry(future, now.add(_signedImageCacheTtl));
  _signedImageCache[key] = entry;
  future.then<void>(
    (_) {},
    onError: (Object error, StackTrace stack) {
      if (identical(_signedImageCache[key], entry)) {
        _signedImageCache.remove(key);
      }
    },
  );
  return future;
}

class _StoragePhotoState extends State<StoragePhoto> {
  Future<String>? url;

  String get bucket => widget.reference.startsWith('customer-media/')
      ? 'customer-media'
      : 'vendor-media';

  String get path => bucket == 'customer-media'
      ? widget.reference.substring('customer-media/'.length)
      : widget.reference;

  Future<String>? get signedUrl {
    final bloc = context.read<AppBloc>();
    final loader = bucket == 'customer-media'
        ? bloc.customerBackend?.signedImageUrl
        : bloc.vendorBackend?.signedImageUrl;
    if (loader == null) return null;
    return _cachedSignedImageUrl('$bucket:$path', () => loader(path));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    url ??= signedUrl;
  }

  @override
  void didUpdateWidget(StoragePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reference != widget.reference) {
      url = signedUrl;
    }
  }

  Widget get placeholder => SizedBox(
    width: widget.width,
    height: widget.height,
    child: const Icon(Icons.image_outlined, color: Palette.purple),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: url,
    builder: (context, snapshot) => snapshot.hasData
        ? Image.network(
            snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (_, _, _) => placeholder,
          )
        : placeholder,
  );
}
