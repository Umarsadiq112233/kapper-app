import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/app_bloc.dart';
import '../../../domain/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppBloc>().state;
    final items = [
      (Icons.favorite_border, 'My Favorites', '/favorites'),
      (Icons.notifications_none, 'Notifications', '/notifications'),
      (Icons.settings_outlined, 'Settings', '/settings'),
      (Icons.payments_outlined, 'Payment', '/transactions'),
      (Icons.info_outline, 'About app', '/about'),
    ];
    return Screen(
      title: 'Profile',
      actions: [
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/profile/edit'),
          child: const Text('Edit Profile', style: TextStyle(fontSize: 10)),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Photo(
              state.isVendor ? 'barber' : 'portrait',
              height: 98,
              width: 98,
              radius: 60,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            state.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            state.isVendor ? state.address : state.email,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 28),
          ...items
              .where((i) => !state.isVendor || i.$3 != '/favorites')
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Surface(
                    onTap: () => Navigator.pushNamed(context, item.$3),
                    child: Row(
                      children: [
                        Icon(item.$1, size: 20),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            item.$2,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
          Surface(
            onTap: () async {
              if (await confirm(
                    context,
                    'Do you want to logout? You can choose another role to explore the demo.',
                  ) &&
                  context.mounted) {
                context.read<AppBloc>().add(SignOut());
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/role',
                  (_) => false,
                );
              }
            },
            child: const Row(
              children: [
                Icon(Icons.logout_rounded, color: Palette.pink, size: 20),
                SizedBox(width: 15),
                Text(
                  'Logout',
                  style: TextStyle(color: Palette.pink, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Kapper · Frontend demo 1.0',
            textAlign: TextAlign.center,
            style: TextStyle(color: Palette.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(
    text: context.read<AppBloc>().state.name,
  );
  late final email = TextEditingController(
    text: context.read<AppBloc>().state.email,
  );
  late final address = TextEditingController(
    text: context.read<AppBloc>().state.address,
  );
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Screen(
    title: 'Edit Profile',
    child: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Photo(
              context.read<AppBloc>().state.isVendor ? 'barber' : 'portrait',
              height: 90,
              width: 90,
              radius: 60,
            ),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: name,
            validator: requiredField,
            decoration: const InputDecoration(labelText: 'Change Name'),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: email,
            validator: (v) => v != null && v.contains('@') && v.contains('.')
                ? null
                : 'Enter a valid email',
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: address,
            validator: requiredField,
            decoration: const InputDecoration(labelText: 'Update address'),
          ),
          const SizedBox(height: 42),
          AppButton(
            'Save',
            onTap: () {
              if (!form.currentState!.validate()) return;
              context.read<AppBloc>().add(
                SaveProfile(
                  name.text.trim(),
                  email.text.trim(),
                  address.text.trim(),
                ),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<AppBloc>();
    final bookings = bloc.state.appointments
        .where((a) => !bloc.state.isVendor || a.salonId == 'danial')
        .toList();
    return Screen(
      title: 'Notifications',
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          if (bookings.isEmpty) const EmptyState('You’re all caught up.'),
          ...bookings.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Surface(
                onTap: () => Navigator.pushNamed(context, '/appointments'),
                child: Row(
                  children: [
                    Icon(
                      a.status == BookingStatus.cancelled
                          ? Icons.event_busy_outlined
                          : Icons.event_available_outlined,
                      color: Palette.purple,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your ${a.service.name} appointment is ${a.status.name}.',
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.chevron_right, size: 17),
                  ],
                ),
              ),
            ),
          ),
          ...bloc.state.messages.entries
              .where(
                (entry) =>
                    entry.value.isNotEmpty &&
                    entry.value.last.sender != bloc.state.role,
              )
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Surface(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: entry.key,
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 22,
                          color: Palette.purple,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You have a new message',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key, this.detail});
  final Appointment? detail;
  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<AppBloc>();
    final records = bloc.state.appointments
        .where((a) => (!bloc.state.isVendor || a.salonId == 'danial'))
        .toList();
    final total = records
        .where((a) => a.status != BookingStatus.cancelled)
        .fold(0.0, (sum, a) => sum + a.service.price);
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Entrance(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + 8,
                  20,
                  26,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Palette.orchid, Palette.purple],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -18,
                      bottom: -30,
                      child: Opacity(
                        opacity: .14,
                        child: const Brand(size: 76),
                      ),
                    ),
                    Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: BackButton(color: Colors.white),
                        ),
                        Text(
                          bloc.state.isVendor
                              ? 'Total Earning · Demo'
                              : 'Total Spent · Demo',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    Text(
                      detail == null ? 'Transactions' : 'Transaction Details',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (detail == null)
                      ...records.map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Surface(
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/transactions/detail',
                              arguments: a,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '\$${a.service.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bloc.state.isVendor
                                            ? a.customer
                                            : bloc.repository.salons
                                                  .firstWhere(
                                                    (s) => s.id == a.salonId,
                                                  )
                                                  .name,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        dateLabel(a.date),
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Palette.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: a.status == BookingStatus.cancelled
                                        ? Palette.pink
                                        : Palette.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    a.status == BookingStatus.cancelled
                                        ? 'Voided'
                                        : 'Demo paid',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...[
                        ('Payment Method', 'Demo card •••• 4242'),
                        ('Transaction ID', detail!.id),
                        (
                          bloc.state.isVendor ? 'Sender Name' : 'Receiver Name',
                          bloc.state.isVendor
                              ? detail!.customer
                              : bloc.repository.salons
                                    .firstWhere((s) => s.id == detail!.salonId)
                                    .name,
                        ),
                        (
                          'Appointment Date',
                          '${dateLabel(detail!.date)} at ${detail!.time}',
                        ),
                        (
                          'Transaction Status',
                          detail!.status == BookingStatus.cancelled
                              ? 'Voided (demo)'
                              : 'Completed (demo)',
                        ),
                        (
                          'Amount',
                          '\$${detail!.service.price.toStringAsFixed(2)}',
                        ),
                      ].map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.$1,
                                style: const TextStyle(
                                  color: Palette.muted,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                row.$2,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'Illustrative session records only. No money has moved.',
                      style: TextStyle(color: Palette.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => Screen(
    title: 'Settings',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Surface(
          onTap: () => Navigator.pushNamed(context, '/profile/edit'),
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline),
            title: Text('Account details'),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
        const SizedBox(height: 16),
        const Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Demo environment',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10),
              Text(
                'Changes are stored in memory while the app is open. Logout and choose the other role to explore shared salon data. Restarting restores the demo.',
                style: TextStyle(color: Palette.muted, height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Surface(
          onTap: () => Navigator.pushNamed(context, '/about'),
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline),
            title: Text('About Kapper'),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
      ],
    ),
  );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => const Screen(
    title: 'About Kapper',
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Brand(),
          SizedBox(height: 24),
          Text(
            'Your next great look starts here.',
            style: TextStyle(fontSize: 22),
          ),
          SizedBox(height: 20),
          Text(
            'Discover salons, plan your next appointment and explore your personal style.\n\nThis is a frontend preview with local sample data. SMS, social login, payments, cloud messaging and live camera hairstyle rendering are not connected.',
            style: TextStyle(height: 1.8, color: Palette.muted),
          ),
        ],
      ),
    ),
  );
}
