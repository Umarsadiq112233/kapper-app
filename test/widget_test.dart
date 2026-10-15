import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapper/main.dart';
import 'package:kapper/application/app_bloc.dart';
import 'package:kapper/data/mock_salon_repository.dart';
import 'package:kapper/domain/models.dart';

void main() {
  testWidgets('Role selection retains vendor through phone signup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = AppBloc(MockSalonRepository());
    await tester.pumpWidget(MyApp(bloc: bloc));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vendor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(bloc.state.role, AccountRole.vendor);
    expect(find.text('Enter Phone Number'), findsOneWidget);
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
        await tester.pump();
        await tester.pumpWidget(MyApp(bloc: bloc));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Appointment').last);
        await tester.pumpAndSettle();
        expect(find.text('Appointments'), findsOneWidget);
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
}
