import '../models/task.dart';
import 'api_service.dart';

class TaskService {
  final ApiService _apiService;

  TaskService(this._apiService);

  Future<List<Task>> getProjectTasks(String projectId) async {
    final response = await _apiService.get('/projects/$projectId/tasks');
    return (response['Items'] as List)
        .map((item) => Task.fromJson(item))
        .toList();
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
