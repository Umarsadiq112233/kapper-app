import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapper/application/app_bloc.dart';
import 'package:kapper/core/theme/app_theme.dart';
import 'package:kapper/core/widgets/shared.dart';
import 'package:kapper/data/mock_salon_repository.dart';
import 'package:kapper/domain/models.dart';
import 'package:kapper/features/auth/presentation/auth_pages.dart';
import 'package:kapper/features/salons/presentation/discovery_pages.dart';
import 'package:kapper/features/salons/presentation/salon_page.dart';
import 'package:kapper/features/account/presentation/account_pages.dart';
import 'package:kapper/features/bookings/presentation/appointments_page.dart';
import 'package:kapper/features/bookings/presentation/booking_dialogs.dart';
import 'package:kapper/features/vendor/presentation/vendor_pages.dart';
import 'package:kapper/features/styles/presentation/style_preview_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('KapperSans')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts/MaterialIcons-Regular.otf',
            ).readAsBytesSync(),
          ),
        ),
      );
    await icons.load();
    final serifFile = File('/System/Library/Fonts/Supplemental/Georgia.ttf');
    if (serifFile.existsSync()) {
      final serif = FontLoader('Georgia')
        ..addFont(
          Future.value(ByteData.sublistView(serifFile.readAsBytesSync())),
        );
      await serif.load();
    }
  });
  testWidgets('Capture reference-sized screens and dialogs', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = AppBloc(MockSalonRepository());
    addTearDown(bloc.close);
    final a = bloc.state.appointments.first;
    final screens = <String, Widget>{
      'role': const RolePage(),
      'phone': const PhonePage(),
      'otp': const OtpPage(phone: '+92 1234567890'),
      'complete': const CompleteProfilePage(),
      'signin': const CompleteProfilePage(signIn: true),
      'dashboard': const Scaffold(body: DashboardPage()),
      'search': const SearchPage(),
      'salon': const SalonPage(),
      'appointments': const AppointmentsPage(),
      'chat': ChatPage(appointmentId: a.id),
      'profile': const ProfilePage(),
      'notifications': const NotificationsPage(),
      'favorites': const SearchPage(favoritesOnly: true),
      'transactions': const TransactionsPage(),
      'transaction_detail': TransactionsPage(detail: a),
      'style_preview': const StylePreviewPage(),
      'vendor_salon': const SalonPage(vendor: true),
      'vendor_profile': const ProfilePage(),
      'vendor_complete': const CompleteProfilePage(),
      'vendor_signin': const CompleteProfilePage(signIn: true),
      'edit_profile': const EditProfilePage(),
      'upload': const UploadPage(),
      'availability': const AvailabilityPage(),
      'custom_styles': const CustomStylesPage(),
    };
    for (final entry in screens.entries) {
      bloc.add(
        SelectRole(
          entry.key.startsWith('vendor') ||
                  [
                    'edit_profile',
                    'upload',
                    'availability',
                    'custom_styles',
                  ].contains(entry.key)
              ? AccountRole.vendor
              : AccountRole.customer,
        ),
      );
      bloc.add(SignIn('', ''));
      bloc.add(ToggleFavorite('danial'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            home: RepaintBoundary(
              key: const ValueKey('capture'),
              child: entry.value,
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(Scaffold).first);
        for (final name in [
          'barber',
          'beauty',
          'bride',
          'hair',
          'portrait',
          'salon',
          'tools',
          'woman',
        ]) {
          await precacheImage(AssetImage('assets/images/$name.jpg'), context);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: entry.key);
      if (const bool.fromEnvironment('CAPTURE_UI')) {
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile('captures/${entry.key}.png'),
        );
      }
    }
    final dialogs = <String, Widget>{
      'filter': const FilterDialog(price: 200, distance: 20),
      'booking': BookingDetailsDialog(
        salonId: a.salonId,
        service: a.service,
        date: a.date,
        time: a.time,
      ),
      'review': ReviewDialog(appointment: a),
      'service': const ServiceEditor(),
      'edit_service': ServiceEditor(service: a.service),
      'album': const AlbumDialog(),
      'create_style': const StyleDialog(),
      'add_date': const AvailabilityDateDialog(),
      'edit_date': AvailabilityDateDialog(date: bloc.state.dates.first),
      'edit_time': const AvailabilityTimeDialog(time: '09:00 AM'),
      'select_slots': SlotSelectionDialog(selected: bloc.state.slots),
    };
    for (final entry in dialogs.entries) {
      await tester.pumpWidget(const SizedBox());
      late BuildContext pageContext;
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            home: Builder(
              builder: (context) {
                pageContext = context;
                return const Scaffold(body: Center(child: Text('Kapper')));
              },
            ),
          ),
        ),
      );
      modal(pageContext, entry.value);
      await tester.runAsync(() async {
        final context = tester.element(find.byType(Scaffold).first);
        for (final name in [
          'barber',
          'beauty',
          'bride',
          'hair',
          'portrait',
          'salon',
          'tools',
          'woman',
        ]) {
          await precacheImage(AssetImage('assets/images/$name.jpg'), context);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: entry.key);
      if (const bool.fromEnvironment('CAPTURE_UI')) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('captures/dialog_${entry.key}.png'),
        );
      }
    }
  });
}
