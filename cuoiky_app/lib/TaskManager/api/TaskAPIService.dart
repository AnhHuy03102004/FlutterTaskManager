import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/Taskdb.dart';

class TaskAPIService {
  static final TaskAPIService instance = TaskAPIService._init();
  final String baseUrl = 'http://192.168.1.7/taskdb';
  TaskAPIService._init();

  Future<Taskdb> createTask(Taskdb task) async {
    final taskMap = {
      'id':task.id,
      'title': task.title,
      'description': task.description,
      'status': task.status,
      'priority': task.priority,
      'dueDate': task.dueDate?.toIso8601String(),
      'createdAt': task.createdAt.toIso8601String(),
      'updatedAt': task.updatedAt.toIso8601String(),
      'createdBy': task.createdBy,
      'assignedTo': task.assignedTo,
      'category': task.category,
      'attachments': jsonEncode(task.attachments ?? []),
      'completed': task.completed ? 1 : 0,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/tasks.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(taskMap),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Taskdb.fromMap(jsonDecode(response.body));
    } else {
      print(' Server response: ${response.body}');
      throw Exception('Tạo task thất bại');
    }
  }

  Future<List<Taskdb>> getAllTasks() async {
    final response = await http.get(Uri.parse('$baseUrl/tasks.php'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Taskdb.fromMap(e)).toList();
    } else {
      print(' Server response: ${response.body}');
      throw Exception('Không thể tải danh sách task');
    }
  }

  Future<Taskdb> updateTask(Taskdb task) async {
    final taskMap = {
      'id':task.id,
      'title': task.title,
      'description': task.description,
      'status': task.status,
      'priority': task.priority,
      'dueDate': task.dueDate?.toIso8601String(),
      'updatedAt': task.updatedAt.toIso8601String(),
      'createdBy': task.createdBy,
      'assignedTo': task.assignedTo,
      'category': task.category,
      'attachments': jsonEncode(task.attachments ?? []),
      'completed': task.completed ? 1 : 0,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/tasks.php?id=${task.id}&_method=PUT'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(taskMap),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final updated = jsonDecode(response.body);
      return Taskdb.fromMap(updated);
    } else {
      print(' Server response: ${response.body}');
      throw Exception('Cập nhật task thất bại');
    }
  }

  Future<bool> deleteTask(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks.php?id=$id&_method=DELETE'),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print(' Server response: ${response.body}');
      return false;
    }
  }

  Future<List<Taskdb>> getTasksByUser(String userId) async {
    final allTasks = await getAllTasks();
    return allTasks.where((task) =>
    task.createdBy == userId || task.assignedTo == userId).toList();
  }

  Future<List<Taskdb>> searchTasks(String userId, String keyword) async {
    final tasks = await getTasksByUser(userId);
    final lowerKeyword = keyword.toLowerCase();
    return tasks.where((task) =>
    task.title.toLowerCase().contains(lowerKeyword) ||
        task.description.toLowerCase().contains(lowerKeyword) ||
        (task.category ?? '').toLowerCase().contains(lowerKeyword)).toList();
  }

  /// ✅ Thêm phương thức này để fix lỗi trong TaskListScreen.dart
  Future<List<Taskdb>> searchAllTasks(String keyword) async {
    final tasks = await getAllTasks();
    final lowerKeyword = keyword.toLowerCase();
    return tasks.where((task) =>
    task.title.toLowerCase().contains(lowerKeyword) ||
        task.description.toLowerCase().contains(lowerKeyword) ||
        (task.category ?? '').toLowerCase().contains(lowerKeyword)).toList();
  }
}
