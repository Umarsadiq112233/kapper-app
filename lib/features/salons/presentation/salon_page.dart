import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/app_bloc.dart';
import '../../../domain/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared.dart';
import '../../bookings/presentation/booking_dialogs.dart';
import '../../vendor/presentation/vendor_pages.dart';

class SalonPage extends StatelessWidget {
  const SalonPage({super.key, this.salonId = 'danial', this.vendor = false});
  final String salonId;
  final bool vendor;
  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, view) {
      final bloc = context.watch<AppBloc>();
      final state = bloc.state;
      final services = bloc.servicesFor(salonId);
      final dates = bloc.datesFor(salonId);
      final slots = bloc.slotsFor(salonId);
      final salon = bloc.repository.salons.firstWhere((s) => s.id == salonId);
      final canEdit = vendor && state.isVendor;
      final tab = view.get('tab', 0);
      final selected = services
          .where((s) => s.id == view.get('service', ''))
          .firstOrNull;
      final date = view.get('date', dates.firstOrNull ?? '');
      final time = view.get('time', '');
      return Scaffold(
        body: Entrance(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Hero(
                      tag: 'salon-$salonId',
                      child: Photo(
                        salon.image,
                        width: double.infinity,
                        height: 278,
                        radius: 0,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: .75),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      left: 14,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withValues(alpha: .9),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            canEdit
                                ? Icons.storefront_outlined
                                : Icons.arrow_back,
                            size: 19,
                          ),
                          onPressed: () => canEdit
                              ? Navigator.pushNamed(context, '/profile')
                              : Navigator.pop(context),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 18,
                      bottom: 20,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  canEdit ? state.name : salon.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '★ ${salon.rating} (100+)  •  Professional Barber',
                                  style: const TextStyle(
                                    color: Palette.gold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!canEdit)
                            IconButton(
                              tooltip: 'Add to favorites',
                              onPressed: () =>
                                  bloc.add(ToggleFavorite(salonId)),
                              icon: Icon(
                                state.favorites.contains(salonId)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.white,
                              ),
                            ),
                          IconButton(
                            tooltip: 'Salon address',
                            onPressed: () => modal(
                              context,
                              Column(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Palette.purple,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(salon.address),
                                  const SizedBox(height: 12),
                                  Text('${salon.distance} km away'),
                                ],
                              ),
                            ),
                            icon: const Icon(
                              Icons.near_me_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Segments(
                        const ['Services', 'Portfolio', 'Reviews'],
                        tab,
                        (i) => change(context, 'tab', i),
                      ),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 250),
                        child: KeyedSubtree(
                          key: ValueKey(tab),
                          child: tab == 0
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.calendar_month_outlined,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          date.isEmpty
                                              ? 'No availability'
                                              : dateLabel(date),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Available Dates',
                                            style: TextStyle(
                                              color: Palette.muted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        if (canEdit)
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pushNamed(
                                                  context,
                                                  '/vendor/availability',
                                                ),
                                            child: const Text(
                                              'Edit Available Dates',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (dates.isEmpty)
                                      const EmptyState(
                                        'No dates available yet.',
                                      ),
                                    SizedBox(
                                      height: 62,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: dates.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(width: 9),
                                        itemBuilder: (_, i) {
                                          final d = DateTime.parse(dates[i]);
                                          return GestureDetector(
                                            onTap: () {
                                              change(context, 'date', dates[i]);
                                              change(context, 'time', '');
                                            },
                                            child: AnimatedContainer(
                                              duration:
                                                  MediaQuery.disableAnimationsOf(
                                                    context,
                                                  )
                                                  ? Duration.zero
                                                  : const Duration(
                                                      milliseconds: 200,
                                                    ),
                                              width: 45,
                                              decoration: BoxDecoration(
                                                color: date == dates[i]
                                                    ? Palette.orchid
                                                    : const Color(0xFFA6A9B3),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '${d.day}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    const [
                                                      'Mon',
                                                      'Tue',
                                                      'Wed',
                                                      'Thu',
                                                      'Fri',
                                                      'Sat',
                                                      'Sun',
                                                    ][d.weekday - 1],
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Available Time Slots',
                                      style: TextStyle(
                                        color: Palette.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: slots.map((slot) {
                                        final booked = state.appointments.any(
                                          (a) =>
                                              a.salonId == salonId &&
                                              a.date == date &&
                                              a.time == slot &&
                                              a.status ==
                                                  BookingStatus.upcoming,
                                        );
                                        return ChoiceChip(
                                          label: Text(
                                            slot,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                          selected: time == slot,
                                          showCheckmark: false,
                                          selectedColor: Palette.orchid,
                                          backgroundColor: const Color(
                                            0xFFE4E3E9,
                                          ),
                                          labelStyle: TextStyle(
                                            color: time == slot
                                                ? Colors.white
                                                : Palette.ink,
                                          ),
                                          side: BorderSide.none,
                                          visualDensity: VisualDensity.compact,
                                          onSelected: booked
                                              ? null
                                              : (_) => change(
                                                  context,
                                                  'time',
                                                  slot,
                                                ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Available Services',
                                            style: TextStyle(
                                              color: Palette.muted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        if (canEdit)
                                          TextButton(
                                            onPressed: () => modal(
                                              context,
                                              const ServiceEditor(),
                                            ),
                                            child: const Text(
                                              '+ Add New Services',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...services.map(
                                      (service) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: Surface(
                                          onTap: () => canEdit
                                              ? modal(
                                                  context,
                                                  ServiceEditor(
                                                    service: service,
                                                  ),
                                                )
                                              : change(
                                                  context,
                                                  'service',
                                                  service.id,
                                                ),
                                          padding: const EdgeInsets.all(9),
                                          child: Row(
                                            children: [
                                              Photo(
                                                service.image,
                                                bytes: service.bytes,
                                                height: 44,
                                                width: 44,
                                                radius: 6,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      service.name,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Duration: ${service.duration} min',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        color: Palette.muted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '${service.price.toStringAsFixed(0)} \$',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                canEdit
                                                    ? Icons.edit_outlined
                                                    : selected?.id == service.id
                                                    ? Icons.check_circle
                                                    : Icons
                                                          .radio_button_unchecked,
                                                size: 18,
                                                color: Palette.orchid,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!canEdit) ...[
                                      const SizedBox(height: 16),
                                      AppButton(
                                        'Book Appointment${selected == null ? '' : ' · \$${selected.price.toStringAsFixed(0)}'}',
                                        onTap:
                                            selected == null ||
                                                date.isEmpty ||
                                                time.isEmpty
                                            ? null
                                            : () => modal(
                                                context,
                                                BookingDetailsDialog(
                                                  salonId: salonId,
                                                  service: selected,
                                                  date: date,
                                                  time: time,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Select a service, date and available time',
                                        style: TextStyle(
                                          color: Palette.muted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              : tab == 1
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (canEdit)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () => Navigator.pushNamed(
                                            context,
                                            '/vendor/upload',
                                          ),
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text('Add Pictures'),
                                        ),
                                      ),
                                    ...{
                                      ...state.gallery.map((p) => p.album),
                                    }.map(
                                      (album) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 20,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              album,
                                              style: const TextStyle(
                                                color: Palette.muted,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: state.gallery
                                                  .where(
                                                    (p) => p.album == album,
                                                  )
                                                  .map(
                                                    (p) => GestureDetector(
                                                      onTap: () => modal(
                                                        context,
                                                        Photo(
                                                          p.image,
                                                          bytes: p.bytes,
                                                          height: 350,
                                                          width:
                                                              double.infinity,
                                                        ),
                                                      ),
                                                      child: Photo(
                                                        p.image,
                                                        bytes: p.bytes,
                                                        width:
                                                            (MediaQuery.sizeOf(
                                                                  context,
                                                                ).width.clamp(
                                                                  0,
                                                                  480,
                                                                ) -
                                                                56) /
                                                            3,
                                                        height: 105,
                                                        radius: 7,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (state.gallery.isEmpty)
                                      const EmptyState(
                                        'No portfolio images yet.',
                                      ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Reviews & Ratings',
                                      style: TextStyle(
                                        color: Palette.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    ...[
                                      ...state.reviews.where(
                                        (r) => r.salonId == salonId,
                                      ),
                                      const SalonReview(
                                        '',
                                        'Clien Name',
                                        'Very happy with my visit. A welcoming space, thoughtful service and a haircut I love. I will be back!',
                                        5,
                                      ),
                                      const SalonReview(
                                        '',
                                        'Amelia Rose',
                                        'Such a lovely experience. The team took their time and made sure everything was perfect.',
                                        5,
                                      ),
                                      const SalonReview(
                                        '',
                                        'James Oliver',
                                        'Great attention to detail and a friendly team. Highly recommended.',
                                        4,
                                      ),
                                    ].map(
                                      (r) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 24,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Photo(
                                              'portrait',
                                              width: 40,
                                              height: 44,
                                              radius: 6,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          r.author,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ),
                                                      Text(
                                                        '★ ${r.stars}.0',
                                                        style: const TextStyle(
                                                          color: Palette.gold,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    r.text,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
