import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/app_bloc.dart';
import '../../../domain/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child, this.photo});
  final Widget child;
  final String? photo;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9785A7), Color(0xFF30114D)],
        ),
      ),
      child: Stack(
        children: [
          if (photo != null) Positioned.fill(child: Photo(photo!, radius: 0)),
          if (photo != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .5),
                      const Color(0xFF420774).withValues(alpha: .88),
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (_, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 28,
                    ),
                    child: Entrance(child: child),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class RolePage extends StatelessWidget {
  const RolePage({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<AppBloc, AppState>(
    builder: (context, state) {
      final isDark = state.isDark;
      final foreground = isDark ? Colors.white : const Color(0xFF16182E);
      final muted = isDark ? const Color(0xFFC0C2D1) : const Color(0xFF74788B);
      final selectedRole = state.role ?? AccountRole.vendor;
      return Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF11131D), Color(0xFF05070D)]
                  : const [Color(0xFFFFFCF8), Color(0xFFF5F2F8)],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 28,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/onboarding'),
                            icon: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: Palette.gold,
                            ),
                            label: const Text(
                              'Onboarding',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Palette.gold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: isDark
                                ? 'Switch to light mode'
                                : 'Switch to dark mode',
                            onPressed: () =>
                                context.read<AppBloc>().add(ToggleTheme()),
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                            ),
                            color: foreground,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Brand(size: 58),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 42, height: 1, color: Palette.gold),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 9),
                            child: Icon(
                              Icons.content_cut_rounded,
                              size: 21,
                              color: Palette.gold,
                            ),
                          ),
                          Container(width: 42, height: 1, color: Palette.gold),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Sign up as',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose how you want to use Kapper',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: muted),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 330,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _RoleCard(
                                role: AccountRole.vendor,
                                selected: selectedRole == AccountRole.vendor,
                                isDark: isDark,
                                foreground: foreground,
                                muted: muted,
                                onTap: () => context.read<AppBloc>().add(
                                  SelectRole(AccountRole.vendor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _RoleCard(
                                role: AccountRole.customer,
                                selected: selectedRole == AccountRole.customer,
                                isDark: isDark,
                                foreground: foreground,
                                muted: muted,
                                onTap: () => context.read<AppBloc>().add(
                                  SelectRole(AccountRole.customer),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7136EE), Color(0xFFB652F5)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Palette.purple.withValues(alpha: .24),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () async {
                                final bloc = context.read<AppBloc>();
                                bloc.add(SelectRole(selectedRole));
                                await bloc.stream.firstWhere(
                                  (next) => next.role == selectedRole,
                                );
                                if (!context.mounted) return;
                                Navigator.pushNamed(
                                  context,
                                  selectedRole == AccountRole.vendor
                                      ? '/auth/vendor'
                                      : '/auth/customer',
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 28),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Continue',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 21,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.read<AppBloc>().liveVendor
                            ? selectedRole == AccountRole.vendor
                                  ? 'Vendor account · email & password'
                                  : 'User account · email & password'
                            : selectedRole == AccountRole.vendor
                            ? 'Vendor preview · demo code 123456'
                            : 'Frontend preview · no live account required',
                        style: TextStyle(color: muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.isDark,
    required this.foreground,
    required this.muted,
    required this.onTap,
  });

  final AccountRole role;
  final bool selected;
  final bool isDark;
  final Color foreground;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vendor = role == AccountRole.vendor;
    final title = vendor ? 'Vendor' : 'User';
    return Semantics(
      button: true,
      selected: selected,
      label: '$title account',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF121521)
                : Colors.white.withValues(alpha: .88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? (isDark ? const Color(0xFFBD57FF) : const Color(0xFFB58AFF))
                  : (isDark
                        ? const Color(0xFF252A39)
                        : const Color(0xFFEEEAF1)),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? Palette.purple.withValues(alpha: isDark ? .22 : .12)
                    : Colors.black.withValues(alpha: isDark ? .14 : .045),
                blurRadius: selected ? 20 : 12,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Flexible(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.asset(
                          vendor
                              ? 'assets/images/role_vendor.jpg'
                              : 'assets/images/role_user.jpg',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                      if (vendor)
                        Positioned(
                          top: 3,
                          right: 2,
                          child: Container(
                            width: 31,
                            height: 31,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD575),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFF75420A),
                              size: 19,
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF863DF1)
                                : (isDark
                                      ? const Color(0xFF22283A)
                                      : const Color(0xFFF2F0F4)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                            color: selected ? Colors.white : foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: TextStyle(
                  color: foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                vendor
                    ? 'List your services, manage bookings and grow your business.'
                    : 'Find barbers, book appointments and enjoy premium grooming.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 12, height: 1.45),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 3,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF9E53F2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpInput extends StatefulWidget {
  const OtpInput({super.key, required this.controller});
  final TextEditingController controller;
  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final focus = FocusNode();
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(refresh);
    focus.addListener(refresh);
  }

  void refresh() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(refresh);
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Stack(
      children: [
        Positioned.fill(
          child: TextField(
            controller: widget.controller,
            focusNode: focus,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: const TextStyle(color: Colors.transparent),
            cursorColor: Colors.transparent,
            decoration: const InputDecoration(
              hintText: '',
              fillColor: Colors.transparent,
              border: InputBorder.none,
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Row(
              children: List.generate(
                6,
                (i) => Expanded(
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6E9FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Palette.purple,
                        width:
                            focus.hasFocus &&
                                widget.controller.text.length.clamp(0, 5) == i
                            ? 2
                            : 1,
                      ),
                    ),
                    child: Text(
                      i < widget.controller.text.length
                          ? widget.controller.text[i]
                          : '',
                      style: const TextStyle(fontSize: 20, color: Palette.ink),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
