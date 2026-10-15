import 'package:flutter_test/flutter_test.dart';
import 'package:kapper/application/app_bloc.dart';
import 'package:kapper/data/mock_salon_repository.dart';
import 'package:kapper/domain/models.dart';

Future<void> dispatch(AppBloc bloc, AppEvent event) async {
  bloc.add(event);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test(
    'booking rejects double booking and customer service mutation',
    () async {
      final bloc = AppBloc(MockSalonRepository());
      addTearDown(bloc.close);
      await dispatch(bloc, SelectRole(AccountRole.customer));
      await dispatch(bloc, SignIn('Josh', ''));
      final a = Appointment(
        id: 'new',
        salonId: 'danial',
        service: bloc.state.services.first,
        date: bloc.state.dates.last,
        time: bloc.state.slots.first,
        customer: 'Josh',
      );
      await dispatch(bloc, BookAppointment(a));
      final count = bloc.state.appointments.length;
      await dispatch(
        bloc,
        BookAppointment(
          Appointment(
            id: 'duplicate',
            salonId: a.salonId,
            service: a.service,
            date: a.date,
            time: a.time,
            customer: 'Other',
          ),
        ),
      );
      expect(bloc.state.appointments.length, count);
      expect(bloc.state.notice, contains('no longer available'));
      await dispatch(
        bloc,
        SaveService(const SalonService(id: 'bad', name: 'Forbidden', price: 1)),
      );
      expect(bloc.state.services.any((s) => s.id == 'bad'), false);
    },
  );
  test(
    'vendor changes survive role switch; completion and reviews synchronize',
    () async {
      final bloc = AppBloc(MockSalonRepository());
      addTearDown(bloc.close);
      await dispatch(bloc, SelectRole(AccountRole.vendor));
      await dispatch(bloc, SignIn('', ''));
      await dispatch(
        bloc,
        SaveService(const SalonService(id: 'new', name: 'New cut', price: 75)),
      );
      await dispatch(bloc, SignOut());
      await dispatch(bloc, SelectRole(AccountRole.customer));
      await dispatch(bloc, SignIn('', ''));
      expect(bloc.state.services.last.name, 'New cut');
      expect(bloc.servicesFor('mk').any((s) => s.id == 'new'), false);
      final a = Appointment(
        id: 'flow',
        salonId: 'danial',
        service: bloc.state.services.last,
        date: bloc.state.dates.last,
        time: bloc.state.slots.last,
        customer: 'Josh',
      );
      await dispatch(bloc, BookAppointment(a));
      await dispatch(
        bloc,
        UpdateAppointment(a.copy(status: BookingStatus.completed)),
      );
      expect(bloc.state.appointments.last.status, BookingStatus.upcoming);
      await dispatch(bloc, SelectRole(AccountRole.vendor));
      await dispatch(
        bloc,
        UpdateAppointment(a.copy(status: BookingStatus.completed)),
      );
      await dispatch(bloc, SelectRole(AccountRole.customer));
      await dispatch(bloc, AddReview(bloc.state.appointments.last, 'Great', 5));
      final reviewedCount = bloc.state.reviews.length;
      await dispatch(
        bloc,
        AddReview(a.copy(status: BookingStatus.completed), 'Duplicate', 5),
      );
      expect(bloc.state.reviews.length, reviewedCount);
      expect(bloc.state.reviews.last.text, 'Great');
      expect(bloc.state.appointments.last.reviewed, true);
    },
  );
}
