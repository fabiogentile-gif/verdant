import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/owned_plants.dart' show OwnedPlant;
import 'package:verdant/widgets/components/app_toggle.dart';
import 'package:verdant/widgets/components/detail_header.dart';
import 'package:verdant/widgets/components/filter_chip.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';

/// "Edit care reminder" screen (Figma: Care reminder scheduling).
/// UI only for now: selections are local and Save/Cancel just close the page.
class CareReminderPage extends StatefulWidget {
  const CareReminderPage({super.key, required this.plant});

  final OwnedPlant plant;

  @override
  State<CareReminderPage> createState() => _CareReminderPageState();
}

enum _CareTask { water, fertilize, repot }

class _CareReminderPageState extends State<CareReminderPage> {
  _CareTask _task = _CareTask.water;
  final Set<int> _days = {3}; // 0 = Monday … 6 = Sunday
  bool _push = true;
  bool _email = false;

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailHeader(
              title: 'Edit care reminder',
              onBack: _close,
              onMore: () {},
            ),
            Expanded(
              child: ScrollViewNoStretch(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Introduction(),
                    const SizedBox(height: 26),
                    _SelectedPlant(plant: plant),
                    const SizedBox(height: 26),
                    _FieldLabel('What kind of care?', strong: true),
                    const SizedBox(height: 13),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _taskChip(
                          _CareTask.water,
                          'Water',
                          LucideIcons.droplets,
                        ),
                        _taskChip(
                          _CareTask.fertilize,
                          'Fertilize',
                          LucideIcons.sprout,
                        ),
                        _taskChip(_CareTask.repot, 'Repot', LucideIcons.shovel),
                      ],
                    ),
                    const SizedBox(height: 26),
                    const _FieldLabel('Repeat'),
                    const SizedBox(height: 9),
                    const _ValueField(
                      icon: LucideIcons.repeat,
                      value: 'Every week',
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('On these days'),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        for (int i = 0; i < _weekdays.length; i++) ...[
                          if (i > 0) const SizedBox(width: 7),
                          Expanded(
                            child: _WeekdayOption(
                              label: _weekdays[i],
                              selected: _days.contains(i),
                              onTap: () => setState(() {
                                if (!_days.remove(i)) _days.add(i);
                              }),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 11),
                    const _Hint('Every Thursday', accent: true),
                    const SizedBox(height: 26),
                    const _FieldLabel('Starting on'),
                    const SizedBox(height: 9),
                    const _ValueField(
                      icon: LucideIcons.calendarDays,
                      value: 'Thu, November 5, 2026',
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Reminder time'),
                    const SizedBox(height: 9),
                    const _ValueField(
                      icon: LucideIcons.clock3,
                      value: '9:00 AM',
                    ),
                    const SizedBox(height: 16),
                    const _Hint('Your local time · Portland (Pacific Time)'),
                    const SizedBox(height: 26),
                    const _FieldLabel('A note for yourself (optional)'),
                    const SizedBox(height: 10),
                    const _NoteField(),
                    const SizedBox(height: 26),
                    _NotificationRow(
                      icon: LucideIcons.bell,
                      title: 'Push notification',
                      subtitle: 'A gentle nudge on your phone',
                      value: _push,
                      onChanged: (v) => setState(() => _push = v),
                    ),
                    const SizedBox(height: 17),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 17),
                    _NotificationRow(
                      icon: LucideIcons.mail,
                      title: 'Email reminder',
                      subtitle: 'Keep your inbox a little quieter',
                      value: _email,
                      onChanged: (v) => setState(() => _email = v),
                    ),
                    const SizedBox(height: 26),
                    const _SchedulePreview(),
                    const SizedBox(height: 26),
                    _FormActions(onSave: _close, onCancel: _close),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskChip(_CareTask task, String label, IconData icon) {
    return AppFilterChip(
      label: label,
      leadingIcon: icon,
      selected: _task == task,
      onTap: () => setState(() => _task = task),
    );
  }
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

class _Introduction extends StatelessWidget {
  const _Introduction();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A LITTLE CONSISTENCY',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Make care a ritual.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: 'Lora',
            fontSize: 32,
            height: 1.15,
            letterSpacing: -0.7,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A gentle nudge, right when your plant needs it. '
          'You can change this anytime.',
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

class _SelectedPlant extends StatelessWidget {
  const _SelectedPlant({required this.plant});

  final OwnedPlant plant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
              image: plant.image,
              width: 64,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${plant.species} · ${plant.room}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Icon(LucideIcons.chevronDown, size: 17, color: scheme.onSurface),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.strong = false});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        fontSize: strong ? 14 : 12,
        fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text, {this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 11,
        height: accent ? null : 1.5,
        color: accent ? scheme.primary : scheme.onSurfaceVariant,
      ),
    );
  }
}

class _ValueField extends StatelessWidget {
  const _ValueField({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Icon(icon, size: 18, color: scheme.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(LucideIcons.chevronDown, size: 15, color: scheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayOption extends StatelessWidget {
  const _WeekdayOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fill = selected ? scheme.onSecondaryContainer : scheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? scheme.onSecondaryContainer
                : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 83),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: TextFormField(
        initialValue:
            'Check the top 2 inches of soil first.\nWater only if dry.',
        maxLines: null,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          height: 1.6,
          color: scheme.onSecondaryContainer,
        ),
        cursorColor: scheme.primary,
        decoration: const InputDecoration(
          isDense: true,
          isCollapsed: true,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.onSurface),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AppToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _SchedulePreview extends StatelessWidget {
  const _SchedulePreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = scheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.calendarCheck, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your next moment of care',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Today, Nov 5 at 9:00 AM\n'
                  'Then every Thursday · next Nov 12',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.5,
                    color: color,
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

class _FormActions extends StatelessWidget {
  const _FormActions({required this.onSave, required this.onCancel});

  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(LucideIcons.arrowRight, size: 18),
          label: const Text(
            'Save reminder',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.surfaceContainerLow,
            minimumSize: const Size.fromHeight(52),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Cancel changes',
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
