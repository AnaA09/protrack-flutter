import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/activity.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../services/activity_service.dart';
import '../services/api_service.dart';
import '../services/cognito_service.dart';
import '../routes/app_routes.dart';
import 'inventory/labs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Project> _projects = [];
  List<Task> _tasks = [];
  List<Activity> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

      // Load all projects
      debugPrint('Loading projects...');
      final projects = await projectService.getAllProjects();
      debugPrint('Loaded ${projects.length} projects');

      // Load all tasks
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

      // Load all activities
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

      debugPrint('Setting state with ${projects.length} projects');
      setState(() {
        _projects = projects;
        _tasks = allTasks;
        _activities = allActivities;
        _isLoading = false;
      });
      debugPrint('State updated. Projects: ${_projects.length}');
    } catch (e) {
      debugPrint('Error in _loadData: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        if (e.toString().contains('Unauthorized') ||
            e.toString().contains('Not authenticated')) {
          // Navigate to login screen if unauthorized
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading data: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: const Text('ProTrack'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('Projects', _buildProjectCards()),
                    _buildSection('Tasks', _buildTaskCards()),
                    _buildSection('Activities', _buildActivityCards()),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 30),
                ),
                SizedBox(height: 10),
                Text(
                  'ProTrack',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Projects'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to projects page
            },
          ),
          ListTile(
            leading: const Icon(Icons.task),
            title: const Text('Tasks'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to tasks page
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Activities'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to activities page
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Inventory'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LabsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to settings page
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 200,
          child: content,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProjectCards() {
    debugPrint(
        'Building project cards. Number of projects: ${_projects.length}');
    if (_projects.isEmpty) {
      debugPrint('No projects found');
      return const Center(
        child: Text('No projects found. Create a new project to get started.'),
      );
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        debugPrint('Building card for project: ${project.name}');
        return Card(
          margin: const EdgeInsets.only(right: 16),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  project.description ?? 'No description',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status: ${project.status}',
                      style: TextStyle(
                        color: _getStatusColor(project.status),
                      ),
                    ),
                    Text(
                      'Instruments: ${project.requiredInstruments.length}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskCards() {
    if (_tasks.isEmpty) {
      return const Center(
        child: Text('No tasks found. Create a new task to get started.'),
      );
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return Card(
          margin: const EdgeInsets.only(right: 16),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.description ?? 'No description',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status: ${task.status}',
                      style: TextStyle(
                        color: _getStatusColor(task.status),
                      ),
                    ),
                    Text(
                      'Project: ${_projects.firstWhere((p) => p.projectId == task.projectId, orElse: () => Project(
                            projectId: '',
                            name: 'Unknown',
                            createdAt: DateTime.now().toIso8601String(),
                            updatedAt: DateTime.now().toIso8601String(),
                            createdBy: '',
                            status: 'UNKNOWN',
                            requiredInstruments: [],
                          )).name}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityCards() {
    if (_activities.isEmpty) {
      return const Center(
        child:
            Text('No activities found. Create a new activity to get started.'),
      );
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        final task = _tasks.firstWhere(
          (t) => t.taskId == activity.taskId,
          orElse: () => Task(
            taskId: '',
            projectId: '',
            name: 'Unknown',
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
            status: 'UNKNOWN',
            requiredInstruments: [],
          ),
        );
        return Card(
          margin: const EdgeInsets.only(right: 16),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  activity.description ?? 'No description',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status: ${activity.status}',
                      style: TextStyle(
                        color: _getStatusColor(activity.status),
                      ),
                    ),
                    Text(
                      'Task: ${task.name}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
