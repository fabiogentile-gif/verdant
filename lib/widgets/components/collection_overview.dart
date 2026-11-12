import 'package:flutter/material.dart';
import 'package:verdant/widgets/components/collection_metrics.dart';

class CollectionOverview extends StatelessWidget {
  const CollectionOverview({
    super.key,
    required this.total,
    required this.healthy,
    required this.needsCare,
    this.title,
    this.actionLabel,
    this.onActionTap,
    this.images = const [],
  });

  final int total;
  final int healthy;
  final int needsCare;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final List<ImageProvider> images;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final portraits = images.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.onSecondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 23,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.5,
                    color: scheme.surface,
                  ),
                ),
                if (actionLabel != null)
                  GestureDetector(
                    onTap: onActionTap,
                    child: Text(
                      actionLabel!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.tertiaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (portraits.isNotEmpty) ...[
            SizedBox(
              height: 83,
              child: Row(
                children: [
                  for (var i = 0; i < portraits.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image(
                          image: portraits[i],
                          height: 83,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          CollectionMetrics(
            total: total,
            healthy: healthy,
            needsCare: needsCare,
          ),
        ],
      ),
    );
  }
}