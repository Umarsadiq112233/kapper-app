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
      final selectedTab = view.get('tab', 0).clamp(0, 2);
      final roleAppointments =
          bloc.state.appointments
              .where(
                (a) => !bloc.state.isVendor || a.salonId == bloc.state.salonId,
              )
              .toList()
            ..sort((a, b) {
              final dateOrder = a.date.compareTo(b.date);
              return dateOrder == 0
                  ? availabilityMinutes(a.time)
                        .compareTo(availabilityMinutes(b.time))
                  : dateOrder;
            });
      final counts = <BookingStatus, int>{
        for (final status in BookingStatus.values)
          status: roleAppointments.where((a) => a.status == status).length,
      };
      final status = BookingStatus.values[selectedTab];
      final bookings = roleAppointments
          .where((a) => a.status == status)
          .toList();
      return Screen(
        title: bloc.state.isVendor ? 'Appointments' : 'My Bookings',
        showAppBar: false,
        onRefresh: () => bloc.refreshAll(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            18,
            MediaQuery.paddingOf(context).top + 16,
            18,
            28,
          ),
          children: [
            _AppointmentsHeader(isVendor: bloc.state.isVendor),
            const SizedBox(height: 22),
            _AppointmentTabs(
              selected: selectedTab,
              counts: counts,
              onSelect: (i) => change(context, 'tab', i),
            ),
            const SizedBox(height: 22),
            if (bookings.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 90),
                child: EmptyState(
                  'No appointments here yet.',
                  icon: Icons.calendar_month_outlined,
                ),
              )
            else
              ...bookings.map(
                (appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _DetailedAppointmentCard(
                    appointment: appointment,
                    salon: bloc.salonFor(appointment.salonId),
                    isVendor: bloc.state.isVendor,
                    onChat: () => Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: appointment.id,
                    ),
                    onReschedule: () => modal(
                      context,
                      RescheduleDialog(appointment: appointment),
                    ),
                    onCancel: () async {
                      if (await confirm(
                            context,
                            'Do you want to cancel this appointment?',
                          ) &&
                          context.mounted) {
                        bloc.add(
                          UpdateAppointment(
                            appointment.copy(status: BookingStatus.cancelled),
                          ),
                        );
                      }
                    },
                    onComplete: () => bloc.add(
                      UpdateAppointment(
                        appointment.copy(status: BookingStatus.completed),
                      ),
                    ),
                    onReview: appointment.reviewed
                        ? null
                        : () => modal(
                            context,
                            ReviewDialog(appointment: appointment),
                          ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _AppointmentsHeader extends StatelessWidget {
  const _AppointmentsHeader({required this.isVendor});
  final bool isVendor;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: isVendor
                    ? const [TextSpan(text: 'Appointments')]
                    : const [
                        TextSpan(text: 'My '),
                        TextSpan(
                          text: 'Bookings',
                          style: TextStyle(color: Palette.orchid),
                        ),
                      ],
              ),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isVendor
                  ? 'All your appointments in one place'
                  : 'Manage all your salon appointments',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Palette.purple.withValues(alpha: .28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Palette.purple.withValues(alpha: .4)),
        ),
        child: const Icon(
          Icons.calendar_month_outlined,
          color: Palette.orchid,
          size: 27,
        ),
      ),
    ],
  );
}

