import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';

class TaskService {
  TaskService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _firestore.collection('tasks');

  Stream<List<Task>> streamTasks(String userId) {
    return _tasksRef.where('userId', isEqualTo: userId).snapshots().map((
      query,
    ) {
      final tasks =
          query.docs.map(Task.fromFirestore).toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return tasks;
    });
  }

  Future<void> addTask({
    required String userId,
    required String title,
    required String description,
    required DateTime dueDate,
    required TaskPriority priority,
  }) async {
    final task = Task(
      id: '',
      userId: userId,
      title: title.trim(),
      description: description.trim(),
      dueDate: dueDate,
      isCompleted: false,
      priority: priority,
    );

    await _tasksRef.add(task.toMap());
  }

  Future<void> toggleCompleted({
    required String taskId,
    required String userId,
    required bool isCompleted,
  }) async {
    final docRef = _tasksRef.doc(taskId);
    final doc = await docRef.get();

    if (!doc.exists || doc.data()?['userId'] != userId) {
      throw StateError('You are not allowed to update this task.');
    }

    await docRef.update({'isCompleted': isCompleted});
  }

  Future<void> deleteTask({
    required String taskId,
    required String userId,
  }) async {
    final docRef = _tasksRef.doc(taskId);
    final doc = await docRef.get();

    if (!doc.exists || doc.data()?['userId'] != userId) {
      throw StateError('You are not allowed to delete this task.');
    }

    await docRef.delete();
  }
}
