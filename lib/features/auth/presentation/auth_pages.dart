import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/app_bloc.dart';
import '../../../domain/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared.dart';
import '../../../core/widgets/role_illustration.dart';

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
                  child: IntrinsicHeight(
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
    builder: (context, state) => AuthBackground(
      child: Column(
        children: [
          const SizedBox(height: 28),
          const Brand(),
          const SizedBox(height: 20),
          const Text(
            'Sign up as',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          const Spacer(),
          ...[AccountRole.vendor, AccountRole.customer].map(
            (role) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: GestureDetector(
                onTap: () => context.read<AppBloc>().add(SelectRole(role)),
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 240),
                  width: 172,
                  height: 172,
                  decoration: BoxDecoration(
                    color: state.role == role ? Palette.gold : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RoleIllustration(vendor: role == AccountRole.vendor),
                      const SizedBox(height: 6),
                      Text(
                        role == AccountRole.vendor ? 'Vendor' : 'User',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: state.role == role
                              ? Colors.white
                              : Palette.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 30),
          AppButton(
            'Continue',
            gold: true,
            onTap: () {
              context.read<AppBloc>().add(
                SelectRole(state.role ?? AccountRole.customer),
              );
              Navigator.pushNamed(context, '/auth/phone');
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Frontend preview · no live account required',
            style: TextStyle(color: Colors.white60, fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

class PhonePage extends StatefulWidget {
  const PhonePage({super.key});
  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  final phone = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthBackground(
    photo: 'tools',
    child: Form(
      key: form,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: BackButton(
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Spacer(),
          const Text(
            'Welcome to',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
          const Brand(size: 64),
          const Spacer(),
          Row(
            children: [
              const Text(
                '+92  ',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Expanded(
                child: TextFormField(
                  controller: phone,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Enter Phone Number',
                    hintStyle: TextStyle(color: Colors.white70),
                    fillColor: Colors.transparent,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 8
                      ? 'Enter a valid phone number'
                      : null,
                ),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Palette.ink,
                ),
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  if (form.currentState!.validate()) {
                    Navigator.pushNamed(
                      context,
                      '/auth/otp',
                      arguments: '+92 ${phone.text}',
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text('OR', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 20),
          ...[
            (Icons.g_mobiledata, 'Google', Colors.blue),
            (Icons.facebook, 'Facebook', Colors.blue),
            (Icons.apple, 'Apple', Colors.black),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: SizedBox(
                height: 47,
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () => toast(
                    context,
                    '${item.$2} sign-in is not connected in this frontend demo.',
                  ),
                  icon: Icon(item.$1, color: item.$3, size: 28),
                  label: Text(
                    'Sign up with ${item.$2}',
                    style: const TextStyle(color: Palette.ink, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/auth/signin'),
            child: const Text(
              'Already have an account? Sign in',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const Spacer(),
        ],
      ),
    ),
  );
}

class OtpPage extends StatefulWidget {
  const OtpPage({super.key, required this.phone});
  final String phone;
  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final code = TextEditingController();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, state) => AuthBackground(
      photo: 'tools',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Brand(size: 46),
          const SizedBox(height: 36),
          Surface(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Icon(
                  Icons.phonelink_lock_outlined,
                  size: 64,
                  color: Palette.purple,
                ),
                const SizedBox(height: 22),
                const Text(
                  'OTP Verification',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the code for ${widget.phone}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Palette.muted, fontSize: 11),
                ),
                const SizedBox(height: 24),
                OtpInput(controller: code),
                const SizedBox(height: 12),
                const Text(
                  'Demo verification code: 123456',
                  style: TextStyle(fontSize: 11, color: Palette.muted),
                ),
                if (state.get('error', '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      state.get('error', ''),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 18),
                const Text(
                  "Didn't receive OTP code?",
                  style: TextStyle(fontSize: 11, color: Palette.muted),
                ),
                TextButton(
                  onPressed: state.get('resent', false)
                      ? null
                      : () {
                          change(context, 'resent', true);
                          toast(
                            context,
                            'Demo code is 123456. No SMS is sent.',
                          );
                          Future.delayed(const Duration(seconds: 30), () {
                            if (context.mounted) {
                              change(context, 'resent', false);
                            }
                          });
                        },
                  child: Text(
                    state.get('resent', false)
                        ? 'Resend available in 30 seconds'
                        : 'Resend Code',
                  ),
                ),
                const SizedBox(height: 10),
                AppButton(
                  state.get('busy', false) ? 'Verifying…' : 'Verify & Proceed',
                  onTap: state.get('busy', false)
                      ? null
                      : () async {
                          if (code.text != '123456') {
                            change(
                              context,
                              'error',
                              'Please enter the demo code 123456',
                            );
                            return;
                          }
                          change(context, 'busy', true);
                          await Future<void>.delayed(
                            const Duration(milliseconds: 500),
                          );
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(
                              context,
                              '/auth/complete',
                            );
                          }
                        },
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Not your number? Edit phone number',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key, this.signIn = false});
  final bool signIn;
  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      repeat = TextEditingController();
  @override
  void dispose() {
    for (final c in [name, email, password, repeat]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, state) {
      final vendor = context.watch<AppBloc>().state.isVendor;
      Widget field(
        String hint,
        TextEditingController controller, {
        bool secret = false,
        String? Function(String?)? validator,
      }) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: TextFormField(
          controller: controller,
          obscureText: secret && !state.get('visible', false),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white70, fontSize: 13),
            fillColor: Colors.white.withValues(alpha: .25),
            suffixIcon: secret
                ? IconButton(
                    icon: Icon(
                      state.get('visible', false)
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => change(
                      context,
                      'visible',
                      !state.get('visible', false),
                    ),
                  )
                : null,
          ),
          validator: validator ?? requiredField,
        ),
      );
      return AuthBackground(
        photo: vendor ? 'salon' : null,
        child: Form(
          key: form,
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Brand(),
              const SizedBox(height: 12),
              Text(
                widget.signIn ? 'Welcome Back' : 'Complete Profile',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 50),
              if (!widget.signIn) ...[
                field(vendor ? 'Enter Salon Name' : 'Enter full name', name),
                if (vendor)
                  field(
                    'Enter Email',
                    email,
                    validator: (v) =>
                        v != null && RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)
                        ? null
                        : 'Enter a valid email',
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: DropdownButtonFormField<String>(
                      initialValue: null,
                      dropdownColor: const Color(0xFF583A70),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        fillColor: Colors.white.withValues(alpha: .25),
                      ),
                      hint: const Text(
                        'Select Gender',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      items: ['Female', 'Male', 'Prefer not to say']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (v) => change(context, 'gender', v),
                      validator: requiredField,
                    ),
                  ),
              ],
              field(
                'Enter Password',
                password,
                secret: true,
                validator: (v) => v == null || v.length < 6
                    ? 'Use at least 6 characters'
                    : null,
              ),
              if (!widget.signIn)
                field(
                  'Confirm Password',
                  repeat,
                  secret: true,
                  validator: (v) =>
                      v != password.text ? 'Passwords do not match' : null,
                ),
              const SizedBox(height: 28),
              AppButton(
                state.get('busy', false) ? 'Please wait…' : 'Finish',
                gold: true,
                onTap: state.get('busy', false)
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        change(context, 'busy', true);
                        await Future<void>.delayed(
                          const Duration(milliseconds: 450),
                        );
                        if (!context.mounted) return;
                        context.read<AppBloc>().add(
                          SignIn(name.text.trim(), email.text.trim()),
                        );
                        await Future<void>.delayed(Duration.zero);
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (_) => false,
                          );
                        }
                      },
              ),
              if (widget.signIn)
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/auth/otp',
                    arguments: 'your demo number',
                  ),
                  child: const Text(
                    'Wanna login through OTP? Send OTP',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Demo only · credentials are not stored',
                style: TextStyle(color: Colors.white60, fontSize: 10),
              ),
              const Spacer(),
            ],
          ),
        ),
      );
    },
  );
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
