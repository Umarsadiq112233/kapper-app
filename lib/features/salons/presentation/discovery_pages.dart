import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/app_bloc.dart';
import '../../../domain/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared.dart';

class SalonCard extends StatelessWidget {
  const SalonCard(this.salon, {super.key, this.compact = false});
  final Salon salon;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final favorite = context.watch<AppBloc>().state.favorites.contains(
      salon.id,
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          salon.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(
          salon.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 8, color: Palette.muted),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(Icons.star, size: 11, color: Palette.gold),
            Text(' ${salon.rating}', style: const TextStyle(fontSize: 9)),
            const SizedBox(width: 4),
            const Icon(Icons.location_on_outlined, size: 10),
            Expanded(
              child: Text(
                '${salon.distance} km away',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 8),
              ),
            ),
          ],
        ),
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
    return SafeArea(
      child: Entrance(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Brand(size: 30),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: const Photo(
                            'portrait',
                            width: 34,
                            height: 34,
                            radius: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello ${bloc.state.name.split(' ').first}',
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                dateLabel(
                                  DateTime.now().toIso8601String().substring(
                                    0,
                                    10,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Notifications',
                          onPressed: () =>
                              Navigator.pushNamed(context, '/notifications'),
                          icon: const Icon(Icons.notifications_none_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Nearby Saloons',
                            style: TextStyle(
                              color: Palette.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Search and filters',
                          onPressed: () =>
                              Navigator.pushNamed(context, '/search'),
                          icon: const Icon(Icons.tune, size: 21),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: .81,
                ),
                itemCount: bloc.repository.salons.length,
                itemBuilder: (_, index) =>
                    SalonCard(bloc.repository.salons[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key, this.favoritesOnly = false});
  final bool favoritesOnly;
  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, view) {
      final bloc = context.watch<AppBloc>();
      final query = view.get('query', '').toLowerCase();
      final salons = bloc.repository.salons
          .where(
            (s) =>
                (!favoritesOnly || bloc.state.favorites.contains(s.id)) &&
                s.name.toLowerCase().contains(query) &&
                s.distance <= view.get('distance', 20.0) &&
                bloc
                    .servicesFor(s.id)
                    .any(
                      (service) => service.price <= view.get('price', 200.0),
                    ),
          )
          .toList();
      if (favoritesOnly) {
        return Screen(
          title: 'My Favorites',
          subtitle: 'Find your favorite saloons here',
          child: salons.isEmpty
              ? const EmptyState(
                  'Save a salon with the heart to find it here.',
                  icon: Icons.favorite_border,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: .81,
                  ),
                  itemCount: salons.length,
                  itemBuilder: (_, i) => SalonCard(salons[i]),
                ),
        );
      }
      return Screen(
        title: favoritesOnly ? 'My Favorites' : 'Search',
        subtitle: favoritesOnly
            ? 'Find your favorite saloons here'
            : 'Search your favorite Saloon',
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          children: [
            if (!favoritesOnly) ...[
              TextField(
                onChanged: (v) => change(context, 'query', v),
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: IconButton(
                    tooltip: 'Filters',
                    icon: const Icon(Icons.tune, size: 20),
                    onPressed: () async {
                      final result = await modal<Map<String, double>>(
                        context,
                        FilterDialog(
                          price: view.get('price', 200.0),
                          distance: view.get('distance', 20.0),
                        ),
                      );
                      if (result != null && context.mounted) {
                        change(context, 'price', result['price']);
                        change(context, 'distance', result['distance']);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${salons.length} saloons nearby',
                style: const TextStyle(color: Palette.muted, fontSize: 11),
              ),
              const SizedBox(height: 14),
            ],
            if (salons.isEmpty)
              const EmptyState(
                'No salons found. Try another search or reset your filters.',
              ),
            ...salons.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SalonCard(s, compact: true),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key, required this.price, required this.distance});
  final double price, distance;
  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  final form = GlobalKey<FormState>();
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
              const Expanded(
                child: TextField(
                  enabled: false,
                  decoration: InputDecoration(hintText: '0', suffixText: 'min'),
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
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Filters', style: TextStyle(fontSize: 24)),
        const SizedBox(height: 26),
        range('By Price:', price, 'max'),
        const SizedBox(height: 24),
        range('By Distance:', distance, 'km'),
        const SizedBox(height: 26),
        AppButton(
          'Apply Filter',
          onTap: () {
            if (form.currentState!.validate()) {
              Navigator.pop(context, {
                'price': double.parse(price.text),
                'distance': double.parse(distance.text),
              });
            }
          },
        ),
        TextButton(
          onPressed: () {
            price.text = '200';
            distance.text = '20';
          },
          child: const Text('Reset filters'),
        ),
      ],
    ),
  );
}
