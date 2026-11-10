import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.tag,
    required this.image,
  });

  final String id;
  final String name;
  final String price;
  final String tag;
  final ImageProvider image;
}

class FeaturedProducts extends StatelessWidget {
  const FeaturedProducts({
    super.key,
    required this.products,
    this.onShopAll,
    this.onProductTap,
    this.onFavoriteTap,
    this.onAddTap,
  });

  final List<Product> products;
  final VoidCallback? onShopAll;
  final ValueChanged<Product>? onProductTap;
  final ValueChanged<Product>? onFavoriteTap;
  final ValueChanged<Product>? onAddTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Rooted in good taste',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 23,
                  letterSpacing: -0.5,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onShopAll,
              child: Text(
                'Shop all →',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < products.length; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              Expanded(
                child: _ProductCard(
                  product: products[i],
                  onTap: () => onProductTap?.call(products[i]),
                  onFavoriteTap: () => onFavoriteTap?.call(products[i]),
                  onAddTap: () => onAddTap?.call(products[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onFavoriteTap,
    required this.onAddTap,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image(image: product.image, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.heart,
                        size: 15,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      product.tag,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.price,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: scheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: onAddTap,
                child: Icon(
                  LucideIcons.circlePlus,
                  size: 23,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}