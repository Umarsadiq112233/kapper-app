import 'salon_map.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/app_bloc.dart';
import '../../../domain/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared.dart';

class SalonCard extends StatelessWidget {
  const SalonCard(
    this.salon, {
    super.key,
    this.compact = false,
    this.matchingCategory,
  });
  final Salon salon;
  final bool compact;
  final String? matchingCategory;
  @override
  Widget build(BuildContext context) {
    final favorite = context.watch<AppBloc>().state.favorites.contains(
      salon.id,
    );
    final allServices = context.read<AppBloc>().servicesFor(salon.id);
    final isCategoryFiltered =
        matchingCategory != null &&
        matchingCategory != 'All' &&
        matchingCategory != 'Any';
    final matchingServices = isCategoryFiltered
        ? allServices
              .where((s) => serviceMatchesCategory(s, matchingCategory!))
              .toList()
        : allServices;
    final startingPrice = matchingServices.isEmpty
        ? (allServices.isEmpty
              ? null
              : allServices
                    .map((service) => service.price)
                    .reduce((a, b) => a < b ? a : b))
        : matchingServices
              .map((service) => service.price)
              .reduce((a, b) => a < b ? a : b);
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          salon.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        if (salon.address.trim().isNotEmpty) ...[
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  salon.address,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (startingPrice != null) ...[
          const SizedBox(height: 4),
          Text(
            isCategoryFiltered && matchingServices.isNotEmpty
                ? '${StandardCategories.find(matchingCategory).label} from Rs ${startingPrice.toStringAsFixed(0)}'
                : 'From Rs ${startingPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Palette.orchid,
            ),
          ),
        ],
        if (salon.rating > 0 || salon.distance >= 0) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              if (salon.rating > 0) ...[
                const Icon(Icons.star_rounded, size: 12, color: Palette.gold),
                Text(
                  ' ${salon.rating.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 9),
                ),
              ],
              if (salon.rating > 0 && salon.distance >= 0)
                const SizedBox(width: 10),
              if (salon.distance >= 0)
                Flexible(
                  child: Text(
                    '${salon.distance.toStringAsFixed(1)} km away',
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
    return Surface(
      padding: const EdgeInsets.all(7),
      onTap: () => Navigator.pushNamed(context, '/salon', arguments: salon.id),
      child: compact
          ? Row(
              children: [
                Photo(salon.image, width: 58, height: 62, radius: 8),
                const SizedBox(width: 10),
                Expanded(child: info),
                IconButton(
                  tooltip: 'Favorite',
                  icon: Icon(
                    favorite ? Icons.favorite : Icons.favorite_border,
                    color: favorite ? Palette.orchid : Palette.muted,
                    size: 18,
                  ),
                  onPressed: () =>
                      context.read<AppBloc>().add(ToggleFavorite(salon.id)),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'salon-${salon.id}',
                        child: Photo(salon.image, radius: 9),
                      ),
                      Positioned(
                        right: 5,
                        top: 5,
                        child: GestureDetector(
                          onTap: () => context.read<AppBloc>().add(
                            ToggleFavorite(salon.id),
                          ),
                          child: CircleAvatar(
                            radius: 13,
                            backgroundColor: Colors.white.withValues(alpha: .9),
                            child: Icon(
                              favorite ? Icons.favorite : Icons.favorite_border,
                              size: 15,
                              color: Palette.orchid,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(3, 8, 3, 2),
                  child: info,
                ),
              ],
            ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<AppBloc>();
    final catalog = bloc.liveCustomer
        ? bloc.state.customerListings.map((item) => item.salon).toList()
        : bloc.repository.salons;
    final salons = [...catalog]
      ..sort((a, b) => a.distance.compareTo(b.distance));
    final recommended = [...catalog]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final favorites = catalog
        .where((salon) => bloc.state.favorites.contains(salon.id))
        .toList();
    final upcomingAppointment = bloc.state.appointments
        .where((a) => a.status == BookingStatus.upcoming)
        .cast<Appointment?>()
        .firstWhere((_) => true, orElse: () => null);
    final completedAppointment = bloc.state.appointments
        .where((a) => a.status == BookingStatus.completed)
        .cast<Appointment?>()
        .firstWhere((_) => true, orElse: () => null);
    final primaryAppointment = upcomingAppointment ?? completedAppointment;
    return SafeArea(
      child: Entrance(
        child: PullToRefresh(
          onRefresh: () => bloc.refreshAll(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good ${_greeting()}, ${bloc.state.name.split(' ').first}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                InkWell(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/profile/edit',
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 15,
                                        color: Palette.orchid,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          bloc.state.address,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Palette.muted,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 16,
                                        color: Palette.muted,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/profile'),
                            child: ProfileAvatar(
                              avatar: bloc.state.avatar,
                              bytes: bloc.state.avatarBytes,
                              isVendor: bloc.state.isVendor,
                              size: 38,
                              borderWidth: 1.5,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Notifications',
                            onPressed: () =>
                                Navigator.pushNamed(context, '/notifications'),
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              size: 23,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, '/search'),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFFE5DFEA)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: Palette.muted),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Find salons, barbers or services',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Palette.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.tune, size: 19, color: Palette.orchid),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HomePrimaryCard(
                        appointment: primaryAppointment,
                        salon: primaryAppointment == null
                            ? null
                            : _salonOrFallback(
                                bloc,
                                primaryAppointment.salonId,
                              ),
                        onExplore: () =>
                            Navigator.pushNamed(context, '/search'),
                        onAppointments: () =>
                            Navigator.pushNamed(context, '/appointments'),
                        onBookAgain: primaryAppointment == null
                            ? null
                            : () => Navigator.pushNamed(
                                context,
                                '/salon',
                                arguments: primaryAppointment.salonId,
                              ),
                      ),
                      if (bloc.liveCustomer &&
                          bloc.state.discoveryError.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DiscoveryFailure(
                          message: bloc.state.discoveryError,
                          onRetry: () => bloc.add(RefreshCustomerCatalog()),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const _HomeSectionTitle('Explore services', action: ''),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 74,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: StandardCategories.all
                              .map(
                                (cat) => _CategoryItem(
                                  cat.label,
                                  cat.icon,
                                  onTap: () =>
                                      _openSearch(context, category: cat.id),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (favorites.isNotEmpty) ...[
                        _HomeSectionTitle(
                          'Saved salons',
                          action: 'View all',
                          onTap: () =>
                              Navigator.pushNamed(context, '/favorites'),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 206,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: favorites.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (_, i) => SizedBox(
                              width: 162,
                              child: SalonCard(favorites[i]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _HomeSectionTitle(
                        'Salons to explore',
                        action: 'See all',
                        onTap: () => Navigator.pushNamed(context, '/search'),
                      ),
                      const SizedBox(height: 8),
                      if (salons.isEmpty && bloc.liveCustomer)
                        const EmptyState(
                          'No salons are listed in your area yet.',
                          icon: Icons.storefront_outlined,
                        )
                      else
                        SizedBox(
                          height: 212,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: salons.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (_, i) => SizedBox(
                              width: 162,
                              child: SalonCard(salons[i]),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      _HomeSectionTitle(
                        'Top rated for you',
                        action: 'See all',
                        onTap: () => Navigator.pushNamed(context, '/search'),
                      ),
                      const SizedBox(height: 8),
                      if (recommended.isEmpty && bloc.liveCustomer)
                        const EmptyState(
                          'Published salons will appear here when vendors make their services available.',
                          icon: Icons.recommend_outlined,
                        )
                      else
                        ...recommended
                            .take(3)
                            .map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SalonCard(s, compact: true),
                              ),
                            ),
                      const SizedBox(height: 14),
                      _HomeSectionTitle(
                        'Popular services',
                        action: 'Explore',
                        onTap: () => Navigator.pushNamed(context, '/search'),
                      ),
                      const SizedBox(height: 8),
                      _PopularServiceList(
                        services: bloc.liveCustomer
                            ? bloc.state.customerListings
                                  .expand((item) => item.services)
                                  .toList()
                            : bloc.repository.initialServices,
                        onSelect: (service) =>
                            _openSearch(context, query: service.name),
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
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    return hour < 12
        ? 'morning'
        : hour < 17
        ? 'afternoon'
        : 'evening';
  }

  static void _openSearch(
    BuildContext context, {
    String? query,
    String? category,
  }) => Navigator.pushNamed(
    context,
    '/search',
    arguments: <String, String?>{'query': query, 'category': category},
  );
}

Salon _salonOrFallback(AppBloc bloc, String salonId) {
  try {
    return bloc.salonFor(salonId);
  } catch (_) {
    return Salon(salonId, 'Salon', 'salon', '', 0, 0);
  }
}

String _appointmentSummary(Appointment? appointment) {
  if (appointment == null) return '';
  return '${appointment.service.name} · ${dateLabel(appointment.date)}';
}

class _HomeSectionTitle extends StatelessWidget {
  const _HomeSectionTitle(this.title, {required this.action, this.onTap});
  final String title, action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      if (action.isNotEmpty)
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Palette.orchid,
              ),
            ),
          ),
        ),
    ],
  );
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem(this.label, this.icon, {required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Palette.orchid.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Palette.orchid, size: 24),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HomePrimaryCard extends StatefulWidget {
  const _HomePrimaryCard({
    required this.appointment,
    required this.salon,
    required this.onExplore,
    required this.onAppointments,
    required this.onBookAgain,
  });

  final Appointment? appointment;
  final Salon? salon;
  final VoidCallback onExplore;
  final VoidCallback onAppointments;
  final VoidCallback? onBookAgain;

  @override
  State<_HomePrimaryCard> createState() => _HomePrimaryCardState();
}

class _HomePrimaryCardState extends State<_HomePrimaryCard>
    with TickerProviderStateMixin {
  late final AnimationController entrance;
  late final AnimationController breathe;

  @override
  void initState() {
    super.initState();
    entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();
  }

  @override
  void dispose() {
    entrance.dispose();
    breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final salon = widget.salon;
    final hasBooking = appointment != null && salon != null;
    final isUpcoming = appointment?.status == BookingStatus.upcoming;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final cardStart = Color.lerp(Palette.ink, colors.primary, .28)!;
    final cardEnd = Color.lerp(Palette.ink, Palette.orchid, .62)!;
    final title = isUpcoming
        ? salon!.name
        : appointment != null
        ? 'Book your next visit'
        : 'A fresh look\nstarts nearby.';
    final subtitle = isUpcoming
        ? _appointmentSummary(appointment)
        : appointment != null
        ? 'Return to ${salon!.name} for your next style.'
        : 'Discover trusted salons and barbers near you.';
    final action = isUpcoming
        ? 'View booking'
        : appointment != null
        ? 'Book again'
        : 'Discover salons';
    final onTap = isUpcoming
        ? widget.onAppointments
        : appointment != null
        ? widget.onBookAgain
        : widget.onExplore;

    return AnimatedBuilder(
      animation: Listenable.merge([entrance, breathe]),
      builder: (context, child) => FadeTransition(
        opacity: CurvedAnimation(parent: entrance, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: entrance, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 190,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: .22)),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: dark ? .28 : .18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardStart, cardEnd],
            ),
          ),
          child: AnimatedBuilder(
            animation: breathe,
            builder: (context, _) => Stack(
              children: [
                if (hasBooking)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 238,
                    child: ClipPath(
                      clipper: _HeroImageClipper(),
                      child: Container(
                        color: cardEnd.withValues(alpha: .22),
                        child: Transform.translate(
                          offset: Offset(0, -4 * breathe.value),
                          child: Opacity(
                            opacity: 1,
                            child: Photo(salon.image, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Positioned(
                    right: -14,
                    bottom: -22,
                    child: Icon(
                      Icons.content_cut,
                      size: 154,
                      color: Colors.white.withValues(alpha: .12),
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          cardStart.withValues(alpha: .98),
                          cardStart.withValues(alpha: .70),
                          cardStart.withValues(alpha: .02),
                        ],
                        stops: const [.0, .52, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  top: -38,
                  child: Container(
                    width: 150,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: .04 + (.03 * breathe.value),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isUpcoming
                                ? Icons.calendar_month_rounded
                                : Icons.auto_awesome_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: .84),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isUpcoming
                                ? 'UPCOMING APPOINTMENT'
                                : appointment != null
                                ? 'KEEP YOUR STYLE GOING'
                                : 'YOUR NEXT GREAT LOOK',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              letterSpacing: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 205),
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.02,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .13),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .24),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              action,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 9),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * .28, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant _HeroImageClipper oldClipper) => false;
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.favoritesOnly = false});
  final bool favoritesOnly;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final searchController = TextEditingController();
  final _recentSearches = <String>[];
  bool _initialized = false;
  String? _initialCategory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is String) {
      searchController.text = routeArgs;
    } else if (routeArgs is Map) {
      final q = routeArgs['query'];
      final c = routeArgs['category'];
      if (q is String && q.isNotEmpty) searchController.text = q;
      if (c is String && c.isNotEmpty) _initialCategory = c;
    }
    final bloc = context.read<AppBloc>();
    if (bloc.liveCustomer) bloc.add(RefreshCustomerCatalog());
    _initialized = true;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, view) {
      final bloc = context.watch<AppBloc>();
      final query = view.get('query', searchController.text).toLowerCase();
      final normalizedQuery = query.replaceAll(RegExp(r'[^a-z0-9]'), '');
      final category = view.get('category', _initialCategory ?? 'Any');
      final minimumRating = view.get('rating', 0.0);
      final catalog = bloc.liveCustomer
          ? bloc.state.customerListings.map((item) => item.salon).toList()
          : bloc.repository.salons;
      final salons = catalog
          .where(
            (s) =>
                (!widget.favoritesOnly ||
                    bloc.state.favorites.contains(s.id)) &&
                (query.isEmpty ||
                    s.name.toLowerCase().contains(query) ||
                    s.address.toLowerCase().contains(query) ||
                    s.name
                        .toLowerCase()
                        .replaceAll(RegExp(r'[^a-z0-9]'), '')
                        .contains(normalizedQuery) ||
                    bloc
                        .servicesFor(s.id)
                        .any(
                          (service) => service.name
                              .toLowerCase()
                              .replaceAll(RegExp(r'[^a-z0-9]'), '')
                              .contains(normalizedQuery),
                        )) &&
                (view.get('distance', double.infinity) == double.infinity ||
                    (s.distance >= 0 &&
                        s.distance <= view.get('distance', double.infinity))) &&
                s.rating >= minimumRating &&
                (category == 'Any' ||
                    category == 'All' ||
                    bloc
                        .servicesFor(s.id)
                        .any(
                          (service) =>
                              serviceMatchesCategory(service, category),
                        )) &&
                (view.get('price', double.infinity) == double.infinity ||
                    bloc
                        .servicesFor(s.id)
                        .any(
                          (service) =>
                              service.price <=
                              view.get('price', double.infinity),
                        )),
          )
          .toList();
      final sort = view.get('sort', 'Recommended');
      if (sort == 'Top rated') {
        salons.sort((a, b) => b.rating.compareTo(a.rating));
      } else if (sort == 'Price: low to high') {
        salons.sort(
          (a, b) =>
              _startingPrice(bloc, a.id).compareTo(_startingPrice(bloc, b.id)),
        );
      } else if (sort == 'Nearest') {
        salons.sort((a, b) => a.distance.compareTo(b.distance));
      }
      if (widget.favoritesOnly) {
        return Screen(
          title: 'My Favorites',
          subtitle: 'Your saved places, ready when you are',
          onRefresh: () => bloc.refreshAll(),
          child: salons.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 100),
                    EmptyState(
                      'Save a salon with the heart to find it here.',
                      icon: Icons.favorite_border,
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: salons.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final salon = salons[i];
                    final price = _startingPrice(bloc, salon.id);
                    return Surface(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Photo(salon.image, width: 88, height: 96, radius: 12),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  salon.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  salon.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Palette.muted,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Palette.gold,
                                      size: 15,
                                    ),
                                    Text(
                                      salon.rating > 0
                                          ? ' ${salon.rating.toStringAsFixed(1)} · ${salon.reviewCount} reviews'
                                          : ' New salon',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  price.isFinite
                                      ? 'From Rs ${price.toStringAsFixed(0)}'
                                      : 'Services available',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Palette.orchid,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppButton(
                                        'Book again',
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          '/salon',
                                          arguments: salon.id,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Remove from saved salons',
                                      onPressed: () => context
                                          .read<AppBloc>()
                                          .add(ToggleFavorite(salon.id)),
                                      icon: const Icon(
                                        Icons.favorite,
                                        color: Palette.orchid,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      }
      return Screen(
        title: 'Explore',
        centerTitle: true,
        onRefresh: () => bloc.refreshAll(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          children: [
            Text(
              'Find your next salon',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (bloc.liveCustomer) SalonDiscoveryMap(salons: salons),
            if (bloc.liveCustomer && bloc.state.discoveryError.isNotEmpty)
              _DiscoveryFailure(
                message: bloc.state.discoveryError,
                onRetry: () => bloc.add(RefreshCustomerCatalog()),
              ),
            if (!widget.favoritesOnly) ...[
              TextField(
                controller: searchController,
                onChanged: (v) => change(context, 'query', v),
                onSubmitted: (value) {
                  final term = value.trim();
                  if (term.isNotEmpty) {
                    setState(() {
                      _recentSearches.remove(term);
                      _recentSearches.insert(0, term);
                      if (_recentSearches.length > 6) {
                        _recentSearches.removeLast();
                      }
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Find salons, barbers or services',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (query.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            searchController.clear();
                            change(context, 'query', '');
                          },
                        ),
                      IconButton(
                        tooltip: 'Filters',
                        icon: const Icon(Icons.tune, size: 20),
                        onPressed: () async {
                          final result = await modal<Map<String, Object?>>(
                            context,
                            FilterDialog(
                              price: view.get('price', 5000.0),
                              distance: view.get('distance', 20.0),
                              category: category,
                              rating: minimumRating,
                            ),
                          );
                          if (result != null && context.mounted) {
                            for (final entry in result.entries) {
                              change(context, entry.key, entry.value);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: category == 'Any' || category == 'All',
                        onSelected: (_) => change(context, 'category', 'All'),
                      ),
                    ),
                    ...StandardCategories.all.map((cat) {
                      final isSelected =
                          category.toLowerCase() == cat.id.toLowerCase() ||
                          category.toLowerCase() == cat.label.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(cat.icon, size: 16),
                          label: Text(cat.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            change(
                              context,
                              'category',
                              selected ? cat.id : 'All',
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              if (category != 'Any' && category != 'All') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Palette.orchid.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            StandardCategories.find(category).icon,
                            size: 14,
                            color: Palette.orchid,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Filtered by: ${StandardCategories.find(category).label}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Palette.orchid,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => change(context, 'category', 'All'),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Palette.orchid,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (query.isEmpty) ...[
                if (_recentSearches.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Recent searches',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(_recentSearches.clear),
                        child: const Text(
                          'Clear all',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 7,
                    children: _recentSearches
                        .map(
                          (term) => ActionChip(
                            label: Text(
                              term,
                              style: const TextStyle(fontSize: 10),
                            ),
                            onPressed: () {
                              searchController.text = term;
                              change(context, 'query', term.toLowerCase());
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Text(
                '${salons.length} salons',
                style: const TextStyle(color: Palette.muted, fontSize: 11),
              ),
              const SizedBox(height: 14),
            ],
            if (bloc.state.saving && catalog.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (salons.isEmpty)
              EmptyState(
                catalog.isEmpty
                    ? 'No salons are available yet. Refresh to check for newly published salons.'
                    : 'No salons match your search. Try another search or reset your filters.',
              ),
            ...salons.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SalonCard(
                  s,
                  compact: true,
                  matchingCategory: (category == 'Any' || category == 'All')
                      ? null
                      : category,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _DiscoveryFailure extends StatelessWidget {
  const _DiscoveryFailure({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.all(13),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_outlined, color: Palette.muted, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 10, color: Palette.muted),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class FilterDialog extends StatefulWidget {
  const FilterDialog({
    super.key,
    required this.price,
    required this.distance,
    this.category = 'Any',
    this.rating = 0,
  });
  final double price, distance, rating;
  final String category;
  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  final form = GlobalKey<FormState>();
  late String _category = widget.category;
  late double _rating = widget.rating;
  late String _sort = 'Recommended';
  late final price = TextEditingController(
    text: widget.price.toStringAsFixed(0),
  );
  late final distance = TextEditingController(
    text: widget.distance.toStringAsFixed(0),
  );
  @override
  void dispose() {
    price.dispose();
    distance.dispose();
    super.dispose();
  }

  Widget range(String label, TextEditingController controller, String unit) =>
      Column(
        children: [
          Row(
            children: [
              Text(label),
              const Spacer(),
              const Icon(Icons.tune, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '0 $unit',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Palette.muted),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('to'),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(suffixText: unit),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return n == null || !n.isFinite || n < 0
                        ? 'Invalid value'
                        : null;
                  },
                ),
              ),
            ],
          ),
        ],
      );
  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find your perfect match',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 26),
          const Text('Services', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('Any'),
                selected: _category == 'Any' || _category == 'All',
                onSelected: (_) => setState(() => _category = 'Any'),
              ),
              ...StandardCategories.all.map(
                (cat) => ChoiceChip(
                  avatar: Icon(cat.icon, size: 16),
                  label: Text(cat.label),
                  selected:
                      _category.toLowerCase() == cat.id.toLowerCase() ||
                      _category.toLowerCase() == cat.label.toLowerCase(),
                  onSelected: (_) => setState(() => _category = cat.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          range('Maximum price', price, 'PKR'),
          const SizedBox(height: 24),
          range('Distance radius', distance, 'km'),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Minimum rating',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                _rating == 0 ? 'Any' : '${_rating.toStringAsFixed(1)}+ stars',
                style: const TextStyle(color: Palette.orchid, fontSize: 12),
              ),
            ],
          ),
          Slider(
            value: _rating,
            min: 0,
            max: 5,
            divisions: 5,
            onChanged: (value) => setState(() => _rating = value),
          ),
          const Text(
            'Sort results',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _sort,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items:
                const [
                      'Recommended',
                      'Top rated',
                      'Nearest',
                      'Price: low to high',
                    ]
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
            onChanged: (value) =>
                setState(() => _sort = value ?? 'Recommended'),
          ),
          const SizedBox(height: 22),
          AppButton(
            'Apply filters',
            onTap: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, {
                  'price': double.parse(price.text),
                  'distance': double.parse(distance.text),
                  'category': _category,
                  'rating': _rating,
                  'sort': _sort,
                });
              }
            },
          ),
          TextButton(
            onPressed: () {
              price.text = '5000';
              distance.text = '20';
              setState(() {
                _category = 'Any';
                _rating = 0;
                _sort = 'Recommended';
              });
            },
            child: const Text('Reset filters'),
          ),
        ],
      ),
    ),
  );
}

double _startingPrice(AppBloc bloc, String salonId) {
  final prices = bloc
      .servicesFor(salonId)
      .map((service) => service.price)
      .toList();
  return prices.isEmpty
      ? double.infinity
      : prices.reduce((a, b) => a < b ? a : b);
}

class _PopularServiceList extends StatelessWidget {
  const _PopularServiceList({required this.services, required this.onSelect});
  final List<SalonService> services;
  final ValueChanged<SalonService> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (services.isEmpty) {
      return const EmptyState(
        'Services will appear here when salons add them.',
      );
    }
    return Column(
      children: services.take(6).map((service) {
        final price = service.price
            .toStringAsFixed(0)
            .replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
              (match) => '${match[1]},',
            );
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: .5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSelect(service),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Photo(
                      service.image,
                      bytes: service.bytes,
                      width: 68,
                      height: 76,
                      radius: 12,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${service.duration} min',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Rs $price',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: .1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
