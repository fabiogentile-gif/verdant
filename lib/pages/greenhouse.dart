import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/widgets/components/standard_app_bar.dart';
import 'package:verdant/widgets/components/filter_chip.dart';
import 'package:verdant/widgets/components/page_header.dart';
import 'package:verdant/widgets/components/product_card.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';
import 'package:verdant/widgets/components/search_bar.dart';

import 'package:verdant/data/cart.dart';
import 'package:verdant/data/favorites.dart';
import 'package:verdant/data/shop_filter.dart';
import 'package:verdant/utils/money.dart';
import 'package:verdant/data/product_repository.dart';
import 'package:verdant/pages/cart.dart' show showAddedToCart;
import 'package:verdant/models/product.dart';
import 'package:verdant/l10n/i18n.dart';

/// Shop tab: search, categories, sorting and the product grid.
class Greenhouse extends StatefulWidget {
  const Greenhouse({super.key});

  @override
  State<Greenhouse> createState() => _GreenhouseState();
}

/// Loads the catalogue once and applies [shopFilter] to it.
class _GreenhouseState extends State<Greenhouse> {
  late Future<List<ProductSummary>> _products;
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _products = productRepository.getProducts();
    _search = TextEditingController(text: shopFilter.query);
    shopFilter.addListener(_syncSearch);
  }

  @override
  void dispose() {
    shopFilter.removeListener(_syncSearch);
    _search.dispose();
    super.dispose();
  }

  /// Keeps the field in sync when another page sets the query.
  void _syncSearch() {
    if (_search.text != shopFilter.query) _search.text = shopFilter.query;
  }

  void _reload() {
    final repo = productRepository;
    if (repo is ApiProductRepository) repo.clearCache();
    setState(() => _products = productRepository.getProducts());
  }

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<ShopSort>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final s in ShopSort.values)
                  ListTile(
                    title: Text(s.label),
                    trailing: s == shopFilter.sort
                        ? Icon(
                            LucideIcons.check,
                            size: 18,
                            color: scheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(s),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) shopFilter.sort = picked;
  }

  Future<void> _openFilters() {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => ListenableBuilder(
        listenable: shopFilter,
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text('In stock only'.tr),
                  value: shopFilter.inStockOnly,
                  onChanged: (v) => shopFilter.inStockOnly = v,
                ),
                SwitchListTile(
                  title: Text('My favourites only'.tr),
                  value: shopFilter.favoritesOnly,
                  onChanged: (v) => shopFilter.favoritesOnly = v,
                ),
                TextButton(
                  onPressed: () {
                    shopFilter.clear();
                    Navigator.of(context).pop();
                  },
                  child: Text('Clear all filters'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([shopFilter, favorites, cart]),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: 'The greenhouse'.tr,
        actionIcon: LucideIcons.shoppingBag,
        actionLabel: 'Your cart'.tr,
        badgeCount: cart.itemCount,
        onActionTap: () => pushRoot(context, AppRoutes.cart),
      ),
      body: ScrollViewNoStretch(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Room to grow.'.tr,
              subtitle: 'Thoughtfully grown plants and beautiful things to help them thrive.'
                  .tr,
            ),
            const SizedBox(height: 24),
            AppSearchField(
              controller: _search,
              hintText: 'Search plants, pots & essentials'.tr,
              onChanged: (v) => shopFilter.query = v,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 9,
              children: [
                for (final c in ShopCategory.values)
                  AppFilterChip(
                    label: c.label,
                    selected: shopFilter.category == c,
                    onTap: () => shopFilter.category = c,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            _FeaturedCollection(
              onTap: () => shopFilter.show(query: 'Easy care'.tr),
            ),
            const SizedBox(height: 24),
            const _DeliveryNote(),
            const SizedBox(height: 24),
            FutureBuilder<List<ProductSummary>>(
              future: _products,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  final error = snap.error;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Text(
                          error is ProductLoadException
                              ? error.message
                              : 'Couldn’t load products.'.tr,
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: _reload,
                          child: Text('Try again'.tr),
                        ),
                      ],
                    ),
                  );
                }
                final all = snap.data!;
                final visible = shopFilter.apply(
                  all,
                  favoriteIds: favorites.ids,
                );
                final controls = _SortAndFilter(
                  countLabel: shopFilter.isActive
                      ? trArgs('{0} of {1} finds', [visible.length, all.length])
                      : trArgs('{0} thoughtfully chosen finds', [all.length]),
                  sortLabel: shopFilter.sort.label,
                  activeFilters: shopFilter.extraFilterCount,
                  onSort: _pickSort,
                  onFilter: _openFilters,
                );

                if (shopFilter.isActive) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionHeading(
                        shopFilter.query.trim().isNotEmpty
                            ? trArgs('Results for “{0}”', [
                                shopFilter.query.trim(),
                              ])
                            : shopFilter.category.label,
                      ),
                      const SizedBox(height: 16),
                      controls,
                      const SizedBox(height: 16),
                      if (visible.isEmpty)
                        _EmptyResults(onClear: shopFilter.clear)
                      else
                        _ProductGrid(products: visible),
                    ],
                  );
                }

                final plants = visible
                    .where((p) => p.category == 'plants')
                    .toList();
                final essentials = visible
                    .where((p) => p.category != 'plants')
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionHeading('The greenhouse favorites'.tr),
                    const SizedBox(height: 16),
                    controls,
                    const SizedBox(height: 16),
                    _ProductGrid(products: plants),
                    if (essentials.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionHeading('Good for your jungle'.tr),
                      const SizedBox(height: 16),
                      _SectionSubtitle(
                        'A few essentials for your Monstera and friends'.tr,
                      ),
                      const SizedBox(height: 16),
                      _ProductGrid(products: essentials),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when no product matches the search or filters.
class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.sprout, size: 28, color: scheme.primary),
          const SizedBox(height: 10),
          Text(
            'Nothing growing here yet.'.tr,
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try another search or category.'.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: scheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onClear, child: Text('Show everything'.tr)),
        ],
      ),
    );
  }
}

