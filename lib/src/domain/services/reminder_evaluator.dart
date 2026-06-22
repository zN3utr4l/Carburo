import '../models/enums.dart';
import '../models/reminder.dart';
import '../models/reminder_evaluation.dart';

/// Pure logic for reminder status and recurrence. No I/O.
///
/// Status is derived from `today` and the vehicle's current odometer (the max
/// odometer across fuel-ups and expenses) — it is never stored.
class ReminderEvaluator {
  const ReminderEvaluator();

  ReminderEvaluation evaluate(
    Reminder r, {
    required DateTime today,
    required double currentOdometer,
  }) {
    final daysRemaining = r.dueDate?.difference(today).inDays;
    final kmRemaining = r.dueOdometer == null
        ? null
        : r.dueOdometer! - currentOdometer;

    if (!r.active) {
      return ReminderEvaluation(
        reminder: r,
        status: ReminderStatus.completed,
        daysRemaining: daysRemaining,
        kmRemaining: kmRemaining,
      );
    }

    final dueByDate = r.dueDate != null && !today.isBefore(r.dueDate!);
    final dueByKm = r.dueOdometer != null && currentOdometer >= r.dueOdometer!;

    final ReminderStatus status;
    if (dueByDate || dueByKm) {
      status = ReminderStatus.overdue;
    } else {
      final upcomingByDate =
          r.leadDays != null &&
          r.dueDate != null &&
          !today.isBefore(r.dueDate!.subtract(Duration(days: r.leadDays!)));
      final upcomingByKm =
          r.leadKm != null &&
          r.dueOdometer != null &&
          currentOdometer >= (r.dueOdometer! - r.leadKm!);
      status = (upcomingByDate || upcomingByKm)
          ? ReminderStatus.upcoming
          : ReminderStatus.ok;
    }

    return ReminderEvaluation(
      reminder: r,
      status: status,
      daysRemaining: daysRemaining,
      kmRemaining: kmRemaining,
    );
  }

  /// The next occurrence after a completion, or null for a one-shot reminder.
  Reminder? nextOccurrence(
    Reminder r, {
    required DateTime completedDate,
    required double completedOdometer,
  }) {
    final isFixed = r.recurUnit == RecurUnit.fixedDate;
    final hasTimeRecur =
        r.recurEvery != null &&
        r.recurUnit != null &&
        r.recurUnit != RecurUnit.km &&
        !isFixed;
    final kmEvery =
        r.recurKmEvery ?? (r.recurUnit == RecurUnit.km ? r.recurEvery : null);
    final hasKmRecur = kmEvery != null;

    if (!isFixed && !hasTimeRecur && !hasKmRecur) {
      return null; // one-shot
    }

    var nextDue = r.dueDate;
    var nextOdo = r.dueOdometer;

    if (isFixed) {
      final base = r.dueDate ?? completedDate;
      nextDue = _nextFixedDate(base.month, base.day, completedDate);
    } else if (hasTimeRecur) {
      nextDue = _addInterval(completedDate, r.recurEvery!, r.recurUnit!);
    }
    if (hasKmRecur) {
      nextOdo = completedOdometer + kmEvery;
    }

    return r.copyWith(
      dueDate: nextDue,
      dueOdometer: nextOdo,
      lastCompletedDate: completedDate,
      lastCompletedOdometer: completedOdometer,
    );
  }

  DateTime _addInterval(DateTime from, int n, RecurUnit unit) => switch (unit) {
    RecurUnit.day => from.add(Duration(days: n)),
    RecurUnit.month => DateTime(from.year, from.month + n, from.day),
    RecurUnit.year => DateTime(from.year + n, from.month, from.day),
    _ => from,
  };

  DateTime _nextFixedDate(int month, int day, DateTime after) {
    var d = DateTime(after.year, month, day);
    if (!d.isAfter(after)) d = DateTime(after.year + 1, month, day);
    return d;
  }
}
