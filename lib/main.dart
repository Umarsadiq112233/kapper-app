import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/backend_config.dart';
import 'data/supabase_customer_backend.dart';
import 'data/supabase_vendor_backend.dart';
import 'features/auth/presentation/customer_auth_page.dart';
import 'features/auth/presentation/vendor_auth_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'application/app_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/mock_salon_repository.dart';
import 'domain/models.dart';
import 'features/auth/presentation/auth_pages.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/salons/presentation/discovery_pages.dart';
import 'features/salons/presentation/salon_page.dart';
import 'features/bookings/presentation/appointments_page.dart';
import 'features/bookings/presentation/booking_dialogs.dart';
import 'features/account/presentation/account_pages.dart';
import 'features/vendor/presentation/vendor_pages.dart';
import 'features/vendor/presentation/vendor_dashboard_page.dart';
import 'features/styles/presentation/style_preview_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
  };

  SupabaseVendorBackend? backend;
  SupabaseCustomerBackend? customerBackend;
  try {
    if (BackendConfig.configured) {
      await Supabase.initialize(
        url: BackendConfig.url,
        publishableKey: BackendConfig.publicKey,
      );
      backend = SupabaseVendorBackend(Supabase.instance.client);
      customerBackend = SupabaseCustomerBackend(Supabase.instance.client);
    }
  } catch (e, st) {
    debugPrint('Supabase initialization failed: $e\n$st');
  }

  final bloc = AppBloc(
    MockSalonRepository(),
    vendorBackend: backend,
    liveVendor: backend != null,
    customerBackend: customerBackend,
  );

  if (customerBackend?.hasSession ?? false) {
    try {
      bloc.add(SelectRole(AccountRole.customer));
      await bloc.submit(RestoreCustomer());
    } catch (_) {
      /* Retry from sign-in. */
    }
  } else if (backend?.hasSession ?? false) {
    try {
      await bloc.submit(RestoreVendor());
    } catch (_) {
      /* Retry from sign-in. */
    }
  }

  runApp(MyApp(bloc: bloc));
}

