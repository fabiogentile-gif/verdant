import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/l10n/i18n.dart';

/// Shop card: image, tag, name, price, favourite and add-to-cart buttons.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.image,
    this.tag,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
    this.onAddTap,
  });

  final String name;
  final String price;
  final ImageProvider image;
  final String? tag;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
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
                    child: Image(image: image, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 1,
                  right: 1,
                  // 48 dp touch area around the 30 dp circle.
                  child: Semantics(
                    button: true,
                    label: isFavorite
                        ? 'Remove from favourites'.tr
                        : 'Add to favourites'.tr,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onFavoriteTap,
                      child: SizedBox.square(
                        dimension: 48,
                        child: Center(
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLowest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite : LucideIcons.heart,
                              size: 15,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (tag != null)
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        tag!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          // The add button covers the whole text block: a 48 dp touch area
          // without making the card taller.
          Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 28),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    height: 23,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        price,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: 48,
                child: Semantics(
                  button: true,
                  label: trArgs('Add {0} to cart', [name]),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onAddTap,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(
                        LucideIcons.circlePlus,
                        size: 23,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
