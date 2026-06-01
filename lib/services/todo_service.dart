import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/models.dart';
import 'local_todo_database.dart';

class TodoService {
  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app());

  FirebaseAuth get _auth => FirebaseAuth.instanceFor(app: Firebase.app());

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('todos');

  final LocalTodoDatabase _localDb = LocalTodoDatabase.instance;

  Stream<List<Todo>> getTodos() {
    final userId = _userId;

    if (userId == null) {
      return const Stream.empty();
    }

    return _collection.where('user_id', isEqualTo: userId).snapshots().map((
      snap,
    ) {
      final todos = snap.docs.map(Todo.fromDoc).toList();

      todos.sort((a, b) {
        return b.createdAt.compareTo(a.createdAt);
      });

      for (final todo in todos) {
        _localDb.insertOrUpdateFromTodo(todo);
      }

      return todos;
    });
  }

  Future<List<Map<String, dynamic>>> getTodosFromSQLite() async {
    final userId = _userId;

    if (userId == null) return [];

    return _localDb.getLocalTodos(userId);
  }

  Future<List<Map<String, dynamic>>> checkSQLiteTodos() async {
    final userId = _userId;

    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    final rows = await _localDb.getLocalTodos(userId);

    print('========== SQLITE TODO CHECK ==========');
    print('Total local todos: ${rows.length}');

    for (final row in rows) {
      print(row);
    }

    print('======================================');

    return rows;
  }

  Future<void> addTodo({
    required String title,
    String description = '',
    String subject = 'General',
    DateTime? deadline,
    String priority = 'medium',
    String notes = '',
    bool reminderEnabled = false,
  }) async {
    final userId = _userId;

    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    final now = DateTime.now();
    final finalNotes = notes.trim().isNotEmpty
        ? notes.trim()
        : description.trim();

    final docRef = await _collection.add({
      'user_id': userId,
      'title': title.trim(),
      'description': finalNotes,
      'notes': finalNotes,
      'subject': subject.trim(),
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline),
      'priority': priority.toLowerCase().trim(),
      'reminder_enabled': reminderEnabled,
      'is_done': false,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'completed_at': null,
    });

    await _localDb.insertOrUpdateTodo(
      id: docRef.id,
      firebaseId: docRef.id,
      userId: userId,
      title: title.trim(),
      description: finalNotes,
      notes: finalNotes,
      subject: subject.trim(),
      deadline: deadline,
      priority: priority.toLowerCase().trim(),
      reminderEnabled: reminderEnabled,
      isDone: false,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
      syncStatus: 'synced',
    );
  }

  Future<void> toggleDone(String todoId, bool currentValue) async {
    final userId = _userId;

    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    final newValue = !currentValue;
    final now = DateTime.now();

    await _collection.doc(todoId).update({
      'is_done': newValue,
      'completed_at': newValue ? FieldValue.serverTimestamp() : null,
      'updated_at': FieldValue.serverTimestamp(),
    });

    final doc = await _collection.doc(todoId).get();

    if (doc.exists) {
      final todo = Todo.fromDoc(doc);

      await _localDb.insertOrUpdateTodo(
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
        isDone: newValue,
        createdAt: todo.createdAt,
        updatedAt: now,
        completedAt: newValue ? now : null,
        syncStatus: 'synced',
      );
    }
  }

  Future<void> updateTodo(
    String todoId, {
    required String title,
    String description = '',
    String? subject,
    DateTime? deadline,
    String? priority,
    String? notes,
    bool? reminderEnabled,
  }) async {
    final userId = _userId;

    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    final now = DateTime.now();
    final finalNotes = notes?.trim() ?? description.trim();

    await _collection.doc(todoId).update({
      'title': title.trim(),
      'description': finalNotes,
      'notes': finalNotes,
      if (subject != null) 'subject': subject.trim(),
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline),
      if (priority != null) 'priority': priority.toLowerCase().trim(),
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      'updated_at': FieldValue.serverTimestamp(),
    });

    final doc = await _collection.doc(todoId).get();

    if (doc.exists) {
      final todo = Todo.fromDoc(doc);

      await _localDb.insertOrUpdateTodo(
        id: todo.id,
        firebaseId: todo.id,
        userId: todo.userId,
        title: title.trim(),
        description: finalNotes,
        notes: finalNotes,
        subject: subject?.trim() ?? todo.subject,
        deadline: deadline,
        priority: priority?.toLowerCase().trim() ?? todo.priority,
        reminderEnabled: reminderEnabled ?? todo.reminderEnabled,
        isDone: todo.isDone,
        createdAt: todo.createdAt,
        updatedAt: now,
        completedAt: todo.completedAt,
        syncStatus: 'synced',
      );
    }
  }

  Future<void> deleteTodo(String todoId) async {
    await _collection.doc(todoId).delete();
    await _localDb.deleteLocalTodo(todoId);
  }
}
