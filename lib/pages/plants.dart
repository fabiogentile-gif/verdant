import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/owned_plants.dart';
import 'package:verdant/models/plant_details.dart';
import 'package:verdant/pages/personal_plant_details.dart';
import 'package:verdant/search_field.dart';
import 'package:verdant/widgets/components/collection_overview.dart';
import 'package:verdant/widgets/components/page_header.dart';
import 'package:verdant/widgets/components/plant_card.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';
import 'package:verdant/widgets/components/search_bar.dart';

class OwnedPlant {
  const OwnedPlant({
    required this.name,
    required this.room,
    required this.species,
    required this.image,
    required this.status,
    required this.statusLabel,
    required this.scheduleLabel,
    this.details,
  });

  final String name;
  final String room;
  final String species;
  final ImageProvider image;
  final PlantStatus status;
  final String statusLabel;
  final String scheduleLabel;
  final PlantDetails? details;
}

enum _PlantFilter { all, needsCare }

class Plants extends StatefulWidget {
  const Plants({super.key});

  @override
  State<Plants> createState() => _PlantsState();
}

class _PlantsState extends State<Plants> {
  _PlantFilter _filter = _PlantFilter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final needsCareCount = ownedPlants
        .where((p) => p.status == PlantStatus.needsCare)
        .length;
    final healthyCount = ownedPlants.length - needsCareCount;

    final query = _query.trim().toLowerCase();

    final visible = ownedPlants.where((p) {
      final matchesFilter =
          _filter == _PlantFilter.all || p.status == PlantStatus.needsCare;
      final matchesQuery =
          query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.room.toLowerCase().contains(query) ||
          p.species.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: StandardAppBar(
        title: 'My plants',
        actionIcon: LucideIcons.plus,
        onActionTap: () {},
      ),
      body: ScrollViewNoStretch(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader.eyebrowText(
              'MAYA’S LITTLE JUNGLE',
              title: 'Growing, together.',
              subtitle: 'Every leaf has a story. Here are yours.',
            ),
            const SizedBox(height: 24),
            CollectionOverview(
              total: ownedPlants.length,
              healthy: healthyCount,
              needsCare: needsCareCount,
            ),
            const SizedBox(height: 24),
            AppSearchField(
              hintText: 'Find a plant in your collection',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All plants (${ownedPlants.length})',
                    selected: _filter == _PlantFilter.all,
                    onTap: () => setState(() => _filter = _PlantFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Needs care ($needsCareCount)',
                    selected: _filter == _PlantFilter.needsCare,
                    onTap: () =>
                        setState(() => _filter = _PlantFilter.needsCare),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'By room',
                    selected: false,
                    leadingIcon: LucideIcons.chevronDown,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No plants match your search.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (int i = 0; i < visible.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              PlantCard(
                name: visible[i].name,
                subtitle: '${visible[i].room} · ${visible[i].species}',
                image: visible[i].image,
                status: visible[i].status,
                statusLabel: visible[i].statusLabel,
                scheduleLabel: visible[i].scheduleLabel,
                onTap: () {
                  final d = visible[i].details;
                  if (d == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PersonalPlantDetails(plant: visible[i], details: d),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
            _AddPlantButton(
              label: 'Add a plant to your collection',
              onPressed: () {},
            ),
            const SizedBox(height: 24),
            const _CollectionGuidance(),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leadingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final background = selected
        ? scheme.onSecondaryContainer
        : scheme.surfaceContainerLowest;
    final border = selected
        ? scheme.onSecondaryContainer
        : scheme.outlineVariant;
    final foreground = selected
        ? scheme.onPrimary
        : scheme.onSecondaryContainer;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 14, color: foreground),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPlantButton extends StatelessWidget {
  const _AddPlantButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(LucideIcons.plus, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
        minimumSize: const Size.fromHeight(50),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _CollectionGuidance extends StatelessWidget {
  const _CollectionGuidance();

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
          Icon(
            LucideIcons.sparkles,
            size: 22,
            color: scheme.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Small rituals, happy roots.',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Check the soil before you water. Your plant knows what it needs.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.5,
                    color: scheme.onTertiaryContainer,
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
