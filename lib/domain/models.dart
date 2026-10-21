import 'dart:typed_data';

import 'package:flutter/material.dart';

enum AccountRole { customer, vendor }

enum BookingStatus { upcoming, completed, cancelled }

class ServiceCategoryDef {
  const ServiceCategoryDef({
    required this.id,
    required this.label,
    required this.icon,
  });
  final String id;
  final String label;
  final IconData icon;
}

class StandardCategories {
  static const haircut = 'haircut';
  static const beard = 'beard';
  static const hairColor = 'hair_color';
  static const facial = 'facial';
  static const makeup = 'makeup';
  static const more = 'more';

  static const all = <ServiceCategoryDef>[
    ServiceCategoryDef(id: haircut, label: 'Haircut', icon: Icons.content_cut),
    ServiceCategoryDef(
      id: beard,
      label: 'Beard',
      icon: Icons.face_retouching_natural,
    ),
    ServiceCategoryDef(
      id: hairColor,
      label: 'Hair color',
      icon: Icons.palette_outlined,
    ),
    ServiceCategoryDef(id: facial, label: 'Facial', icon: Icons.spa_outlined),
    ServiceCategoryDef(
      id: makeup,
      label: 'Makeup',
      icon: Icons.auto_awesome_outlined,
    ),
    ServiceCategoryDef(id: more, label: 'More', icon: Icons.more_horiz),
  ];

  static ServiceCategoryDef find(String? idOrLabel) {
    if (idOrLabel == null || idOrLabel.trim().isEmpty) {
      return all.last; // more
    }
    final clean = idOrLabel.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '',
    );
    return all.firstWhere(
      (c) =>
          c.id.replaceAll('_', '') == clean ||
          c.label.toLowerCase().replaceAll(' ', '') == clean,
      orElse: () => all.last, // more
    );
  }
}

String inferServiceCategory(String name, [String? explicitCategory]) {
  if (explicitCategory != null && explicitCategory.trim().isNotEmpty) {
    final clean = explicitCategory.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '',
    );
    for (final cat in StandardCategories.all) {
      if (cat.id.replaceAll('_', '') == clean ||
          cat.label.toLowerCase().replaceAll(' ', '') == clean) {
        if (cat.id != StandardCategories.more) return cat.id;
      }
    }
  }
  final lower = name.toLowerCase();
  // Haircut primary indicators (fade, buzz, taper, scissor cut, haircut)
  if (lower.contains('haircut') ||
      lower.contains('hair cut') ||
      lower.contains('fade') ||
      lower.contains('buzz') ||
      lower.contains('taper') ||
      lower.contains('scissor') ||
      lower.contains('crew cut') ||
      lower.contains('undercut')) {
    return StandardCategories.haircut;
  }
  // Beard primary indicators
  if (lower.contains('beard') ||
      lower.contains('shave') ||
      lower.contains('mustache') ||
      lower.contains('moustache') ||
      lower.contains('darhi') ||
      lower.contains('khat') ||
      lower.contains('goatee')) {
    return StandardCategories.beard;
  }
  // Color primary indicators
  if (lower.contains('color') ||
      lower.contains('colour') ||
      lower.contains('dye') ||
      lower.contains('highlight') ||
      lower.contains('bleach') ||
      lower.contains('tint') ||
      lower.contains('balayage') ||
      lower.contains('streak') ||
      lower.contains('blonde')) {
    return StandardCategories.hairColor;
  }
  // Makeup indicators
  if (lower.contains('makeup') ||
      lower.contains('make up') ||
      lower.contains('make-up') ||
      lower.contains('bridal') ||
      lower.contains('glam') ||
      lower.contains('cosmetic') ||
      lower.contains('lash') ||
      lower.contains('mehendi') ||
      lower.contains('eyebrow')) {
    return StandardCategories.makeup;
  }
  // Facial indicators
  if (lower.contains('facial') ||
      lower.contains('clean') ||
      lower.contains('glow') ||
      lower.contains('scrub') ||
      lower.contains('hydra') ||
      lower.contains('mask') ||
      lower.contains('peel') ||
      lower.contains('skin')) {
    return StandardCategories.facial;
  }
  // Generic hair
  if (lower.contains('hair') ||
      lower.contains('cut') ||
      lower.contains('trim') ||
      lower.contains('wash') ||
      lower.contains('blowdry') ||
      lower.contains('styling')) {
    return StandardCategories.haircut;
  }
  return StandardCategories.more;
}

bool serviceMatchesCategory(SalonService service, String categoryId) {
  if (categoryId.isEmpty ||
      categoryId == 'all' ||
      categoryId == 'Any' ||
      categoryId == 'All') {
    return true;
  }
  final targetCat = StandardCategories.find(categoryId).id;
  final serviceExplicit = StandardCategories.find(service.category).id;
  if (serviceExplicit != StandardCategories.more &&
      serviceExplicit == targetCat) {
    return true;
  }
  final inferred = inferServiceCategory(service.name);
  return inferred == targetCat;
}

