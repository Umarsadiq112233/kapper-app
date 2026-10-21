import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/app_bloc.dart';
import '../../../domain/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared.dart';
import '../../bookings/presentation/booking_dialogs.dart';
import '../../vendor/presentation/vendor_pages.dart';

class SalonPage extends StatefulWidget {
  const SalonPage({super.key, this.salonId = 'danial', this.vendor = false});
  final String salonId;
  final bool vendor;

  @override
  State<SalonPage> createState() => _SalonPageState();
}

class _SalonPageState extends State<SalonPage> {
  bool _requestedDetails = false;
  bool _loadingDetails = false;
  String? _detailsError;

  Future<void> _loadDetails() async {
    setState(() {
      _loadingDetails = true;
      _detailsError = null;
    });
    try {
      await context.read<AppBloc>().submit(
        LoadCustomerSalonDetails(widget.salonId),
      );
    } catch (_) {
      if (mounted) {
        _detailsError = 'Could not load this studio’s portfolio. Please retry.';
      }
    } finally {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = context.read<AppBloc>();
    if (!_requestedDetails && bloc.liveCustomer && !widget.vendor) {
      _requestedDetails = true;
      bloc.add(RefreshCustomerCatalog());
      _loadDetails();
    }
  }

  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, view) {
      final bloc = context.watch<AppBloc>();
      final state = bloc.state;
      final colors = Theme.of(context).colorScheme;
      final salonId = widget.vendor ? state.salonId : widget.salonId;
      final services = bloc.servicesFor(salonId);
      final dates = bloc.datesFor(salonId);
      final salon = bloc.salonFor(salonId);
      final canEdit = widget.vendor && state.isVendor;
      final publicDetails = state.customerSalonDetails[salonId];
      final portfolio = bloc.liveCustomer && !widget.vendor
          ? publicDetails?.gallery ?? const <GalleryItem>[]
          : state.gallery;
      final customStyles = bloc.liveCustomer && !widget.vendor
          ? publicDetails?.styles ?? const <StyleItem>[]
          : state.styles;
      final publicReviews =
          publicDetails?.reviews ??
          state.reviews.where((review) => review.salonId == salonId).toList();
      final tab = view.get('tab', 0);
      final selected = services
          .where((s) => s.id == view.get('service', ''))
          .firstOrNull;
      final date = view.get('date', dates.firstOrNull ?? '');
      final slots = bloc.slotsFor(salonId, date: date);
      final time = view.get('time', '');
      final conversation = state.appointments
          .where(
            (a) => a.salonId == salonId && a.status == BookingStatus.upcoming,
          )
          .firstOrNull;
      return Scaffold(
        body: Entrance(
          child: PullToRefresh(
            onRefresh: _pullRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                          backgroundColor: colors.surface,
                          foregroundColor: colors.onSurface,
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
                                    widget.vendor && bloc.liveVendor
                                        ? 'Your salon'
                                        : salon.rating > 0
                                        ? '★ ${salon.rating.toStringAsFixed(1)}${salon.reviewCount > 0 ? ' (${salon.reviewCount} reviews)' : ''}'
                                        : 'New salon · No reviews yet',
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
                            if (!canEdit && conversation != null)
                              IconButton(
                                tooltip: 'Message salon',
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/chat',
                                  arguments: conversation.id,
                                ),
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Colors.white,
                                  size: 21,
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
                                    Text(
                                      salon.address.isEmpty
                                          ? 'Address not added yet'
                                          : salon.address,
                                    ),
                                    if (salon.latitude != null &&
                                        salon.longitude != null)
                                      TextButton.icon(
                                        icon: const Icon(
                                          Icons.location_on_outlined,
                                        ),
                                        label: const Text(
                                          'View saved salon location',
                                        ),
                                        onPressed: () => modal(
                                          context,
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(salon.name),
                                              const SizedBox(height: 8),
                                              Text(salon.address),
                                              const SizedBox(height: 12),
                                              SelectableText(
                                                'https://www.google.com/maps/search/?api=1&query=${salon.latitude},${salon.longitude}',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    if (!(widget.vendor && bloc.liveVendor))
                                      if (salon.distance > 0)
                                        Text(
                                          '${salon.distance.toStringAsFixed(1)} km away',
                                        ),
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
                        const SizedBox(height: 16),
                        Surface(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Salon location',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    SelectableText(
                                      salon.address.trim().isEmpty
                                          ? 'The salon has not added an address yet.'
                                          : salon.address,
                                    ),
                                    if (salon.latitude != null &&
                                        salon.longitude != null) ...[
                                      const SizedBox(height: 8),
                                      SelectableText(
                                        'https://www.google.com/maps/search/?api=1&query=${salon.latitude},${salon.longitude}',
                                        style: TextStyle(
                                          color: colors.primary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                    if (salon.distance >= 0)
                                      Text(
                                        '${salon.distance.toStringAsFixed(1)} km away',
                                        style: TextStyle(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (publicDetails?.about.isNotEmpty == true &&
                            tab == 0) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'About the salon',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  publicDetails!.about,
                                  style: const TextStyle(
                                    color: Palette.muted,
                                    height: 1.5,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                        AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 250),
                          child: KeyedSubtree(
                            key: ValueKey(tab),
                            child: tab == 0
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                                change(
                                                  context,
                                                  'date',
                                                  dates[i],
                                                );
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
                                                      : colors
                                                            .surfaceContainerHighest,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '${d.day}',
                                                      style: TextStyle(
                                                        color: date == dates[i]
                                                            ? Colors.white
                                                            : colors.onSurface,
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
                                                      style: TextStyle(
                                                        color: date == dates[i]
                                                            ? Colors.white70
                                                            : colors
                                                                  .onSurfaceVariant,
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
                                      if (slots.isEmpty)
                                        const Text(
                                          "No available times for this date. Please choose another date.",
                                        ),
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
                                            backgroundColor:
                                                colors.surfaceContainerHighest,
                                            labelStyle: TextStyle(
                                              color: time == slot
                                                  ? Colors.white
                                                  : colors.onSurface,
                                            ),
                                            side: BorderSide.none,
                                            visualDensity:
                                                VisualDensity.compact,
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
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        service.name,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: Palette
                                                                  .orchid
                                                                  .withValues(
                                                                    alpha: .12,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              StandardCategories.find(
                                                                service
                                                                    .category,
                                                              ).label,
                                                              style: const TextStyle(
                                                                fontSize: 9,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Palette
                                                                    .orchid,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            '${service.duration} min',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 9,
                                                                  color: Palette
                                                                      .muted,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  'Rs ${service.price.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  canEdit
                                                      ? Icons.edit_outlined
                                                      : selected?.id ==
                                                            service.id
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
                                          'Book Appointment${selected == null ? '' : ' · Rs ${selected.price.toStringAsFixed(0)}'}',
                                          onTap:
                                              selected == null ||
                                                  date.isEmpty ||
                                                  time.isEmpty ||
                                                  !slots.contains(time) ||
                                                  !dates.contains(date)
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (canEdit)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () =>
                                                Navigator.pushNamed(
                                                  context,
                                                  '/vendor/upload',
                                                ),
                                            icon: const Icon(
                                              Icons.add,
                                              size: 16,
                                            ),
                                            label: const Text('Add Pictures'),
                                          ),
                                        ),
                                      if (customStyles.isNotEmpty) ...[
                                        const Text(
                                          'Custom Styles',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Real work uploaded by this studio',
                                          style: TextStyle(
                                            color: Palette.muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _CustomStyleGrid(styles: customStyles),
                                        if (portfolio.isNotEmpty)
                                          const SizedBox(height: 24),
                                      ],
                                      if (portfolio.isNotEmpty)
                                        const Text(
                                          'Portfolio',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      if (portfolio.isNotEmpty)
                                        const SizedBox(height: 12),
                                      ...{...portfolio.map((p) => p.album)}.map(
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
                                                children: portfolio
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
                                      if (_loadingDetails)
                                        const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      else if (_detailsError != null)
                                        EmptyState(_detailsError!)
                                      else if (customStyles.isEmpty &&
                                          portfolio.isEmpty)
                                        const EmptyState(
                                          'This studio has not uploaded styles or portfolio photos yet.',
                                        ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Reviews & Ratings',
                                        style: TextStyle(
                                          color: Palette.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      if (bloc.liveCustomer &&
                                          publicDetails != null) ...[
                                        _RatingSummary(
                                          reviews: publicReviews,
                                          rating: salon.rating,
                                        ),
                                        const SizedBox(height: 22),
                                      ],
                                      ...[
                                        ...publicReviews,
                                        if (!bloc.liveCustomer &&
                                            !(widget.vendor && bloc.liveVendor))
                                          const SalonReview(
                                            '',
                                            'Clien Name',
                                            'Very happy with my visit. A welcoming space, thoughtful service and a haircut I love. I will be back!',
                                            5,
                                          ),
                                        if (!bloc.liveCustomer &&
                                            !(widget.vendor && bloc.liveVendor))
                                          const SalonReview(
                                            '',
                                            'Amelia Rose',
                                            'Such a lovely experience. The team took their time and made sure everything was perfect.',
                                            5,
                                          ),
                                        if (!bloc.liveCustomer &&
                                            !(widget.vendor && bloc.liveVendor))
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
                                                          style:
                                                              const TextStyle(
                                                                color: Palette
                                                                    .gold,
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
        ),
      );
    },
  );

  Future<void> _pullRefresh() async {
    final bloc = context.read<AppBloc>();
    if (bloc.liveCustomer && !widget.vendor) {
      await Future.wait([bloc.refreshAll(), _loadDetails()]);
    } else {
      await bloc.refreshAll();
    }
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.reviews, required this.rating});
  final List<SalonReview> reviews;
  final double rating;

  @override
  Widget build(BuildContext context) {
    final counts = List<int>.generate(
      5,
      (index) => reviews.where((r) => r.stars == 5 - index).length,
    );
    final maxCount = counts.fold<int>(
      0,
      (value, count) => count > value ? count : value,
    );
    return Surface(
      child: Row(
        children: [
          Column(
            children: [
              Text(
                rating > 0 ? rating.toStringAsFixed(1) : '—',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Icon(Icons.star_rounded, color: Palette.gold, size: 18),
              const SizedBox(height: 3),
              Text(
                '${reviews.length} reviews',
                style: const TextStyle(fontSize: 10, color: Palette.muted),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final stars = 5 - index;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        child: Text(
                          '$stars',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: Palette.gold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            value: maxCount == 0 ? 0 : counts[index] / maxCount,
                            backgroundColor: Palette.lavender,
                            color: Palette.orchid,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${counts[index]}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Palette.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomStyleGrid extends StatelessWidget {
  const _CustomStyleGrid({required this.styles});
  final List<StyleItem> styles;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 10) / 2;
      final colors = Theme.of(context).colorScheme;
      return Wrap(
        spacing: 10,
        runSpacing: 12,
        children: styles
            .map(
              (style) => SizedBox(
                width: width,
                child: Material(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => modal(
                      context,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Photo(
                              style.image,
                              width: double.infinity,
                              height: 300,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            style.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            style.effectiveCategory,
                            style: const TextStyle(
                              color: Palette.orchid,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (style.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              style.description,
                              style: const TextStyle(
                                color: Palette.muted,
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Photo(
                          style.image,
                          width: width,
                          height: 145,
                          radius: 0,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                style.effectiveCategory,
                                style: const TextStyle(
                                  color: Palette.orchid,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (style.description.trim().isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  style.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Palette.muted,
                                    fontSize: 10,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}