class _AppointmentTabs extends StatelessWidget {
  const _AppointmentTabs({
    required this.selected,
    required this.counts,
    required this.onSelect,
  });
  final int selected;
  final Map<BookingStatus, int> counts;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const labels = ['Upcoming', 'Completed', 'Cancelled'];
    const icons = [
      Icons.access_time_rounded,
      Icons.check_circle_outline_rounded,
      Icons.cancel_outlined,
    ];
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .5)),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = selected == i;
          final count = counts[BookingStatus.values[i]] ?? 0;
          return Expanded(
            child: Semantics(
              selected: isSelected,
              button: true,
              label: '${labels[i]}, $count appointments',
              child: Padding(
                padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Palette.purple, Palette.orchid],
                            )
                          : null,
                      color: isSelected ? null : colors.surface,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icons[i],
                              size: 20,
                              color: isSelected
                                  ? Colors.white
                                  : colors.onSurfaceVariant,
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF4A159B)
                                      : Palette.purple.withValues(alpha: .3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : colors.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DetailedAppointmentCard extends StatelessWidget {
  const _DetailedAppointmentCard({
    required this.appointment,
    required this.salon,
    required this.isVendor,
    required this.onChat,
    required this.onReschedule,
    required this.onCancel,
    required this.onComplete,
    required this.onReview,
  });
  final Appointment appointment;
  final Salon salon;
  final bool isVendor;
  final VoidCallback onChat, onReschedule, onComplete;
  final Future<void> Function() onCancel;
  final VoidCallback? onReview;

  Color get accent => switch (appointment.status) {
    BookingStatus.upcoming => Palette.green,
    BookingStatus.completed => Palette.orchid,
    BookingStatus.cancelled => Palette.pink,
  };

  String get statusLabel => switch (appointment.status) {
    BookingStatus.upcoming => 'Confirmed',
    BookingStatus.completed => 'Completed',
    BookingStatus.cancelled => 'Cancelled',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF20182F), Color(0xFF121B2B)]
              : [colors.surface, const Color(0xFFF4EEFA)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: .35)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(4, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Container(
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: accent, width: 3)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatar(),
                  const SizedBox(width: 12),
                  Expanded(child: _identity(context)),
                ],
              ),
              const SizedBox(height: 14),
              _AppointmentDatePill(
                date: appointment.date,
                time: appointment.time,
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0x222D3B62), height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _AppointmentInfoCell(
                      icon: Icons.content_cut_rounded,
                      label: 'Service',
                      value: appointment.service.name,
                    ),
                  ),
                  _verticalDivider(),
                  Expanded(
                    child: _AppointmentInfoCell(
                      icon: Icons.access_time_rounded,
                      label: 'Duration',
                      value: '${appointment.service.duration} min',
                    ),
                  ),
                  _verticalDivider(),
                  Expanded(
                    child: _AppointmentInfoCell(
                      icon: Icons.credit_card_rounded,
                      label: 'Price',
                      value:
                          '\$${appointment.service.price.toStringAsFixed(0)}',
                    ),
                  ),
                ],
              ),
              if (!isVendor && salon.address.trim().isNotEmpty) ...[
                const SizedBox(height: 13),
                const Divider(color: Color(0x222D3B62), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Palette.lavender,
                      size: 21,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        salon.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC6C0D6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (appointment.status == BookingStatus.cancelled)
                _AppointmentCallout()
              else if (appointment.status == BookingStatus.completed)
                _CompletedActions(
                  onChat: onChat,
                  onReview: onReview,
                  reviewed: appointment.reviewed,
                )
              else
                _UpcomingActions(
                  isVendor: isVendor,
                  onChat: onChat,
                  onReschedule: onReschedule,
                  onCancel: onCancel,
                  onComplete: onComplete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _verticalDivider() => Container(
    width: 1,
    height: 42,
    color: const Color(0x222D3B62),
    margin: const EdgeInsets.symmetric(horizontal: 7),
  );

  Widget _avatar() => isVendor
      ? ProfileAvatar(
          avatar: appointment.customerAvatar,
          isVendor: false,
          size: 64,
          radius: 14,
          borderWidth: 0,
        )
      : Photo(salon.image, width: 64, height: 64, radius: 14);

  Widget _identity(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _AppointmentStatusBadge(label: statusLabel, color: accent),
      const SizedBox(height: 8),
      Text(
        isVendor ? appointment.customer : salon.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      if (!isVendor && salon.rating > 0)
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Palette.gold, size: 17),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '${salon.rating.toStringAsFixed(1)}${salon.reviewCount > 0 ? ' (${salon.reviewCount} reviews)' : ''}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        )
      else
        Text(
          appointment.service.name,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
    ],
  );
}

class _AppointmentStatusBadge extends StatelessWidget {
  const _AppointmentStatusBadge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: .22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          label == 'Cancelled'
              ? Icons.cancel_rounded
              : label == 'Completed'
              ? Icons.check_circle_rounded
              : Icons.check_circle_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _AppointmentDatePill extends StatelessWidget {
  const _AppointmentDatePill({required this.date, required this.time});
  final String date, time;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: Palette.purple.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: Palette.purple.withValues(alpha: .20)),
    ),
    child: Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: Palette.orchid,
              size: 18,
            ),
            const SizedBox(width: 7),
            Text(
              dateLabel(date),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, color: Palette.orchid, size: 18),
            const SizedBox(width: 7),
            Text(
              time,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AppointmentInfoCell extends StatelessWidget {
  const _AppointmentInfoCell({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(icon, color: Palette.orchid, size: 20),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _AppointmentCallout extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Palette.pink.withValues(alpha: .08),
      border: Border.all(color: Palette.pink.withValues(alpha: .18)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Palette.pink,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, color: Palette.ink, size: 22),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This appointment was cancelled',
                style: TextStyle(
                  color: Palette.pink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'If you have any questions, please contact the salon.',
                style: TextStyle(color: Color(0xFFC6C0D6), fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _UpcomingActions extends StatelessWidget {
  const _UpcomingActions({
    required this.isVendor,
    required this.onChat,
    required this.onReschedule,
    required this.onCancel,
    required this.onComplete,
  });
  final bool isVendor;
  final VoidCallback onChat, onReschedule, onComplete;
  final Future<void> Function() onCancel;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _AppointmentActionGroup(
        children: [
          _AppointmentActionButton(
            label: isVendor ? 'Mark completed' : 'Reschedule',
            icon: isVendor
                ? Icons.check_circle_outline_rounded
                : Icons.calendar_month_outlined,
            outlined: true,
            color: isVendor ? Palette.green : Palette.orchid,
            onTap: isVendor ? onComplete : onReschedule,
          ),
          _AppointmentActionButton(
            label: 'View Details',
            icon: Icons.arrow_forward_rounded,
            onTap: onChat,
          ),
        ],
      ),
      const SizedBox(height: 6),
      TextButton.icon(
        onPressed: onCancel,
        icon: const Icon(Icons.cancel_outlined, size: 17),
        label: Text(isVendor ? 'Cancel appointment' : 'Cancel booking'),
        style: TextButton.styleFrom(foregroundColor: Palette.pink),
      ),
    ],
  );
}

class _CompletedActions extends StatelessWidget {
  const _CompletedActions({
    required this.onChat,
    required this.onReview,
    required this.reviewed,
  });
  final VoidCallback onChat;
  final VoidCallback? onReview;
  final bool reviewed;
  @override
  Widget build(BuildContext context) => _AppointmentActionGroup(
    children: [
      _AppointmentActionButton(
        label: reviewed ? 'Review submitted' : 'Leave a review',
        icon: reviewed ? Icons.check_rounded : Icons.star_outline_rounded,
        outlined: true,
        color: Palette.gold,
        onTap: onReview,
      ),
      _AppointmentActionButton(
        label: 'View Details',
        icon: Icons.arrow_forward_rounded,
        onTap: onChat,
      ),
    ],
  );
}

class _AppointmentActionGroup extends StatelessWidget {
  const _AppointmentActionGroup({required this.children});
  final List<_AppointmentActionButton> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      var requiredWidth = 0.0;
      for (final button in children) {
        final painter = TextPainter(
          text: TextSpan(
            text: button.label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
        )..layout();
        requiredWidth = requiredWidth < painter.width + 60
            ? painter.width + 60
            : requiredWidth;
        painter.dispose();
      }
      final fits = (constraints.maxWidth - 10) / 2 >= requiredWidth;
      if (!fits) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              children[i],
            ],
          ],
        );
      }
      return Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: children[i]),
          ],
        ],
      );
    },
  );
}

class _AppointmentActionButton extends StatelessWidget {
  const _AppointmentActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
    this.color = Palette.purple,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool outlined;
  final Color color;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: outlined
        ? OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label, textAlign: TextAlign.center),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              textStyle: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label, textAlign: TextAlign.center),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Palette.purple,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              textStyle: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
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
