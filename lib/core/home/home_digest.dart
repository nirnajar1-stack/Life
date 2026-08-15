import 'package:intl/intl.dart';

import '../../features/expenses/data/models/expense_model.dart';
import '../../features/expenses/domain/models/expense_category_taxonomy.dart';
import '../../features/habits/data/models/habit_models.dart';
import '../../features/habits/domain/habit_engine.dart';
import '../../features/tasks/data/models/task_model.dart';

final _money =
    NumberFormat.currency(locale: 'he_IL', symbol: '₪', decimalDigits: 0);

class HomeDigest {
  const HomeDigest({
    required this.overdue,
    required this.today,
    required this.thisWeek,
    required this.openCount,
    required this.monthTotal,
    required this.previousMonthTotal,
    required this.todaySpend,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.recent,
    this.habitsDueToday = 0,
    this.habitsDoneToday = 0,
  });

  final List<TaskModel> overdue;
  final List<TaskModel> today;
  final List<TaskModel> thisWeek;
  final int openCount;
  final double monthTotal;
  final double previousMonthTotal;
  final double todaySpend;
  final String? topCategory;
  final double? topCategoryAmount;
  final List<ExpenseModel> recent;
  final int habitsDueToday;
  final int habitsDoneToday;

  int get habitsPendingToday {
    final pending = habitsDueToday - habitsDoneToday;
    return pending < 0 ? 0 : pending;
  }

  bool get hasUrgentTasks => overdue.isNotEmpty || today.isNotEmpty;

  List<TaskModel> get focusTasks {
    final items = [...overdue, ...today];
    return items.take(4).toList();
  }

  List<TaskModel> get upcomingIfIdle => thisWeek.take(3).toList();

  double? get monthDeltaPercent {
    if (previousMonthTotal <= 0) {
      return monthTotal > 0 ? 100 : null;
    }
    return ((monthTotal - previousMonthTotal) / previousMonthTotal) * 100;
  }

  String get headline {
    final money = monthTotal > 0 ? ' החודש יצאו ${_money.format(monthTotal)}.' : '';
    final habits = habitsPendingToday > 0
        ? ' נשארו $habitsPendingToday הרגלים.'
        : (habitsDueToday > 0 ? ' השגרה הושלמה.' : '');

    if (overdue.isNotEmpty && today.isNotEmpty) {
      return 'יש ${_countPhrase(overdue.length, 'באיחור')} ו־${_countPhrase(today.length, 'להיום')}.$habits$money';
    }
    if (overdue.isNotEmpty) {
      return 'יש ${_countPhrase(overdue.length, 'באיחור')}.$habits$money';
    }
    if (today.isNotEmpty) {
      return 'יש ${_countPhrase(today.length, 'להיום')}.$habits$money';
    }
    if (openCount == 0) {
      if (monthTotal <= 0 && habitsDueToday == 0) {
        return 'הכל שקט — אפשר להתחיל במשימה, בהרגל או בהוצאה.';
      }
      return 'אין משימות פתוחות.$habits$money';
    }
    if (thisWeek.isNotEmpty) {
      return '${_countPhrase(thisWeek.length, 'השבוע')}, בלי דחיפות להיום.$habits$money';
    }
    return '$openCount משימות פתוחות, בלי יעד קרוב.$habits$money';
  }

  static HomeDigest from({
    required List<TaskModel> tasks,
    required List<ExpenseModel> expenses,
    List<HabitSnapshot> habits = const [],
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final todayStart = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final monthStart = DateTime(timestamp.year, timestamp.month);
    final previousStart = DateTime(timestamp.year, timestamp.month - 1);

    final overdue = tasks.where((t) => t.isOverdue).toList()
      ..sort((a, b) =>
          (a.dueDate ?? a.createdAt).compareTo(b.dueDate ?? a.createdAt));
    final today = tasks.where((t) => t.isDueToday).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final thisWeek = tasks.where((t) => t.isDueThisWeek).toList()
      ..sort((a, b) =>
          (a.dueDate ?? a.createdAt).compareTo(b.dueDate ?? a.createdAt));

    final thisMonth = expenses.where((e) => !e.createdAt.isBefore(monthStart));
    final previousMonth = expenses.where(
      (e) =>
          !e.createdAt.isBefore(previousStart) && e.createdAt.isBefore(monthStart),
    );
    final todayItems = expenses.where((e) => !e.createdAt.isBefore(todayStart));

    final byParent = <String, double>{};
    for (final expense in thisMonth) {
      final parent = ExpenseCategoryTaxonomy.resolveParent(expense.category);
      byParent[parent] = (byParent[parent] ?? 0) + expense.amount;
    }
    String? topCategory;
    double? topAmount;
    byParent.forEach((label, amount) {
      if (topAmount == null || amount > topAmount!) {
        topCategory = label;
        topAmount = amount;
      }
    });

    final recent = [...expenses]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final dueHabits =
        habits.where((item) => habitIsDueOn(item.habit, timestamp));
    final doneHabits = dueHabits.where((item) {
      final log = item.logOn(timestamp);
      return log != null && log.countsForStreak;
    });

    return HomeDigest(
      overdue: overdue,
      today: today,
      thisWeek: thisWeek,
      openCount: tasks.length,
      monthTotal: thisMonth.fold<double>(0, (sum, e) => sum + e.amount),
      previousMonthTotal:
          previousMonth.fold<double>(0, (sum, e) => sum + e.amount),
      todaySpend: todayItems.fold<double>(0, (sum, e) => sum + e.amount),
      topCategory: topCategory,
      topCategoryAmount: topAmount,
      recent: recent.take(3).toList(),
      habitsDueToday: dueHabits.length,
      habitsDoneToday: doneHabits.length,
    );
  }

  static String _countPhrase(int count, String suffix) {
    if (count == 1) return 'משימה אחת $suffix';
    return '$count משימות $suffix';
  }
}
