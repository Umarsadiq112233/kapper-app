import 'dart:typed_data';

enum AccountRole { customer, vendor }

enum BookingStatus { upcoming, completed, cancelled }

class Salon {
  const Salon(
    this.id,
    this.name,
    this.image,
    this.address,
    this.distance,
    this.rating,
  );
  final String id, name, image, address;
  final double distance, rating;
}

class SalonService {
  const SalonService({
    required this.id,
    required this.name,
    required this.price,
    this.duration = 45,
    this.description = 'A little care. A fresh new you.',
    this.image = 'hair',
    this.bytes,
  });
  final String id, name, description, image;
  final double price;
  final int duration;
  final Uint8List? bytes;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.salonId,
    required this.service,
    required this.date,
    required this.time,
    required this.customer,
    this.status = BookingStatus.upcoming,
    this.reviewed = false,
  });
  final String id, salonId, date, time, customer;
  final SalonService service;
  final BookingStatus status;
  final bool reviewed;
  Appointment copy({
    BookingStatus? status,
    String? date,
    String? time,
    bool? reviewed,
  }) => Appointment(
    id: id,
    salonId: salonId,
    service: service,
    date: date ?? this.date,
    time: time ?? this.time,
    customer: customer,
    status: status ?? this.status,
    reviewed: reviewed ?? this.reviewed,
  );
}

class StyleItem {
  const StyleItem(this.name, this.description, this.image, [this.bytes]);
  final String name, description, image;
  final Uint8List? bytes;
}

class GalleryItem {
  const GalleryItem(this.album, this.image, [this.bytes]);
  final String album, image;
  final Uint8List? bytes;
}

class ChatMessage {
  const ChatMessage(this.text, this.sender);
  final String text;
  final AccountRole sender;
}

class SalonReview {
  const SalonReview(this.salonId, this.author, this.text, this.stars);
  final String salonId, author, text;
  final int stars;
}

abstract class SalonRepository {
  List<Salon> get salons;
  List<SalonService> get initialServices;
  List<Appointment> get initialAppointments;
  List<String> get initialDates;
}
