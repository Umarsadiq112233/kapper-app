import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/models.dart';

class AppState {
  const AppState({
    this.role,
    this.authenticated = false,
    this.name = 'Josh Jakarta',
    this.email = 'jakartajosh_123@gmail.com',
    this.address = '250 William St, New York',
    this.favorites = const {},
    this.services = const [],
    this.appointments = const [],
    this.dates = const [],
    this.slots = const [
      '09:00 AM',
      '10:30 AM',
      '12:00 PM',
      '01:30 PM',
      '03:00 PM',
      '04:30 PM',
      '06:00 PM',
      '07:30 PM',
    ],
    this.styles = const [],
    this.gallery = const [],
    this.albums = const [
      'Some satisfied clients',
      'Our brides & grooms',
      'Our professional crew',
    ],
    this.messages = const {},
    this.reviews = const [],
    this.notice = '',
    this.revision = 0,
  });
  final AccountRole? role;
  final bool authenticated;
  final String name, email, address, notice;
  final Set<String> favorites;
  final List<SalonService> services;
  final List<Appointment> appointments;
  final List<String> dates, slots, albums;
  final List<StyleItem> styles;
  final List<GalleryItem> gallery;
  final Map<String, List<ChatMessage>> messages;
  final List<SalonReview> reviews;
  final int revision;
  bool get isVendor => role == AccountRole.vendor;
  AppState copy({
    AccountRole? role,
    bool? authenticated,
    String? name,
    String? email,
    String? address,
    Set<String>? favorites,
    List<SalonService>? services,
    List<Appointment>? appointments,
    List<String>? dates,
    List<String>? slots,
    List<StyleItem>? styles,
    List<GalleryItem>? gallery,
    List<String>? albums,
    Map<String, List<ChatMessage>>? messages,
    List<SalonReview>? reviews,
    String? notice,
  }) => AppState(
    role: role ?? this.role,
    authenticated: authenticated ?? this.authenticated,
    name: name ?? this.name,
    email: email ?? this.email,
    address: address ?? this.address,
    favorites: favorites ?? this.favorites,
    services: services ?? this.services,
    appointments: appointments ?? this.appointments,
    dates: dates ?? this.dates,
    slots: slots ?? this.slots,
    styles: styles ?? this.styles,
    gallery: gallery ?? this.gallery,
    albums: albums ?? this.albums,
    messages: messages ?? this.messages,
    reviews: reviews ?? this.reviews,
    notice: notice ?? '',
    revision: revision + 1,
  );
}

sealed class AppEvent {}

class SelectRole extends AppEvent {
  SelectRole(this.role);
  final AccountRole role;
}

class SignIn extends AppEvent {
  SignIn(this.name, this.email);
  final String name, email;
}

class SignOut extends AppEvent {}

class SaveProfile extends AppEvent {
  SaveProfile(this.name, this.email, this.address);
  final String name, email, address;
}

class ToggleFavorite extends AppEvent {
  ToggleFavorite(this.id);
  final String id;
}

class SaveService extends AppEvent {
  SaveService(this.service);
  final SalonService service;
}

class BookAppointment extends AppEvent {
  BookAppointment(this.appointment);
  final Appointment appointment;
}

class UpdateAppointment extends AppEvent {
  UpdateAppointment(this.appointment);
  final Appointment appointment;
}

class SaveAvailability extends AppEvent {
  SaveAvailability(this.dates, this.slots);
  final List<String> dates, slots;
}

class AddStyle extends AppEvent {
  AddStyle(this.style);
  final StyleItem style;
}

class AddPhoto extends AppEvent {
  AddPhoto(this.photo);
  final GalleryItem photo;
}

class AddAlbum extends AppEvent {
  AddAlbum(this.name);
  final String name;
}

class SendMessage extends AppEvent {
  SendMessage(this.id, this.text);
  final String id, text;
}

