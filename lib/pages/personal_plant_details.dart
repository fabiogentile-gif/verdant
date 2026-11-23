import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/care_schedule.dart';
import 'package:verdant/data/owned_plants.dart';
import 'package:verdant/models/plant_details.dart';
import 'package:verdant/pages/care_reminder.dart';
import 'package:verdant/pages/not_found.dart';
import 'package:verdant/theme/theme.dart';
import 'package:verdant/widgets/components/detail_header.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';
import 'package:verdant/widgets/plants/plant_form_sheet.dart';
import 'package:verdant/l10n/i18n.dart';

DateFormat get _shortDate => appDate('MMM d');
DateFormat get _fullDate => appDate('MMM d, y');

/// Details of a plant in the user's collection.
class PersonalPlantDetails extends StatelessWidget {
  const PersonalPlantDetails({super.key, required this.plantId});

  final String plantId;

  Future<void> _showMenu(BuildContext context, OwnedPlant plant) async {
    final action = await showModalBottomSheet<String>(
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
                ListTile(
                  leading: Icon(LucideIcons.pencil, color: scheme.onSurface),
                  title: Text('Edit name & room'.tr),
                  onTap: () => Navigator.of(context).pop('edit'),
                ),
                ListTile(
                  leading: Icon(LucideIcons.bellPlus, color: scheme.onSurface),
                  title: Text('Schedule a care reminder'.tr),
                  onTap: () => Navigator.of(context).pop('remind'),
                ),
                ListTile(
                  leading: Icon(LucideIcons.trash2, color: scheme.error),
                  title: Text(
                    'Remove from my plants'.tr,
                    style: TextStyle(color: scheme.error),
                  ),
                  onTap: () => Navigator.of(context).pop('remove'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!context.mounted || action == null) return;

    switch (action) {
      case 'edit':
        await showPlantFormSheet(context, plant: plant);
      case 'remind':
        _openReminder(context, plant);
      case 'remove':
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(trArgs('Remove {0}?', [plant.name])),
            content: Text(
              'Its reminders and care history will be removed too.'.tr,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Keep it'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Remove'.tr),
              ),
            ],
          ),
        );
        if (ok == true && context.mounted) {
          Navigator.of(context).pop();
          plantCollection.remove(plant);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(trArgs('{0} was removed.', [plant.name]))),
          );
        }
    }
  }

  static void _openReminder(
    BuildContext context,
    OwnedPlant plant, [
    CareKind kind = CareKind.water,
  ]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CareReminderPage(plant: plant, kind: kind),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([plantCollection, careSchedule]),
      builder: (context, _) {
        final plant = plantCollection.byId(plantId);
        if (plant == null) {
          return NotFoundPage(
            title: 'This plant is no longer here.'.tr,
            message: 'It may have been removed from your collection.'.tr,
          );
        }
        final guide = plant.guide;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                DetailHeader(
                  title: trArgs('Your {0}', [plant.name]),
                  onBack: () => Navigator.of(context).maybePop(),
                  onMore: () => _showMenu(context, plant),
                ),
                Expanded(
                  child: ScrollViewNoStretch(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PlantPortrait(image: plant.image, room: plant.room),
                        const SizedBox(height: 26),
                        _PlantIdentity(plant: plant, guide: guide),
                        const SizedBox(height: 26),
                        _TodaysCare(plant: plant, guide: guide),
                        const SizedBox(height: 26),
                        _CareGuide(requirements: guide.requirements),
                        const SizedBox(height: 26),
                        _SeasonalNote(guide: guide),
                        const SizedBox(height: 26),
                        _BotanicalNotes(guide: guide),
                        const SizedBox(height: 26),
                        _CareRhythm(plant: plant),
                        const SizedBox(height: 26),
                        _CareHistory(plant: plant),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Portrait + identity
// ---------------------------------------------------------------------------

/// Large photo of the plant.
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

/// Name, species, room and health status.
class _PlantIdentity extends StatelessWidget {
  const _PlantIdentity({required this.plant, required this.guide});

  final OwnedPlant plant;
  final PlantGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final needsCare = careSchedule.needsCare(plant);
    final family = guide.family;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                trArgs('GROWING SINCE {0}', [
                  _shortDate.format(plant.addedOn).toUpperCase(),
                ]),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                  color: scheme.primary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: needsCare
                    ? scheme.tertiaryContainer
                    : scheme.primaryContainer,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: needsCare ? scheme.tertiary : scheme.primary,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    needsCare ? LucideIcons.triangleAlert : LucideIcons.check,
                    size: 12,
                    color: needsCare
                        ? scheme.onTertiaryContainer
                        : scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    careSchedule.statusLabel(plant),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: needsCare
                          ? scheme.onTertiaryContainer
                          : scheme.onPrimaryContainer,
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
          family == null ? plant.species : '${plant.species} · $family',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          guide.description,
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

/// Next care due (watering by default) with the action to mark it as done.
class _TodaysCare extends StatelessWidget {
  const _TodaysCare({required this.plant, required this.guide});

  final OwnedPlant plant;
  final PlantGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final due = careSchedule.dueTasks(plantId: plant.id);
    final task = due.isEmpty ? null : due.first;
    final next = careSchedule.firstFrom(
      dateOnly(DateTime.now()).add(const Duration(days: 1)),
      plantId: plant.id,
    );
    final lastWater = careSchedule.lastDone(plant.id, CareKind.water);
    final kind = task?.plan.kind ?? CareKind.water;

    final headline = switch (kind) {
      _ when task == null => 'All caught up for today.'.tr,
      CareKind.water => 'A drink is due today.'.tr,
      CareKind.fertilize => 'Time for a little feed.'.tr,
      CareKind.repot => 'Time for a roomier pot.'.tr,
    };
    final instructions =
        task?.plan.note ??
        (task == null
            ? 'Nothing to do right now. Enjoy it, and check back tomorrow.'.tr
            : guide.waterInstructions);
    final lastLabel = lastWater == null
        ? 'Not watered in Verdant yet'.tr
        : trArgs('Last watered {0}', [_shortDate.format(lastWater.date)]);
    final nextLabel = task != null
        ? formatDue(task.due)
        : next == null
        ? 'No reminders yet'.tr
        : trArgs('Next · {0}', [formatDue(next.due)]);

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
                task == null ? LucideIcons.sparkles : kind.icon,
                size: 24,
                color: scheme.surfaceContainerLowest,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  headline,
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
            instructions,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.6,
              color: scheme.secondaryContainer,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  lastLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: scheme.tertiaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                nextLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: scheme.tertiaryContainer,
                ),
              ),
            ],
          ),
          if (task != null) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                careSchedule.complete(task);
                final upcoming = careSchedule.firstFrom(
                  dateOnly(DateTime.now()).add(const Duration(days: 1)),
                  plantId: plant.id,
                );
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        upcoming == null
                            ? trArgs('{0} is happy.', [plant.name])
                            : trArgs('{0} is happy. Next: {1}.', [
                                plant.name,
                                formatDue(upcoming.due),
                              ]),
                      ),
                    ),
                  );
              },
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              label: Text(
                trArgs('Mark as {0}', [kind.doneLabel.toLowerCase()]),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

/// Title of a section with an optional action.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

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
              fontSize: 23,
              letterSpacing: -0.5,
              fontWeight: FontWeight.w400,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              actionLabel!,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Rounded square with an icon, used in front of list rows.
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

/// Care requirements of the species (light, water, humidity…).
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
        _SectionHeading(title: 'What makes it thrive'.tr),
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

/// Seasonal advice for the species.
class _SeasonalNote extends StatelessWidget {
  const _SeasonalNote({required this.guide});

  final PlantGuide guide;

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
                  guide.seasonLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  guide.seasonTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  guide.seasonBody,
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

/// Botanical notes and pet safety of the species.
class _BotanicalNotes extends StatelessWidget {
  const _BotanicalNotes({required this.guide});

  final PlantGuide guide;

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
          _SectionHeading(title: 'A little plant knowledge'.tr),
          const SizedBox(height: 12),
          Text(
            guide.botanicalNotes,
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
              Expanded(
                child: Text(
                  guide.petSafetyLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: scheme.onTertiaryContainer,
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

// ---------------------------------------------------------------------------
// Care rhythm (reminders)
// ---------------------------------------------------------------------------

/// The plant's reminders, with a shortcut to add a missing one.
class _CareRhythm extends StatelessWidget {
  const _CareRhythm({required this.plant});

  final OwnedPlant plant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plans = careSchedule.plansFor(plant.id)
      ..sort((a, b) => a.nextDue.compareTo(b.nextDue));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: 'Your care rhythm'.tr,
          actionLabel: plans.isEmpty ? null : 'Edit →'.tr,
          onAction: () => PersonalPlantDetails._openReminder(
            context,
            plant,
            plans.first.kind,
          ),
        ),
        if (plans.isEmpty) ...[
          const SizedBox(height: 13),
          Text(
            'No reminders yet. Add one and Verdant will nudge you at the right moment.'
                .tr,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        for (final plan in plans) ...[
          const SizedBox(height: 13),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.cardSoft(scheme),
            ),
            child: Material(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => PersonalPlantDetails._openReminder(
                  context,
                  plant,
                  plan.kind,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      _IconBox(
                        icon: plan.kind.icon,
                        boxSize: 42,
                        iconSize: 20,
                        radius: 14,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${plan.kind.verb} ${plant.name}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatDue(plan.nextDue)} · '
                              '${formatEvery(plan.everyDays).toLowerCase()}',
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
            ),
          ),
        ],
        const SizedBox(height: 13),
        FilledButton.icon(
          onPressed: () => PersonalPlantDetails._openReminder(
            context,
            plant,
            _firstFreeKind(plans),
          ),
          icon: const Icon(LucideIcons.plus, size: 18),
          label: Text(
            'Schedule a care reminder'.tr,
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

  /// Suggests a care type that has no reminder yet.
  static CareKind _firstFreeKind(List<CarePlan> plans) {
    for (final kind in CareKind.values) {
      if (plans.every((p) => p.kind != kind)) return kind;
    }
    return CareKind.water;
  }
}

/// Care already done for this plant.
class _CareHistory extends StatefulWidget {
  const _CareHistory({required this.plant});

  final OwnedPlant plant;

  @override
  State<_CareHistory> createState() => _CareHistoryState();
}

/// Shows the latest entries and expands to the full history.
class _CareHistoryState extends State<_CareHistory> {
  static const _collapsed = 3;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final events = careSchedule.completedFor(widget.plant.id);
    final shown = _showAll ? events : events.take(_collapsed).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: 'A history of little rituals'.tr,
          actionLabel: events.length > _collapsed
              ? (_showAll ? 'Show less'.tr : 'See all →'.tr)
              : null,
          onAction: () => setState(() => _showAll = !_showAll),
        ),
        if (events.isEmpty) ...[
          const SizedBox(height: 13),
          Text(
            'Care you mark as done will appear here.'.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        for (final e in shown) ...[
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
                      children: [
                        Expanded(
                          child: Text(
                            e.title,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          _fullDate.format(e.date),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (e.note != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        e.note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
