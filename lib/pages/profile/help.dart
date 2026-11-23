import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/widgets/components/subpage_scaffold.dart';
import 'package:verdant/l10n/i18n.dart';

/// Frequently asked questions about using Verdant.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _faq = [
    (
      'How do I know when to water?',
      'Each plant has a watering reminder based on its species. When it is '
          'due, it appears in Today on the Activity tab and on your home '
          'screen. Always check the soil first: if the top inch is still '
          'damp, wait a day or two.',
    ),
    (
      'How do I add a plant?',
      'Open My plants and tap “+” or “Add a plant to your collection”. Pick '
          'the species, give it a name and a room, and Verdant sets up its '
          'first watering reminder.',
    ),
    (
      'Can I change or delete a reminder?',
      'Yes. Open the plant, tap a reminder under “Your care rhythm”, change '
          'the days, time or repeat, and save. Use the “⋯” menu to delete it.',
    ),
    (
      'Why didn’t I get a notification?',
      'Check that phone notifications are on in Profile and that Android '
          'allows notifications for Verdant (Profile → Privacy & '
          'permissions). Android may delay reminders slightly to save '
          'battery.',
    ),
    (
      'Is my payment real?',
      'No. Verdant’s checkout is a demo: cards are checked but never '
          'charged, PayPal is simulated, and only the last 4 digits of a '
          'card are kept.',
    ),
    (
      'Where is my data stored?',
      'Your plants, reminders, cart, orders and settings are saved to your '
          'account and on this phone. You can erase them from Privacy & '
          'permissions.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SubpageScaffold(
      title: 'Help & support'.tr,
      actionIcon: LucideIcons.messageCircle,
      heading: 'We’re here to help you grow.'.tr,
      lede: 'Answers to the questions new plant parents ask most.'.tr,
      children: [
        for (final (question, answer) in _faq) ...[
          SoftCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                iconColor: scheme.primary,
                collapsedIconColor: scheme.onSurfaceVariant,
                title: Text(
                  question.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                children: [
                  Text(
                    answer.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      height: 1.55,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
