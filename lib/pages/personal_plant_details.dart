import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/models/plant_details.dart';
import 'package:verdant/widgets/components/detail_header.dart';
import 'package:verdant/widgets/components/plant_card.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';
import 'package:verdant/data/owned_plants.dart' show OwnedPlant;
import 'package:verdant/pages/care_reminder.dart';

class PersonalPlantDetails extends StatelessWidget {
  const PersonalPlantDetails({
    super.key,
    required this.plant,
    required this.details,
  });

  final OwnedPlant plant;
  final PlantDetails details;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailHeader(
              title: 'Your ${plant.name}',
              onBack: () => Navigator.of(context).maybePop(),
              onMore: () {},
            ),
            Expanded(
              child: ScrollViewNoStretch(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PlantPortrait(image: plant.image, room: plant.room),
                    const SizedBox(height: 26),
                    _PlantIdentity(plant: plant, details: details),
                    const SizedBox(height: 26),
                    _TodaysCare(details: details),
                    const SizedBox(height: 26),
                    _CareGuide(requirements: details.requirements),
                    const SizedBox(height: 26),
                    _SeasonalNote(details: details),
                    const SizedBox(height: 26),
                    _BotanicalNotes(details: details),
                    const SizedBox(height: 26),
                    _CareRhythm(plant: plant, details: details),
                    const SizedBox(height: 26),
                    _CareHistory(events: details.history),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Portrait + identity
// ---------------------------------------------------------------------------

class _PlantPortrait extends StatelessWidget {
  const _PlantPortrait({required this.image, required this.room});

  final ImageProvider image;
  final String room;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 295,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(image: image, fit: BoxFit.cover),
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.mapPin, size: 13, color: scheme.onSurface),
                    const SizedBox(width: 6),
                    Text(
                      room,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlantIdentity extends StatelessWidget {
  const _PlantIdentity({required this.plant, required this.details});

  final OwnedPlant plant;
  final PlantDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final needsCare = plant.status == PlantStatus.needsCare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              details.sinceLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
                color: scheme.primary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: scheme.tertiary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    needsCare ? LucideIcons.triangleAlert : LucideIcons.check,
                    size: 12,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    plant.statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          plant.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 34,
            height: 1.15,
            letterSpacing: -0.7,
            fontWeight: FontWeight.w400,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          details.latinName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          details.description,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Today's care
// ---------------------------------------------------------------------------

class _TodaysCare extends StatelessWidget {
  const _TodaysCare({required this.details});

  final PlantDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.onSecondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.droplets,
                size: 24,
                color: scheme.surfaceContainerLowest,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  details.careHeadline,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: scheme.surfaceContainerLowest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            details.careInstructions,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.6,
              color: scheme.secondaryContainer,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                details.lastWateredLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: scheme.tertiaryContainer,
                ),
              ),
              Text(
                details.nextCareLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: scheme.tertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.arrowRight, size: 18),
            label: const Text(
              'Mark as watered',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.actionLabel});

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
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 23,
              letterSpacing: -0.5,
              fontWeight: FontWeight.w400,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: 8),
          Text(
            actionLabel!,
            style: theme.textTheme.labelMedium?.copyWith(
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

class _IconBox extends StatelessWidget {
  const _IconBox({
    required this.icon,
    required this.boxSize,
    required this.iconSize,
    required this.radius,
  });

  final IconData icon;
  final double boxSize;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: scheme.onSecondaryContainer),
    );
  }
}

// ---------------------------------------------------------------------------
// Care guide
// ---------------------------------------------------------------------------

class _CareGuide extends StatelessWidget {
  const _CareGuide({required this.requirements});

  final List<CareRequirement> requirements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'What makes it thrive'),
        for (final r in requirements) ...[
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBox(icon: r.icon, boxSize: 40, iconSize: 20, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      r.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        height: 1.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SeasonalNote extends StatelessWidget {
  const _SeasonalNote({required this.details});

  final PlantDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shovel, size: 21, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.seasonLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  details.seasonTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  details.seasonBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.45,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Botanical notes
// ---------------------------------------------------------------------------

class _BotanicalNotes extends StatelessWidget {
  const _BotanicalNotes({required this.details});

  final PlantDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(title: 'A little plant knowledge'),
          const SizedBox(height: 12),
          Text(
            details.botanicalNotes,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.5,
              color: scheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                LucideIcons.pawPrint,
                size: 16,
                color: scheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                details.petSafetyLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: scheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Care rhythm (reminders)
// ---------------------------------------------------------------------------

class _CareRhythm extends StatelessWidget {
  const _CareRhythm({required this.plant, required this.details});

  final OwnedPlant plant;
  final PlantDetails details;

  void _openReminder(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CareReminderPage(plant: plant)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openReminder(context),
          child: const _SectionHeading(
            title: 'Your care rhythm',
            actionLabel: 'Edit →',
          ),
        ),
        for (final r in details.reminders) ...[
          const SizedBox(height: 13),
          GestureDetector(
            onTap: () => _openReminder(context),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _IconBox(icon: r.icon, boxSize: 42, iconSize: 20, radius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.whenLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 13),
        Text(
          details.reminderRecurrence,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 13),
        FilledButton.icon(
          onPressed: () => _openReminder(context),
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text(
            'Schedule a care reminder',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
            minimumSize: const Size.fromHeight(50),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

class _CareHistory extends StatelessWidget {
  const _CareHistory({required this.events});

  final List<CareEvent> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'A history of little rituals',
          actionLabel: 'See all →',
        ),
        for (final e in events) ...[
          const SizedBox(height: 17),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  e.icon,
                  size: 15,
                  color: scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.title,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          e.dateLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      e.note,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
