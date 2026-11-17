import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/care_schedule.dart';
import 'package:verdant/data/owned_plants.dart';
import 'package:verdant/data/settings.dart';
import 'package:verdant/services/notifications.dart';
import 'package:verdant/widgets/components/app_toggle.dart';
import 'package:verdant/widgets/components/detail_header.dart';
import 'package:verdant/widgets/components/filter_chip.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';

final _longDate = DateFormat('EEE, MMMM d, y', 'en_US');
final _dayName = DateFormat('EEEE', 'en_US');
final _shortDay = DateFormat('EEE', 'en_US');

/// Create or edit the care reminder of one plant for one kind of care
/// (Figma: Care reminder scheduling). Saved into [careSchedule].
class CareReminderPage extends StatefulWidget {
  const CareReminderPage({
    super.key,
    required this.plant,
    this.kind = CareKind.water,
  });

  final OwnedPlant plant;
  final CareKind kind;

  @override
  State<CareReminderPage> createState() => _CareReminderPageState();
}

/// Form state: repeat interval, weekdays, start date, time, note and channels.
class _CareReminderPageState extends State<CareReminderPage> {
  static const _repeatOptions = [1, 7, 14, 30];
  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  late OwnedPlant _plant;
  late CareKind _kind;
  int _everyDays = 7;
  final Set<int> _weekdays = {}; // DateTime.monday … DateTime.sunday
  late DateTime _start;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  final _note = TextEditingController();
  bool _push = true;
  bool _email = false;
  bool _existing = false;

  bool get _weekly => _everyDays == 7 || _everyDays == 14;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _kind = widget.kind;
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Fills the form from the saved plans for (plant, kind), or defaults.
  void _load() {
    final today = dateOnly(DateTime.now());
    final plans = careSchedule.plansFor(_plant.id, kind: _kind)
      ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
    _existing = plans.isNotEmpty;
    _weekdays.clear();

    if (plans.isNotEmpty) {
      final first = plans.first;
      _everyDays = first.everyDays;
      _time = TimeOfDay.fromDateTime(first.nextDue);
      final firstDay = dateOnly(first.nextDue);
      _start = firstDay.isBefore(today) ? today : firstDay;
      _weekdays.addAll(plans.map((p) => p.nextDue.weekday));
      _note.text = first.note ?? '';
      _push = first.push;
      _email = first.email;
    } else {
      _everyDays = switch (_kind) {
        CareKind.water => _plant.speciesInfo.waterEveryDays,
        CareKind.fertilize => 30,
        CareKind.repot => 365,
      };
      _start = today.add(const Duration(days: 1));
      _weekdays.add(_start.weekday);
      _time = const TimeOfDay(hour: 9, minute: 0);
      _note.text = _kind == CareKind.water
          ? _plant.guide.waterInstructions
          : '';
      _push = appSettings.push;
      _email = appSettings.email;
    }
  }

  /// The plans this form describes (not saved yet).
  List<CarePlan> _buildPlans() {
    DateTime at(DateTime day) =>
        day.add(Duration(hours: _time.hour, minutes: _time.minute));
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();

    CarePlan plan(DateTime due) => careSchedule.newPlan(
      plantId: _plant.id,
      kind: _kind,
      nextDue: due,
      everyDays: _everyDays,
      note: note,
      push: _push,
      email: _email,
    );

    if (!_weekly) return [plan(at(_start))];
    return [
      for (final weekday in _weekdays.toList()..sort())
        plan(at(_start.add(Duration(days: (weekday - _start.weekday) % 7)))),
    ];
  }

  /// First two upcoming reminders, for the preview card.
  List<DateTime> _preview(List<CarePlan> plans) {
    final now = DateTime.now();
    final dates = <DateTime>[];
    for (final p in plans) {
      var due = p.nextDue;
      for (var i = 0; i < 3; i++) {
        if (!due.isBefore(now)) dates.add(due);
        due = due.add(Duration(days: p.everyDays));
      }
    }
    dates.sort();
    return dates.take(2).toList();
  }

