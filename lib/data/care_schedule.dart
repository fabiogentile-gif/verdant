import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/owned_plants.dart';
import 'package:verdant/data/storage.dart';

enum CareKind {
  water(
    verb: 'Water',
    doneLabel: 'Watered',
    filterLabel: 'Watering',
    needsLabel: 'Needs water',
    icon: LucideIcons.droplets,
  ),
  fertilize(
    verb: 'Fertilize',
    doneLabel: 'Fertilized',
    filterLabel: 'Feeding',
    needsLabel: 'Needs feeding',
    icon: LucideIcons.sprout,
  ),
  repot(
    verb: 'Repot',
    doneLabel: 'Repotted',
    filterLabel: 'Repotting',
    needsLabel: 'Needs repotting',
    icon: LucideIcons.shovel,
  );

  const CareKind({
    required this.verb,
    required this.doneLabel,
    required this.filterLabel,
    required this.needsLabel,
    required this.icon,
  });

  final String verb;
  final String doneLabel;
  final String filterLabel;
  final String needsLabel;
  final IconData icon;
}

/// A recurring care routine for one plant (e.g. water every 7 days).
class CarePlan {
  CarePlan({
    required this.id,
    required this.plantId,
    required this.kind,
    required this.nextDue,
    this.everyDays = 7,
    this.note,
    this.push = true,
    this.email = false,
  });

  final String id;
  final String plantId;
  final CareKind kind;
  final int everyDays;
  final String? note;
  final bool push;
  final bool email;

  /// Date and time of the next reminder.
  DateTime nextDue;

  OwnedPlant? get plant => plantCollection.byId(plantId);

  Map<String, Object?> toJson() => {
    'id': id,
    'plantId': plantId,
    'kind': kind.name,
    'everyDays': everyDays,
    'nextDue': nextDue.toIso8601String(),
    'note': note,
    'push': push,
    'email': email,
  };

  factory CarePlan.fromJson(Map json) => CarePlan(
    id: json['id'] as String,
    plantId: json['plantId'] as String,
    kind: CareKind.values.byName(json['kind'] as String),
    everyDays: json['everyDays'] as int,
    nextDue: DateTime.parse(json['nextDue'] as String),
    note: json['note'] as String?,
    push: json['push'] as bool? ?? true,
    email: json['email'] as bool? ?? false,
  );
}

/// One reminder on the calendar (a single occurrence of a [CarePlan]).
class CareTask {
  const CareTask({required this.plan, required this.plant, required this.due});

  final CarePlan plan;
  final OwnedPlant plant;
  final DateTime due;

  String get title => '${plan.kind.verb} ${plant.name}';
}

/// A care action that has been done.
class CompletedCare {
  const CompletedCare({
    required this.plantId,
    required this.title,
    required this.date,
    this.note,
    this.kind,
  });

  final String plantId;
  final String title;
  final DateTime date;
  final String? note;

  /// Null for care that is not part of a routine (e.g. wiping leaves).
  final CareKind? kind;

  IconData get icon => kind?.icon ?? LucideIcons.leaf;
  OwnedPlant? get plant => plantCollection.byId(plantId);

  Map<String, Object?> toJson() => {
    'plantId': plantId,
    'title': title,
    'date': date.toIso8601String(),
    'note': note,
    'kind': kind?.name,
  };

  factory CompletedCare.fromJson(Map json) => CompletedCare(
    plantId: json['plantId'] as String,
    title: json['title'] as String,
    date: DateTime.parse(json['date'] as String),
    note: json['note'] as String?,
    kind: json['kind'] == null
        ? null
        : CareKind.values.byName(json['kind'] as String),
  );
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

final _day = DateFormat('EEE, MMM d', 'en_US');
final _time = DateFormat('h:mm a', 'en_US');

/// "Today · 9:00 AM", "Tomorrow · 9:00 AM", "Sat, Nov 7 · 9:00 AM".
String formatDue(DateTime due, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final day = dateOnly(due);
  final time = _time.format(due);
  if (day.isBefore(today)) return 'Overdue since ${_day.format(due)}';
  if (day == today) return 'Today · $time';
  if (day == today.add(const Duration(days: 1))) return 'Tomorrow · $time';
  return '${_day.format(due)} · $time';
}

/// "Every day", "Every week", "Every 2 weeks", "Every 12 days"…
String formatEvery(int days) => switch (days) {
  1 => 'Every day',
  7 => 'Every week',
  14 => 'Every 2 weeks',
  30 => 'Every month',
  _ => 'Every $days days',
};

String _newId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}';

