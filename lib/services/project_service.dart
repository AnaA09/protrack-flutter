import '../models/project.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

class ProjectService {
  final ApiService _apiService;

  ProjectService(this._apiService);

  Future<List<Project>> getAllProjects() async {
    final response = await _apiService.get('/projects');
    debugPrint('Raw API Response: $response');

    if (response is! List) {
      debugPrint('Error: Expected List but got ${response.runtimeType}');
      return [];
    }

    final projects = response.map((item) {
      debugPrint('Parsing project item: $item');
      return Project.fromJson(item as Map<String, dynamic>);
    }).toList();

    debugPrint('Parsed Projects: ${projects.map((p) => p.name).join(', ')}');
    return projects;
  }

  Future<Project> getProject(String projectId) async {
    final response = await _apiService.get('/projects/$projectId');
    return Project.fromJson(response as Map<String, dynamic>);
  }

  Future<Project> createProject(Project project) async {
    final response = await _apiService.post('/projects', project.toJson());
    return Project.fromJson(response as Map<String, dynamic>);
  }

  Future<Project> updateProject(String projectId, Project project) async {
    final response =
        await _apiService.put('/projects/$projectId', project.toJson());
    return Project.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteProject(String projectId) async {
    await _apiService.delete('/projects/$projectId');
  }
}
