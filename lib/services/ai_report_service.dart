import 'dart:convert';
import 'api_service.dart';

class AiReportService {
  final ApiService _apiService;

  AiReportService(this._apiService);

  /// Generate a report for a project
  Future<Map<String, dynamic>> generateProjectReport(String projectId) async {
    try {
      final response = await _apiService.post(
        '/ai/projects/$projectId/report',
        {},
      );
      return response;
    } catch (e) {
      throw Exception('Failed to generate project report: $e');
    }
  }

  /// Generate a report for a task
  Future<Map<String, dynamic>> generateTaskReport(
      String projectId, String taskId) async {
    try {
      final response = await _apiService.post(
        '/ai/projects/$projectId/tasks/$taskId/report',
        {},
      );
      return response;
    } catch (e) {
      throw Exception('Failed to generate task report: $e');
    }
  }

  /// Generate a summary for an activity
  Future<Map<String, dynamic>> generateActivitySummary(
      String projectId, String taskId, String activityId) async {
    try {
      final response = await _apiService.post(
        '/ai/projects/$projectId/tasks/$taskId/activities/$activityId/summary',
        {},
      );
      return response;
    } catch (e) {
      throw Exception('Failed to generate activity summary: $e');
    }
  }
}
