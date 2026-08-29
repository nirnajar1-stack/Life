import 'package:flutter/material.dart';

import '../money/money_hub_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/tasks/presentation/screens/tasks_list_screen.dart';
import 'app_module.dart';

/// Central registry of all top-level modules shown on the home dashboard.
///
/// Add a new module by appending a single [AppModule] entry here and
/// pointing `builder` to its entry screen.
const List<AppModule> appModules = [
  AppModule(
    id: 'tasks',
    title: 'משימות',
    subtitle: 'ניהול המשימות שלי',
    icon: Icons.checklist_rtl,
    color: Color(0xFF1976D2),
    builder: _buildTasks,
  ),
  AppModule(
    id: 'calendar',
    title: 'יומן',
    subtitle: 'אירועים מטלגרם ו־Google',
    icon: Icons.calendar_month_outlined,
    color: Color(0xFF0F766E),
    builder: _buildCalendar,
  ),
  AppModule(
    id: 'expenses',
    title: 'כסף',
    subtitle: 'הוצאות, הכנסות ותזרים',
    icon: Icons.account_balance_wallet_outlined,
    color: Color(0xFF2E7D32),
    builder: _buildExpenses,
  ),
];

Widget _buildTasks(BuildContext context) => const TasksListScreen();

Widget _buildCalendar(BuildContext context) => const CalendarScreen();

Widget _buildExpenses(BuildContext context) => const MoneyHubScreen();
