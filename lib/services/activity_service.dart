import '../models/activity.dart';
import 'api_service.dart';

class ActivityService {
  final ApiService _apiService;

  ActivityService(this._apiService);

  Future<List<Activity>> getTaskActivities(
      String projectId, String taskId) async {
    final response =
        await _apiService.get('/projects/$projectId/tasks/$taskId/activities');
    // Handle the response as a direct list since Lambda returns activities directly
    if (response is List) {
      return response.map((item) => Activity.fromJson(item)).toList();
    } else if (response is Map && response.containsKey('Items')) {
      // Fallback for responses that still use the Items wrapper
      return (response['Items'] as List)
          .map((item) => Activity.fromJson(item))
          .toList();
    } else {
      return [];
    }
  }

  Future<Activity> getActivity(
      String projectId, String taskId, String activityId) async {
    final response = await _apiService
        .get('/projects/$projectId/tasks/$taskId/activities/$activityId');
    return Activity.fromJson(response);
  }

  Future<Activity> createActivity(
      String projectId, String taskId, Activity activity) async {
    final response = await _apiService.post(
      '/projects/$projectId/tasks/$taskId/activities',
      activity.toJson(),
    );
    return Activity.fromJson(response);
  }

  Future<Activity> updateActivity(String projectId, String taskId,
      String activityId, Activity activity) async {
    final response = await _apiService.put(
      '/projects/$projectId/tasks/$taskId/activities/$activityId',
      activity.toJson(),
    );
    return Activity.fromJson(response);
  }

  Future<void> deleteActivity(
      String projectId, String taskId, String activityId) async {
    await _apiService
        .delete('/projects/$projectId/tasks/$taskId/activities/$activityId');
  }
}