  String get _daysHint {
    if (!_weekly || _weekdays.isEmpty) return '';
    final days = _weekdays.toList()..sort();
    final monday = DateTime(2024, 1, 1);
    String name(int weekday, {bool short = false}) {
      final d = monday.add(Duration(days: weekday - 1));
      return short ? _shortDay.format(d) : _dayName.format(d);
    }

    final every = _everyDays == 14 ? 'Every other' : 'Every';
    if (days.length == 1) return '$every ${name(days.first)}';
    if (days.length == 7) {
      return _everyDays == 14 ? 'Every day, every other week' : 'Every day';
    }
    final names = days.map((d) => name(d, short: true)).toList();
    return '$every ${names.sublist(0, names.length - 1).join(', ')} '
        'and ${names.last}';
  }

  Future<T?> _sheet<T>(WidgetBuilder builder) => showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: builder,
  );

  Future<void> _pickPlant() async {
    final picked = await _sheet<OwnedPlant>(
      (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            for (final p in ownedPlants)
              ListTile(
                leading: CircleAvatar(backgroundImage: p.image),
                title: Text(p.name),
                subtitle: Text(p.room),
                onTap: () => Navigator.of(context).pop(p),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked.id != _plant.id) {
      setState(() {
        _plant = picked;
        _load();
      });
    }
  }

  Future<void> _pickRepeat() async {
    final options = {..._repeatOptions, _everyDays}.toList()..sort();
    final picked = await _sheet<int>((context) {
      final scheme = Theme.of(context).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final days in options)
                ListTile(
                  title: Text(formatEvery(days)),
                  trailing: days == _everyDays
                      ? Icon(LucideIcons.check, size: 18, color: scheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(days),
                ),
            ],
          ),
        ),
      );
    });
    if (picked == null) return;
    setState(() {
      _everyDays = picked;
      if (_weekly && _weekdays.isEmpty) _weekdays.add(_start.weekday);
    });
  }

  Future<void> _pickStart() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _start.isBefore(today) ? today : _start,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _start = dateOnly(picked));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _setPush(bool value) async {
    if (value) {
      if (!appSettings.push) {
        _snack('Phone notifications are off in your profile settings.');
      } else {
        await NotificationService.requestPermission();
      }
    }
    if (mounted) setState(() => _push = value);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    if (_weekly && _weekdays.isEmpty) {
      _snack('Pick at least one day.');
      return;
    }
    final plans = _buildPlans();
    careSchedule.replacePlans(_plant.id, _kind, plans);
    final next = _preview(plans);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).maybePop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          next.isEmpty
              ? 'Reminder saved.'
              : 'Reminder saved. Next: ${formatDue(next.first)}.',
        ),
      ),
    );
  }

  Future<void> _showMenu() async {
    if (!_existing) {
      _snack('This reminder isn’t saved yet.');
      return;
    }
    final delete = await _sheet<bool>((context) {
      final scheme = Theme.of(context).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ListTile(
            leading: Icon(LucideIcons.trash2, color: scheme.error),
            title: Text(
              'Delete this reminder',
              style: TextStyle(color: scheme.error),
            ),
            onTap: () => Navigator.of(context).pop(true),
          ),
        ),
      );
    });
    if (delete != true || !mounted) return;
    careSchedule.replacePlans(_plant.id, _kind, const []);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).maybePop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${_kind.verb} reminder for ${_plant.name} deleted.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = _weekly && _weekdays.isEmpty ? <CarePlan>[] : _buildPlans();
    final preview = _preview(plans);
    final timeZone = NotificationService.timeZone;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailHeader(
              title: _existing ? 'Edit care reminder' : 'New care reminder',
              onBack: () => Navigator.of(context).maybePop(),
              onMore: _showMenu,
            ),
            Expanded(
              child: ScrollViewNoStretch(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Introduction(),
                    const SizedBox(height: 26),
                    _SelectedPlant(plant: _plant, onTap: _pickPlant),
                    const SizedBox(height: 26),
                    const _FieldLabel('What kind of care?', strong: true),
                    const SizedBox(height: 13),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final kind in CareKind.values)
                          AppFilterChip(
                            label: kind.verb,
                            leadingIcon: kind.icon,
                            selected: _kind == kind,
                            onTap: () => setState(() {
                              _kind = kind;
                              _load();
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    const _FieldLabel('Repeat'),
                    const SizedBox(height: 9),
                    _ValueField(
                      icon: LucideIcons.repeat,
                      value: formatEvery(_everyDays),
                      onTap: _pickRepeat,
                    ),
                    if (_weekly) ...[
                      const SizedBox(height: 16),
                      const _FieldLabel('On these days'),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          for (int i = 0; i < 7; i++) ...[
                            if (i > 0) const SizedBox(width: 7),
                            Expanded(
                              child: _WeekdayOption(
                                label: _weekdayLetters[i],
                                selected: _weekdays.contains(i + 1),
                                onTap: () => setState(() {
                                  if (!_weekdays.remove(i + 1)) {
                                    _weekdays.add(i + 1);
                                  }
                                }),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 11),
                      _Hint(
                        _weekdays.isEmpty ? 'Pick at least one day' : _daysHint,
                        accent: true,
                      ),
                    ],
                    const SizedBox(height: 26),
                    const _FieldLabel('Starting on'),
                    const SizedBox(height: 9),
                    _ValueField(
                      icon: LucideIcons.calendarDays,
                      value: _longDate.format(_start),
                      onTap: _pickStart,
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Reminder time'),
                    const SizedBox(height: 9),
                    _ValueField(
                      icon: LucideIcons.clock3,
                      value: _time.format(context),
                      onTap: _pickTime,
                    ),
                    const SizedBox(height: 16),
                    _Hint(
                      timeZone == null
                          ? 'Your phone’s local time'
                          : 'Your local time · $timeZone',
                    ),
                    const SizedBox(height: 26),
                    const _FieldLabel('A note for yourself (optional)'),
                    const SizedBox(height: 10),
                    _NoteField(controller: _note),
                    const SizedBox(height: 26),
                    _NotificationRow(
                      icon: LucideIcons.bell,
                      title: 'Push notification',
                      subtitle: 'A gentle nudge on your phone',
                      value: _push,
                      onChanged: _setPush,
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
                      subtitle: 'Saved for when email reminders arrive',
                      value: _email,
                      onChanged: (v) => setState(() => _email = v),
                    ),
                    const SizedBox(height: 26),
                    _SchedulePreview(
                      first: preview.isEmpty ? null : preview.first,
                      second: preview.length > 1 ? preview[1] : null,
                      everyLabel: _weekly && _weekdays.isNotEmpty
                          ? _daysHint
                          : formatEvery(_everyDays),
                    ),
                    const SizedBox(height: 26),
                    _FormActions(
                      onSave: _save,
                      onCancel: () => Navigator.of(context).maybePop(),
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

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

/// Page title and a short explanation.
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

/// The plant the reminder is for.
class _SelectedPlant extends StatelessWidget {
  const _SelectedPlant({required this.plant, required this.onTap});

  final OwnedPlant plant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.primaryContainer,
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
        ),
      ),
    );
  }
}

/// Label above a form field.
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

/// Small helper text under a field.
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

/// Tappable field showing a value (date, time) that opens a picker.
class _ValueField extends StatelessWidget {
  const _ValueField({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final VoidCallback onTap;

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
        onTap: onTap,
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

/// One selectable day of the week.
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

/// Optional free-text note saved with the reminder.
class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

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
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
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

/// A notification channel (push or email) with its toggle.
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

/// Preview of the next reminders the form would create.
class _SchedulePreview extends StatelessWidget {
  const _SchedulePreview({
    required this.first,
    required this.second,
    required this.everyLabel,
  });

  final DateTime? first;
  final DateTime? second;
  final String everyLabel;

  static final _date = DateFormat('MMM d', 'en_US');
  static final _time = DateFormat('h:mm a', 'en_US');

  String get _lines {
    final f = first;
    if (f == null) return 'Pick a day to see your first reminder.';
    final today = dateOnly(DateTime.now());
    final day = dateOnly(f);
    final when = day == today
        ? 'Today, ${_date.format(f)}'
        : day == today.add(const Duration(days: 1))
        ? 'Tomorrow, ${_date.format(f)}'
        : DateFormat('EEE, MMM d', 'en_US').format(f);
    final s = second;
    final then = s == null
        ? ''
        : '\nThen ${everyLabel.toLowerCase()} · next ${_date.format(s)}';
    return '$when at ${_time.format(f)}$then';
  }

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
                  _lines,
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

/// Save and cancel buttons at the bottom of the form.
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
