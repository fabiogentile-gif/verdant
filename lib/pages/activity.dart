import 'package:flutter/material.dart';
import 'package:verdant/theme/theme.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/care_schedule.dart';
import 'package:verdant/data/owned_plants.dart';
import 'package:verdant/pages/care_reminder.dart';
import 'package:verdant/pages/personal_plant_details.dart';
import 'package:verdant/search_field.dart';
import 'package:verdant/widgets/components/filter_chip.dart';
import 'package:verdant/widgets/components/page_header.dart';
import 'package:verdant/widgets/components/plant_card.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';

final _day = DateFormat('EEE, MMM d', 'en_US');
final _time = DateFormat('h:mm a', 'en_US');
final _fullDate = DateFormat('MMM d, y', 'en_US');

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// "November 5–11, 2026", across months/years when needed.
String _rangeLabel(DateTime start, DateTime endInclusive) {
  final month = DateFormat('MMMM', 'en_US');
  if (start.year != endInclusive.year) {
    final f = DateFormat('MMMM d, y', 'en_US');
    return '${f.format(start)} – ${f.format(endInclusive)}';
  }
  if (start.month != endInclusive.month) {
    return '${month.format(start)} ${start.day} – '
        '${month.format(endInclusive)} ${endInclusive.day}, ${start.year}';
  }
  return '${month.format(start)} ${start.day}–${endInclusive.day}, '
      '${start.year}';
}

/// Activity tab (Figma: Activity): today's care, what's coming up and
/// what has been done.
class Activity extends StatefulWidget {
  const Activity({super.key});

  @override
  State<Activity> createState() => _ActivityState();
}

class _ActivityState extends State<Activity> {
  static const _ranges = [7, 14, 30];

  int _rangeDays = 7;
  CareKind? _kind; // null = all care
  OwnedPlant? _plant; // null = all plants
  bool _showAllHistory = false;

  bool _matches(OwnedPlant plant, CareKind? kind) =>
      (_plant == null || plant == _plant) && (_kind == null || kind == _kind);