final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.bloc, this.initialRoute});
  final AppBloc? bloc;
  final String? initialRoute;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => bloc ?? AppBloc(MockSalonRepository()),
    child: Builder(
      builder: (context) {
        final state = context.watch<AppBloc>().state;
        return MaterialApp(
          title: 'Kapper',
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute,
          builder: (context, child) => BlocListener<AppBloc, AppState>(
            listenWhen: (before, after) =>
                before.authenticated && !after.authenticated,
            listener: (context, state) {
              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                '/role',
                (_) => false,
              );
            },
            child: child!,
          ),
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: messengerKey,
          theme: buildTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: state.themeMode,
          onGenerateRoute: (settings) {
            final state = context.read<AppBloc>().state;
            final name = settings.name ?? '/';
            final args = settings.arguments;
            Widget page;
            if (name == '/' || name == '/splash') {
              page = const SplashScreen();
            } else if (name == '/role') {
              page = state.authenticated
                  ? const HomeShell()
                  : (context.read<AppBloc>().vendorBackend?.hasSession ?? false)
                  ? const VendorAuthPage(demo: false)
                  : const RolePage();
            } else if (name == '/auth/vendor' && state.isVendor) {
              page = VendorAuthPage(demo: !context.read<AppBloc>().liveVendor);
            } else if (name.startsWith('/auth/') &&
                context.read<AppBloc>().liveVendor &&
                (state.isVendor || name == '/auth/vendor')) {
              page = const VendorAuthPage(demo: false);
            } else if (!state.authenticated && !name.startsWith('/auth/')) {
              page = const RolePage();
            } else if (name.startsWith('/vendor/') && !state.isVendor) {
              page = const HomeShell();
            } else {
              page = switch (name) {
                '/auth/customer' ||
                '/auth/signin' ||
                '/auth/phone' ||
                '/auth/otp' => const CustomerAuthPage(),
                '/auth/signup' ||
                '/auth/complete' => const CustomerAuthPage(createAccount: true),
                '/home' => HomeShell(initialIndex: args is int ? args : 0),
                '/salon' => SalonPage(
                  salonId:
                      args is String &&
                          (context.read<AppBloc>().repository.salons.any(
                                (s) => s.id == args,
                              ) ||
                              context
                                  .read<AppBloc>()
                                  .state
                                  .customerListings
                                  .any((listing) => listing.salon.id == args))
                      ? args
                      : 'danial',
                ),
                '/search' => const SearchPage(),
                '/favorites' => const SearchPage(favoritesOnly: true),
                '/appointments' => const AppointmentsPage(),
                '/chat' when args is String => ChatPage(appointmentId: args),
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
            final reduceMotion = MediaQuery.disableAnimationsOf(context);
            return PageRouteBuilder<void>(
              settings: settings,
              transitionDuration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              reverseTransitionDuration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 190),
              pageBuilder: (_, _, _) => page,
              transitionsBuilder: (_, animation, secondaryAnimation, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(.025, 0),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
            );
          },
        );
      },
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
    final state = context.watch<AppBloc>().state;
    final vendor = state.isVendor;
    final isDark = state.isDark;
    final pages = vendor
        ? <Widget>[
            VendorDashboardPage(
              onSelectTab: (index) => setState(() => selected = index),
            ),
            const CustomStylesPage(),
            const InboxPage(),
            const AppointmentsPage(),
            const ProfilePage(),
          ]
        : const <Widget>[
            DashboardPage(),
            SearchPage(),
            AppointmentsPage(),
            InboxPage(),
            ProfilePage(),
          ];
    final labels = vendor
        ? ['Home', 'Styles', 'Inbox', 'Appointment', 'Profile']
        : ['Home', 'Explore', 'Bookings', 'Chat', 'Profile'];
    final icons = vendor
        ? [
            Icons.home_outlined,
            Icons.content_cut_rounded,
            Icons.chat_bubble_outline,
            Icons.calendar_month_outlined,
            Icons.person_outline,
          ]
        : [
            Icons.home_outlined,
            Icons.search_rounded,
            Icons.calendar_month_outlined,
            Icons.chat_bubble_outline_rounded,
            Icons.person_outline,
          ];
    return BlocListener<AppBloc, AppState>(
      listenWhen: (before, after) =>
          after.notice.isNotEmpty && after.revision != before.revision,
      listener: (context, state) => messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(state.notice)),
      ),
      child: Scaffold(
        body: IndexedStack(index: selected, children: pages),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF100A1D) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE8E1F0),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: List.generate(5, (i) {
                final active = selected == i;
                final camera = false;
                // Give every selected vendor destination the same active
                // treatment so tab selection feels consistent across the app.
                final isStylesButton = vendor && active;

                return Expanded(
                  child: Semantics(
                    selected: active,
                    button: true,
                    label: labels[i],
                    child: InkWell(
                      onTap: () {
                        setState(() => selected = i);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 200),
                              padding: EdgeInsets.all(
                                isStylesButton && active ? 9 : (5),
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isStylesButton && active
                                    ? RadialGradient(
                                        colors: isDark
                                            ? const [
                                                Color(0xFFA855F7),
                                                Color(0xFF7E22CE),
                                                Color(0xFF3B0764),
                                              ]
                                            : const [
                                                Color(0xFF9333EA),
                                                Color(0xFF7C3AED),
                                                Color(0xFF6D28D9),
                                              ],
                                      )
                                    : null,
                                color: (isStylesButton && active)
                                    ? null
                                    : (active || camera
                                          ? (vendor
                                                ? (isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.08,
                                                        )
                                                      : const Color(0xFFF3EEFC))
                                                : Palette.lavender)
                                          : Colors.transparent),
                                border: isStylesButton && active
                                    ? Border.all(
                                        color: isDark
                                            ? const Color(0xFFC084FC)
                                                  .withValues(alpha: 0.75)
                                            : const Color(0xFFA855F7),
                                        width: 1.5,
                                      )
                                    : null,
                                boxShadow: isStylesButton && active
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFA855F7)
                                              .withValues(
                                                alpha: isDark ? 0.5 : 0.35,
                                              ),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : (null),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    icons[i],
                                    size: isStylesButton && active ? 21 : (20),
                                    color: isStylesButton && active
                                        ? Colors.white
                                        : (active || camera
                                              ? (vendor
                                                    ? (isDark
                                                          ? const Color(
                                                              0xFFC084FC,
                                                            )
                                                          : Palette.purple)
                                                    : Palette.purple)
                                              : (vendor
                                                    ? (isDark
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.55,
                                                                )
                                                          : const Color(
                                                              0xFF64748B,
                                                            ))
                                                    : (isDark
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.55,
                                                                )
                                                          : Palette.ink))),
                                  ),
                                  if (i == (vendor ? 2 : 3) &&
                                      state.unreadMessages > 0)
                                    Positioned(
                                      top: -3,
                                      right: -5,
                                      child: Container(
                                        padding: const EdgeInsets.all(2.5),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 10,
                                          minHeight: 10,
                                        ),
                                        child: Center(
                                          child: Text(
                                            state.unreadMessages > 99
                                                ? '99+'
                                                : '${state.unreadMessages}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (!camera) ...[
                              const SizedBox(height: 2),
                              Text(
                                labels[i],
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: active
                                      ? (vendor
                                            ? (isDark
                                                  ? const Color(0xFFC084FC)
                                                  : Palette.purple)
                                            : Palette.purple)
                                      : (vendor
                                            ? (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.55,
                                                    )
                                                  : const Color(0xFF64748B))
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.55,
                                                    )
                                                  : Palette.ink)),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
