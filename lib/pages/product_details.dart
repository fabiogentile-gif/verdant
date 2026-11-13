import 'package:flutter/material.dart';
import 'package:verdant/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/cart.dart';
import 'package:verdant/data/product_repository.dart';
import 'package:verdant/pages/cart.dart' show showAddedToCart;
import 'package:verdant/models/product.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/widgets/components/filter_chip.dart';
import 'package:verdant/widgets/components/product_card.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';

ImageProvider _imageFor(String source) {
  if (source.startsWith('http')) return NetworkImage(source);
  return AssetImage(source);
}

IconData? _iconFor(String? key) {
  switch (key) {
    case 'sprout':
      return LucideIcons.sprout;
    case 'sun':
      return LucideIcons.sun;
    case 'droplets':
      return LucideIcons.droplets;
    default:
      return null;
  }
}

String _price(double value, {bool compact = false}) {
  final isWhole = value == value.roundToDouble();
  if (compact && isWhole) return '\$${value.toInt()}';
  return '\$${value.toStringAsFixed(2)}';
}

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key, required this.productId});

  final int productId;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late Future<ProductDetails> _future;
  final _pageController = PageController();
  final Set<int> _relatedFavorites = {};
  int _imageIndex = 0;
  int _quantity = 1;
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _load() {
    _future = productRepository.getProductDetails(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _DetailHeader(
              favorite: _favorite,
              onBack: () => Navigator.of(context).maybePop(),
              onFavorite: () => setState(() => _favorite = !_favorite),
            ),
            Expanded(
              child: FutureBuilder<ProductDetails>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    debugPrint(
                      'Product load error: ${snapshot.error}\n${snapshot.stackTrace}',
                    );
                    return _ErrorState(onRetry: () => setState(_load));
                  }
                  return _buildContent(context, snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProductDetails p) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ScrollViewNoStretch(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Gallery(
            images: p.images,
            controller: _pageController,
            index: _imageIndex,
            onChanged: (i) => setState(() => _imageIndex = i),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (p.eyebrow != null) _Eyebrow(p.eyebrow!) else const SizedBox(),
              if (p.rating != null)
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 13, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      p.reviewCount != null
                          ? '${p.rating} (${p.reviewCount})'
                          : '${p.rating}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            p.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontFamily: 'Lora',
              fontSize: 31,
              height: 1.15,
              letterSpacing: -0.7,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _price(p.price),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
              if (p.availabilityLabel != null)
                Text(
                  '● ${p.availabilityLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: p.inStock ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (p.summary != null) ...[
            const SizedBox(height: 12),
            Text(
              p.summary!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (p.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final tag in p.tags)
                  AppFilterChip(
                    label: tag.label,
                    selected: false,
                    leadingIcon: _iconFor(tag.icon),
                    onTap: () {},
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          // Acquisto
          _PurchaseCard(
            product: p,
            quantity: _quantity,
            onMinus: () => setState(() {
              if (_quantity > 1) _quantity--;
            }),
            onPlus: () => setState(() {
              if (_quantity < 99) _quantity++;
            }),
            onAddToCart: () {
              cart.addDetails(p, quantity: _quantity);
              showAddedToCart(context, p.name);
            },
          ),

          // Descrizione botanica
          if (p.description != null) ...[
            const SizedBox(height: 24),
            if (p.descriptionTitle != null) ...[
              _SectionHeading(p.descriptionTitle!),
              const SizedBox(height: 12),
            ],
            Text(
              p.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (p.growth != null || p.goodToKnow != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: p.growth != null
                        ? _Characteristic(label: 'GROWTH', value: p.growth!)
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: p.goodToKnow != null
                        ? _Characteristic(
                            label: 'GOOD TO KNOW',
                            value: p.goodToKnow!,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ],

          if (p.careSteps.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 24),
            const _SectionHeading('The simple care guide'),
            const SizedBox(height: 17),
            for (int i = 0; i < p.careSteps.length; i++) ...[
              if (i > 0) const SizedBox(height: 17),
              _CareRow(step: p.careSteps[i]),
            ],
            const SizedBox(height: 24),
            const _CareAssistantNote(),
          ],

          // Correlati
          if (p.related.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeading('Better together', actionLabel: 'View all →'),
            const SizedBox(height: 16),
            _RelatedGrid(
              products: p.related,
              favorites: _relatedFavorites,
              onFavoriteTap: (id) => setState(() {
                if (!_relatedFavorites.remove(id)) _relatedFavorites.add(id);
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.favorite,
    required this.onBack,
    required this.onFavorite,
  });

  final bool favorite;
  final VoidCallback onBack;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Icon(
              LucideIcons.arrowLeft,
              size: 20,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Plant profile',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          GestureDetector(
            onTap: onFavorite,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Icon(
                favorite ? Icons.favorite : LucideIcons.heart,
                size: 20,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.images,
    required this.controller,
    required this.index,
    required this.onChanged,
  });

  final List<String> images;
  final PageController controller;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          height: 360,
          child: images.isEmpty
              ? Container(
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                )
              : PageView.builder(
                  controller: controller,
                  itemCount: images.length,
                  onPageChanged: onChanged,
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image(
                      image: _imageFor(images[i]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < images.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: i == index ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: i == index
                        ? scheme.onSurface
                        : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({
    required this.product,
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
    required this.onAddToCart,
  });

  final ProductDetails product;
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = product.price * quantity;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        boxShadow: AppShadows.cardSoft(scheme),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (product.variantLabel != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.variantLabel!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                if (product.variantDetail != null)
                  Text(
                    product.variantDetail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Make room for green',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onMinus,
                      child: Icon(
                        LucideIcons.minus,
                        size: 14,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 17),
                    Text(
                      '$quantity',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 17),
                    GestureDetector(
                      onTap: onPlus,
                      child: Icon(
                        LucideIcons.plus,
                        size: 14,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: product.inStock ? onAddToCart : null,
            icon: const Icon(LucideIcons.arrowRight, size: 18),
            label: Text(
              'Add to cart · ${_price(total)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              minimumSize: const Size.fromHeight(52),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (product.purchaseNote != null) ...[
            const SizedBox(height: 16),
            Text(
              product.purchaseNote!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, {this.actionLabel});

  final String title;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Lora',
              fontSize: 23,
              letterSpacing: -0.5,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: 8),
          Text(
            actionLabel!,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _Characteristic extends StatelessWidget {
  const _Characteristic({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(label),
        const SizedBox(height: 5),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            height: 1.5,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _CareRow extends StatelessWidget {
  const _CareRow({required this.step});

  final CareStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _iconFor(step.icon) ?? LucideIcons.sprout,
            size: 18,
            color: scheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                step.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CareAssistantNote extends StatelessWidget {
  const _CareAssistantNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.bellRing,
            size: 20,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bring it home. We’ll help you build its care routine in My plants.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                height: 1.5,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedGrid extends StatelessWidget {
  const _RelatedGrid({
    required this.products,
    required this.favorites,
    required this.onFavoriteTap,
  });

  final List<ProductSummary> products;
  final Set<int> favorites;
  final ValueChanged<int> onFavoriteTap;

  Widget _card(BuildContext context, ProductSummary p) {
    return ProductCard(
      name: p.name,
      price: _price(p.price, compact: true),
      image: _imageFor(p.image),
      tag: p.tag,
      isFavorite: favorites.contains(p.id),
      onFavoriteTap: () => onFavoriteTap(p.id),
      onAddTap: () {
        cart.addSummary(p);
        showAddedToCart(context, p.name);
      },
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.productPath(p.id)),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'We couldn’t load this product.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text('Try again', style: TextStyle(color: scheme.primary)),
          ),
        ],
      ),
    );
  }
}
