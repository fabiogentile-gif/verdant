import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/care_schedule.dart';
import 'package:verdant/data/owned_plants.dart';
import 'package:verdant/pages/care_reminder.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/widgets/components/subpage_scaffold.dart';

/// Every care reminder, grouped by plant.
class CareRemindersPage extends StatelessWidget {
  const CareRemindersPage({super.key});

  void _edit(BuildContext context, OwnedPlant plant, CareKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CareReminderPage(plant: plant, kind: kind),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([plantCollection, careSchedule]),
      builder: (context, _) {
        final plants = ownedPlants;
        return SubpageScaffold(
          title: 'Care reminders',
          actionIcon: LucideIcons.calendarDays,
          onAction: () => goToTab(context, AppRoutes.activity),
          heading: 'Your care rhythm.',
          lede: 'Every reminder for every plant. Tap one to change it.',
          children: [
            if (plants.isEmpty)
              Text(
                'Add a plant to start a care routine.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            for (final plant in plants) ...[
              Row(
                children: [
                  CircleAvatar(radius: 16, backgroundImage: plant.image),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${plant.name} · ${plant.room}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add a reminder for ${plant.name}',
                    onPressed: () {
                      final used = careSchedule
                          .plansFor(plant.id)
                          .map((p) => p.kind)
                          .toSet();
                      _edit(
                        context,
                        plant,
                        CareKind.values.firstWhere(
                          (k) => !used.contains(k),
                          orElse: () => CareKind.water,
                        ),
                      );
                    },
                    icon: Icon(
                      LucideIcons.plus,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._planTiles(context, plant),
              const SizedBox(height: 20),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _planTiles(BuildContext context, OwnedPlant plant) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final byKind = <CareKind, List<CarePlan>>{};
    for (final p in careSchedule.plansFor(plant.id)) {
      byKind.putIfAbsent(p.kind, () => []).add(p);
    }
    if (byKind.isEmpty) {
      return [
        Text(
          'No reminders yet.',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ];
    }
    return [
      for (final entry in byKind.entries) ...[
        SoftCard(
          onTap: () => _edit(context, plant, entry.key),
          child: Row(
            children: [
              Icon(
                entry.key.icon,
                size: 20,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key.verb} · '
                      '${formatEvery(entry.value.first.everyDays).toLowerCase()}'
                      '${entry.value.length > 1 ? ' (${entry.value.length} days)' : ''}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Next: ${formatDue((entry.value..sort((a, b) => a.nextDue.compareTo(b.nextDue))).first.nextDue)}'
                      '${entry.value.first.push ? '' : ' · notifications off'}',
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
        const SizedBox(height: 10),
      ],
    ];
  }
}