class Salon {
  const Salon(
    this.id,
    this.name,
    this.image,
    this.address,
    this.distance,
    this.rating, [
    this.reviewCount = 0,
    this.latitude,
    this.longitude,
  ]);
  final String id, name, image, address;
  final double distance, rating;
  final int reviewCount;
  final double? latitude, longitude;
}

class SalonService {
  const SalonService({
    required this.id,
    required this.name,
    required this.price,
    this.category = StandardCategories.haircut,
    this.duration = 45,
    this.description = 'A little care. A fresh new you.',
    this.image = 'hair',
    this.enabled = true,
    this.bytes,
  });
  final bool enabled;
  SalonService withEnabled(bool value) => SalonService(
    id: id,
    name: name,
    price: price,
    category: category,
    duration: duration,
    description: description,
    image: image,
    bytes: bytes,
    enabled: value,
  );
  final String id, name, category, description, image;
  final double price;
  final int duration;
  final Uint8List? bytes;
}

class SalonListing {
  const SalonListing({required this.salon, required this.services});
  final Salon salon;
  final List<SalonService> services;
}

class PublicSalonDetails {
  const PublicSalonDetails({
    this.about = '',
    this.availability = const {},
    this.gallery = const [],
    this.styles = const [],
    this.reviews = const [],
  });
  final String about;
  final Map<String, List<String>> availability;
  final List<GalleryItem> gallery;
  final List<StyleItem> styles;
  final List<SalonReview> reviews;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.salonId,
    required this.service,
    required this.date,
    required this.time,
    required this.customer,
    this.customerId,
    this.customerAvatar,
    this.status = BookingStatus.upcoming,
    this.reviewed = false,
  });
  final String id, salonId, date, time, customer;

  /// Stable auth id used to merge multiple bookings into one conversation.
  final String? customerId;

  /// Avatar saved with the booking so the vendor can display the customer
  /// without querying the customer's private profile row.
  final String? customerAvatar;
  final SalonService service;
  final BookingStatus status;
  final bool reviewed;
  Appointment copy({
    BookingStatus? status,
    String? date,
    String? time,
    bool? reviewed,
    String? customerId,
    String? customerAvatar,
  }) => Appointment(
    id: id,
    salonId: salonId,
    service: service,
    date: date ?? this.date,
    time: time ?? this.time,
    customer: customer,
    customerId: customerId ?? this.customerId,
    customerAvatar: customerAvatar ?? this.customerAvatar,
    status: status ?? this.status,
    reviewed: reviewed ?? this.reviewed,
  );
}

class StyleItem {
  const StyleItem(
    this.name,
    this.description,
    this.image, [
    this.bytes,
    this.category,
  ]);
  final String name, description, image;
  final Uint8List? bytes;
  final String? category;

  String get effectiveCategory {
    if (category != null && category!.trim().isNotEmpty) return category!;
    final lower = '$name $description'.toLowerCase();
    if (lower.contains('beard') || lower.contains('shave')) return 'Beard';
    if (lower.contains('cut') ||
        lower.contains('hair') ||
        lower.contains('fade')) {
      return 'Haircuts';
    }
    return 'Styling';
  }
}

class GalleryItem {
  const GalleryItem(this.album, this.image, [this.bytes]);
  final String album, image;
  final Uint8List? bytes;
}

class ChatMessage {
  const ChatMessage(
    this.text,
    this.sender, {
    this.createdAt,
    this.readAt,
    this.id = '',
  });
  final String text;
  final String id;
  final AccountRole sender;
  final DateTime? createdAt;
  final DateTime? readAt;
}

class SalonReview {
  const SalonReview(this.salonId, this.author, this.text, this.stars);
  final String salonId, author, text;
  final int stars;
}

class VendorNotification {
  const VendorNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.appointmentId,
    this.readAt,
  });
  final String id, kind, title, body;
  final DateTime createdAt;
  final String? appointmentId;
  final DateTime? readAt;
  bool get isRead => readAt != null;
  VendorNotification markRead([DateTime? time]) => VendorNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    createdAt: createdAt,
    appointmentId: appointmentId,
    readAt: time ?? DateTime.now(),
  );
}

abstract class SalonRepository {
  List<Salon> get salons;
  List<SalonService> get initialServices;
  List<Appointment> get initialAppointments;
  List<String> get initialDates;
}

/// Converts the persisted 12-hour slot label to minutes for chronological order.
int availabilityMinutes(String label) {
  final match = RegExp(r'^(0[1-9]|1[0-2]):([0-5][0-9]) (AM|PM)$')
      .firstMatch(label);
  if (match == null) return -1;
  return (int.parse(match[1]!) % 12 + (match[3] == 'PM' ? 12 : 0)) * 60 +
      int.parse(match[2]!);
}
