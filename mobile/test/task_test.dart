import 'package:flutter_test/flutter_test.dart';
import 'package:duo/core/models/task_model.dart';

void main() {
  group('TaskModel Serialization & Logic Tests', () {
    test('Correctly deserializes personal task with category, repeat_type, reminder, and due_time', () {
      final json = {
        'id': 10,
        'title': 'Dentist appointment',
        'description': 'Regular 6 month checkup',
        'category': 'Health',
        'priority': 'HIGH',
        'status': 'PENDING',
        'is_done': false,
        'due_date': '2026-11-20',
        'due_time': '15:30:00',
        'repeat_type': 'MONTHLY',
        'has_reminder': true,
        'reminder_time': '14:30:00',
        'creator_details': {'id': 1, 'name': 'Alex Sharma'},
      };

      final task = TaskModel.fromJson(json);
      expect(task.id, 10);
      expect(task.title, 'Dentist appointment');
      expect(task.category, 'Health');
      expect(task.priority, 'HIGH');
      expect(task.status, 'PENDING');
      expect(task.isDone, false);
      expect(task.dueDate, '2026-11-20');
      expect(task.dueTime, '15:30:00');
      expect(task.repeatType, 'MONTHLY');
      expect(task.hasReminder, true);
      expect(task.reminderTime, '14:30:00');
      expect(task.creatorName, 'Alex Sharma');
    });

    test('Correctly identifies overdue task', () {
      final json = {
        'id': 11,
        'title': 'Overdue tax payment',
        'priority': 'HIGH',
        'status': 'PENDING',
        'due_date': '2020-01-01',
      };

      final task = TaskModel.fromJson(json);
      expect(task.isOverdue, true);
    });

    test('Completed task is not marked overdue even if due_date is in past', () {
      final json = {
        'id': 12,
        'title': 'Old completed bill',
        'priority': 'MEDIUM',
        'status': 'COMPLETED',
        'is_done': true,
        'due_date': '2020-01-01',
      };

      final task = TaskModel.fromJson(json);
      expect(task.isDone, true);
      expect(task.isOverdue, false);
    });

    test('Serializes task to JSON payload', () {
      final task = TaskModel(
        id: 15,
        title: 'Weekly grocery prep',
        priority: 'MEDIUM',
        status: 'PENDING',
        isDone: false,
        category: 'Home',
        repeatType: 'WEEKLY',
        hasReminder: true,
        reminderTime: '09:00:00',
        dueDate: '2026-11-08',
      );

      final json = task.toJson();
      expect(json['id'], 15);
      expect(json['title'], 'Weekly grocery prep');
      expect(json['category'], 'Home');
      expect(json['priority'], 'MEDIUM');
      expect(json['repeat_type'], 'WEEKLY');
      expect(json['has_reminder'], true);
      expect(json['reminder_time'], '09:00:00');
    });
  });

  group('TaskSummaryCounts Tests', () {
    test('Correctly parses task summary response', () {
      final json = {
        'personal': {
          'total': 8,
          'pending': 4,
          'in_progress': 1,
          'completed': 3,
          'overdue': 1,
          'today': 2,
        },
        'counts': {
          'completed_total': 3,
          'pending_total': 5,
        },
      };

      final summary = TaskSummaryCounts.fromJson(json);
      expect(summary.completedTotal, 3);
      expect(summary.pendingTotal, 5);
      expect(summary.personalPending, 4);
      expect(summary.personalInProgress, 1);
      expect(summary.personalCompleted, 3);
      expect(summary.personalOverdue, 1);
      expect(summary.personalToday, 2);
    });
  });
}
