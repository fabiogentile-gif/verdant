import 'package:flutter/material.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/search_field.dart';
import 'package:verdant/shell.dart';
import 'package:verdant/widgets/components/page_header.dart';
import 'package:verdant/widgets/components/personal_collection.dart';
import 'package:verdant/widgets/components/search_bar.dart';
import 'package:verdant/widgets/homepage/category_filter.dart';
import 'package:verdant/widgets/homepage/featured_products.dart';
import 'package:verdant/widgets/homepage/seasonal_card.dart';
import 'package:verdant/widgets/homepage/upcoming_care.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selected = 0;

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
              FeaturedProducts(
                onProductTap: (product) => Navigator.of(context,rootNavigator: true).pushNamed(AppRoutes.productDetails,arguments: product.id),
                onShopAll: () => AppShell.of(context)?.goTotab(AppRoutes.plants),
                products: const [
                  Product(
                    id: 'monstera',
                    name: 'Monstera deliciosa',
                    price: '\$38',
                    tag: 'Bestseller',
                    image: AssetImage(
                      'assets/images/products/product_monstera_deliciosa.png',
                    ),
                  ),
                  Product(
                    id: 'sandstone-pot',
                    name: 'Sandstone pot',
                    price: '\$24',
                    tag: 'Hand-finished',
                    image: AssetImage(
                      'assets/images/products/product_sandstone_pot.png',
                    ),
                  ),
                ],
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
                onCollectionTap: () => AppShell.of(context)?.goTotab(AppRoutes.plants),
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
