import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/owned_plants.dart';

enum CareKind {
  water(
    verb: 'Water',
    doneLabel: 'Watered',
    filterLabel: 'Watering',
    icon: LucideIcons.droplets,
  );

  const CareKind({
    required this.verb,
    required this.doneLabel,
    required this.filterLabel,
    required this.icon,
  });

  final String verb;
  final String doneLabel;
  final String filterLabel;
  final IconData icon;
}

/// A recurring care routine for one plant (e.g. water every 7 days).
class CarePlan {
  CarePlan({
    required this.plant,
    required this.kind,
    required this.nextDue,
    this.everyDays = 7,
    this.instructions,
  });

  final OwnedPlant plant;
  final CareKind kind;
  final int everyDays;
  final String? instructions;

  /// Date and time of the next reminder.
  DateTime nextDue;
}

/// One reminder on the calendar (a single occurrence of a [CarePlan]).
class CareTask {
  const CareTask({required this.plan, required this.due});

  final CarePlan plan;
  final DateTime due;

  OwnedPlant get plant => plan.plant;
  String get title => '${plan.kind.verb} ${plant.name}';
}

/// A care action that has been done.
class CompletedCare {
  const CompletedCare({
    required this.plant,
    required this.title,
    required this.date,
    required this.icon,
    this.note,
    this.kind,
  });

  final OwnedPlant plant;
  final String title;
  final DateTime date;
  final IconData icon;
  final String? note;

  /// Null for care that is not part of a routine (e.g. wiping leaves).
  final CareKind? kind;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Care calendar shared by the app (in memory, demo data relative to today).
class CareSchedule extends ChangeNotifier {
  CareSchedule({DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    DateTime at(int days) => today.add(Duration(days: days, hours: 9));
    OwnedPlant plant(String name) =>
        ownedPlants.firstWhere((p) => p.name == name);

    final monstera = plant('Monstera');
    _plans.addAll([
      CarePlan(
        plant: monstera,
        kind: CareKind.water,
        nextDue: at(0),
        instructions: 'Check the top 2 inches of soil. Water only if dry.',
      ),
      CarePlan(
        plant: plant('Peace Lily'),
        kind: CareKind.water,
        nextDue: at(2),
      ),
      CarePlan(
        plant: plant('Rubber Plant'),
        kind: CareKind.water,
        nextDue: at(3),
        everyDays: 12,
      ),
      CarePlan(
        plant: plant('Golden Pothos'),
        kind: CareKind.water,
        nextDue: at(4),
        everyDays: 9,
      ),
    ]);

    _completed.addAll([
      CompletedCare(
        plant: monstera,
        title: 'Leaves gently wiped',
        date: at(-3),
        icon: LucideIcons.leaf,
        note: 'Dust removed with a damp cloth',
      ),
      CompletedCare(
        plant: monstera,
        title: 'Watered',
        date: at(-7),
        icon: LucideIcons.droplets,
        note: 'Soil checked · watered until draining',
        kind: CareKind.water,
      ),
      CompletedCare(
        plant: monstera,
        title: 'Watered',
        date: at(-14),
        icon: LucideIcons.droplets,
        note: 'Weekly care complete',
        kind: CareKind.water,
      ),
    ]);
  }

  final List<CarePlan> _plans = [];
  final List<CompletedCare> _completed = [];

  /// Most recent first.
  List<CompletedCare> get completed => List.unmodifiable(
    [..._completed]..sort((a, b) => b.date.compareTo(a.date)),
  );

  /// All reminders from [from] (inclusive) to [to] (exclusive), sorted.
  /// Overdue reminders are reported on [from].
  List<CareTask> tasksBetween(DateTime from, DateTime to) {
    final tasks = <CareTask>[];
    for (final plan in _plans) {
      var due = plan.nextDue;
      if (due.isBefore(from)) {
        tasks.add(CareTask(plan: plan, due: due));
        due = due.add(Duration(days: plan.everyDays));
      }
      while (due.isBefore(to)) {
        tasks.add(CareTask(plan: plan, due: due));
        due = due.add(Duration(days: plan.everyDays));
      }
    }
    tasks.sort((a, b) => a.due.compareTo(b.due));
    return tasks;
  }

  /// First reminder at or after [from].
  CareTask? firstFrom(DateTime from) {
    final next = tasksBetween(
      from,
      from.add(const Duration(days: 366)),
    ).where((t) => !t.due.isBefore(from));
    return next.isEmpty ? null : next.first;
  }

  /// Marks [task] as done now and moves its plan to the next occurrence.
  void complete(CareTask task, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final plan = task.plan;
    _completed.add(
      CompletedCare(
        plant: plan.plant,
        title: plan.kind.doneLabel,
        date: at,
        icon: plan.kind.icon,
        note: 'Marked as done in Verdant',
        kind: plan.kind,
      ),
    );
    final base = _dateOnly(at)
        .add(Duration(hours: plan.nextDue.hour, minutes: plan.nextDue.minute));
    plan.nextDue = base.add(Duration(days: plan.everyDays));
    notifyListeners();
  }
}

final careSchedule = CareSchedule();
