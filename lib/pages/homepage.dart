import 'package:flutter/material.dart';
import 'package:verdant/data/care_schedule.dart';
import 'package:verdant/data/cart.dart';
import 'package:verdant/data/favorites.dart';
import 'package:verdant/data/orders.dart';
import 'package:verdant/data/owned_plants.dart';
import 'package:verdant/data/product_repository.dart';
import 'package:verdant/data/settings.dart';
import 'package:verdant/data/shop_filter.dart';
import 'package:verdant/models/product.dart';
import 'package:verdant/pages/care_reminder.dart';
import 'package:verdant/pages/cart.dart' show showAddedToCart;
import 'package:verdant/pages/notifications.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/utils/money.dart';
import 'package:verdant/widgets/components/page_header.dart';
import 'package:verdant/widgets/components/personal_collection.dart';
import 'package:verdant/widgets/components/plant_card.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';
import 'package:verdant/widgets/components/search_bar.dart';
import 'package:verdant/widgets/components/standard_app_bar.dart';
import 'package:verdant/widgets/homepage/category_filter.dart';
import 'package:verdant/widgets/homepage/featured_products.dart' as fp;
import 'package:verdant/widgets/homepage/seasonal_card.dart';
import 'package:verdant/widgets/homepage/upcoming_care.dart';

/// Home tab: greeting, search, categories, featured products and upcoming care.
class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

/// Loads the featured products and builds the sections.
class _HomepageState extends State<Homepage> {
  /// Homepage category chips → Greenhouse categories.
  static final _categoryTargets = [
    ShopCategory.indoorPlants,
    ShopCategory.outdoorPlants,
    ShopCategory.pots,
  ];

  int _selected = 0;
  late Future<List<ProductSummary>> _featured;

  @override
  void initState() {
    super.initState();
    _featured = productRepository.getFeaturedProducts();
  }

  void _openShop({String query = '', ShopCategory? category}) {
    shopFilter.show(query: query, category: category);
    goToTab(context, AppRoutes.greenhouse);
  }

  fp.Product _card(ProductSummary p) => fp.Product(
    id: p.id,
    name: p.name,
    price: formatCompactMoney(p.price),
    tag: p.tag ?? '',
    image: imageFor(p.image),
  );

  void _openReminder(CareTask task) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) =>
            CareReminderPage(plant: task.plant, kind: task.plan.kind),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        plantCollection,
        careSchedule,
        favorites,
        appSettings,
        orderHistory,
      ]),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final now = DateTime.now();
    final plants = ownedPlants;
    final due = careSchedule.dueTasks(now: now);
    final focus = due.isNotEmpty
        ? due.first.plant
        : (plants.isEmpty ? null : plants.first);
    final upcoming = careSchedule
        .tasksBetween(now, dateOnly(now).add(const Duration(days: 30)))
        .where((t) => t.due.isAfter(now))
        .take(2)
        .toList();

    return Scaffold(
      appBar: StandardAppBar.home(
        hasUnread: hasUnreadNotifications(now: now),
        onActionTap: () => pushRoot(context, AppRoutes.notifications),
      ),
      body: ScrollViewNoStretch(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader.eyebrowDate(
              now,
              title: 'A little greener, Maya.',
              subtitle: 'Good things grow with a little care.',
            ),
            const SizedBox(height: 28),
            AppSearchField(
              hintText: 'Find your next green companion',
              onSubmitted: (q) => _openShop(query: q.trim()),
            ),
            const SizedBox(height: 28),
            SeasonalFeatureCard(
              onTap: () => _openShop(category: ShopCategory.indoorPlants),
            ),
            const SizedBox(height: 28),
            PopularCategories(
              selectedIndex: _selected,
              onSelected: (i) {
                setState(() => _selected = i);
                _openShop(category: _categoryTargets[i]);
              },
            ),
            const SizedBox(height: 28),
            FutureBuilder<List<ProductSummary>>(
              future: _featured,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _FeaturedError(
                    message: snap.error is ProductLoadException
                        ? (snap.error as ProductLoadException).message
                        : 'We couldn’t load our favourites.',
                    onRetry: () => setState(
                      () => _featured = productRepository.getFeaturedProducts(),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final products = snap.data!.take(2).toList();
                final byId = {for (final p in products) p.id: p};
                return fp.FeaturedProducts(
                  products: products.map(_card).toList(),
                  favoriteIds: favorites.ids,
                  onProductTap: (p) =>
                      pushRoot(context, AppRoutes.productPath(p.id)),
                  onFavoriteTap: (p) => favorites.toggle(p.id),
                  onAddTap: (p) {
                    cart.addSummary(byId[p.id]!);
                    showAddedToCart(context, p.name);
                  },
                  onShopAll: () => _openShop(),
                );
              },
            ),
            const SizedBox(height: 28),
            if (focus != null)
              PersonalCollection(
                plantName: focus.name,
                plantSubtitle: '${focus.room} · ${focus.species}',
                plantImage: focus.image,
                plantStatus: careSchedule.needsCare(focus)
                    ? PlantStatus.needsCare
                    : PlantStatus.healthy,
                statusLabel: careSchedule.statusLabel(focus),
                scheduleLabel: careSchedule.scheduleLabel(focus),
                collectionLabel: plants.length == 1
                    ? '1 plant, one happy home'
                    : '${plants.length} plants, one happy home',
                onSeeAll: () => goToTab(context, AppRoutes.plants),
                onPlantTap: () => openPlant(context, focus),
                onCollectionTap: () => goToTab(context, AppRoutes.plants),
              ),
            if (upcoming.isNotEmpty) ...[
              const SizedBox(height: 28),
              UpcomingCare(
                onViewAll: () => goToTab(context, AppRoutes.activity),
                reminders: [
                  for (final t in upcoming)
                    CareReminder(
                      title: t.title,
                      schedule: formatDue(t.due, now: now),
                      onTap: () => _openReminder(t),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

/// Shown when the featured products cannot be loaded, with a retry button.
class _FeaturedError extends StatelessWidget {
  const _FeaturedError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                height: 1.5,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
