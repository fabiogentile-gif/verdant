import 'package:flutter/material.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/search_field.dart';
import 'package:verdant/shell.dart';
import 'package:verdant/widgets/components/page_header.dart';
import 'package:verdant/widgets/components/personal_collection.dart';
import 'package:verdant/widgets/components/search_bar.dart';
import 'package:verdant/widgets/homepage/category_filter.dart';
import 'package:verdant/widgets/homepage/featured_products.dart' as fp;
import 'package:verdant/widgets/homepage/seasonal_card.dart';
import 'package:verdant/widgets/homepage/upcoming_care.dart';

import 'package:verdant/data/product_repository.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selected = 0;
  late Future<List<fp.Product>> _featured;

  @override
  void initState() {
    super.initState();
    _featured = _loadFeatured();
  }

  Future<List<fp.Product>> _loadFeatured() async {
    final list = await productRepository.getFeaturedProducts();
    return list
        .take(2)
        .map(
          (p) => fp.Product(
            id: p.id,
            name: p.name,
            price:
                '\$${p.price % 1 == 0 ? p.price.toStringAsFixed(0) : p.price.toStringAsFixed(2)}',
            tag: p.tag ?? '',
            image: imageFor(p.image),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar.home(hasUnread: false, onActionTap: () {}),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader.eyebrowDate(
                DateTime.now(),
                title: 'A little greener, Maya.',
                subtitle: 'Good things grow with a little care.',
              ),
              const SizedBox(height: 28),
              const AppSearchField(hintText: 'Find your next green companion'),
              const SizedBox(height: 28),
              const SeasonalFeatureCard(),
              const SizedBox(height: 28),
              PopularCategories(
                selectedIndex: _selected,
                onSelected: (i) => setState(() => _selected = i),
              ),
              const SizedBox(height: 28),
              FutureBuilder<List<fp.Product>>(
                future: _featured,
                builder: (context, snap) {
                  if (snap.hasError) return const SizedBox.shrink();
                  if (!snap.hasData) {
                    return const SizedBox(
                      height: 240,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return fp.FeaturedProducts(
                    products: snap.data!,
                    onProductTap: (product) => Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed(AppRoutes.productPath(product.id)),
                    onShopAll: () =>
                        AppShell.of(context)?.goTotab(AppRoutes.greenhouse),
                  );
                },
              ),
              const SizedBox(height: 28),
              PersonalCollection(
                plantName: 'Monstera',
                plantSubtitle: 'Living room · Monstera deliciosa',
                plantImage: const AssetImage(
                  'assets/images/owned/monstera_deliciosa.png',
                ),
                statusLabel: 'Needs water',
                scheduleLabel: 'Water today · 9:00 AM',
                collectionLabel: '4 plants, one happy home',
                onSeeAll: () => AppShell.of(context)?.goTotab(AppRoutes.plants),
                onPlantTap: () {},
                onCollectionTap: () =>
                    AppShell.of(context)?.goTotab(AppRoutes.plants),
              ),
              const SizedBox(height: 28),
              UpcomingCare(
                onViewAll: () {},
                reminders: const [
                  CareReminder(
                    title: 'Water Monstera',
                    schedule: 'Today · 9:00 AM',
                  ),
                  CareReminder(
                    title: 'Water Rubber Plant',
                    schedule: 'Sun, Nov 8 · 9:00 AM',
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