/// Care calendar shared by the app, saved on the device.
class CareSchedule extends ChangeNotifier {
  CareSchedule({DateTime? now}) {
    _seed(now ?? DateTime.now());
  }

  final List<CarePlan> _plans = [];
  final List<CompletedCare> _completed = [];

  List<CarePlan> get plans => List.unmodifiable(_plans);

  List<CarePlan> plansFor(String plantId, {CareKind? kind}) => _plans
      .where((p) => p.plantId == plantId && (kind == null || p.kind == kind))
      .toList();

  /// Most recent first.
  List<CompletedCare> get completed => List.unmodifiable(
    [..._completed]..sort((a, b) => b.date.compareTo(a.date)),
  );

  List<CompletedCare> completedFor(String plantId) =>
      completed.where((c) => c.plantId == plantId).toList();

  CompletedCare? lastDone(String plantId, CareKind kind) {
    for (final c in completed) {
      if (c.plantId == plantId && c.kind == kind) return c;
    }
    return null;
  }

  /// All reminders from [from] (inclusive) to [to] (exclusive), sorted.
  /// Overdue reminders are reported once, at their original date.
  List<CareTask> tasksBetween(DateTime from, DateTime to) {
    final tasks = <CareTask>[];
    for (final plan in _plans) {
      final plant = plan.plant;
      if (plant == null) continue;
      var due = plan.nextDue;
      if (due.isBefore(from)) {
        tasks.add(CareTask(plan: plan, plant: plant, due: due));
        due = due.add(Duration(days: plan.everyDays));
        while (due.isBefore(from)) {
          due = due.add(Duration(days: plan.everyDays));
        }
      }
      while (due.isBefore(to)) {
        tasks.add(CareTask(plan: plan, plant: plant, due: due));
        due = due.add(Duration(days: plan.everyDays));
      }
    }
    tasks.sort((a, b) => a.due.compareTo(b.due));
    return tasks;
  }

  /// First reminder at or after [from].
  CareTask? firstFrom(DateTime from, {String? plantId}) {
    final next = tasksBetween(from, from.add(const Duration(days: 366))).where(
      (t) =>
          !t.due.isBefore(from) && (plantId == null || t.plant.id == plantId),
    );
    return next.isEmpty ? null : next.first;
  }

