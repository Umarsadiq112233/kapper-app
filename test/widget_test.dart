import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapper/main.dart';
import 'package:kapper/application/app_bloc.dart';
import 'package:kapper/data/mock_salon_repository.dart';
import 'package:kapper/domain/models.dart';
import 'package:kapper/features/auth/presentation/splash_screen.dart';

void main() {
  testWidgets('Role selection retains vendor through phone signup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = AppBloc(MockSalonRepository());
    await tester.pumpWidget(MyApp(bloc: bloc, initialRoute: '/role'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vendor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(bloc.state.role, AccountRole.vendor);
    expect(find.text('Vendor sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final vendor in [false, true]) {
    for (final width in [320.0, 430.0]) {
      testWidgets('${vendor ? 'Vendor' : 'Customer'} navigation at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final bloc = AppBloc(MockSalonRepository());
        bloc.add(
          SelectRole(vendor ? AccountRole.vendor : AccountRole.customer),
        );
        bloc.add(SignIn('', ''));
        await bloc.stream.firstWhere((s) => s.authenticated);
        await tester.pumpWidget(MyApp(bloc: bloc, initialRoute: '/home'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(vendor ? 'Appointment' : 'Bookings').last);
        await tester.pumpAndSettle();
        expect(
          find.text(vendor ? 'Appointments' : 'Bookings'),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Profile').last);
        await tester.pumpAndSettle();
        expect(find.text('Logout'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Customer cannot enter vendor management route', (tester) async {
    final bloc = AppBloc(MockSalonRepository());
    bloc.add(SelectRole(AccountRole.customer));
    bloc.add(SignIn('', ''));
    await tester.pump();
    await tester.pumpWidget(MyApp(bloc: bloc));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed('/vendor/availability');
    await tester.pumpAndSettle();
    expect(find.text('Edit Available Dates'), findsNothing);
  });

  test(
    'live vendor can change app appearance without a backend write',
    () async {
      final bloc = AppBloc(MockSalonRepository(), liveVendor: true);
      addTearDown(bloc.close);

      bloc.add(SelectRole(AccountRole.vendor));
      await bloc.stream.firstWhere((state) => state.isVendor);

      expect(bloc.state.themeMode, ThemeMode.dark);
      await bloc.submit(SetThemeMode(ThemeMode.light));
      expect(bloc.state.themeMode, ThemeMode.light);
      expect(bloc.state.notice, isEmpty);

      await bloc.submit(ToggleTheme());
      expect(bloc.state.themeMode, ThemeMode.dark);
      expect(bloc.state.notice, isEmpty);
    },
  );

  testWidgets('splash artwork follows the selected app theme', (tester) async {
    final bloc = AppBloc(MockSalonRepository());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(
          home: SplashScreen(
            autoNavigate: false,
            duration: Duration(milliseconds: 400),
          ),
        ),
      ),
    );
    await tester.pump();

    bool showsAsset(String path) => tester.any(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == path,
      ),
    );

    expect(showsAsset('assets/images/splashdark.png'), isTrue);
    bloc.add(SetThemeMode(ThemeMode.light));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(showsAsset('assets/images/splashlight.png'), isTrue);
  });
}
