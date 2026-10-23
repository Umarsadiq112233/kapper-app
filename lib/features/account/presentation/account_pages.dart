import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../application/app_bloc.dart';
import '../../../domain/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared.dart';
import '../../location/presentation/location_picker_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppBloc>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Screen(
      title: 'Profile',
      showAppBar: false,
      onRefresh: () => context.read<AppBloc>().refreshAll(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          18,
          MediaQuery.paddingOf(context).top + 14,
          18,
          28,
        ),
        children: [
          _ProfileTopBar(isVendor: state.isVendor),
          const SizedBox(height: 20),
          _ProfileHeroCard(
            state: state,
            isDark: isDark,
            onEdit: () => Navigator.pushNamed(context, '/profile/edit'),
          ),
          const SizedBox(height: 14),
          _ProfileFeatureBanner(
            isVendor: state.isVendor,
            onTap: state.isVendor
                ? null
                : () => Navigator.pushNamed(context, '/about'),
          ),
          const SizedBox(height: 24),
          if (state.isVendor)
            _VendorProfileContent(state: state)
          else
            _CustomerProfileContent(state: state),
          const SizedBox(height: 24),
          _ProfileActionTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: state.isVendor
                ? 'Bookings and customer updates'
                : 'Appointment and salon updates',
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Preferences and account settings',
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Sign out of this account',
            color: Palette.pink,
            onTap: () async {
              if (await confirm(context, 'Do you want to log out?') &&
                  context.mounted) {
                if (!await saveAction(context, SignOut())) return;
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/role',
                  (_) => false,
                );
              }
            },
          ),
          const SizedBox(height: 24),
          Text(
            state.isVendor && context.read<AppBloc>().liveVendor
                ? 'Kapper · Vendor Live 1.0'
                : 'Kapper · Premium Salon Edition 1.0',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppBloc>().state;
    final reviews = state.reviews;
    final average = reviews.isEmpty
        ? 0.0
        : reviews.fold<int>(0, (sum, review) => sum + review.stars) /
              reviews.length;
    final counts = List<int>.generate(
      5,
      (index) => reviews.where((review) => review.stars == 5 - index).length,
    );
    return Screen(
      title: 'Reviews & Ratings',
      showAppBar: false,
      onRefresh: () => context.read<AppBloc>().refreshAll(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          18,
          MediaQuery.paddingOf(context).top + 16,
          18,
          28,
        ),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviews & Ratings',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Feedback from your completed appointments',
                      style: TextStyle(color: Palette.muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.rate_review_outlined, color: Palette.orchid),
            ],
          ),
          const SizedBox(height: 20),
          _VendorReviewSummary(
            average: average,
            reviewCount: reviews.length,
            counts: counts,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Customer feedback',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'}',
                style: const TextStyle(color: Palette.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 46),
              child: EmptyState(
                'No reviews yet. Customer ratings will appear here after completed appointments.',
                icon: Icons.rate_review_outlined,
              ),
            )
          else
            ...reviews.reversed.map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _VendorReviewCard(review: review),
              ),
            ),
        ],
      ),
    );
  }
}

