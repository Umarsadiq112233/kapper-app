import '../domain/models.dart';

/// In-memory fixtures only. No authentication, payment or network service.
class MockSalonRepository implements SalonRepository {
  @override
  final salons = const [
    Salon(
      'danial',
      'Danial Willam',
      'barber',
      '250 William St, New York',
      1.2,
      4.8,
    ),
    Salon('mk', 'M&K Saloon', 'salon', '28 Madison Avenue, New York', 2.4, 4.9),
    Salon(
      'skin',
      'Skin Care Beauty',
      'beauty',
      '68 Spring Street, New York',
      3.1,
      4.7,
    ),
    Salon(
      'refinery',
      'The Refinery',
      'tools',
      '120 Broadway, New York',
      4.2,
      4.8,
    ),
    Salon('nail', 'Nail Knight', 'bride', '42 Park Avenue, New York', 2.8, 4.6),
    Salon(
      'velvet',
      'Velvet Touch',
      'hair',
      '16 Elizabeth Street, New York',
      5.0,
      4.9,
    ),
    Salon(
      'obsessed',
      'Obsessed',
      'woman',
      '74 Fifth Avenue, New York',
      3.5,
      4.8,
    ),
    Salon(
      'studio',
      'The Style Studio',
      'salon',
      '90 West Street, New York',
      6.1,
      4.7,
    ),
  ];
  @override
  final initialServices = const [
    SalonService(id: 'cut', name: 'Hair Cutting', price: 50, duration: 45),
    SalonService(
      id: 'facial',
      name: 'Hydra Facial',
      price: 65,
      duration: 60,
      image: 'beauty',
    ),
    SalonService(
      id: 'manicure',
      name: 'Manicure',
      price: 35,
      duration: 30,
      image: 'bride',
    ),
  ];
  @override
  List<String> get initialDates => List.generate(
    12,
    (i) => DateTime.now()
        .add(Duration(days: i))
        .toIso8601String()
        .substring(0, 10),
  );
  @override
  List<Appointment> get initialAppointments => [
    Appointment(
      id: 'sample-1',
      salonId: 'mk',
      service: initialServices.first,
      date: initialDates[1],
      time: '10:30 AM',
      customer: 'Josh Jakarta',
    ),
    Appointment(
      id: 'sample-2',
      salonId: 'danial',
      service: initialServices[1],
      date: initialDates.first,
      time: '09:00 AM',
      customer: 'Elizabt Olin',
      status: BookingStatus.completed,
    ),
    Appointment(
      id: 'sample-3',
      salonId: 'skin',
      service: initialServices.first,
      date: initialDates.first,
      time: '05:00 PM',
      customer: 'Shinore Akram',
      status: BookingStatus.cancelled,
    ),
  ];
}
