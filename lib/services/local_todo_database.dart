import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class LocalTodoDatabase {
  LocalTodoDatabase._internal();

  static final LocalTodoDatabase instance = LocalTodoDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scoremind_todos.db');

    print('========== SQLITE DATABASE PATH ==========');
    print(path);
    print('=========================================');

    return openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id TEXT PRIMARY KEY,
        firebase_id TEXT,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        notes TEXT,
        subject TEXT,
        deadline INTEGER,
        priority TEXT,
        reminder_enabled INTEGER NOT NULL DEFAULT 0,
        is_done INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        completed_at INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'synced'
      )
    ''');
  }

  Future<void> insertOrUpdateTodo({
    required String id,
    required String firebaseId,
    required String userId,
    required String title,
    required String description,
    required String notes,
    required String subject,
    required DateTime? deadline,
    required String priority,
    required bool reminderEnabled,
    required bool isDone,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? completedAt,
    String syncStatus = 'synced',
  }) async {
    final db = await database;

    await db.insert('todos', {
      'id': id,
      'firebase_id': firebaseId,
      'user_id': userId,
      'title': title,
      'description': description,
      'notes': notes,
      'subject': subject,
      'deadline': deadline?.millisecondsSinceEpoch,
      'priority': priority,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'is_done': isDone ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'sync_status': syncStatus,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertOrUpdateFromTodo(
    Todo todo, {
    String syncStatus = 'synced',
  }) async {
    await insertOrUpdateTodo(
      id: todo.id,
      firebaseId: todo.id,
      userId: todo.userId,
      title: todo.title,
      description: todo.description,
      notes: todo.notes,
      subject: todo.subject,
      deadline: todo.deadline,
      priority: todo.priority,
      reminderEnabled: todo.reminderEnabled,
      isDone: todo.isDone,
      createdAt: todo.createdAt,
      updatedAt: todo.updatedAt,
      completedAt: todo.completedAt,
      syncStatus: syncStatus,
    );
  }

  Future<List<Map<String, dynamic>>> getLocalTodos(String userId) async {
    final db = await database;

    return db.query(
      'todos',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> deleteLocalTodo(String todoId) async {
    final db = await database;

    await db.delete('todos', where: 'id = ?', whereArgs: [todoId]);
  }

  Future<void> clearUserTodos(String userId) async {
    final db = await database;

    await db.delete('todos', where: 'user_id = ?', whereArgs: [userId]);
  }
}
