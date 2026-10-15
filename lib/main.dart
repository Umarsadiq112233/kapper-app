import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'application/app_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/mock_salon_repository.dart';
import 'domain/models.dart';
import 'features/auth/presentation/auth_pages.dart';
import 'features/salons/presentation/discovery_pages.dart';
import 'features/salons/presentation/salon_page.dart';
import 'features/bookings/presentation/appointments_page.dart';
import 'features/bookings/presentation/booking_dialogs.dart';
import 'features/account/presentation/account_pages.dart';
import 'features/vendor/presentation/vendor_pages.dart';
import 'features/styles/presentation/style_preview_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.bloc});
  final AppBloc? bloc;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => bloc ?? AppBloc(MockSalonRepository()),
    child: Builder(
      builder: (context) => MaterialApp(
        title: 'Kapper',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        onGenerateRoute: (settings) {
          final state = context.read<AppBloc>().state;
          final name = settings.name ?? '/';
          final args = settings.arguments;
          Widget page;
          if (name == '/' || name == '/role') {
            page = state.authenticated ? const HomeShell() : const RolePage();
          } else if (!state.authenticated && !name.startsWith('/auth/')) {
            page = const RolePage();
          } else if (name.startsWith('/vendor/') && !state.isVendor) {
            page = const HomeShell();
          } else {
            page = switch (name) {
              '/auth/phone' => const PhonePage(),
              '/auth/otp' => OtpPage(
                phone: args is String ? args : 'your demo number',
              ),
              '/auth/complete' => const CompleteProfilePage(),
              '/auth/signin' => const CompleteProfilePage(signIn: true),
              '/home' => HomeShell(initialIndex: args is int ? args : 0),
              '/salon' => SalonPage(
                salonId:
                    args is String &&
                        context.read<AppBloc>().repository.salons.any(
                          (s) => s.id == args,
                        )
                    ? args
                    : 'danial',
              ),
              '/search' => const SearchPage(),
              '/favorites' => const SearchPage(favoritesOnly: true),
              '/appointments' => const AppointmentsPage(),
              '/chat'
                  when args is String &&
                      state.appointments.any(
                        (a) =>
                            a.id == args &&
                            (!state.isVendor || a.salonId == 'danial'),
                      ) =>
                ChatPage(appointmentId: args),
              '/profile' => const ProfilePage(),
              '/profile/edit' => const EditProfilePage(),
              '/notifications' => const NotificationsPage(),
              '/transactions' => const TransactionsPage(),
              '/transactions/detail' when args is Appointment =>
                TransactionsPage(detail: args),
              '/settings' => const SettingsPage(),
              '/about' => const AboutPage(),
              '/payment' when args is Appointment && !state.isVendor =>
                PaymentPage(appointment: args),
              '/booking/confirmed'
                  when args is Appointment &&
                      state.appointments.any((a) => a.id == args.id) =>
                BookingConfirmationPage(appointment: args),
              '/styles/preview' => const StylePreviewPage(),
              '/vendor/availability' => const AvailabilityPage(),
              '/vendor/upload' => const UploadPage(),
              '/vendor/styles' => const CustomStylesPage(),
              _ => const HomeShell(),
            };
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => page,
          );
        },
      ),
    ),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});
  final int initialIndex;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int selected = widget.initialIndex.clamp(0, 4);
  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<AppBloc>().state.isVendor;
    final pages = <Widget>[
      vendor ? const SalonPage(vendor: true) : const DashboardPage(),
      vendor ? const CustomStylesPage() : const InboxPage(),
      vendor ? const InboxPage() : const SizedBox.shrink(),
      const AppointmentsPage(),
      const ProfilePage(),
    ];
    final labels = vendor
        ? ['Home', 'Create Style', 'Inbox', 'Appointment', 'Profile']
        : ['Home', 'Inbox', 'Try a style', 'Appointment', 'Profile'];
    final icons = [
      Icons.home_outlined,
      vendor ? Icons.face_outlined : Icons.chat_bubble_outline,
      vendor ? Icons.chat_bubble_outline : Icons.camera_alt_outlined,
      Icons.calendar_month_outlined,
      Icons.person_outline,
    ];
    return Scaffold(
      body: IndexedStack(index: selected, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: List.generate(5, (i) {
              final active = selected == i;
              final camera = !vendor && i == 2;
              return Expanded(
                child: Semantics(
                  selected: active,
                  button: true,
                  label: labels[i],
                  child: InkWell(
                    onTap: () {
                      if (camera) {
                        Navigator.pushNamed(context, '/styles/preview');
                      } else {
                        setState(() => selected = i);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 200),
                            padding: EdgeInsets.all(camera ? 12 : 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active || camera
                                  ? Palette.lavender
                                  : Colors.transparent,
                              boxShadow: camera
                                  ? [
                                      BoxShadow(
                                        color: Palette.purple.withValues(
                                          alpha: .22,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              icons[i],
                              size: camera ? 23 : 20,
                              color: active || camera
                                  ? Palette.purple
                                  : Palette.ink,
                            ),
                          ),
                          if (!camera)
                            Text(
                              labels[i],
                              style: TextStyle(
                                fontSize: 9,
                                color: active ? Palette.purple : Palette.ink,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