  /// Reminders due today or overdue.
  List<CareTask> dueTasks({DateTime? now, String? plantId}) {
    final today = dateOnly(now ?? DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    return tasksBetween(today, tomorrow)
        .where((t) => t.due.isBefore(tomorrow))
        .where((t) => plantId == null || t.plant.id == plantId)
        .toList();
  }

  bool needsCare(OwnedPlant plant, {DateTime? now}) =>
      dueTasks(now: now, plantId: plant.id).isNotEmpty;

  /// "Needs water" / "Healthy".
  String statusLabel(OwnedPlant plant, {DateTime? now}) {
    final due = dueTasks(now: now, plantId: plant.id);
    return due.isEmpty ? 'Healthy' : due.first.plan.kind.needsLabel;
  }

  /// "Water today · 9:00 AM" / "Next watering · Sun, Nov 8" / "No reminders yet".
  String scheduleLabel(OwnedPlant plant, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final due = dueTasks(now: at, plantId: plant.id);
    if (due.isNotEmpty) {
      final t = due.first;
      return t.due.isBefore(dateOnly(at))
          ? '${t.plan.kind.verb} · overdue since ${_day.format(t.due)}'
          : '${t.plan.kind.verb} today · ${_time.format(t.due)}';
    }
    final next = firstFrom(dateOnly(at), plantId: plant.id);
    if (next == null) return 'No reminders yet';
    return 'Next ${next.plan.kind.filterLabel.toLowerCase()} · '
        '${_day.format(next.due)}';
  }

  /// Marks [task] as done now and moves its plan to the next occurrence.
  void complete(CareTask task, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final plan = task.plan;
    _completed.add(
      CompletedCare(
        plantId: task.plant.id,
        title: plan.kind.doneLabel,
        date: at,
        note: 'Marked as done in Verdant',
        kind: plan.kind,
      ),
    );
    final base = dateOnly(at)
        .add(Duration(hours: plan.nextDue.hour, minutes: plan.nextDue.minute));
    plan.nextDue = base.add(Duration(days: plan.everyDays));
    _save();
  }

  /// Replaces every plan of [kind] for [plantId] with [plans].
  void replacePlans(String plantId, CareKind kind, List<CarePlan> plans) {
    _plans.removeWhere((p) => p.plantId == plantId && p.kind == kind);
    _plans.addAll(plans);
    _save();
  }

  /// New plan with a fresh id.
  CarePlan newPlan({
    required String plantId,
    required CareKind kind,
    required DateTime nextDue,
    int everyDays = 7,
    String? note,
    bool push = true,
    bool email = false,
  }) => CarePlan(
    id: _newId(),
    plantId: plantId,
    kind: kind,
    nextDue: nextDue,
    everyDays: everyDays,
    note: note,
    push: push,
    email: email,
  );

  /// Default watering routine for a newly added plant (first one tomorrow).
  void addDefaultPlan(OwnedPlant plant, {required int everyDays}) {
    final tomorrow = dateOnly(DateTime.now()).add(const Duration(days: 1));
    _plans.add(
      newPlan(
        plantId: plant.id,
        kind: CareKind.water,
        nextDue: tomorrow.add(const Duration(hours: 9)),
        everyDays: everyDays,
        note: plant.guide.waterInstructions,
      ),
    );
    _save();
  }

  void removePlant(String plantId) {
    _plans.removeWhere((p) => p.plantId == plantId);
    _completed.removeWhere((c) => c.plantId == plantId);
    _save();
  }

  void restore() {
    final json = Storage.read(StorageKeys.careSchedule);
    if (json is! Map) return;
    _plans
      ..clear()
      ..addAll(
        (json['plans'] as List? ?? []).whereType<Map>().map(CarePlan.fromJson),
      );
    _completed
      ..clear()
      ..addAll(
        (json['completed'] as List? ?? []).whereType<Map>().map(
          CompletedCare.fromJson,
        ),
      );
    notifyListeners();
  }

  void reset({DateTime? now}) {
    _plans.clear();
    _completed.clear();
    _seed(now ?? DateTime.now());
    notifyListeners();
  }

  void _save() {
    Storage.write(StorageKeys.careSchedule, {
      'plans': _plans.map((p) => p.toJson()).toList(),
      'completed': _completed.map((c) => c.toJson()).toList(),
    });
    notifyListeners();
  }

  /// Demo routine relative to today, used on first launch.
  void _seed(DateTime now) {
    final today = dateOnly(now);
    DateTime at(int days) => today.add(Duration(days: days, hours: 9));

    _plans.addAll([
      CarePlan(
        id: 'water-monstera',
        plantId: 'monstera',
        kind: CareKind.water,
        nextDue: at(0),
        note: 'Check the top 2 inches of soil. Water only if dry.',
      ),
      CarePlan(
        id: 'water-peace-lily',
        plantId: 'peace-lily',
        kind: CareKind.water,
        nextDue: at(2),
      ),
      CarePlan(
        id: 'water-rubber-plant',
        plantId: 'rubber-plant',
        kind: CareKind.water,
        nextDue: at(3),
        everyDays: 12,
      ),
      CarePlan(
        id: 'water-golden-pothos',
        plantId: 'golden-pothos',
        kind: CareKind.water,
        nextDue: at(4),
        everyDays: 9,
      ),
    ]);

    _completed.addAll([
      CompletedCare(
        plantId: 'monstera',
        title: 'Leaves gently wiped',
        date: at(-3),
        note: 'Dust removed with a damp cloth',
      ),
      CompletedCare(
        plantId: 'monstera',
        title: 'Watered',
        date: at(-7),
        note: 'Soil checked · watered until draining',
        kind: CareKind.water,
      ),
      CompletedCare(
        plantId: 'monstera',
        title: 'Watered',
        date: at(-14),
        note: 'Weekly care complete',
        kind: CareKind.water,
      ),
    ]);
  }
}

final careSchedule = CareSchedule();
