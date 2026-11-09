import 'package:flutter/material.dart';
import 'package:verdant/search_field.dart';
import 'package:verdant/widgets/components/page_header.dart';
import 'package:verdant/widgets/components/search_bar.dart';
import 'package:verdant/widgets/homepage/category_filter.dart';
import 'package:verdant/widgets/homepage/featured_products.dart';
import 'package:verdant/widgets/homepage/seasonal_card.dart';

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
      body: SingleChildScrollView(
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
              products: const [
                Product(
                  name: 'Monstera deliciosa',
                  price: '\$38',
                  tag: 'Bestseller',
                  image: AssetImage('assets/images/products/product_monstera_deliciosa.png'),
                ),
                Product(
                  name: 'Sandstone pot',
                  price: '\$24',
                  tag: 'Hand-finished',
                  image: AssetImage('assets/images/products/product_sandstone_pot.png'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