  void _openPlant(OwnedPlant plant) {
    final details = plant.details;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => details != null
            ? PersonalPlantDetails(plant: plant, details: details)
            : CareReminderPage(plant: plant),
      ),
    );
  }

  void _openReminder([OwnedPlant? plant]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CareReminderPage(plant: plant ?? _plant ?? ownedPlants.first),
      ),
    );
  }

  void _complete(CareTask task) {
    careSchedule.complete(task);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${task.plant.name} is happy. '
            'Next: ${_day.format(task.plan.nextDue)}.',
          ),
        ),
      );
  }

  Future<void> _pickRange() async {
    final choice = await _showOptions<int>(
      context,
      title: 'Show reminders for',
      options: {for (final d in _ranges) d: 'Next $d days'},
      selected: _rangeDays,
    );
    if (choice case _OptionPicked(:final value)) {
      setState(() => _rangeDays = value);
    }
  }

  Future<void> _pickPlant() async {
    final choice = await _showOptions<OwnedPlant?>(
      context,
      title: 'Show care for',
      options: {
        null: 'All plants',
        for (final p in ownedPlants) p: '${p.name} · ${p.room}',
      },
      selected: _plant,
    );
    if (choice case _OptionPicked(:final value)) {
      setState(() => _plant = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Activity',
        actionIcon: LucideIcons.calendarDays,
        onActionTap: _pickRange,
      ),
      body: ListenableBuilder(
        listenable: careSchedule,
        builder: (context, _) {
          final now = DateTime.now();
          final today = _dateOnly(now);
          final tomorrow = today.add(const Duration(days: 1));
          final rangeEnd = today.add(Duration(days: _rangeDays));

          final all = careSchedule.tasksBetween(today, rangeEnd);
          final dueToday = all.where((t) => t.due.isBefore(tomorrow)).toList();
          final comingUp = all.where((t) => !t.due.isBefore(tomorrow)).toList();
          final next = careSchedule.firstFrom(rangeEnd);

          bool visible(CareTask t) => _matches(t.plant, t.plan.kind);
          final history = careSchedule.completed
              .where((c) => _matches(c.plant, c.kind))
              .toList();

          return ScrollViewNoStretch(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader.eyebrowDate(
                  now,
                  title: 'A moment of care.',
                  subtitle: 'Little rituals. Happier plants. All in one place.',
                ),
                const SizedBox(height: 24),
                _CareOverview(
                  dueToday: dueToday.length,
                  comingUp: comingUp.length,
                  plants: ownedPlants.length,
                ),
                const SizedBox(height: 24),
                _ReviewControls(
                  rangeLabel: _rangeLabel(
                    today,
                    rangeEnd.subtract(const Duration(days: 1)),
                  ),
                  rangeDays: _rangeDays,
                  onRangeTap: _pickRange,
                  kind: _kind,
                  onKindChanged: (k) => setState(() => _kind = k),
                  plantLabel: _plant?.name ?? 'All plants',
                  plantSelected: _plant != null,
                  onPlantTap: _pickPlant,
                ),
                const SizedBox(height: 24),
                _TodaySection(
                  tasks: dueToday.where(visible).toList(),
                  today: today,
                  onOpen: _openPlant,
                  onComplete: _complete,
                ),
                const SizedBox(height: 24),
                _ComingUpSection(
                  tasks: comingUp.where(visible).toList(),
                  next: next != null && visible(next) ? next : null,
                  onManage: _openReminder,
                  onOpen: (t) => _openReminder(t.plant),
                  onSchedule: _openReminder,
                ),
                const SizedBox(height: 24),
                _HistorySection(
                  events: history,
                  today: today,
                  showAll: _showAllHistory,
                  onToggle: () =>
                      setState(() => _showAllHistory = !_showAllHistory),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

class _CareOverview extends StatelessWidget {
  const _CareOverview({
    required this.dueToday,
    required this.comingUp,
    required this.plants,
  });

  final int dueToday;
  final int comingUp;
  final int plants;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget metric(int value, String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 29,
              fontWeight: FontWeight.w400,
              color: scheme.surfaceContainerLow,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: scheme.secondaryContainer,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.onSecondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          metric(dueToday, 'due today'),
          const SizedBox(width: 12),
          metric(comingUp, 'coming up'),
          const SizedBox(width: 12),
          metric(plants, 'plants at home'),
        ],
      ),
    );
  }
}

class _ReviewControls extends StatelessWidget {
  const _ReviewControls({
    required this.rangeLabel,
    required this.rangeDays,
    required this.onRangeTap,
    required this.kind,
    required this.onKindChanged,
    required this.plantLabel,
    required this.plantSelected,
    required this.onPlantTap,
  });

  final String rangeLabel;
  final int rangeDays;
  final VoidCallback onRangeTap;
  final CareKind? kind;
  final ValueChanged<CareKind?> onKindChanged;
  final String plantLabel;
  final bool plantSelected;
  final VoidCallback onPlantTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                rangeLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRangeTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    'Next $rangeDays days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 14,
                    color: scheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppFilterChip(
              label: 'All care',
              selected: kind == null,
              onTap: () => onKindChanged(null),
            ),
            for (final k in CareKind.values)
              AppFilterChip(
                label: k.filterLabel,
                selected: kind == k,
                onTap: () => onKindChanged(k),
              ),
            AppFilterChip(
              label: plantLabel,
              selected: plantSelected,
              trailingIcon: LucideIcons.chevronDown,
              onTap: onPlantTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _TodaySection extends StatelessWidget {
  const _TodaySection({
    required this.tasks,
    required this.today,
    required this.onOpen,
    required this.onComplete,
  });

  final List<CareTask> tasks;
  final DateTime today;
  final ValueChanged<OwnedPlant> onOpen;
  final ValueChanged<CareTask> onComplete;

  String _schedule(CareTask t) {
    if (t.due.isBefore(today)) {
      return '${t.plan.kind.verb} · overdue since ${_day.format(t.due)}';
    }
    return '${t.plan.kind.verb} today · ${_time.format(t.due)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(
          'Today',
          actionLabel:
              '${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'}',
        ),
        if (tasks.isEmpty) ...[
          const SizedBox(height: 12),
          _SoftNote(
            icon: LucideIcons.sparkles,
            text: 'Nothing due today. Enjoy the green.',
          ),
        ],
        for (final task in tasks) ...[
          const SizedBox(height: 12),
          PlantCard(
            name: task.plant.name,
            subtitle: '${task.plant.room} · ${task.plant.species}',
            image: task.plant.image,
            status: PlantStatus.needsCare,
            statusLabel: 'Needs ${task.plan.kind.verb.toLowerCase()}',
            scheduleLabel: _schedule(task),
            onTap: () => onOpen(task.plant),
          ),
          if (task.plan.instructions != null) ...[
            const SizedBox(height: 12),
            Text(
              task.plan.instructions!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => onComplete(task),
            icon: const Icon(LucideIcons.arrowRight, size: 18),
            label: Text(
              'Mark as ${task.plan.kind.doneLabel.toLowerCase()}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.surfaceContainerLow,
              minimumSize: const Size.fromHeight(50),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ComingUpSection extends StatelessWidget {
  const _ComingUpSection({
    required this.tasks,
    required this.next,
    required this.onManage,
    required this.onOpen,
    required this.onSchedule,
  });

  final List<CareTask> tasks;
  final CareTask? next;
  final VoidCallback onManage;
  final ValueChanged<CareTask> onOpen;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(
          'Coming up',
          actionLabel: 'Manage →',
          onAction: onManage,
        ),
        if (tasks.isEmpty) ...[
          const SizedBox(height: 12),
          _SoftNote(
            icon: LucideIcons.calendarCheck,
            text: 'No other reminders in this period.',
          ),
        ],
        for (final task in tasks) ...[
          const SizedBox(height: 12),
          _ReminderTile(task: task, onTap: () => onOpen(task)),
        ],
        if (next != null) ...[
          const SizedBox(height: 12),
          _SoftNote(
            icon: LucideIcons.calendarDays,
            text:
                'Then ${next!.title} · ${_day.format(next!.due)}, '
                '${_time.format(next!.due)}',
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onSchedule,
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text(
            'Schedule a care reminder',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primaryContainer,
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

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.task, required this.onTap});

  final CareTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardSoft(scheme),
      ),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(
                    image: task.plant.image,
                    width: 56,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        task.plant.room,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_day.format(task.due)} · ${_time.format(task.due)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: scheme.onSurface,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.events,
    required this.today,
    required this.showAll,
    required this.onToggle,
  });

  static const _collapsedCount = 3;

  final List<CompletedCare> events;
  final DateTime today;
  final bool showAll;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weekStart = today.subtract(const Duration(days: 6));
    final shown = showAll ? events : events.take(_collapsedCount).toList();
    final thisWeek = shown.where((e) => !e.date.isBefore(weekStart)).toList();
    final earlier = shown.where((e) => e.date.isBefore(weekStart)).toList();
    final canToggle = events.length > _collapsedCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(
          'Little rituals, completed.',
          actionLabel: canToggle ? (showAll ? 'Show less' : 'See all →') : null,
          onAction: onToggle,
        ),
        if (events.isEmpty) ...[
          const SizedBox(height: 17),
          _SoftNote(
            icon: LucideIcons.leaf,
            text: 'Completed care will appear here.',
          ),
        ],
        if (thisWeek.isNotEmpty) ...[
          const SizedBox(height: 17),
          const _GroupLabel('THIS WEEK'),
          for (final e in thisWeek) ...[
            const SizedBox(height: 17),
            _CompletedRow(event: e),
          ],
        ],
        if (thisWeek.isNotEmpty && earlier.isNotEmpty) ...[
          const SizedBox(height: 17),
          Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
        ],
        if (earlier.isNotEmpty) ...[
          const SizedBox(height: 17),
          const _GroupLabel('EARLIER'),
          for (final e in earlier) ...[
            const SizedBox(height: 17),
            _CompletedRow(event: e),
          ],
        ],
      ],
    );
  }
}

class _CompletedRow extends StatelessWidget {
  const _CompletedRow({required this.event});

  final CompletedCare event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(event.icon, size: 15, color: scheme.onSecondaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _fullDate.format(event.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${event.plant.name} · ${event.plant.room}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSecondaryContainer,
                ),
              ),
              if (event.note != null) ...[
                const SizedBox(height: 5),
                Text(
                  event.note!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Small pieces
// ---------------------------------------------------------------------------

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, {this.actionLabel, this.onAction});

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
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'Lora',
              fontSize: 23,
              letterSpacing: -0.5,
              fontWeight: FontWeight.w400,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAction,
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

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _SoftNote extends StatelessWidget {
  const _SoftNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                height: 1.5,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Option picker (bottom sheet)
// ---------------------------------------------------------------------------

/// Distinguishes "picked null" from "dismissed".
sealed class _OptionResult<T> {}

class _OptionPicked<T> extends _OptionResult<T> {
  _OptionPicked(this.value);
  final T value;
}

Future<_OptionResult<T>?> _showOptions<T>(
  BuildContext context, {
  required String title,
  required Map<T, String> options,
  required T selected,
}) async {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  final result = await showModalBottomSheet<_OptionResult<T>>(
    context: context,
    useSafeArea: true,
    backgroundColor: theme.scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _SectionHeading(title),
            ),
            for (final entry in options.entries)
              ListTile(
                title: Text(
                  entry.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: scheme.onSurface,
                  ),
                ),
                trailing: entry.key == selected
                    ? Icon(LucideIcons.check, size: 18, color: scheme.primary)
                    : null,
                onTap: () =>
                    Navigator.of(context).pop(_OptionPicked<T>(entry.key)),
              ),
          ],
        ),
      ),
    ),
  );
  return result;
}