class AddReview extends AppEvent {
  AddReview(this.appointment, this.text, this.stars);
  final Appointment appointment;
  final String text;
  final int stars;
}

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc(this.repository)
    : super(
        AppState(
          services: repository.initialServices,
          appointments: repository.initialAppointments,
          dates: repository.initialDates,
          styles: const [
            StyleItem('Fluffy Hair', 'Soft texture, natural volume', 'hair'),
            StyleItem(
              'Shoulder-length Hairstyle',
              'An effortless everyday look',
              'woman',
            ),
            StyleItem(
              'Plaited Hairstyle',
              'Beautifully woven details',
              'bride',
            ),
            StyleItem('Regular Hairstyle', 'A timeless classic', 'portrait'),
          ],
          gallery: const [
            GalleryItem('Hair Cutting', 'hair'),
            GalleryItem('Hair Cutting', 'barber'),
            GalleryItem('Hair Cutting', 'portrait'),
            GalleryItem('Makeover', 'bride'),
            GalleryItem('Makeover', 'woman'),
            GalleryItem('Makeover', 'beauty'),
          ],
        ),
      ) {
    on<SelectRole>((e, emit) => emit(state.copy(role: e.role)));
    on<SignIn>(
      (e, emit) => emit(
        state.copy(
          authenticated: true,
          name: e.name.isEmpty
              ? (state.isVendor ? 'Danial Willam' : 'Josh Jakarta')
              : e.name,
          email: e.email.isEmpty ? state.email : e.email,
        ),
      ),
    );
    on<SignOut>((e, emit) => emit(state.copy(authenticated: false)));
    on<SaveProfile>(
      (e, emit) =>
          emit(state.copy(name: e.name, email: e.email, address: e.address)),
    );
    on<ToggleFavorite>((e, emit) {
      final favorites = {...state.favorites};
      favorites.contains(e.id) ? favorites.remove(e.id) : favorites.add(e.id);
      emit(state.copy(favorites: favorites));
    });
    on<SaveService>((e, emit) {
      if (!state.authenticated || !state.isVendor) return;
      emit(
        state.copy(
          services: [
            ...state.services.where((s) => s.id != e.service.id),
            e.service,
          ],
        ),
      );
    });
    on<BookAppointment>((e, emit) {
      final a = e.appointment;
      if (state.isVendor || !state.authenticated) return;
      if (!repository.salons.any((s) => s.id == a.salonId) ||
          !servicesFor(a.salonId).any(
            (s) =>
                s.id == a.service.id &&
                s.price == a.service.price &&
                s.duration == a.service.duration,
          ) ||
          state.appointments.any((b) => b.id == a.id) ||
          !datesFor(a.salonId).contains(a.date) ||
          !slotsFor(a.salonId).contains(a.time) ||
          state.appointments.any(
            (b) =>
                b.salonId == a.salonId &&
                b.date == a.date &&
                b.time == a.time &&
                b.status == BookingStatus.upcoming,
          )) {
        emit(
          state.copy(
            notice: 'This slot is no longer available. Please choose another.',
          ),
        );
        return;
      }
      emit(
        state.copy(
          appointments: [...state.appointments, a],
          notice: 'Demo booking confirmed',
        ),
      );
    });
    on<UpdateAppointment>((e, emit) {
      final a = e.appointment;
      final previous = state.appointments
          .where((b) => b.id == a.id)
          .firstOrNull;
      if (!state.authenticated ||
          previous == null ||
          previous.status != BookingStatus.upcoming ||
          (state.isVendor && previous.salonId != 'danial')) {
        return;
      }
      if (a.status == BookingStatus.completed && !state.isVendor) return;
      if (a.status == BookingStatus.upcoming &&
          (!datesFor(a.salonId).contains(a.date) ||
              !slotsFor(a.salonId).contains(a.time) ||
              state.appointments.any(
                (b) =>
                    b.id != a.id &&
                    b.salonId == a.salonId &&
                    b.date == a.date &&
                    b.time == a.time &&
                    b.status == BookingStatus.upcoming,
              ))) {
        emit(state.copy(notice: 'That time is unavailable.'));
        return;
      }
      emit(
        state.copy(
          appointments: state.appointments
              .map((b) => b.id == a.id ? a : b)
              .toList(),
          notice: 'Appointment updated',
        ),
      );
    });
    on<SaveAvailability>((e, emit) {
      if (state.authenticated && state.isVendor) {
        emit(state.copy(dates: [...e.dates]..sort(), slots: e.slots));
      }
    });
    on<AddStyle>((e, emit) {
      if (state.authenticated && state.isVendor) {
        emit(state.copy(styles: [...state.styles, e.style]));
      }
    });
    on<AddPhoto>((e, emit) {
      if (state.authenticated && state.isVendor) {
        emit(state.copy(gallery: [...state.gallery, e.photo]));
      }
    });
    on<AddAlbum>((e, emit) {
      if (state.authenticated &&
          state.isVendor &&
          !state.albums.contains(e.name)) {
        emit(state.copy(albums: [...state.albums, e.name]));
      }
    });
    on<SendMessage>((e, emit) {
      if (!state.authenticated ||
          state.role == null ||
          e.text.trim().isEmpty ||
          !state.appointments.any(
            (a) => a.id == e.id && (!state.isVendor || a.salonId == 'danial'),
          )) {
        return;
      }
      emit(
        state.copy(
          messages: {
            ...state.messages,
            e.id: [
              ...?state.messages[e.id],
              ChatMessage(e.text.trim(), state.role!),
            ],
          },
        ),
      );
    });
    on<AddReview>((e, emit) {
      final stored = state.appointments
          .where((a) => a.id == e.appointment.id)
          .firstOrNull;
      if (!state.authenticated ||
          state.isVendor ||
          stored == null ||
          stored.status != BookingStatus.completed ||
          stored.reviewed ||
          e.stars < 1 ||
          e.stars > 5) {
        return;
      }
      emit(
        state.copy(
          reviews: [
            ...state.reviews,
            SalonReview(e.appointment.salonId, state.name, e.text, e.stars),
          ],
          appointments: state.appointments
              .map((a) => a.id == e.appointment.id ? a.copy(reviewed: true) : a)
              .toList(),
        ),
      );
    });
  }
  final SalonRepository repository;
  List<SalonService> servicesFor(String salonId) =>
      salonId == 'danial' ? state.services : repository.initialServices;
  List<String> datesFor(String salonId) =>
      salonId == 'danial' ? state.dates : repository.initialDates;
  List<String> slotsFor(String salonId) =>
      salonId == 'danial' ? state.slots : const AppState().slots;
}

/// Screen-local selection/form state is also event-driven BLoC state.
class ViewState {
  const ViewState([this.values = const {}]);
  final Map<String, Object?> values;
  T get<T>(String key, T fallback) => values[key] as T? ?? fallback;
}

class ViewChanged {
  const ViewChanged(this.key, this.value);
  final String key;
  final Object? value;
}

class ViewBloc extends Bloc<ViewChanged, ViewState> {
  ViewBloc() : super(const ViewState()) {
    on<ViewChanged>(
      (event, emit) =>
          emit(ViewState({...state.values, event.key: event.value})),
    );
  }
  void change(String key, Object? value) => add(ViewChanged(key, value));
}
