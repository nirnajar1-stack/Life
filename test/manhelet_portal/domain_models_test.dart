import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/manhelet_portal/domain/models.dart';

void main() {
  group('PortalTask attention rules', () {
    test('overdue open task requires attention', () {
      final task = PortalTask(
        id: '1',
        titleHe: 'בדיקה',
        status: TaskStatus.open,
        priority: TaskPriority.medium,
        treatmentUnitId: 'u',
        familyId: 'f',
        updatedAt: DateTime.now().toUtc(),
        dueAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      );
      expect(task.isOverdue, isTrue);
      expect(task.requiresAttention, isTrue);
    });

    test('completed task is not overdue', () {
      final task = PortalTask(
        id: '2',
        titleHe: 'סגורה',
        status: TaskStatus.completed,
        priority: TaskPriority.critical,
        treatmentUnitId: 'u',
        familyId: 'f',
        updatedAt: DateTime.now().toUtc(),
        dueAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      );
      expect(task.isOpen, isFalse);
      expect(task.isOverdue, isFalse);
    });

    test('blocked requires attention without due date', () {
      final task = PortalTask(
        id: '3',
        titleHe: 'חסומה',
        status: TaskStatus.blocked,
        priority: TaskPriority.low,
        treatmentUnitId: 'u',
        familyId: 'f',
        updatedAt: DateTime.now().toUtc(),
      );
      expect(task.requiresAttention, isTrue);
    });
  });

  group('status mapping', () {
    test('round-trip db codes', () {
      for (final s in TaskStatus.values) {
        expect(taskStatusFromDb(taskStatusToDb(s)), s);
      }
    });
  });

  group('person age', () {
    test('calculates age', () {
      final dob = DateTime(2000, 1, 1);
      final p = PersonSummary(
        id: 'p',
        firstNameHe: 'א',
        lastNameHe: 'ב',
        treatmentUnitId: 'u',
        familyId: 'f',
        status: 'returned',
        dateOfBirth: dob,
      );
      expect(p.ageYears, greaterThanOrEqualTo(25));
    });
  });
}
