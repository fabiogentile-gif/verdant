import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/search_field.dart';
import 'package:verdant/widgets/components/filter_chip.dart';
import 'package:verdant/widgets/components/page_header.dart';
import 'package:verdant/widgets/components/product_card.dart';
import 'package:verdant/widgets/components/search_bar.dart';

class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.tag,
  });

  final String id;
  final String name;
  final String price;
  final ImageProvider image;
  final String? tag;
}

class Greenhouse extends StatefulWidget {
  const Greenhouse({super.key});

  @override
  State<Greenhouse> createState() => _GreenhouseState();
}

class _GreenhouseState extends State<Greenhouse> {
  int _categoryIndex = 0;
  final Set<String> _favorites = {};

  static const _categories = [
    'All',
    'Indoor Plants',
    'Outdoor Plants',
    'Pots',
    'Soil',
    'Fertilizers',
    'Accessories',
  ];

  static const _favoriteProducts = [
    ShopProduct(
      id: 'monstera',
      name: 'Monstera deliciosa',
      price: '\$38',
      tag: 'Bestseller',
      image: AssetImage(
        'assets/images/products/product_monstera_deliciosa.png',
      ),
    ),
    ShopProduct(
      id: 'rubber-plant',
      name: 'Rubber plant',
      price: '\$32',
      tag: 'Easy care',
      image: AssetImage('assets/images/products/product_rubber_plant.png'),
    ),
    ShopProduct(
      id: 'sandstone-pot',
      name: 'Sandstone pot',
      price: '\$24',
      image: AssetImage('assets/images/products/product_sandstone_pot.png'),
    ),
    ShopProduct(
      id: 'white-orchid',
      name: 'White orchid',
      price: '\$42',
      tag: 'In bloom',
      image: AssetImage('assets/images/products/product_white_orchid.png'),
    ),
  ];

  static const _recommendedProducts = [
    ShopProduct(
      id: 'potting-mix',
      name: 'Organic potting mix',
      price: '\$12',
      image: AssetImage(
        'assets/images/products/product_organic_potting_mix.png',
      ),
    ),
    ShopProduct(
      id: 'watering-set',
      name: 'Watering ritual set',
      price: '\$46',
      image: AssetImage(
        'assets/images/products/product_watering_ritual_set.png',
      ),
    ),
  ];

  void _toggleFavorite(String id) {
    setState(() {
      if (!_favorites.remove(id)) _favorites.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: 'The greenhouse',
        actionIcon: LucideIcons.shoppingBag,
        onActionTap: () {},
      ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: 'Room to grow.',
                subtitle: 'Thoughtfully grown plants and beautiful things to help them thrive.',
              ),
              const SizedBox(height: 24),
              const AppSearchField(
                hintText: 'Search plants, pots & essentials',
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 9,
                children: [
                  for (int i = 0; i < _categories.length; i++)
                    AppFilterChip(
                      label: _categories[i],
                      selected: _categoryIndex == i,
                      onTap: () => setState(() => _categoryIndex = i),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _FeaturedCollection(onTap: () {}),
              const SizedBox(height: 24),
              const _SectionHeading('The greenhouse favorites'),
              const SizedBox(height: 16),
              const _SortAndFilter(countLabel: '24 thoughtfully chosen finds'),
              const SizedBox(height: 16),
              _ProductGrid(
                products: _favoriteProducts,
                favorites: _favorites,
                onFavoriteTap: _toggleFavorite,
              ),
              const SizedBox(height: 24),
              const _SectionHeading('Good for your jungle'),
              const SizedBox(height: 16),
              const _SectionSubtitle(
                'A few essentials for your Monstera and friends.',
              ),
              const SizedBox(height: 16),
              _ProductGrid(
                products: _recommendedProducts,
                favorites: _favorites,
                onFavoriteTap: _toggleFavorite,
              ),
              const SizedBox(height: 24),
              const _DeliveryNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontFamily: 'Lora',
        fontSize: 23,
        letterSpacing: -0.5,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _SectionSubtitle extends StatelessWidget {
  const _SectionSubtitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.5,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _FeaturedCollection extends StatelessWidget {
  const _FeaturedCollection({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE EASY-GROW EDIT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Start small. Grow wild.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Meet your first plant →',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: const Image(
                image: AssetImage('assets/images/products/easy_grow_edit.png'),
                width: 104,
                height: 110,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortAndFilter extends StatelessWidget {
  const _SortAndFilter({required this.countLabel});

  final String countLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          countLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Row(
          children: [
            Icon(
              LucideIcons.slidersHorizontal,
              size: 18,
              color: scheme.onSurface,
            ),
            const SizedBox(width: 14),
            Text(
              'Featured',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 13, color: scheme.onSurface),
          ],
        ),
      ],
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.favorites,
    required this.onFavoriteTap,
  });

  final List<ShopProduct> products;
  final Set<String> favorites;
  final ValueChanged<String> onFavoriteTap;

  Widget _card(BuildContext context, ShopProduct p) {
    return ProductCard(
      name: p.name,
      price: p.price,
      image: p.image,
      tag: p.tag,
      isFavorite: favorites.contains(p.id),
      onFavoriteTap: () => onFavoriteTap(p.id),
      onAddTap: () {},
      onTap: () => Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed(AppRoutes.productDetails, arguments: p.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (int i = 0; i < products.length; i += 2) {
      final second = i + 1 < products.length ? products[i + 1] : null;
      if (i > 0) rows.add(const SizedBox(height: 16));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _card(context,products[i])),
            const SizedBox(width: 14),
            Expanded(
              child: second != null ? _card(context,second) : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    return Column(children: rows);
  }
}

class _DeliveryNote extends StatelessWidget {
  const _DeliveryNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.truck, size: 20, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Grown with care. Delivered with love. Free shipping on orders \$100+.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                height: 1.5,
                color: scheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