class _VendorReviewSummary extends StatelessWidget {
  const _VendorReviewSummary({
    required this.average,
    required this.reviewCount,
    required this.counts,
  });
  final double average;
  final int reviewCount;
  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final maxCount = counts.fold<int>(
      0,
      (highest, count) => count > highest ? count : highest,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1536), Color(0xFF120D27)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.purple.withValues(alpha: .42)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Column(
              children: [
                Text(
                  average == 0 ? '—' : average.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Icon(Icons.star_rounded, color: Palette.gold, size: 21),
                const SizedBox(height: 4),
                Text(
                  '$reviewCount reviews',
                  style: const TextStyle(color: Palette.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final stars = 5 - index;
                final ratio = maxCount == 0 ? 0.0 : counts[index] / maxCount;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        child: Text(
                          '$stars',
                          style: const TextStyle(
                            color: Color(0xFFD6D1E3),
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        color: Palette.gold,
                        size: 13,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: ratio,
                            backgroundColor: Colors.white.withValues(alpha: .1),
                            color: Palette.orchid,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${counts[index]}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Palette.muted,
                            fontSize: 9,
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

class _VendorReviewCard extends StatelessWidget {
  const _VendorReviewCard({required this.review});
  final SalonReview review;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF11172D),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Palette.purple.withValues(alpha: .2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileAvatar(
          avatar: 'portrait',
          isVendor: false,
          size: 40,
          radius: 12,
          borderWidth: 0,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '★ ${review.stars}.0',
                    style: const TextStyle(
                      color: Palette.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                review.text.trim().isEmpty
                    ? 'Customer left a rating without written feedback.'
                    : review.text,
                style: const TextStyle(
                  color: Color(0xFFD1CCDF),
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.isVendor});
  final bool isVendor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 25,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                  children: [
                    TextSpan(text: isVendor ? 'Business ' : 'My '),
                    const TextSpan(
                      text: 'Profile',
                      style: TextStyle(color: Palette.orchid),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isVendor
                    ? 'Manage your salon, services and account'
                    : 'Manage your account and preferences',
                style: const TextStyle(color: Palette.muted, fontSize: 11.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _ProfileIconButton(
          icon: Icons.notifications_none_rounded,
          badge: true,
          tooltip: 'Notifications',
          onTap: () => Navigator.pushNamed(context, '/notifications'),
        ),
        const SizedBox(width: 8),
        _ProfileIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
    );
  }
}

class _ProfileIconButton extends StatelessWidget {
  const _ProfileIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badge = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool badge;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.ink.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Palette.purple.withValues(alpha: .22),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 23),
              ),
            ),
            if (badge)
              Positioned(
                right: 5,
                top: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.state,
    required this.isDark,
    required this.onEdit,
  });
  final AppState state;
  final bool isDark;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final accent = state.isVendor ? Palette.orchid : Palette.purple;
    final stats = state.isVendor
        ? _vendorStats(state)
        : [
            _ProfileStatData(
              Icons.calendar_month_outlined,
              state.appointments.length.toString(),
              'Bookings',
            ),
            _ProfileStatData(
              Icons.favorite_rounded,
              state.favorites.length.toString(),
              'Favorites',
            ),
            const _ProfileStatData(Icons.star_rounded, '4.8', 'Rating'),
          ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? const Color(0xFF1B1435) : const Color(0xFFF2EBFF),
            isDark ? const Color(0xFF32105A) : const Color(0xFFE7D8FF),
            isDark ? const Color(0xFF120D27) : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: .78), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .22),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfileAvatar(
                avatar: state.avatar,
                bytes: state.avatarBytes,
                isVendor: state.isVendor,
                size: 94,
                borderWidth: 3,
                showEditBadge: true,
                badgeIcon: Icons.camera_alt_rounded,
                onTap: onEdit,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            state.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          color: Palette.orchid,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.isVendor
                          ? 'Salon & Grooming Studio'
                          : 'Premium Member',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Palette.muted,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 11),
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Palette.purple,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: Palette.purple.withValues(alpha: .34),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Divider(
            color: isDark ? Colors.white12 : Palette.ink.withValues(alpha: .08),
          ),
          SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  Expanded(child: _ProfileStat(data: stats[i])),
                  if (i != stats.length - 1)
                    Container(
                      width: 1,
                      height: 36,
                      color: isDark
                          ? Colors.white12
                          : Palette.ink.withValues(alpha: .08),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<_ProfileStatData> _vendorStats(AppState state) {
  final ratings = state.reviews.map((review) => review.stars).toList();
  final rating = ratings.isEmpty
      ? '—'
      : (ratings.reduce((a, b) => a + b) / ratings.length).toStringAsFixed(1);
  final customers = state.appointments
      .map((appointment) => appointment.customerId ?? appointment.customer)
      .where((name) => name.trim().isNotEmpty)
      .toSet()
      .length;
  return [
    _ProfileStatData(Icons.star_rounded, rating, 'Rating'),
    _ProfileStatData(
      Icons.calendar_month_outlined,
      _compactCount(state.appointments.length),
      'Bookings',
    ),
    _ProfileStatData(
      Icons.groups_rounded,
      _compactCount(customers),
      'Customers',
    ),
  ];
}

String _compactCount(int value) => value >= 1000
    ? '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K'
    : value.toString();

class _ProfileStatData {
  const _ProfileStatData(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.data});
  final _ProfileStatData data;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(data.icon, color: Palette.orchid, size: 21),
      const SizedBox(width: 6),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: Palette.muted),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ProfileFeatureBanner extends StatelessWidget {
  const _ProfileFeatureBanner({required this.isVendor, this.onTap});
  final bool isVendor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isVendor ? Palette.gold : Palette.purple;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isVendor
                ? [const Color(0xFF382717), const Color(0xFF1C1520)]
                : [const Color(0xFF241549), const Color(0xFF130E28)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .64)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isVendor
                    ? Icons.workspace_premium_rounded
                    : Icons.diamond_rounded,
                color: color,
                size: 29,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVendor ? 'Certified Salon Vendor' : 'Premium Member',
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isVendor
                        ? 'Verified business on Kapper platform'
                        : 'Enjoy exclusive offers and discounts',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Palette.purple,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerProfileContent extends StatelessWidget {
  const _CustomerProfileContent({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ProfileSectionTitle(
        icon: Icons.person_rounded,
        title: 'Personal Information',
        onEdit: () => Navigator.pushNamed(context, '/profile/edit'),
      ),
      const SizedBox(height: 10),
      _ProfileInfoCard(
        rows: [
          _ProfileInfoData(
            Icons.person_outline_rounded,
            'Full Name',
            state.name,
          ),
          _ProfileInfoData(Icons.mail_outline_rounded, 'Email', state.email),
          _ProfileInfoData(Icons.phone_outlined, 'Phone', state.phone),
          _ProfileInfoData(
            Icons.location_on_outlined,
            'Location',
            state.address,
          ),
        ],
        onEdit: () => Navigator.pushNamed(context, '/profile/edit'),
      ),
      const SizedBox(height: 16),
      _ProfileActionTile(
        icon: Icons.calendar_month_outlined,
        title: 'My Bookings',
        subtitle: 'View and manage your appointments',
        onTap: () => Navigator.pushNamed(context, '/appointments'),
      ),
      const SizedBox(height: 10),
      _ProfileActionTile(
        icon: Icons.favorite_border_rounded,
        title: 'My Favorites',
        subtitle: 'Saved salons and services',
        onTap: () => Navigator.pushNamed(context, '/favorites'),
      ),
      const SizedBox(height: 10),
      _ProfileActionTile(
        icon: Icons.credit_card_outlined,
        title: 'Payment Methods',
        subtitle: 'Manage cards and wallets',
        onTap: () => Navigator.pushNamed(context, '/transactions'),
      ),
    ],
  );
}

class _VendorProfileContent extends StatelessWidget {
  const _VendorProfileContent({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ProfileSectionTitle(
        icon: Icons.storefront_rounded,
        title: 'Business Information',
        onEdit: () => Navigator.pushNamed(context, '/profile/edit'),
      ),
      const SizedBox(height: 10),
      _ProfileInfoCard(
        rows: [
          _ProfileInfoData(
            Icons.storefront_outlined,
            'Business Name',
            state.name,
          ),
          _ProfileInfoData(Icons.mail_outline_rounded, 'Email', state.email),
          _ProfileInfoData(Icons.phone_outlined, 'Phone', state.phone),
          _ProfileInfoData(
            Icons.location_on_outlined,
            'Address',
            state.address,
          ),
          _ProfileInfoData(
            Icons.access_time_rounded,
            'Business Hours',
            state.dates.isEmpty
                ? 'Not configured'
                : '${state.dates.length} days · ${state.slots.length} slots',
          ),
        ],
        onEdit: () => Navigator.pushNamed(context, '/profile/edit'),
      ),
      const SizedBox(height: 16),
      _ProfileActionTile(
        icon: Icons.content_cut_rounded,
        title: 'My Services',
        subtitle: 'Manage salon services and prices',
        onTap: () => Navigator.pushNamed(context, '/vendor/services'),
      ),
      const SizedBox(height: 10),
      _ProfileActionTile(
        icon: Icons.photo_library_outlined,
        title: 'Gallery',
        subtitle: 'Photos and portfolio',
        onTap: () => Navigator.pushNamed(context, '/vendor/upload'),
      ),
      const SizedBox(height: 10),
      _ProfileActionTile(
        icon: Icons.rate_review_outlined,
        title: 'Reviews & Ratings',
        subtitle: 'See customer feedback and your rating',
        onTap: () => Navigator.pushNamed(context, '/vendor/reviews'),
      ),
      const SizedBox(height: 10),
      _ProfileActionTile(
        icon: Icons.groups_rounded,
        title: 'Staff Management',
        subtitle: 'Manage your team and barbers',
        onTap: () => toast(
          context,
          'Staff management will be available when team profiles are connected.',
        ),
      ),
      const SizedBox(height: 10),
      _ProfileActionTile(
        icon: Icons.schedule_rounded,
        title: 'Availability',
        subtitle: 'Manage dates and time slots',
        onTap: () => Navigator.pushNamed(context, '/vendor/availability'),
      ),
    ],
  );
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({
    required this.icon,
    required this.title,
    required this.onEdit,
  });
  final IconData icon;
  final String title;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Palette.orchid, size: 25),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      TextButton(
        onPressed: onEdit,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Edit',
          style: TextStyle(
            color: Palette.orchid,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _ProfileInfoData {
  const _ProfileInfoData(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.rows, required this.onEdit});
  final List<_ProfileInfoData> rows;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF11172D)
          : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Palette.purple.withValues(alpha: .18)),
    ),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  Icon(rows[i].icon, color: Palette.orchid, size: 22),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 98,
                    child: Text(
                      rows[i].label,
                      style: const TextStyle(
                        color: Palette.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: rows[i].label == 'Full Name'
                        ? Text.rich(
                            TextSpan(
                              text: rows[i].value.trim().isEmpty
                                  ? 'Not added'
                                  : '${rows[i].value} ',
                              style: const TextStyle(fontSize: 11.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          )
                        : Text(
                            rows[i].value.trim().isEmpty
                                ? 'Not added'
                                : rows[i].value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 11.5),
                          ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Palette.muted,
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
          if (i != rows.length - 1)
            Divider(
              height: 1,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white10
                  : Palette.ink.withValues(alpha: .08),
            ),
        ],
      ],
    ),
  );
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = Palette.orchid,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF11172D)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.purple.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Palette.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Palette.muted),
        ],
      ),
    ),
  );
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  double? locationLatitude, locationLongitude;
  String? locatedAddress;
  final form = GlobalKey<FormState>();

  late final name = TextEditingController(
    text: context.read<AppBloc>().state.name,
  );
  late final email = TextEditingController(
    text:
        context.read<AppBloc>().liveVendor &&
            context.read<AppBloc>().state.isVendor
        ? context.read<AppBloc>().state.phone
        : context.read<AppBloc>().state.email,
  );
  late final address = TextEditingController(
    text: context.read<AppBloc>().state.address,
  );
  late final phone = TextEditingController(
    text: context.read<AppBloc>().state.phone,
  );
  late final bio = TextEditingController(
    text: context.read<AppBloc>().state.bio,
  );

  late String selectedGender;
  late String? selectedAvatar;
  late Uint8List? selectedBytes;
  bool isAvatarCleared = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppBloc>().state;
    selectedGender = s.gender;
    selectedAvatar = s.avatar;
    selectedBytes = s.avatarBytes;
    locationLatitude = s.latitude;
    locationLongitude = s.longitude;
    if (s.latitude != null && s.longitude != null) locatedAddress = s.address;
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    address.dispose();
    phone.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> _openPhotoOptions() async {
    final state = context.read<AppBloc>().state;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final dark = Theme.of(sheetContext).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF140D24) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Palette.muted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Palette.purple.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Palette.purple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Picture',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Upload from your device or choose a salon avatar',
                            style: TextStyle(
                              fontSize: 11,
                              color: Palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Camera and Gallery buttons
                Row(
                  children: [
                    Expanded(
                      child: _UploadOptionCard(
                        icon: Icons.camera_alt_outlined,
                        title: 'Take Photo',
                        subtitle: 'Use camera',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UploadOptionCard(
                        icon: Icons.photo_library_outlined,
                        title: 'Gallery',
                        subtitle: 'From photos',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Salon Avatar Presets
                Row(
                  children: [
                    const Text(
                      'SALON AVATARS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Palette.muted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Theme.of(sheetContext).dividerColor
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 84,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _AvatarPresetItem(
                        name: 'barber',
                        label: 'Barber',
                        selected:
                            !isAvatarCleared &&
                            selectedBytes == null &&
                            (selectedAvatar == 'barber' ||
                                (selectedAvatar == null && state.isVendor)),
                        onTap: () => _selectPreset('barber', sheetContext),
                      ),
                      _AvatarPresetItem(
                        name: 'portrait',
                        label: 'Gentleman',
                        selected:
                            !isAvatarCleared &&
                            selectedBytes == null &&
                            (selectedAvatar == 'portrait' ||
                                (selectedAvatar == null && !state.isVendor)),
                        onTap: () => _selectPreset('portrait', sheetContext),
                      ),
                      _AvatarPresetItem(
                        name: 'hair',
                        label: 'Haircut',
                        selected:
                            !isAvatarCleared &&
                            selectedBytes == null &&
                            selectedAvatar == 'hair',
                        onTap: () => _selectPreset('hair', sheetContext),
                      ),
                      _AvatarPresetItem(
                        name: 'cutting_beard',
                        label: 'Beard Trim',
                        selected:
                            !isAvatarCleared &&
                            selectedBytes == null &&
                            selectedAvatar == 'cutting_beard',
                        onTap: () =>
                            _selectPreset('cutting_beard', sheetContext),
                      ),
                      _AvatarPresetItem(
                        name: 'cleaning_face',
                        label: 'Facial Spa',
                        selected:
                            !isAvatarCleared &&
                            selectedBytes == null &&
                            selectedAvatar == 'cleaning_face',
                        onTap: () =>
                            _selectPreset('cleaning_face', sheetContext),
                      ),
                      _AvatarPresetItem(
                        name: 'salon',
                        label: 'Studio',
                        selected:
                            !isAvatarCleared &&
                            selectedBytes == null &&
                            selectedAvatar == 'salon',
                        onTap: () => _selectPreset('salon', sheetContext),
                      ),
                      _AvatarPresetItem(
                        name: 'beauty',
                        label: 'Stylist',
                        selected:
                            !isAvatarCleared &&
                            selectedBytes == null &&
                            selectedAvatar == 'beauty',
                        onTap: () => _selectPreset('beauty', sheetContext),
                      ),
                      _AvatarPresetItem(
                        name: 'bride',
                        label: 'Bridal',
                        selected:
                            !isAvatarCleared &&
                            selectedBytes == null &&
                            selectedAvatar == 'bride',
                        onTap: () => _selectPreset('bride', sheetContext),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Reset / Remove photo option if customized
                if (selectedBytes != null ||
                    (selectedAvatar != null && selectedAvatar!.isNotEmpty)) ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Palette.pink,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      setState(() {
                        selectedBytes = null;
                        selectedAvatar = null;
                        isAvatarCleared = true;
                      });
                      toast(
                        context,
                        'Photo reset to default. Tap Save to apply.',
                      );
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text(
                      'Reset to Default Avatar',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectPreset(String preset, BuildContext sheetContext) {
    Navigator.pop(sheetContext);
    setState(() {
      selectedAvatar = preset;
      selectedBytes = null;
      isAvatarCleared = false;
    });
    toast(context, 'Avatar preset selected! Tap Save to keep.');
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 88,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;
      if (!mounted) return;
      setState(() {
        selectedBytes = bytes;
        selectedAvatar = null;
        isAvatarCleared = false;
      });
      toast(context, 'Photo chosen! Tap Save to keep changes.');
    } catch (_) {
      if (mounted) {
        toast(
          context,
          source == ImageSource.camera
              ? 'Camera is not accessible. Please choose from gallery or presets.'
              : 'Photo library is not accessible. Please choose from presets.',
        );
      }
    }
  }

  Future<void> _openMapPicker() async {
    FocusScope.of(context).unfocus();
    final picked = await showLocationPicker(
      context,
      latitude: locationLatitude,
      longitude: locationLongitude,
      address: address.text.trim(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      address.text = picked.address;
      locatedAddress = picked.address;
      locationLatitude = picked.latitude;
      locationLongitude = picked.longitude;
    });
    toast(context, 'Location set on map 📍');
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    final saved = await saveAction(
      context,
      SaveProfile(
        name.text.trim(),
        email.text.trim(),
        address.text.trim(),
        phone: phone.text.trim(),
        bio: bio.text.trim(),
        gender: selectedGender,
        avatar: isAvatarCleared ? '' : selectedAvatar,
        avatarBytes: isAvatarCleared ? null : selectedBytes,
        clearAvatar: isAvatarCleared,
        isPublic: true,
        latitude: locatedAddress == address.text.trim()
            ? locationLatitude
            : null,
        longitude: locatedAddress == address.text.trim()
            ? locationLongitude
            : null,
      ),
    );
    if (!saved) return;
    if (mounted) {
      toast(context, 'Profile updated successfully! ✨');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<AppBloc>();
    final liveVendor = bloc.liveVendor;
    final isVendor = bloc.state.isVendor;

    return Screen(
      title: 'Edit Profile',
      actions: [
        IconButton(
          tooltip: 'Save',
          icon: const Icon(Icons.check_rounded, color: Palette.gold),
          onPressed: _save,
        ),
      ],
      bottom: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: AppButton(
            'Save',
            icon: Icons.check_circle_outline_rounded,
            onTap: _save,
          ),
        ),
      ),
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Centered Photo with camera edit badge
            Center(
              child: Column(
                children: [
                  ProfileAvatar(
                    avatar: isAvatarCleared ? '' : selectedAvatar,
                    bytes: isAvatarCleared ? null : selectedBytes,
                    isVendor: isVendor,
                    size: 104,
                    borderWidth: 3.5,
                    showEditBadge: true,
                    badgeIcon: Icons.camera_alt_rounded,
                    onTap: _openPhotoOptions,
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _openPhotoOptions,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            size: 15,
                            color: Palette.gold,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Change Photo',
                            style: TextStyle(
                              color: Palette.gold,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 15,
                            color: Palette.gold,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selectedBytes != null ||
                      (selectedAvatar != null &&
                          selectedAvatar != bloc.state.avatar)) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Palette.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Palette.green.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 12,
                            color: Palette.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'New photo ready to save',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Palette.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: Personal Details Card
            _FormSectionHeader(
              title: isVendor ? 'SALON INFORMATION' : 'PERSONAL INFORMATION',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 8),
            Surface(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: name,
                    validator: requiredField,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: isVendor ? 'Salon / Barber Name' : 'Full Name',
                      hintText: isVendor ? 'Danial Willam' : 'Josh Jakarta',
                      prefixIcon: const Icon(
                        Icons.person_rounded,
                        color: Palette.purple,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: email,
                    readOnly: liveVendor && isVendor,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (liveVendor && isVendor) ||
                            (v != null && v.contains('@') && v.contains('.'))
                        ? null
                        : 'Enter a valid email address',
                    decoration: InputDecoration(
                      labelText: liveVendor && isVendor
                          ? 'Verified Phone / Account'
                          : 'Email Address',
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Palette.purple,
                        size: 20,
                      ),
                      suffixIcon: liveVendor && isVendor
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Palette.green,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: Palette.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone',
                      hintText: '+1 (555) 000-0000',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: Palette.purple,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Location Card
            _FormSectionHeader(
              title: isVendor ? 'STUDIO LOCATION' : 'YOUR ADDRESS',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 8),
            Surface(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('profile_address_field'),
                    controller: address,
                    validator: requiredField,
                    readOnly: true,
                    onTap: _openMapPicker,
                    maxLines: 2,
                    minLines: 1,
                    decoration: InputDecoration(
                      labelText: isVendor
                          ? 'Salon / Studio Address'
                          : 'Default Address',
                      hintText: 'Tap to search or pick on map',
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: Palette.purple,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Pick on map',
                        icon: const Icon(
                          Icons.map_outlined,
                          color: Palette.gold,
                          size: 20,
                        ),
                        onPressed: _openMapPicker,
                      ),
                    ),
                  ),
                  if (locationLatitude != null &&
                      locationLongitude != null &&
                      locatedAddress == address.text.trim()) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: Palette.green,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Pinned on map — customers will see the exact spot',
                            style: TextStyle(
                              fontSize: 11,
                              color: Palette.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: About & Specialty Card
            _FormSectionHeader(
              title: isVendor ? 'ABOUT SALON & SERVICES' : 'ABOUT & STYLE',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 8),
            Surface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: bio,
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      labelText: isVendor
                          ? 'Salon Bio & Description'
                          : 'Personal Style Notes',
                      hintText: isVendor
                          ? 'Certified barber specializing in fades, beard shaping, and luxury hot towel trims.'
                          : 'Prefer classic scissor cut with low taper fade and beard trim.',
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: Palette.purple,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Preferred Category / Audience',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Palette.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Male', 'Female', 'All / Unisex'].map((gender) {
                      final isSelected = selectedGender == gender;
                      return ChoiceChip(
                        label: Text(
                          gender,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Palette.purple,
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => selectedGender = gender);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            if (isVendor && liveVendor)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Your salon is automatically listed for customers. Saved services and portfolio photos appear on your salon page.',
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Palette.gold),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Palette.gold,
          ),
        ),
      ],
    ),
  );
}

class _UploadOptionCard extends StatelessWidget {
  const _UploadOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1430) : Palette.canvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF3B2555) : const Color(0xFFE2DDEC),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Palette.purple, Palette.orchid],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Palette.purple.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPresetItem extends StatelessWidget {
  const _AvatarPresetItem({
    required this.name,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Palette.gold : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Photo(name, width: 48, height: 48, radius: 26),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Palette.gold : Palette.muted,
            ),
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
    if (bloc.state.isVendor) {
      final notifications = bloc.state.notifications;
      return Screen(
        title: 'Notifications',
        subtitle: bloc.liveVendor
            ? 'Updates for your salon and customers'
            : 'Vendor notifications are available in live account mode.',
        onRefresh: () => bloc.refreshAll(),
        child: notifications.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    'New bookings and customer messages will appear here.',
                    icon: Icons.notifications_none_outlined,
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(22),
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final message = notification.kind == 'message';
                  return Surface(
                    padding: const EdgeInsets.all(15),
                    onTap: () {
                      if (!notification.isRead) {
                        bloc.add(MarkVendorNotificationRead(notification.id));
                      }
                      if (notification.appointmentId != null) {
                        Navigator.pushNamed(
                          context,
                          message ? '/chat' : '/appointments',
                          arguments: message
                              ? notification.appointmentId
                              : null,
                        );
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          message
                              ? Icons.chat_bubble_outline
                              : Icons.event_available_outlined,
                          color: Palette.purple,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.body,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Palette.muted,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _notificationTimestamp(notification.createdAt),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Palette.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!notification.isRead)
                          const Padding(
                            padding: EdgeInsets.only(top: 5, left: 8),
                            child: Icon(
                              Icons.circle,
                              color: Palette.purple,
                              size: 8,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      );
    }
    final bookings = bloc.state.appointments
        .where((a) => !bloc.state.isVendor || a.salonId == bloc.state.salonId)
        .toList();
    return Screen(
      title: 'Notifications',
      onRefresh: () => bloc.refreshAll(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(22),
        children: [
          if (bookings.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: EmptyState('You’re all caught up.'),
            ),
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

String _notificationTimestamp(DateTime time) =>
    '${time.month}/${time.day}/${time.year} · ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key, this.detail});
  final Appointment? detail;
  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<AppBloc>();
    final records = bloc.state.appointments
        .where((a) => (!bloc.state.isVendor || a.salonId == bloc.state.salonId))
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
  Widget build(BuildContext context) {
    final state = context.watch<AppBloc>().state;
    final isDark = state.isDark;
    return Screen(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: Palette.purple,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Appearance',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose the look that feels right. It updates the whole app.',
                  style: TextStyle(color: Palette.muted, fontSize: 12.5),
                ),
                const SizedBox(height: 14),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {state.themeMode},
                  onSelectionChanged: (selection) => context
                      .read<AppBloc>()
                      .add(SetThemeMode(selection.first)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Surface(
            onTap: () =>
                Navigator.pushNamed(context, '/splash', arguments: 'preview'),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.play_circle_outline_rounded,
                color: Palette.gold,
              ),
              title: Text('Replay Splash Screen'),
              subtitle: Text(
                'Experience luxury brand intro & animations',
                style: TextStyle(fontSize: 11, color: Palette.muted),
              ),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: 16),
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
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.read<AppBloc>().liveVendor &&
                          context.read<AppBloc>().state.isVendor
                      ? 'Vendor account'
                      : 'Demo environment',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10),
                Text(
                  context.read<AppBloc>().liveVendor &&
                          context.read<AppBloc>().state.isVendor
                      ? 'Your salon changes are saved to your account. Use Refresh on the home screen to load the latest appointments and messages.'
                      : 'Changes are stored in memory while the app is open. Restarting restores the demo.',
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
            'Discover salons, plan your next appointment and explore your personal style.\n\nVendor accounts support SMS verification and cloud storage. Customer booking, payments and camera hairstyle rendering remain previews.',
            style: TextStyle(height: 1.8, color: Palette.muted),
          ),
        ],
      ),
    ),
  );
}
