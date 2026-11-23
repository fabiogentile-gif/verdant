// Private fields can't be named parameters.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/l10n/i18n.dart';

/// One line of a care guide (e.g. light, humidity) with its icon.
class CareRequirement {
  const CareRequirement({
    required this.icon,
    required String title,
    required String description,
  }) : _title = title,
       _description = description;

  final IconData icon;
  final String _title;
  final String _description;

  String get title => _title.tr;
  String get description => _description.tr;
}

/// A species Verdant knows how to look after.
class PlantSpecies {
  const PlantSpecies({
    required this.latinName,
    required String commonName,
    required this.imagePath,
    required this.waterEveryDays,
    required this.guide,
  }) : _commonName = commonName;

  final String latinName;
  final String _commonName;

  String get commonName => _commonName.tr;

  final String imagePath;
  final int waterEveryDays;
  final PlantGuide guide;

  static const other = PlantSpecies(
    latinName: 'Other',
    commonName: 'Another plant',
    imagePath: 'assets/images/autumn_botanical_still_life.png',
    waterEveryDays: 7,
    guide: PlantGuide.generic,
  );

  static const catalog = [monstera, rubberPlant, goldenPothos, peaceLily];

  static PlantSpecies byLatinName(String latinName) =>
      catalog.firstWhere((s) => s.latinName == latinName, orElse: () => other);

  static const monstera = PlantSpecies(
    latinName: 'Monstera deliciosa',
    commonName: 'Monstera',
    imagePath: 'assets/images/owned/monstera_deliciosa.png',
    waterEveryDays: 7,
    guide: PlantGuide(
      family: 'Araceae',
      description:
          'Your tropical, split-leaf companion. A little support and a steady '
          'routine help it flourish.',
      waterInstructions:
          'Check the top 2 inches of soil. If dry, water slowly until it '
          'drains. Empty the saucer afterwards.',
      requirements: [
        CareRequirement(
          icon: LucideIcons.droplets,
          title: 'Water · check every 7 days',
          description: 'Let the top 2 inches dry. Water less often in the cooler months.',
        ),
        CareRequirement(
          icon: LucideIcons.sun,
          title: 'Light · bright & indirect',
          description: 'Near an east-facing window. Avoid harsh afternoon sun.',
        ),
        CareRequirement(
          icon: LucideIcons.sprout,
          title: 'Soil · airy & well-draining',
          description:
              'Use potting soil with orchid bark and perlite. Keep drainage '
              'holes clear.',
        ),
        CareRequirement(
          icon: LucideIcons.thermometer,
          title: 'Comfort · 65–85°F',
          description:
              'Average home humidity is fine. Keep away from cold drafts.',
        ),
      ],
      seasonLabel: 'Seasonal note · Review in spring',
      seasonTitle: 'Give roots room to grow',
      seasonBody:
          'Repot only when roots crowd the pot. Use a container just '
          '1–2 inches wider.',
      botanicalNotes:
          'Native to Central American rainforests, Monstera is a climbing '
          'aroid. Its leaf splits deepen as it matures in good light. Add a '
          'moss pole to support new growth.',
      petSafetyLabel: 'Not pet-safe · keep out of reach',
    ),
  );

  static const rubberPlant = PlantSpecies(
    latinName: 'Ficus elastica',
    commonName: 'Rubber Plant',
    imagePath: 'assets/images/owned/rubber_plant.png',
    waterEveryDays: 12,
    guide: PlantGuide(
      family: 'Moraceae',
      description:
          'Glossy, deep green leaves and a calm, upright shape. Forgiving, '
          'and happiest with a steady spot.',
      waterInstructions:
          'Water when the top inch of soil is dry. Soak evenly, then let the '
          'excess drain away.',
      requirements: [
        CareRequirement(
          icon: LucideIcons.droplets,
          title: 'Water · every 10–14 days',
          description:
              'Let the top inch dry out. Yellow, dropping leaves often mean '
              'too much water.',
        ),
        CareRequirement(
          icon: LucideIcons.sun,
          title: 'Light · bright & indirect',
          description:
              'Tolerates medium light, but grows fuller near a bright window.',
        ),
        CareRequirement(
          icon: LucideIcons.sprout,
          title: 'Soil · well-draining',
          description: 'A general indoor mix with some perlite works well.',
        ),
        CareRequirement(
          icon: LucideIcons.thermometer,
          title: 'Comfort · 60–80°F',
          description: 'Avoid moving it often; it dislikes sudden changes.',
        ),
      ],
      seasonLabel: 'Seasonal note · All year',
      seasonTitle: 'Keep the leaves shining',
      seasonBody:
          'Wipe the leaves with a damp cloth every few weeks so they can '
          'catch more light.',
      botanicalNotes:
          'Native to South and Southeast Asia, the rubber plant is a fig. '
          'Its milky sap was once used to make rubber.',
      petSafetyLabel: 'Not pet-safe · sap can irritate',
    ),
  );

