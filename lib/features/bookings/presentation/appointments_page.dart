import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/app_bloc.dart';
import '../../../domain/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared.dart';
import 'booking_dialogs.dart';

export 'chat_pages.dart' show InboxPage, ChatPage;

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});
  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, view) {
      final bloc = context.watch<AppBloc>();
      final status = BookingStatus.values[view.get('tab', 0)];
      final bookings = bloc.state.appointments
          .where(
            (a) =>
                a.status == status &&
                (!bloc.state.isVendor || a.salonId == bloc.state.salonId),
          )
          .toList();
      return Screen(
        title: bloc.state.isVendor ? 'Appointments' : 'Bookings',
        subtitle: 'All of your appointments are here',
        onRefresh: () => bloc.refreshAll(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Segments(
                const ['Upcoming', 'Completed', 'Cancelled'],
                view.get('tab', 0),
                (i) => change(context, 'tab', i),
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: bookings.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        EmptyState(
                          'No appointments here yet.',
                          icon: Icons.calendar_month_outlined,
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 4,
                      ),
                      itemCount: bookings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (_, i) {
                        final a = bookings[i];
                        final salon = bloc.salonFor(a.salonId);
                        final color = [
                          Palette.purple,
                          Palette.green,
                          Palette.pink,
                        ][a.status.index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 62,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  a.time,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: color, width: 3),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Surface(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          bloc.state.isVendor
                                              ? ProfileAvatar(
                                                  avatar: a.customerAvatar,
                                                  isVendor: false,
                                                  size: 42,
                                                  radius: 6,
                                                  borderWidth: 0,
                                                )
                                              : Photo(
                                                  salon.image,
                                                  width: 42,
                                                  height: 42,
                                                  radius: 6,
                                                ),
                                          const SizedBox(width: 9),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  bloc.state.isVendor
                                                      ? a.customer
                                                      : salon.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
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
                                          Icon(
                                            Icons.circle,
                                            color: color,
                                            size: 8,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Services: ${a.service.name}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Price: \$${a.service.price.toStringAsFixed(0)} · ${a.service.duration} min',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Palette.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (a.status == BookingStatus.upcoming)
                                        Wrap(
                                          spacing: 4,
                                          children: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/chat',
                                                    arguments: a.id,
                                                  ),
                                              child: const Text(
                                                'Tap to chat',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => modal(
                                                context,
                                                RescheduleDialog(
                                                  appointment: a,
                                                ),
                                              ),
                                              child: const Text(
                                                'Reschedule',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                if (await confirm(
                                                      context,
                                                      'Do you want to cancel this appointment?',
                                                    ) &&
                                                    context.mounted) {
                                                  bloc.add(
                                                    UpdateAppointment(
                                                      a.copy(
                                                        status: BookingStatus
                                                            .cancelled,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Palette.pink,
                                                ),
                                              ),
                                            ),
                                            if (bloc.state.isVendor)
                                              TextButton(
                                                onPressed: () => bloc.add(
                                                  UpdateAppointment(
                                                    a.copy(
                                                      status: BookingStatus
                                                          .completed,
                                                    ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Mark completed',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Palette.green,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      if (a.status == BookingStatus.completed &&
                                          !bloc.state.isVendor)
                                        TextButton(
                                          onPressed: a.reviewed
                                              ? null
                                              : () => modal(
                                                  context,
                                                  ReviewDialog(appointment: a),
                                                ),
                                          child: Text(
                                            a.reviewed
                                                ? 'Review submitted'
                                                : 'Leave a review',
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      if (a.status == BookingStatus.cancelled)
                                        const Text(
                                          'Cancelled',
                                          style: TextStyle(
                                            color: Palette.pink,
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );
}

class RescheduleDialog extends StatelessWidget {
  const RescheduleDialog({super.key, required this.appointment});
  final Appointment appointment;
  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, view) {
      final bloc = context.watch<AppBloc>();
      final date = view.get(
        'date',
        bloc.datesFor(appointment.salonId).firstOrNull ?? '',
      );
      final slots = bloc
          .slotsFor(appointment.salonId)
          .where(
            (t) => !bloc.state.appointments.any(
              (a) =>
                  a.id != appointment.id &&
                  a.salonId == appointment.salonId &&
                  a.date == date &&
                  a.time == t &&
                  a.status == BookingStatus.upcoming,
            ),
          )
          .toList();
      return Column(
        children: [
          const Text('Reschedule Appointment', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 22),
          DropdownButtonFormField<String>(
            initialValue: date.isEmpty ? null : date,
            items: bloc
                .datesFor(appointment.salonId)
                .map(
                  (d) => DropdownMenuItem(value: d, child: Text(dateLabel(d))),
                )
                .toList(),
            onChanged: (v) {
              change(context, 'date', v);
              change(context, 'time', '');
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            children: slots
                .map(
                  (t) => ChoiceChip(
                    label: Text(t, style: const TextStyle(fontSize: 11)),
                    selected: view.get('time', '') == t,
                    onSelected: (_) => change(context, 'time', t),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
          AppButton(
            'Save',
            onTap: view.get('time', '').isEmpty
                ? null
                : () async {
                    final next = bloc.stream.firstWhere(
                      (state) => !state.saving,
                    );
                    bloc.add(
                      UpdateAppointment(
                        appointment.copy(
                          date: date,
                          time: view.get('time', ''),
                        ),
                      ),
                    );
                    final result = await next;
                    if (context.mounted) {
                      if (result.notice == 'Appointment updated') {
                        Navigator.pop(context);
                      } else {
                        toast(context, result.notice);
                      }
                    }
                  },
          ),
        ],
      );
    },
  );
}
