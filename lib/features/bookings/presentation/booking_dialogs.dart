import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/app_bloc.dart';
import '../../../domain/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared.dart';

class BookingDetailsDialog extends StatefulWidget {
  const BookingDetailsDialog({
    super.key,
    required this.salonId,
    required this.service,
    required this.date,
    required this.time,
  });
  final String salonId, date, time;
  final SalonService service;
  @override
  State<BookingDetailsDialog> createState() => _BookingDetailsDialogState();
}

class _BookingDetailsDialogState extends State<BookingDetailsDialog> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  @override
  void initState() {
    super.initState();
    name.text = context.read<AppBloc>().state.name;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, state) => Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter Details',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),
          Text(
            '${widget.service.name} · ${widget.time}\n${dateLabel(widget.date)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Palette.muted,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: name,
            validator: requiredField,
            decoration: const InputDecoration(hintText: 'Enter full name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(hintText: 'Select Gender'),
            items: ['Female', 'Male', 'Prefer not to say']
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, style: const TextStyle(fontSize: 12)),
                  ),
                )
                .toList(),
            onChanged: (v) => change(context, 'gender', v),
            validator: requiredField,
          ),
          const SizedBox(height: 12),
          TextFormField(
            readOnly: true,
            key: ValueKey(state.get('dob', '')),
            initialValue: state.get('dob', ''),
            decoration: const InputDecoration(
              hintText: 'Date of birth (optional)',
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 16),
            ),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
              );
              if (d != null && context.mounted) {
                change(
                  context,
                  'dob',
                  dateLabel(d.toIso8601String().substring(0, 10)),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: 'Myself',
            items: ['Myself', 'Family member', 'Friend']
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, style: const TextStyle(fontSize: 12)),
                  ),
                )
                .toList(),
            onChanged: (v) => change(context, 'relation', v),
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(hintText: 'Extra Notes (Optional)'),
          ),
          const SizedBox(height: 20),
          AppButton(
            'Verify & Proceed',
            onTap: () {
              if (!form.currentState!.validate()) return;
              final a = Appointment(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                salonId: widget.salonId,
                service: widget.service,
                date: widget.date,
                time: widget.time,
                customer: name.text.trim(),
              );
              final nav = Navigator.of(context);
              nav.pop();
              nav.pushNamed('/payment', arguments: a);
            },
          ),
        ],
      ),
    ),
  );
}

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key, required this.appointment});
  final Appointment appointment;
  @override
  Widget build(BuildContext context) {
    if (context.watch<AppBloc>().liveCustomer) {
      return _LivePayAtSalonPage(appointment: appointment);
    }
    return LocalView(
      builder: (context, view) => Screen(
        title: 'Payment Information',
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your appointment',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Text(appointment.service.name),
                  const SizedBox(height: 8),
                  Text(
                    '${dateLabel(appointment.date)} · ${appointment.time}',
                    style: const TextStyle(color: Palette.muted),
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Text('Total'),
                      const Spacer(),
                      Text(
                        '\$${appointment.service.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Your Payment Information',
                    style: TextStyle(fontSize: 17),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Palette.lavender.withValues(alpha: .3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.credit_card, color: Palette.purple),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Demo card •••• 4242\nNo charge will be made',
                            style: TextStyle(fontSize: 12, height: 1.7),
                          ),
                        ),
                        Text(
                          'VISA',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w900,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Billing Address',
                    style: TextStyle(color: Palette.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: 'Pakistan',
                    items: ['Pakistan', 'United States', 'United Kingdom']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => change(context, 'country', v),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Simulate declined payment',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: view.get('decline', false),
                    onChanged: (v) => change(context, 'decline', v),
                  ),
                  if (view.get('error', '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Text(
                        view.get('error', ''),
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  AppButton(
                    view.get('busy', false)
                        ? 'Processing…'
                        : 'Pay Now \$${appointment.service.price.toStringAsFixed(0)} · Demo',
                    onTap: view.get('busy', false)
                        ? null
                        : () async {
                            change(context, 'busy', true);
                            await Future<void>.delayed(
                              const Duration(milliseconds: 650),
                            );
                            if (!context.mounted) return;
                            if (view.get('decline', false)) {
                              change(context, 'busy', false);
                              change(
                                context,
                                'error',
                                'Demo payment declined. Please retry. No booking was created.',
                              );
                              return;
                            }
                            final bloc = context.read<AppBloc>();
                            final next = bloc.stream.first;
                            bloc.add(BookAppointment(appointment));
                            final result = await next;
                            if (!context.mounted) return;
                            if (!result.appointments.any(
                              (a) => a.id == appointment.id,
                            )) {
                              change(context, 'busy', false);
                              change(context, 'error', result.notice);
                              return;
                            }
                            Navigator.pushReplacementNamed(
                              context,
                              '/booking/confirmed',
                              arguments: appointment,
                            );
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Frontend demonstration only. No card details are collected or sent to a payment service.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePayAtSalonPage extends StatefulWidget {
  const _LivePayAtSalonPage({required this.appointment});
  final Appointment appointment;

  @override
  State<_LivePayAtSalonPage> createState() => _LivePayAtSalonPageState();
}

class _LivePayAtSalonPageState extends State<_LivePayAtSalonPage> {
  bool busy = false;
  String error = '';

  Future<void> _confirm() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = '';
    });
    final bloc = context.read<AppBloc>();
    try {
      await bloc.submit(BookAppointment(widget.appointment));
      if (!mounted) return;
      final saved = bloc.state.appointments
          .where(
            (item) =>
                item.salonId == widget.appointment.salonId &&
                item.date == widget.appointment.date &&
                item.time == widget.appointment.time,
          )
          .lastOrNull;
      if (saved == null) {
        throw StateError(
          'The appointment could not be confirmed. Please refresh and try another slot.',
        );
      }
      Navigator.pushReplacementNamed(
        context,
        '/booking/confirmed',
        arguments: saved,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Screen(
    title: 'Confirm appointment',
    child: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Surface(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Appointment summary',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Text(widget.appointment.service.name),
              const SizedBox(height: 6),
              Text(
                '${dateLabel(widget.appointment.date)} · ${widget.appointment.time}',
                style: const TextStyle(color: Palette.muted),
              ),
              const Divider(height: 26),
              Row(
                children: [
                  const Text('Service total'),
                  const Spacer(),
                  Text(
                    '\$${widget.appointment.service.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Surface(
          padding: const EdgeInsets.all(16),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.storefront_outlined, color: Palette.purple),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pay at the salon',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'No online payment provider is connected. Reserve your time now and pay the salon directly after your service.',
                      style: TextStyle(fontSize: 11, color: Palette.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (error.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(error, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        AppButton(
          busy ? 'Reserving…' : 'Confirm · Pay at salon',
          onTap: busy ? null : _confirm,
        ),
      ],
    ),
  );
}

class BookingConfirmationPage extends StatelessWidget {
  const BookingConfirmationPage({super.key, required this.appointment});
  final Appointment appointment;
  @override
  Widget build(BuildContext context) => Screen(
    title: 'Booking Confirmation',
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 52,
            backgroundColor: Palette.lavender,
            child: Icon(Icons.check_rounded, size: 60, color: Palette.purple),
          ),
          const SizedBox(height: 28),
          const Text("You're all booked!", style: TextStyle(fontSize: 27)),
          const SizedBox(height: 12),
          const Text(
            'Your next great look is on the calendar.',
            style: TextStyle(color: Palette.muted),
          ),
          const SizedBox(height: 30),
          Surface(
            child: Column(
              children: [
                Text(
                  appointment.service.name,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text('${dateLabel(appointment.date)} · ${appointment.time}'),
                const SizedBox(height: 12),
                const Text(
                  'Demo payment confirmed',
                  style: TextStyle(color: Palette.purple),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            'View Upcoming Appointments',
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (_) => false,
              arguments: 3,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (_) => false,
            ),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    ),
  );
}

class ReviewDialog extends StatefulWidget {
  const ReviewDialog({super.key, required this.appointment});
  final Appointment appointment;
  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final review = TextEditingController();
  @override
  void dispose() {
    review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, view) {
      final bloc = context.read<AppBloc>();
      final salon = bloc.salonFor(widget.appointment.salonId);
      final stars = view.get('stars', 0);
      return Column(
        children: [
          const Text(
            'How was your experience?',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            salon.name,
            style: const TextStyle(color: Palette.muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tap a star to rate your completed appointment',
            style: TextStyle(color: Palette.muted, fontSize: 11),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                tooltip: '${i + 1} stars',
                icon: Icon(
                  i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Palette.gold,
                  size: 36,
                ),
                onPressed: () => change(context, 'stars', i + 1),
              ),
            ),
          ),
          Text(
            stars == 0
                ? 'Choose a rating'
                : '$stars out of 5 · ${_ratingLabel(stars)}',
            style: TextStyle(
              color: stars == 0 ? Palette.muted : Palette.gold,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: review,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Share a few words (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            'Submit Review',
            icon: Icons.send_rounded,
            onTap: stars == 0
                ? null
                : () async {
                    final saved = await saveAction(
                      context,
                      AddReview(widget.appointment, review.text.trim(), stars),
                    );
                    if (saved && context.mounted) Navigator.pop(context);
                  },
          ),
        ],
      );
    },
  );

  String _ratingLabel(int stars) => switch (stars) {
    1 => 'Needs improvement',
    2 => 'Could be better',
    3 => 'Good',
    4 => 'Very good',
    _ => 'Excellent',
  };
}
