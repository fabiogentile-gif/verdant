import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CareRequirement {
  const CareRequirement({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class CareReminder {
  const CareReminder({
    required this.icon,
    required this.title,
    required this.whenLabel,
  });

  final IconData icon;
  final String title;
  final String whenLabel;
}

class CareEvent {
  const CareEvent({
    required this.icon,
    required this.title,
    required this.dateLabel,
    required this.note,
  });

  final IconData icon;
  final String title;
  final String dateLabel;
  final String note;
}

class PlantDetails {
  const PlantDetails({
    required this.sinceLabel,
    required this.latinName,
    required this.description,
    required this.careHeadline,
    required this.careInstructions,
    required this.lastWateredLabel,
    required this.nextCareLabel,
    required this.requirements,
    required this.seasonLabel,
    required this.seasonTitle,
    required this.seasonBody,
    required this.botanicalNotes,
    required this.petSafetyLabel,
    required this.reminders,
    required this.reminderRecurrence,
    required this.history,
  });

  final String sinceLabel;
  final String latinName;
  final String description;
  final String careHeadline;
  final String careInstructions;
  final String lastWateredLabel;
  final String nextCareLabel;
  final List<CareRequirement> requirements;
  final String seasonLabel;
  final String seasonTitle;
  final String seasonBody;
  final String botanicalNotes;
  final String petSafetyLabel;
  final List<CareReminder> reminders;
  final String reminderRecurrence;
  final List<CareEvent> history;
}

const monsteraDetails = PlantDetails(
  sinceLabel: 'GROWING SINCE MAY 16',
  latinName: 'Monstera deliciosa · Araceae',
  description:
      'Your tropical, split-leaf companion. A little support and a steady '
      'routine help it flourish.',
  careHeadline: 'A drink is due today.',
  careInstructions:
      'Check the top 2 inches of soil. If dry, water slowly until it drains. '
      'Empty the saucer afterwards.',
  lastWateredLabel: 'Last watered Oct 29',
  nextCareLabel: 'Today · Nov 5',
  requirements: [
    CareRequirement(
      icon: LucideIcons.droplets,
      title: 'Water · check every 7 days',
      description:
          'Let the top 2 inches dry. Water less often in the cooler months.',
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
          'Use potting soil with orchid bark and perlite. Keep drainage holes clear.',
    ),
    CareRequirement(
      icon: LucideIcons.thermometer,
      title: 'Comfort · 65–85°F',
      description: 'Average home humidity is fine. Keep away from cold drafts.',
    ),
  ],
  seasonLabel: 'Seasonal note · Review in spring',
  seasonTitle: 'Give roots room to grow',
  seasonBody:
      'Repot only when roots crowd the pot. Use a container just 1–2 inches wider.',
  botanicalNotes:
      'Native to Central American rainforests, Monstera is a climbing aroid. '
      'Its leaf splits deepen as it matures in good light. Add a moss pole to '
      'support new growth.',
  petSafetyLabel: 'Not pet-safe · keep out of reach',
  reminders: [
    CareReminder(
      icon: LucideIcons.droplets,
      title: 'Water Monstera',
      whenLabel: 'Today · 9:00 AM',
    ),
  ],
  reminderRecurrence: 'Every Thursday · next after today: Nov 12, 9:00 AM',
  history: [
    CareEvent(
      icon: LucideIcons.leaf,
      title: 'Leaves gently wiped',
      dateLabel: 'Nov 2, 2026',
      note: 'Dust removed with a damp cloth',
    ),
    CareEvent(
      icon: LucideIcons.droplets,
      title: 'Watered',
      dateLabel: 'Oct 29, 2026',
      note: 'Soil checked · watered until draining',
    ),
    CareEvent(
      icon: LucideIcons.droplets,
      title: 'Watered',
      dateLabel: 'Oct 22, 2026',
      note: 'Weekly care complete',
    ),
  ],
);