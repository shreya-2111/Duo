import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DuoLocalDb {
  static Database? _database;
  static final List<Map<String, dynamic>> _inMemoryTasks = [];
  static final List<Map<String, dynamic>> _inMemoryExpenses = [];

  static Future<Database?> get database async {
    if (kIsWeb) return null;
    try {
      if (_database != null) return _database!;
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      debugPrint('sqflite database init failed: $e');
      return null;
    }
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'duo_local_v1.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Expenses Cache
        await db.execute('''
          CREATE TABLE cached_expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER UNIQUE,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            notes TEXT,
            sync_status TEXT DEFAULT 'synced'
          )
        ''');

        // Tasks Cache (Personal + Shared)
        await db.execute('''
          CREATE TABLE cached_tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER UNIQUE,
            type TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            dueDate TEXT,
            isDone INTEGER NOT NULL DEFAULT 0,
            assigned_to_name TEXT,
            sync_status TEXT DEFAULT 'synced'
          )
        ''');

        // Monthly Budget Cache
        await db.execute('''
          CREATE TABLE cached_budget (
            id INTEGER PRIMARY KEY,
            month INTEGER NOT NULL,
            year INTEGER NOT NULL,
            amount_limit REAL NOT NULL,
            alert_level TEXT
          )
        ''');
      },
    );
  }

  // --- Expenses Cache CRUD ---
  static Future<void> saveExpenses(List<dynamic> remoteExpenses) async {
    try {
      final db = await database;
      if (db == null) {
        for (final exp in remoteExpenses) {
          final amt = double.tryParse(exp['amount']?.toString() ?? '0') ?? 0.0;
          final d = exp['expense_date'] ?? exp['date'] ?? DateTime.now().toIso8601String();
          _inMemoryExpenses.removeWhere((e) => e['remote_id'] == exp['id']);
          _inMemoryExpenses.insert(0, {
            'remote_id': exp['id'],
            'title': exp['title'] ?? exp['name'] ?? 'Expense',
            'amount': amt,
            'category': exp['category'] ?? 'Other',
            'date': d,
            'notes': exp['description'] ?? exp['notes'] ?? '',
            'sync_status': 'synced',
          });
        }
        return;
      }

      final batch = db.batch();
      for (final exp in remoteExpenses) {
        final amt = double.tryParse(exp['amount']?.toString() ?? '0') ?? 0.0;
        final d = exp['expense_date'] ?? exp['date'] ?? DateTime.now().toIso8601String();
        batch.insert(
          'cached_expenses',
          {
            'remote_id': exp['id'],
            'title': exp['title'] ?? exp['name'] ?? 'Expense',
            'amount': amt,
            'category': exp['category'] ?? 'Other',
            'date': d,
            'notes': exp['description'] ?? exp['notes'] ?? '',
            'sync_status': 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('saveExpenses error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getExpenses() async {
    try {
      final db = await database;
      if (db == null) return List.unmodifiable(_inMemoryExpenses);
      return await db.query('cached_expenses', orderBy: 'date DESC, id DESC');
    } catch (e) {
      debugPrint('getExpenses error: $e');
      return List.unmodifiable(_inMemoryExpenses);
    }
  }

  static Future<int> insertLocalExpense(Map<String, dynamic> data) async {
    try {
      final db = await database;
      if (db == null) {
        _inMemoryExpenses.insert(0, data);
        return 1;
      }
      return await db.insert('cached_expenses', data);
    } catch (e) {
      debugPrint('insertLocalExpense error: $e');
      return 0;
    }
  }

  static Future<int> deleteExpense(int remoteId) async {
    try {
      final db = await database;
      if (db == null) {
        _inMemoryExpenses.removeWhere((e) => e['remote_id'] == remoteId);
        return 1;
      }
      return await db.delete('cached_expenses', where: 'remote_id = ?', whereArgs: [remoteId]);
    } catch (e) {
      debugPrint('deleteExpense error: $e');
      return 0;
    }
  }

  // --- Tasks Cache CRUD ---
  static Future<void> saveTasks(List<dynamic> remoteTasks) async {
    try {
      final db = await database;
      if (db == null) {
        for (final task in remoteTasks) {
          final assigned = task['assigned_to_details'] != null
              ? task['assigned_to_details']['name']
              : null;
          final item = {
            'remote_id': task['id'],
            'type': task['type'] ?? task['visibility'] ?? 'PERSONAL',
            'title': task['title'] ?? 'Task',
            'description': task['description'] ?? '',
            'dueDate': task['due_date'],
            'isDone': (task['is_done'] == true || task['isDone'] == 1) ? 1 : 0,
            'assigned_to_name': assigned,
            'sync_status': 'synced',
          };
          _inMemoryTasks.removeWhere((t) => t['remote_id'] == task['id']);
          _inMemoryTasks.insert(0, item);
        }
        return;
      }

      final batch = db.batch();
      for (final task in remoteTasks) {
        final assigned = task['assigned_to_details'] != null
            ? task['assigned_to_details']['name']
            : null;
        batch.insert(
          'cached_tasks',
          {
            'remote_id': task['id'],
            'type': task['type'] ?? task['visibility'] ?? 'PERSONAL',
            'title': task['title'] ?? 'Task',
            'description': task['description'] ?? '',
            'dueDate': task['due_date'],
            'isDone': (task['is_done'] == true || task['isDone'] == 1) ? 1 : 0,
            'assigned_to_name': assigned,
            'sync_status': 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('saveTasks error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getTasks({String? type}) async {
    try {
      final db = await database;
      if (db == null) {
        if (type != null) {
          return _inMemoryTasks.where((t) => t['type'] == type).toList();
        }
        return List.unmodifiable(_inMemoryTasks);
      }
      if (type != null) {
        return await db.query('cached_tasks', where: 'type = ?', whereArgs: [type], orderBy: 'isDone ASC, id DESC');
      }
      return await db.query('cached_tasks', orderBy: 'isDone ASC, id DESC');
    } catch (e) {
      debugPrint('getTasks error: $e');
      return List.unmodifiable(_inMemoryTasks);
    }
  }

  static Future<int> updateTaskStatus(int remoteId, bool isDone) async {
    try {
      final db = await database;
      if (db == null) {
        final idx = _inMemoryTasks.indexWhere((t) => t['remote_id'] == remoteId);
        if (idx != -1) {
          _inMemoryTasks[idx]['isDone'] = isDone ? 1 : 0;
        }
        return 1;
      }
      return await db.update(
        'cached_tasks',
        {'isDone': isDone ? 1 : 0},
        where: 'remote_id = ?',
        whereArgs: [remoteId],
      );
    } catch (e) {
      debugPrint('updateTaskStatus error: $e');
      return 0;
    }
  }

  static Future<int> deleteTask(int remoteId) async {
    try {
      final db = await database;
      if (db == null) {
        _inMemoryTasks.removeWhere((t) => t['remote_id'] == remoteId);
        return 1;
      }
      return await db.delete('cached_tasks', where: 'remote_id = ?', whereArgs: [remoteId]);
    } catch (e) {
      debugPrint('deleteTask error: $e');
      return 0;
    }
  }

  static Future<void> clearAll() async {
    try {
      final db = await database;
      _inMemoryTasks.clear();
      _inMemoryExpenses.clear();
      if (db != null) {
        await db.delete('cached_expenses');
        await db.delete('cached_tasks');
        await db.delete('cached_budget');
      }
    } catch (e) {
      debugPrint('clearAll error: $e');
    }
  }
}
