import '../models/task.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

class TaskService {
  final ApiService _apiService;

  TaskService(this._apiService);

  Future<List<Task>> getProjectTasks(String projectId) async {
    final response = await _apiService.get('/projects/$projectId/tasks');
    debugPrint('Raw tasks API response: $response');
    debugPrint('Response type: ${response.runtimeType}');

    // Handle the response as a direct list since Lambda returns tasks directly
    if (response is List) {
      debugPrint('Response is List with ${response.length} items');
      final tasks = response.map((item) => Task.fromJson(item)).toList();
      debugPrint(
          'Parsed ${tasks.length} tasks: ${tasks.map((t) => t.name).join(', ')}');
      return tasks;
    } else if (response is Map && response.containsKey('Items')) {
      // Fallback for responses that still use the Items wrapper
      debugPrint('Response is Map with Items key');
      return (response['Items'] as List)
          .map((item) => Task.fromJson(item))
          .toList();
    } else {
      debugPrint('Response format not recognized, returning empty list');
      return [];
    }
  }

  Future<Task> getTask(String projectId, String taskId) async {
    final response =
        await _apiService.get('/projects/$projectId/tasks/$taskId');
    return Task.fromJson(response);
  }

  Future<Task> createTask(String projectId, Task task) async {
    final response =
        await _apiService.post('/projects/$projectId/tasks', task.toJson());
    return Task.fromJson(response);
  }

  Future<Task> updateTask(String projectId, String taskId, Task task) async {
    final response = await _apiService.put(
        '/projects/$projectId/tasks/$taskId', task.toJson());
    return Task.fromJson(response);
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    await _apiService.delete('/projects/$projectId/tasks/$taskId');
  }
}