  static const goldenPothos = PlantSpecies(
    latinName: 'Epipremnum aureum',
    commonName: 'Golden Pothos',
    imagePath: 'assets/images/owned/golden_pothos.png',
    waterEveryDays: 9,
    guide: PlantGuide(
      family: 'Araceae',
      description:
          'An easy-going trailing vine with marbled golden leaves. Perfect '
          'for shelves and high corners.',
      waterInstructions:
          'Water when the top half of the soil feels dry. Droopy leaves are '
          'its way of asking.',
      requirements: [
        CareRequirement(
          icon: LucideIcons.droplets,
          title: 'Water · every 1–2 weeks',
          description: 'Let the soil dry halfway down between drinks.',
        ),
        CareRequirement(
          icon: LucideIcons.sun,
          title: 'Light · low to bright indirect',
          description:
              'Copes with low light; brighter light keeps the gold markings.',
        ),
        CareRequirement(
          icon: LucideIcons.sprout,
          title: 'Soil · light & airy',
          description: 'Any well-draining indoor mix.',
        ),
        CareRequirement(
          icon: LucideIcons.thermometer,
          title: 'Comfort · 65–85°F',
          description: 'Keep away from cold windows in winter.',
        ),
      ],
      seasonLabel: 'Seasonal note · Spring',
      seasonTitle: 'Trim to keep it full',
      seasonBody:
          'Snip long vines just above a leaf. The cuttings root easily in a '
          'glass of water.',
      botanicalNotes:
          'Native to Mo’orea in French Polynesia, pothos climbs trees in the '
          'wild and grows much larger leaves when it has support.',
      petSafetyLabel: 'Not pet-safe · keep out of reach',
    ),
  );

  static const peaceLily = PlantSpecies(
    latinName: 'Spathiphyllum',
    commonName: 'Peace Lily',
    imagePath: 'assets/images/owned/peace_lily.png',
    waterEveryDays: 7,
    guide: PlantGuide(
      family: 'Araceae',
      description:
          'Soft white blooms over dark green leaves. It tells you clearly '
          'when it is thirsty.',
      waterInstructions:
          'Keep the soil lightly moist. If the leaves droop, give it a good '
          'drink and they will lift within hours.',
      requirements: [
        CareRequirement(
          icon: LucideIcons.droplets,
          title: 'Water · about once a week',
          description: 'Never let it sit in water; empty the saucer.',
        ),
        CareRequirement(
          icon: LucideIcons.sun,
          title: 'Light · medium & indirect',
          description: 'More light means more flowers. Avoid direct sun.',
        ),
        CareRequirement(
          icon: LucideIcons.sprout,
          title: 'Soil · rich & moist',
          description: 'A peat-free indoor mix that holds some moisture.',
        ),
        CareRequirement(
          icon: LucideIcons.thermometer,
          title: 'Comfort · 65–80°F',
          description: 'Enjoys humidity; a bathroom or kitchen suits it.',
        ),
      ],
      seasonLabel: 'Seasonal note · Winter',
      seasonTitle: 'A little humidity helps',
      seasonBody:
          'Heating dries the air. Group plants together or place it near a '
          'tray of water and pebbles.',
      botanicalNotes:
          'Not a true lily: it comes from the tropical Americas. The white '
          '“flower” is a leaf-like spathe around a small spike of blooms.',
      petSafetyLabel: 'Not pet-safe · mildly toxic to cats and dogs',
    ),
  );
}

/// Care knowledge for a species (fixed content).
class PlantGuide {
  const PlantGuide({
    required this.family,
    required String description,
    required String waterInstructions,
    required this.requirements,
    required String seasonLabel,
    required String seasonTitle,
    required String seasonBody,
    required String botanicalNotes,
    required String petSafetyLabel,
  }) : _description = description,
       waterInstructionsKey = waterInstructions,
       _seasonLabel = seasonLabel,
       _seasonTitle = seasonTitle,
       _seasonBody = seasonBody,
       _botanicalNotes = botanicalNotes,
       _petSafetyLabel = petSafetyLabel;

  final String? family;
  final String _description;

  /// English text, saved as the note of a new reminder.
  final String waterInstructionsKey;
  final List<CareRequirement> requirements;
  final String _seasonLabel;
  final String _seasonTitle;
  final String _seasonBody;
  final String _botanicalNotes;
  final String _petSafetyLabel;

  String get description => _description.tr;
  String get waterInstructions => waterInstructionsKey.tr;
  String get seasonLabel => _seasonLabel.tr;
  String get seasonTitle => _seasonTitle.tr;
  String get seasonBody => _seasonBody.tr;
  String get botanicalNotes => _botanicalNotes.tr;
  String get petSafetyLabel => _petSafetyLabel.tr;

  static const generic = PlantGuide(
    family: null,
    description:
        'A new green companion. Watch how it responds and adjust '
        'your routine as you go.',
    waterInstructions:
        'Check the top inch of soil. Water when it feels dry, then let the '
        'excess drain away.',
    requirements: [
      CareRequirement(
        icon: LucideIcons.droplets,
        title: 'Water · when the top inch is dry',
        description: 'Most houseplants prefer drying out a little to wet feet.',
      ),
      CareRequirement(
        icon: LucideIcons.sun,
        title: 'Light · bright & indirect',
        description: 'A spot near a window, out of harsh midday sun.',
      ),
      CareRequirement(
        icon: LucideIcons.sprout,
        title: 'Soil · well-draining',
        description: 'Use a pot with drainage holes.',
      ),
    ],
    seasonLabel: 'Seasonal note · Spring',
    seasonTitle: 'Feed while it grows',
    seasonBody:
        'Most plants enjoy a gentle feed once a month in spring and summer.',
    botanicalNotes:
        'Every plant is a little different. Look up its species to learn '
        'where it comes from and what it loves.',
    petSafetyLabel: 'Pet safety unknown · check before sharing a room',
  );
}
