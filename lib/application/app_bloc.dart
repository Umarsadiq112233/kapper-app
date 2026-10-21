import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'customer_backend.dart';
import 'vendor_backend.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/models.dart';

class AppState {
  const AppState({
    this.role,
    this.salonId = 'danial',
    this.saving = false,
    this.authenticated = false,
    this.isPublic = true,
    this.latitude,
    this.longitude,
    this.name = 'Josh Jakarta',
    this.phone = '',
    this.email = 'jakartajosh_123@gmail.com',
    this.address = '250 William St, New York',
    this.bio = 'Passionate grooming specialist & style enthusiast.',
    this.gender = 'Male',
    this.avatar,
    this.avatarBytes,
    this.favorites = const {},
    this.customerListings = const [],
    this.customerSalonDetails = const {},
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
    this.notifications = const [],
    this.themeMode = ThemeMode.dark,
    this.notice = '',
    this.discoveryError = '',
    this.revision = 0,
  });
  final AccountRole? role;
  final String salonId;
  final bool saving;
  final bool authenticated;
  final bool isPublic;
  final double? latitude, longitude;
  final String name, email, phone, address, notice, discoveryError, bio, gender;
  final String? avatar;
  final Uint8List? avatarBytes;
  final Set<String> favorites;
  final List<SalonListing> customerListings;
  final Map<String, PublicSalonDetails> customerSalonDetails;
  final List<SalonService> services;
  final List<Appointment> appointments;
  final List<String> dates, slots, albums;
  final List<StyleItem> styles;
  final List<GalleryItem> gallery;
  final Map<String, List<ChatMessage>> messages;
  final List<SalonReview> reviews;
  final List<VendorNotification> notifications;
  final ThemeMode themeMode;
  final int revision;
  int unreadFor(String id) => (messages[id] ?? const <ChatMessage>[])
      .where((m) => m.sender != role && m.readAt == null)
      .length;
  int get unreadMessages =>
      messages.keys.fold(0, (sum, id) => sum + unreadFor(id));
  bool get isVendor => role == AccountRole.vendor;
  bool get isDark => themeMode == ThemeMode.dark;
  AppState copy({
    AccountRole? role,
    String? salonId,
    bool? saving,
    bool? authenticated,
    bool? isPublic,
    double? latitude,
    double? longitude,
    bool clearCoordinates = false,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? bio,
    String? gender,
    String? avatar,
    Uint8List? avatarBytes,
    bool clearAvatar = false,
    bool clearAvatarBytes = false,
    Set<String>? favorites,
    List<SalonListing>? customerListings,
    Map<String, PublicSalonDetails>? customerSalonDetails,
    List<SalonService>? services,
    List<Appointment>? appointments,
    List<String>? dates,
    List<String>? slots,
    List<StyleItem>? styles,
    List<GalleryItem>? gallery,
    List<String>? albums,
    Map<String, List<ChatMessage>>? messages,
    List<SalonReview>? reviews,
    List<VendorNotification>? notifications,
    ThemeMode? themeMode,
    String? notice,
    String? discoveryError,
  }) => AppState(
    role: role ?? this.role,
    salonId: salonId ?? this.salonId,
    saving: saving ?? this.saving,
    authenticated: authenticated ?? this.authenticated,
    isPublic: isPublic ?? this.isPublic,
    latitude: clearCoordinates ? null : latitude ?? this.latitude,
    longitude: clearCoordinates ? null : longitude ?? this.longitude,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    bio: bio ?? this.bio,
    gender: gender ?? this.gender,
    avatar: clearAvatar ? null : (avatar ?? this.avatar),
    avatarBytes: clearAvatar || clearAvatarBytes
        ? null
        : (avatarBytes ?? this.avatarBytes),
    favorites: favorites ?? this.favorites,
    customerListings: customerListings ?? this.customerListings,
    customerSalonDetails: customerSalonDetails ?? this.customerSalonDetails,
    services: services ?? this.services,
    appointments: appointments ?? this.appointments,
    dates: dates ?? this.dates,
    slots: slots ?? this.slots,
    styles: styles ?? this.styles,
    gallery: gallery ?? this.gallery,
    albums: albums ?? this.albums,
    messages: messages ?? this.messages,
    reviews: reviews ?? this.reviews,
    notifications: notifications ?? this.notifications,
    themeMode: themeMode ?? this.themeMode,
    notice: notice ?? '',
    discoveryError: discoveryError ?? this.discoveryError,
    revision: revision + 1,
  );
}