/// Title of a section of the shop.
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

/// Muted line under a section title.
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

/// Banner for the "Easy-grow edit" collection.
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
                    'THE EASY-GROW EDIT'.tr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Start small. Grow wild.'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Meet your first plant →'.tr,
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

/// Result count with the sort and filter buttons.
class _SortAndFilter extends StatelessWidget {
  const _SortAndFilter({
    required this.countLabel,
    required this.sortLabel,
    required this.activeFilters,
    required this.onSort,
    required this.onFilter,
  });

  final String countLabel;
  final String sortLabel;
  final int activeFilters;
  final VoidCallback onSort;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            countLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Filters'.tr,
          onPressed: onFilter,
          icon: Badge(
            isLabelVisible: activeFilters > 0,
            label: Text('$activeFilters'),
            backgroundColor: scheme.primary,
            child: Icon(
              LucideIcons.slidersHorizontal,
              size: 18,
              color: scheme.onSurface,
            ),
          ),
        ),
        TextButton(
          onPressed: onSort,
          style: TextButton.styleFrom(
            foregroundColor: scheme.onSurface,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sortLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronDown, size: 13, color: scheme.onSurface),
            ],
          ),
        ),
      ],
    );
  }
}

/// Two-column grid of product cards.
class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});

  final List<ProductSummary> products;

  Widget _card(BuildContext context, ProductSummary p) {
    return ProductCard(
      name: p.name,
      price: formatCompactMoney(p.price),
      image: imageFor(p.image),
      tag: p.tag,
      isFavorite: favorites.contains(p.id),
      onFavoriteTap: () => favorites.toggle(p.id),
      onAddTap: () {
        cart.addSummary(p);
        showAddedToCart(context, p.name);
      },
      onTap: () => pushRoot(context, AppRoutes.productPath(p.id)),
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
            Expanded(child: _card(context, products[i])),
            const SizedBox(width: 14),
            Expanded(
              child: second != null
                  ? _card(context, second)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    return Column(children: rows);
  }
}

/// Free-shipping note at the bottom of the shop.
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
              'Grown with care. Delivered with love. Free shipping on orders \$100+.'
                  .tr,
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
