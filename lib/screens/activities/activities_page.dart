import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activity.dart';
import '../../models/task.dart';
import '../../models/project.dart';
import '../../services/activity_service.dart';
import '../../services/task_service.dart';
import '../../services/project_service.dart';
import '../../services/api_service.dart';
import '../../services/cognito_service.dart';
import '../../routes/app_routes.dart';
import 'activity_detail_page.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  List<Activity> _activities = [];
  List<Activity> _filteredActivities = [];
  List<Task> _tasks = [];
  List<Project> _projects = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final cognitoService =
          Provider.of<CognitoService>(context, listen: false);

      // Refresh the token before making API calls
      final idToken = await cognitoService.getIdToken();
      if (idToken == null) {
        throw Exception('Not authenticated: Please sign in again');
      }
      apiService.updateAuthToken(idToken);

      final projectService = ProjectService(apiService);
      final taskService = TaskService(apiService);
      final activityService = ActivityService(apiService);

      // Load all projects first
      final projects = await projectService.getAllProjects();

      // Load all tasks for all projects
      List<Task> allTasks = [];
      for (var project in projects) {
        try {
          final tasks = await taskService.getProjectTasks(project.projectId);
          allTasks.addAll(tasks);
        } catch (e) {
          debugPrint(
              'Error loading tasks for project ${project.projectId}: $e');
        }
      }

      // Load all activities for all tasks
      List<Activity> allActivities = [];
      for (var task in allTasks) {
        try {
          final activities = await activityService.getTaskActivities(
            task.projectId,
            task.taskId,
          );
          allActivities.addAll(activities);
        } catch (e) {
          debugPrint('Error loading activities for task ${task.taskId}: $e');
        }
      }

      setState(() {
        _projects = projects;
        _tasks = allTasks;
        _activities = allActivities;
        _filteredActivities = allActivities; // Initialize filtered list
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        if (e.toString().contains('Unauthorized') ||
            e.toString().contains('Not authenticated')) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading activities: $e')),
          );
        }
      }
    }
  }

  void _navigateToActivityDetail(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailPage(activity: activity),
      ),
    );
  }

  String _getTaskName(String taskId) {
    final task = _tasks.firstWhere(
      (t) => t.taskId == taskId,
      orElse: () => Task(
        taskId: '',
        projectId: '',
        name: 'Unknown Task',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        status: 'UNKNOWN',
        requiredInstruments: [],
      ),
    );
    return task.name;
  }

  String _getProjectName(String projectId) {
    final project = _projects.firstWhere(
      (p) => p.projectId == projectId,
      orElse: () => Project(
        projectId: '',
        name: 'Unknown Project',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        createdBy: '',
        status: 'UNKNOWN',
        requiredInstruments: [],
      ),
    );
    return project.name;
  }

  void _filterActivities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredActivities = List.from(_activities);
      } else {
        _filteredActivities = _activities
            .where((activity) =>
                activity.name.toLowerCase().contains(query.toLowerCase()) ||
                (activity.description ?? '').toLowerCase().contains(query.toLowerCase()) ||
                _getTaskName(activity.taskId).toLowerCase().contains(query.toLowerCase()) ||
                _getProjectName(activity.projectId).toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterActivities,
              decoration: InputDecoration(
                hintText: 'Search activities...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              ),
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadActivities,
              child: _filteredActivities.isEmpty
                  ? const Center(
                      child: Text(
                        'No activities found.\nCreate a new activity to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredActivities.length,
                      itemBuilder: (context, index) {
                        final activity = _filteredActivities[index];
                        return _buildActivityCard(activity);
                      },
                    ),
            ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToActivityDetail(activity),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      activity.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(activity.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(activity.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      activity.status,
                      style: TextStyle(
                        color: _getStatusColor(activity.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Task: ${_getTaskName(activity.taskId)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Project: ${_getProjectName(activity.projectId)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 8),
              if (activity.description != null &&
                  activity.description!.isNotEmpty)
                Text(
                  activity.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (activity.performedBy != null &&
                      activity.performedBy!.isNotEmpty) ...[
                    Icon(Icons.person_outline,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      activity.performedBy!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                  ],
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(activity.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (activity.startTime != null || activity.endTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _getTimeRange(activity.startTime, activity.endTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              if (activity.usedInstruments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.build, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Instruments: ${activity.usedInstruments.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'PAUSED':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeRange(DateTime? startTime, DateTime? endTime) {
    if (startTime == null && endTime == null) {
      return 'No time set';
    }
    if (startTime != null && endTime != null) {
      return '${_formatDateTime(startTime)} - ${_formatDateTime(endTime)}';
    }
    if (startTime != null) {
      return 'Started: ${_formatDateTime(startTime)}';
    }
    if (endTime != null) {
      return 'Ended: ${_formatDateTime(endTime)}';
    }
    return '';
  }
}