sealed class AppEvent {}

class SelectRole extends AppEvent {
  SelectRole(this.role);
  final AccountRole role;
}

class SignIn extends AppEvent {
  SignIn(this.name, this.email, {this.phone});
  final String name, email;
  final String? phone;
}

class SignOut extends AppEvent {}

class SaveProfile extends AppEvent {
  SaveProfile(
    this.name,
    this.email,
    this.address, {
    this.phone,
    this.bio,
    this.gender,
    this.avatar,
    this.avatarBytes,
    this.clearAvatar = false,
    this.isPublic,
    this.latitude,
    this.longitude,
  });
  final double? latitude, longitude;
  final String name, email, address;
  final String? phone;
  final String? bio;
  final String? gender;
  final String? avatar;
  final Uint8List? avatarBytes;
  final bool clearAvatar;
  final bool? isPublic;
}

class ToggleFavorite extends AppEvent {
  ToggleFavorite(this.id);
  final String id;
}

class SaveService extends AppEvent {
  SaveService(this.service);
  final SalonService service;
}

class SetServiceEnabled extends AppEvent {
  SetServiceEnabled(this.id, this.enabled);
  final String id;
  final bool enabled;
}

class DeleteService extends AppEvent {
  DeleteService(this.id);
  final String id;
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

class DeleteStyle extends AppEvent {
  DeleteStyle(this.style);
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

class MarkVendorNotificationRead extends AppEvent {
  MarkVendorNotificationRead(this.id);
  final String id;
}

class RestoreVendor extends AppEvent {}

class VendorSessionEnded extends AppEvent {}

class MarkConversationRead extends AppEvent {
  MarkConversationRead(this.id, this.through);
  final String id;
  final DateTime through;
}

class RefreshVendor extends AppEvent {}

/// Loads the signed-in customer's Supabase profile into app state.
class RestoreCustomer extends AppEvent {}

class RefreshCustomerCatalog extends AppEvent {}

class LoadCustomerSalonDetails extends AppEvent {
  LoadCustomerSalonDetails(this.salonId);
  final String salonId;
}

class RefreshCustomerMessages extends AppEvent {}

class CustomerSessionEnded extends AppEvent {}

class SetThemeMode extends AppEvent {
  SetThemeMode(this.themeMode);
  final ThemeMode themeMode;
}

class ToggleTheme extends AppEvent {}

class VendorRequest extends AppEvent {
  VendorRequest(this.event);
  final AppEvent event;
  final done = Completer<void>();
}

final _defaultChatMessages = <String, List<ChatMessage>>{
  'LK4582': [
    ChatMessage(
      'Hi, I would like to confirm my appointment tomorrow at 10:00 AM.',
      AccountRole.customer,
      createdAt: DateTime(2024, 5, 11, 10, 28),
    ),
    ChatMessage(
      'Yes sure! Your appointment is confirmed. Please be on time. 😊',
      AccountRole.vendor,
      createdAt: DateTime(2024, 5, 11, 10, 30),
    ),
    ChatMessage(
      'Can you also share your exact location?',
      AccountRole.customer,
      createdAt: DateTime(2024, 5, 11, 10, 31),
    ),
    ChatMessage(
      'LOCATION: Our Salon Location\n87, Main Boulevard, Johar Town, Lahore, Pakistan',
      AccountRole.vendor,
      createdAt: DateTime(2024, 5, 11, 10, 32),
    ),
    ChatMessage(
      'Thank you! See you tomorrow. 😊',
      AccountRole.customer,
      createdAt: DateTime(2024, 5, 11, 10, 33),
    ),
  ],
  'LK4583': [
    ChatMessage(
      'Can I reschedule my appointment to afternoon?',
      AccountRole.customer,
      createdAt: DateTime(2024, 5, 11, 9, 15),
    ),
  ],
  'LK4584': [
    ChatMessage(
      'Thank you so much! 😊',
      AccountRole.customer,
      createdAt: DateTime(2024, 5, 10, 16, 20),
    ),
  ],
  'LK4585': [
    ChatMessage(
      'Is there any slot available for tomorrow?',
      AccountRole.customer,
      createdAt: DateTime(2024, 5, 10, 14, 10),
    ),
  ],
  'LK4586': [
    ChatMessage(
      'Great service! 👏',
      AccountRole.customer,
      createdAt: DateTime(2024, 5, 2, 11, 45),
    ),
  ],
  'LK4587': [
    ChatMessage(
      'What is the price for beard styling?',
      AccountRole.customer,
      createdAt: DateTime(2024, 5, 1, 13, 10),
    ),
  ],
};

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc(
    this.repository, {
    this.vendorBackend,
    this.liveVendor = false,
    this.customerBackend,
  }) : super(
         AppState(
           services: repository.initialServices,
           appointments: repository.initialAppointments,
           dates: repository.initialDates,
           styles: const [
             StyleItem(
               'Cutting ✂️',
               'Smoothly',
               'cutting_beard',
               null,
               'Haircuts',
             ),
             StyleItem(
               'Cleaning 🧼 Face',
               'Wonderful 😊',
               'cleaning_face',
               null,
               'Styling',
             ),
             StyleItem(
               'Fluffy Hair',
               'Soft texture, natural volume',
               'hair',
               null,
               'Haircuts',
             ),
             StyleItem(
               'Beard Sculpting',
               'Precision lines & grooming',
               'barber',
               null,
               'Beard',
             ),
             StyleItem(
               'Regular Hairstyle',
               'A timeless classic',
               'portrait',
               null,
               'Haircuts',
             ),
           ],
           gallery: const [
             GalleryItem('Hair Cutting', 'hair'),
             GalleryItem('Hair Cutting', 'barber'),
             GalleryItem('Hair Cutting', 'portrait'),
             GalleryItem('Makeover', 'bride'),
             GalleryItem('Makeover', 'woman'),
             GalleryItem('Makeover', 'beauty'),
           ],
           messages: _defaultChatMessages,
         ),
       ) {
    _demoState = state;
    final handlers =
        <Type, FutureOr<void> Function(AppEvent, Emitter<AppState>)>{};
    void handle<E extends AppEvent>(
      FutureOr<void> Function(E, Emitter<AppState>) action,
    ) {
      handlers[E] = (event, emit) => action(event as E, emit);
    }

    handle<SelectRole>((e, emit) => emit(state.copy(role: e.role)));
    handle<SetThemeMode>((e, emit) => emit(state.copy(themeMode: e.themeMode)));
    handle<ToggleTheme>(
      (_, emit) => emit(
        state.copy(themeMode: state.isDark ? ThemeMode.light : ThemeMode.dark),
      ),
    );
    handle<SignIn>(
      (e, emit) => emit(
        state.copy(
          authenticated: true,
          name: e.name.isEmpty
              ? (state.isVendor ? 'Danial Willam' : 'Josh Jakarta')
              : e.name,
          email: e.email.isEmpty ? state.email : e.email,
          phone: e.phone ?? state.phone,
        ),
      ),
    );
    handle<SignOut>((e, emit) => emit(state.copy(authenticated: false)));
    handle<SaveProfile>(
      (e, emit) => emit(
        state.copy(
          name: e.name,
          email: e.email,
          address: e.address,
          phone: e.phone ?? state.phone,
          bio: e.bio ?? state.bio,
          gender: e.gender ?? state.gender,
          avatar: e.clearAvatar ? '' : (e.avatar ?? state.avatar),
          avatarBytes: e.clearAvatar
              ? null
              : (e.avatarBytes ?? state.avatarBytes),
          clearAvatar: e.clearAvatar,
          clearAvatarBytes: e.clearAvatar,
        ),
      ),
    );
    handle<ToggleFavorite>((e, emit) {
      final favorites = {...state.favorites};
      favorites.contains(e.id) ? favorites.remove(e.id) : favorites.add(e.id);
      emit(state.copy(favorites: favorites));
    });
    handle<SaveService>((e, emit) {
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
    handle<SetServiceEnabled>((e, emit) {
      if (!state.authenticated || !state.isVendor) return;
      emit(
        state.copy(
          services: state.services
              .map((s) => s.id == e.id ? s.withEnabled(e.enabled) : s)
              .toList(),
        ),
      );
    });
    handle<DeleteService>((e, emit) {
      if (!state.authenticated || !state.isVendor) return;
      emit(
        state.copy(
          services: state.services.where((s) => s.id != e.id).toList(),
        ),
      );
    });
    handle<BookAppointment>((e, emit) {
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
    handle<UpdateAppointment>((e, emit) {
      final a = e.appointment;
      final previous = state.appointments
          .where((b) => b.id == a.id)
          .firstOrNull;
      if (!state.authenticated ||
          previous == null ||
          previous.status != BookingStatus.upcoming ||
          (state.isVendor && previous.salonId != state.salonId)) {
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
    handle<SaveAvailability>((e, emit) {
      _validateAvailability(e);
      if (state.authenticated && state.isVendor) {
        emit(
          state.copy(
            dates: e.dates.toSet().toList()..sort(),
            slots: e.slots.toSet().toList()
              ..sort(
                (a, b) =>
                    availabilityMinutes(a).compareTo(availabilityMinutes(b)),
              ),
          ),
        );
      }
    });
    handle<AddStyle>((e, emit) {
      if (state.authenticated && state.isVendor) {
        emit(state.copy(styles: [...state.styles, e.style]));
      }
    });
    handle<DeleteStyle>((e, emit) {
      if (state.authenticated && state.isVendor) {
        emit(
          state.copy(
            styles: state.styles.where((s) => s.name != e.style.name).toList(),
          ),
        );
      }
    });
    handle<AddPhoto>((e, emit) {
      if (state.authenticated && state.isVendor) {
        emit(state.copy(gallery: [...state.gallery, e.photo]));
      }
    });
    handle<AddAlbum>((e, emit) {
      if (state.authenticated &&
          state.isVendor &&
          !state.albums.contains(e.name)) {
        emit(state.copy(albums: [...state.albums, e.name]));
      }
    });
    handle<SendMessage>((e, emit) {
      if (!state.authenticated || state.role == null || e.text.trim().isEmpty) {
        return;
      }
      emit(
        state.copy(
          messages: {
            ...state.messages,
            e.id: [
              ...?state.messages[e.id],
              ChatMessage(
                e.text.trim(),
                state.role!,
                createdAt: DateTime.now(),
              ),
            ],
          },
        ),
      );
    });
    handle<AddReview>((e, emit) {
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
    handle<MarkVendorNotificationRead>((e, emit) {
      if (!state.isVendor) return;
      emit(
        state.copy(
          notifications: state.notifications
              .map(
                (notification) => notification.id == e.id
                    ? notification.markRead()
                    : notification,
              )
              .toList(),
        ),
      );
    });
    on<AppEvent>((event, emit) async {
      final request = event is VendorRequest ? event : null;
      final action = request?.event ?? event;
      try {
        // Appearance is local app state. Keep it out of the live-vendor
        // backend routing below, which only accepts persisted salon actions.
        if (action is MarkConversationRead &&
            (liveCustomer || (liveVendor && state.isVendor))) {
          await Supabase.instance.client.rpc(
            'mark_conversation_read',
            params: {
              'conversation_id': action.id,
              'through_time': action.through.toUtc().toIso8601String(),
            },
          );
          add(state.isVendor ? RefreshVendor() : RefreshCustomerMessages());
        } else if (action is SetThemeMode || action is ToggleTheme) {
          await handlers[action.runtimeType]?.call(action, emit);
        } else if (action is CustomerSessionEnded) {
          if (!state.isVendor && state.authenticated) {
            await _catalogSubscription?.cancel();
            await _customerMessageSubscription?.cancel();
            _customerMessageSubscription = null;
            emit(_demoState);
          }
        } else if (liveCustomer &&
            (action is RestoreCustomer ||
                action is RefreshCustomerCatalog ||
                action is LoadCustomerSalonDetails ||
                (!state.isVendor &&
                    state.authenticated &&
                    (action is SaveProfile ||
                        action is SignOut ||
                        action is ToggleFavorite ||
                        action is BookAppointment ||
                        action is SendMessage ||
                        action is RefreshCustomerMessages)))) {
          await _handleCustomer(action, emit);
        } else if (action is VendorSessionEnded) {
          await _stopWatchingVendorChanges();
          if (state.isVendor) emit(_demoState);
        } else if (liveVendor &&
            (action is RestoreVendor ||
                (state.isVendor && action is! SelectRole))) {
          await _handleVendor(action, emit);
        } else if (liveVendor && action is SelectRole && state.authenticated) {
          // Switching roles requires signing out first.
        } else {
          await handlers[action.runtimeType]?.call(action, emit);
        }
        request?.done.complete();
      } catch (error) {
        final diagnostic = error is PostgrestException
            ? 'PostgrestException code=${error.code ?? 'none'}'
            : error is AuthException
            ? 'AuthException code=${error.code ?? error.statusCode ?? 'none'}'
            : error.runtimeType.toString();
        final operation = error is CustomerFailure ? 'Customer' : 'Vendor';
        debugPrint('$operation operation failed [$diagnostic]');
        final message = error is VendorFailure
            ? error.message
            : error is CustomerFailure
            ? error.message
            : error is AuthException
            ? error.message
            : error is PostgrestException
            ? error.message
            : 'Could not sync with your account. Check your connection and try again.';
        emit(state.copy(saving: false, notice: message));
        request?.done.completeError(VendorFailure(message));
      }
    }, transformer: (events, mapper) => events.asyncExpand(mapper));
    _authSubscription = vendorBackend?.sessionEnded.listen(
      (_) => add(VendorSessionEnded()),
      onError: (Object _) => add(VendorSessionEnded()),
    );
    _customerAuthSubscription = customerBackend?.sessionEnded.listen(
      (_) => add(CustomerSessionEnded()),
      onError: (Object _) => add(CustomerSessionEnded()),
    );
  }
  late final AppState _demoState;
  final VendorBackend? vendorBackend;
  final bool liveVendor;
  final CustomerBackend? customerBackend;
  bool get liveCustomer => customerBackend?.hasSession == true;
  StreamSubscription<void>? _authSubscription;
  StreamSubscription<void>? _customerAuthSubscription;
  StreamSubscription<void>? _customerMessageSubscription;
  StreamSubscription<void>? _catalogSubscription;
  StreamSubscription<void>? _dataSubscription;
  Future<void> submit(AppEvent event) {
    final request = VendorRequest(event);
    add(request);
    return request.done.future;
  }

  /// Reloads live data for the signed-in role. Used by pull-to-refresh.
  /// Errors are swallowed so the spinner always settles.
  Future<void> refreshAll() async {
    try {
      if (liveVendor && state.isVendor && vendorBackend?.hasSession == true) {
        await submit(RefreshVendor());
      } else if (liveCustomer) {
        await submit(RefreshCustomerCatalog());
        await submit(RefreshCustomerMessages());
      }
    } catch (error) {
      debugPrint('Pull-to-refresh failed [${error.runtimeType}]');
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    await _customerAuthSubscription?.cancel();
    await _catalogSubscription?.cancel();
    await _customerMessageSubscription?.cancel();
    await _dataSubscription?.cancel();
    return super.close();
  }

  Future<void> _handleCustomer(AppEvent event, Emitter<AppState> emit) async {
    final backend = customerBackend!;
    if (event is SignOut) {
      await _catalogSubscription?.cancel();
      await _customerMessageSubscription?.cancel();
      _customerMessageSubscription = null;
      await backend.signOut();
      emit(_demoState);
      return;
    }
    if (!backend.hasSession) {
      throw const CustomerFailure('Please sign in to your account.');
    }
    if (event is RestoreCustomer || event is RefreshCustomerCatalog) {
      emit(state.copy(saving: true));
      final profile = event is RestoreCustomer
          ? await backend.loadProfile()
          : null;
      final appointments = event is RestoreCustomer
          ? await backend.loadAppointments()
          : state.appointments;
      final messages = event is RestoreCustomer
          ? await backend.loadMessages()
          : state.messages;
      if (event is RestoreCustomer) _watchCustomerMessages(backend);
      try {
        final listings = await backend.discoverSalons();
        final favorites = await backend.loadFavoriteSalonIds();
        emit(
          (profile == null ? state : _withProfile(profile)).copy(
            saving: false,
            customerListings: listings,
            customerSalonDetails: event is RestoreCustomer
                ? const {}
                : state.customerSalonDetails,
            favorites: favorites,
            appointments: appointments,
            services: event is RestoreCustomer ? const [] : state.services,
            dates: event is RestoreCustomer ? const [] : state.dates,
            styles: event is RestoreCustomer ? const [] : state.styles,
            gallery: event is RestoreCustomer ? const [] : state.gallery,
            messages: messages,
            reviews: event is RestoreCustomer ? const [] : state.reviews,
            notifications: event is RestoreCustomer
                ? const []
                : state.notifications,
            discoveryError: '',
          ),
        );
      } on CustomerFailure catch (error) {
        emit(
          (profile == null ? state : _withProfile(profile)).copy(
            saving: false,
            customerListings: const [],
            customerSalonDetails: event is RestoreCustomer
                ? const {}
                : state.customerSalonDetails,
            favorites: const {},
            appointments: appointments,
            services: event is RestoreCustomer ? const [] : state.services,
            dates: event is RestoreCustomer ? const [] : state.dates,
            styles: event is RestoreCustomer ? const [] : state.styles,
            gallery: event is RestoreCustomer ? const [] : state.gallery,
            messages: messages,
            reviews: event is RestoreCustomer ? const [] : state.reviews,
            notifications: event is RestoreCustomer
                ? const []
                : state.notifications,
            discoveryError: error.message,
          ),
        );
      } on PostgrestException catch (error) {
        debugPrint('Customer catalog refresh failed [${error.code}]');
        emit(
          (profile == null ? state : _withProfile(profile)).copy(
            saving: false,
            customerListings: const [],
            customerSalonDetails: event is RestoreCustomer
                ? const {}
                : state.customerSalonDetails,
            favorites: const {},
            appointments: appointments,
            services: event is RestoreCustomer ? const [] : state.services,
            dates: event is RestoreCustomer ? const [] : state.dates,
            styles: event is RestoreCustomer ? const [] : state.styles,
            gallery: event is RestoreCustomer ? const [] : state.gallery,
            messages: messages,
            reviews: event is RestoreCustomer ? const [] : state.reviews,
            notifications: event is RestoreCustomer
                ? const []
                : state.notifications,
            discoveryError: 'Could not load salon data. Check your connection and Supabase setup.',
          ),
        );
      } catch (error) {
        debugPrint('Customer catalog refresh failed [${error.runtimeType}]');
        emit(
          (profile == null ? state : _withProfile(profile)).copy(
            saving: false,
            customerListings: const [],
            favorites: const {},
            appointments: appointments,
            messages: messages,
            discoveryError: 'Could not load salon data. Check your internet connection and retry.',
          ),
        );
      }
      return;
    }
    if (event is RefreshCustomerMessages) {
      emit(state.copy(messages: await backend.loadMessages()));
      return;
    }
    if (event is LoadCustomerSalonDetails) {
      final details = await backend.loadSalonDetails(event.salonId);
      emit(
        state.copy(
          customerSalonDetails: {
            ...state.customerSalonDetails,
            event.salonId: details,
          },
        ),
      );
      return;
    }
    if (event is SendMessage) {
      if (!state.appointments.any(
        (appointment) => appointment.id == event.id,
      )) {
        emit(
          state.copy(
            messages: {
              ...state.messages,
              event.id: [
                ...?state.messages[event.id],
                ChatMessage(
                  event.text.trim(),
                  AccountRole.customer,
                  createdAt: DateTime.now(),
                ),
              ],
            },
          ),
        );
        return;
      }
      await backend.sendMessage(event.id, event.text);
      emit(
        state.copy(
          messages: await backend.loadMessages(),
          notice: 'Message sent',
        ),
      );
      return;
    }
    if (event is ToggleFavorite) {
      final favorites = await backend.toggleFavorite(event.id);
      emit(state.copy(favorites: favorites));
      return;
    }
    if (event is BookAppointment) {
      final appointment = await backend.createBooking(event.appointment);
      emit(
        state.copy(
          appointments: [...state.appointments, appointment],
          notice: 'Appointment requested. Pay at the salon.',
        ),
      );
      return;
    }
    if (event is SaveProfile) {
      if (event.name.trim().isEmpty) {
        throw const CustomerFailure('Enter your full name.');
      }
      emit(state.copy(saving: true));
      String? uploadedAvatar = event.avatar;
      if (event.avatarBytes != null && event.avatarBytes!.isNotEmpty) {
        uploadedAvatar = await backend.uploadImage(event.avatarBytes!);
      }
      final saved = await backend.saveProfile(
        CustomerProfile(
          id: '',
          name: event.name,
          email: state.email,
          gender: event.gender ?? state.gender,
          phone: event.phone ?? state.phone,
          address: event.address,
          bio: event.bio ?? state.bio,
          avatar: event.clearAvatar ? null : (uploadedAvatar ?? state.avatar),
        ),
      );
      emit(
        _withProfile(saved).copy(
          // Uploaded photos are now represented by the storage reference in
          // `avatar`; keeping raw bytes here would make the UI look saved
          // until the next restart only.
          avatarBytes: null,
          clearAvatar: event.clearAvatar,
          clearAvatarBytes: event.clearAvatar,
          notice: 'Profile saved',
        ),
      );
    }
  }

  AppState _withProfile(CustomerProfile p) => state.copy(
    role: AccountRole.customer,
    authenticated: true,
    saving: false,
    name: p.name,
    email: p.email,
    phone: p.phone,
    address: p.address,
    bio: p.bio,
    gender: p.gender,
    avatar: p.avatar,
    clearAvatar: p.avatar == null || p.avatar!.isEmpty,
  );

  void _watchCustomerMessages(CustomerBackend backend) {
    _catalogSubscription?.cancel();
    if (backend is CustomerCatalogUpdates) {
      _catalogSubscription = (backend as CustomerCatalogUpdates).catalogChanges
          .listen((_) {
            if (!isClosed && liveCustomer) {
              add(RefreshCustomerCatalog());
              for (final id in state.customerSalonDetails.keys.toList()) {
                add(LoadCustomerSalonDetails(id));
              }
            }
          }, onError: (Object _) {});
    }
    _customerMessageSubscription?.cancel();
    _customerMessageSubscription = backend.messageChanges.listen((_) {
      if (!isClosed) add(RefreshCustomerMessages());
    }, onError: (Object _) {});
  }

  Future<void> _watchVendorChanges(VendorBackend backend) async {
    await _stopWatchingVendorChanges();
    _dataSubscription = backend.changes.listen(
      (_) {
        if (!isClosed) add(RefreshVendor());
      },
      onError: (Object _) {
        // The visible refresh control remains available if Realtime disconnects.
      },
    );
  }

  Future<void> _stopWatchingVendorChanges() async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;
  }

  Future<void> _handleVendor(AppEvent event, Emitter<AppState> emit) async {
    final backend = vendorBackend;
    if (backend == null) {
      throw const VendorFailure('Vendor sign-in is not configured yet.');
    }
    if (event is SignOut) {
      await _stopWatchingVendorChanges();
      await backend.signOut();
      emit(_demoState);
      return;
    }
    if (event is RestoreVendor || event is RefreshVendor) {
      emit(state.copy(saving: true));
      emit(await backend.load());
      if (event is RestoreVendor) await _watchVendorChanges(backend);
      return;
    }
    if (!backend.hasSession) {
      throw const VendorFailure('Please verify your phone number first.');
    }
    if (event is SignIn) {
      throw const VendorFailure('Use SMS verification to sign in.');
    }
    if (!state.authenticated && event is! SaveProfile) {
      throw const VendorFailure('Complete your salon profile first.');
    }
    emit(state.copy(saving: true));
    var next = state;
    if (event is SaveProfile) {
      if (event.name.trim().isEmpty || event.address.trim().isEmpty) {
        throw const VendorFailure('Enter your salon name and address.');
      }
      String? uploadedAvatar = event.avatar;
      if (event.avatarBytes != null && event.avatarBytes!.isNotEmpty) {
        try {
          uploadedAvatar = await backend.uploadImage(event.avatarBytes!);
        } catch (e) {
          debugPrint('Avatar upload note: $e');
        }
      }
      next = state.copy(
        name: event.name.trim(),
        email: event.email.trim().isEmpty ? state.email : event.email.trim(),
        address: event.address.trim(),
        latitude: event.latitude,
        longitude: event.longitude,
        clearCoordinates:
            event.latitude == null && event.address.trim() != state.address,
        phone: event.phone ?? state.phone,
        bio: event.bio ?? state.bio,
        gender: event.gender ?? state.gender,
        isPublic: event.isPublic ?? state.isPublic,
        avatar: event.clearAvatar
            ? ''
            : (uploadedAvatar ?? event.avatar ?? state.avatar),
        avatarBytes: event.clearAvatar
            ? null
            : (event.avatarBytes ?? state.avatarBytes),
        clearAvatar: event.clearAvatar,
        clearAvatarBytes: event.clearAvatar,
      );
    } else if (event is SaveService) {
      final service = event.service;
      if (service.name.trim().isEmpty ||
          !service.price.isFinite ||
          service.price <= 0 ||
          service.duration <= 0) {
        throw const VendorFailure(
          'Enter a valid service name, price and duration.',
        );
      }
      final image = service.bytes == null
          ? service.image
          : await backend.uploadImage(service.bytes!);
      final saved = SalonService(
        id: service.id,
        name: service.name,
        price: service.price,
        duration: service.duration,
        description: service.description,
        image: image,
        enabled: service.enabled,
      );
      next = state.copy(
        services: [...state.services.where((s) => s.id != saved.id), saved],
      );
    } else if (event is SetServiceEnabled) {
      next = state.copy(
        services: state.services
            .map((s) => s.id == event.id ? s.withEnabled(event.enabled) : s)
            .toList(),
      );
    } else if (event is DeleteService) {
      next = state.copy(
        services: state.services.where((s) => s.id != event.id).toList(),
      );
    } else if (event is SaveAvailability) {
      _validateAvailability(event);
      next = state.copy(
        dates: [...event.dates.toSet()]..sort(),
        slots: event.slots.toSet().toList()
          ..sort(
            (a, b) => availabilityMinutes(a).compareTo(availabilityMinutes(b)),
          ),
      );
    } else if (event is AddAlbum) {
      final name = event.name.trim();
      if (name.isEmpty) throw const VendorFailure('Enter an album name.');
      next = state.copy(albums: {...state.albums, name}.toList());
    } else if (event is AddStyle) {
      final item = event.style;
      final image = item.bytes == null
          ? item.image
          : await backend.uploadImage(item.bytes!);
      next = state.copy(
        styles: [
          ...state.styles,
          StyleItem(item.name, item.description, image, null, item.category),
        ],
      );
    } else if (event is DeleteStyle) {
      next = state.copy(
        styles: state.styles.where((s) => s.name != event.style.name).toList(),
      );
    } else if (event is AddPhoto) {
      final item = event.photo;
      if (!state.albums.contains(item.album) ||
          item.bytes == null ||
          item.bytes!.isEmpty) {
        throw const VendorFailure(
          'Select an album and a photo before uploading.',
        );
      }
      final image = item.bytes == null
          ? item.image
          : await backend.uploadImage(item.bytes!);
      next = state.copy(
        gallery: [...state.gallery, GalleryItem(item.album, image)],
      );
    } else if (event is UpdateAppointment) {
      await backend.updateAppointment(event.appointment);
      emit((await backend.load()).copy(notice: 'Appointment updated'));
      return;
    } else if (event is SendMessage) {
      if (event.text.trim().isEmpty) {
        throw const VendorFailure('Enter a message.');
      }
      await backend.sendMessage(event.id, event.text);
      emit(await backend.load());
      return;
    } else if (event is MarkVendorNotificationRead) {
      await backend.markNotificationRead(event.id);
      emit(await backend.load());
      return;
    } else {
      throw const VendorFailure(
        'This action is not available for vendor accounts.',
      );
    }
    emit(
      (await backend.saveWorkspace(next)).copy(saving: false, notice: 'Saved'),
    );
  }

  Salon salonFor(String id) {
    if (liveVendor && state.isVendor && id == state.salonId) {
      return Salon(id, state.name, 'salon', state.address, 0, 0);
    }
    for (final listing in state.customerListings) {
      if (listing.salon.id == id) return listing.salon;
    }
    return repository.salons.firstWhere((salon) => salon.id == id);
  }

  final SalonRepository repository;
  List<SalonService> servicesFor(String salonId) {
    if (liveCustomer) {
      for (final listing in state.customerListings) {
        if (listing.salon.id == salonId) return listing.services;
      }
      return const [];
    }
    return (salonId == state.salonId
            ? state.services
            : repository.initialServices)
        .where((service) => service.enabled)
        .toList();
  }

  List<String> datesFor(String salonId) {
    if (liveCustomer) {
      return (state.customerSalonDetails[salonId]?.availability.keys.toList() ??
            <String>[])
        ..sort();
    }
    return salonId == state.salonId ? state.dates : repository.initialDates;
  }

  List<String> slotsFor(String salonId, {String? date}) {
    if (liveCustomer) {
      final availability = state.customerSalonDetails[salonId]?.availability;
      if (date != null) return availability?[date] ?? const [];
      return availability?.values.expand((slots) => slots).toSet().toList() ??
          const [];
    }
    return salonId == state.salonId ? state.slots : const AppState().slots;
  }
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

void _validateAvailability(SaveAvailability event) {
  for (final date in event.dates) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null || parsed.toIso8601String().substring(0, 10) != date) {
      throw const VendorFailure('Choose valid availability dates.');
    }
  }
  if (event.slots.any((slot) => availabilityMinutes(slot) < 0)) {
    throw const VendorFailure('Choose valid start times.');
  }
  if (event.dates.isNotEmpty && event.slots.isEmpty) {
    throw const VendorFailure(
      'Add at least one start time for your selected dates.',
    );
  }
}
