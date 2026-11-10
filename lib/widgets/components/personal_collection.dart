import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/widgets/components/plant_card.dart';

class PersonalCollection extends StatelessWidget {
  const PersonalCollection({
    super.key,
    required this.plantName,
    required this.plantSubtitle,
    required this.plantImage,
    required this.statusLabel,
    required this.scheduleLabel,
    required this.collectionLabel,
    this.plantStatus = PlantStatus.needsCare,
    this.onSeeAll,
    this.onPlantTap,
    this.onCollectionTap,
  });

  final String plantName;
  final String plantSubtitle;
  final ImageProvider plantImage;
  final String statusLabel;
  final String scheduleLabel;
  final String collectionLabel;
  final PlantStatus plantStatus;
  final VoidCallback? onSeeAll;
  final VoidCallback? onPlantTap;
  final VoidCallback? onCollectionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Your little jungle',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Lora',
                  fontSize: 23,
                  letterSpacing: -0.5,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'My plants →',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        PlantCard(
          name: plantName,
          subtitle: plantSubtitle,
          image: plantImage,
          statusLabel: statusLabel,
          scheduleLabel: scheduleLabel,
          status: plantStatus,
          onTap: onPlantTap,
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onCollectionTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.sprout,
                  size: 20,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    collectionLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  LucideIcons.arrowRight,
                  size: 17,
                  color: scheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}