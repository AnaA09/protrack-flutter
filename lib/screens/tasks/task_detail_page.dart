import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../models/activity.dart';
import '../../models/project.dart';
import '../../services/activity_service.dart';
import '../../services/project_service.dart';
import '../../services/api_service.dart';
import '../../services/cognito_service.dart';
import '../../services/ai_report_service.dart';
import '../../utils/pdf_utils.dart';
import 'create_activity_form.dart';
import '../activities/activity_detail_page.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;

  const TaskDetailPage({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  List<Activity> _activities = [];
  Project? _project;
  bool _isLoading = true;
  
  // AI Report state variables
  String? _aiReportResponse;
  bool _isGeneratingReport = false;
  
  // Helper method to sanitize file names
  String _sanitizeFileName(String input) {
    // Replace invalid file name characters with underscores
    return input
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

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

      final activityService = ActivityService(apiService);
      final projectService = ProjectService(apiService);

      // Load activities for this task
      final activities = await activityService.getTaskActivities(
        widget.task.projectId,
        widget.task.taskId,
      );

      // Load project details
      final project = await projectService.getProject(widget.task.projectId);

      setState(() {
        _activities = activities;
        _project = project;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _showCreateActivityForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateActivityForm(
        taskId: widget.task.taskId,
        projectId: widget.task.projectId,
        onActivityCreated: _loadData,
      ),
    );
  }

  void _navigateToActivityDetail(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailPage(activity: activity),
      ),
    );
  }
  Future<void> _generateTaskReport() async {
    try {
      setState(() {
        _isGeneratingReport = true;
        _aiReportResponse = null;
      });
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requesting AI report...')),
      );
      
      final apiService = Provider.of<ApiService>(context, listen: false);
      final aiReportService = AiReportService(apiService);
      
      // Call the AI report service
      final response = await aiReportService.generateTaskReport(
        widget.task.projectId,
        widget.task.taskId,
      );
      
      // Update the state with the response
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
          _aiReportResponse = response['report'] ?? 'No report data available';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }
    Future<void> _downloadReportAsPdf() async {
    try {
      if (_aiReportResponse == null) {
        throw Exception('No report available to download');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing PDF report...')),
      );
      
      // Get project name if available
      final projectName = _project != null ? _project!.name : 'Unknown Project';
        // Generate and download PDF
      await PdfUtils.generateAndDownloadReport(
        title: 'Task Report: ${widget.task.name}',
        content: _aiReportResponse!,
        fileName: 'task_report_${_sanitizeFileName(widget.task.name)}',
        context: context,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report downloaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.name),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Task Details',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.task.status)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getStatusColor(widget.task.status),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.task.status,
                            style: TextStyle(
                              color: _getStatusColor(widget.task.status),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Project context
                    if (_project != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.folder,
                                color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Project: ${_project!.name}',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),                    ],                    // AI Report Generation Button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.auto_awesome), // AI icon
                        label: const Text('Generate Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isGeneratingReport ? null : _generateTaskReport,
                      ),
                    ),
                    
                    if (_isGeneratingReport)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      
                    if (_aiReportResponse != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'AI Generated Report', 
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.download),
                            tooltip: 'Download as PDF',
                            onPressed: _downloadReportAsPdf,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(_aiReportResponse!),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    if (widget.task.description != null &&
                        widget.task.description!.isNotEmpty) ...[
                      Text(
                        'Description',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.task.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (widget.task.priority != null)
                      _buildInfoRow(
                        'Priority',
                        widget.task.priority.toString(),
                        icon: Icon(
                          Icons.flag,
                          size: 16,
                          color: _getPriorityColor(widget.task.priority!),
                        ),
                      ),
                    if (widget.task.assignedTo != null &&
                        widget.task.assignedTo!.isNotEmpty)
                      _buildInfoRow('Assigned To', widget.task.assignedTo!),
                    _buildInfoRow(
                        'Created', _formatDate(widget.task.createdAt)),
                    _buildInfoRow(
                        'Last Updated', _formatDate(widget.task.updatedAt)),
                    if (widget.task.startDate != null)
                      _buildInfoRow('Start Date',
                          _formatDateOnly(widget.task.startDate!)),
                    if (widget.task.dueDate != null)
                      _buildInfoRow(
                          'Due Date', _formatDateOnly(widget.task.dueDate!)),
                    if (widget.task.requiredInstruments.isNotEmpty)
                      _buildInfoRow('Required Instruments',
                          '${widget.task.requiredInstruments.length} items'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Activities Section
            Row(
              children: [
                Text(
                  'Activities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_activities.length} activities',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_activities.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No activities yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first activity for this task',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...List.generate(_activities.length, (index) {
                final activity = _activities[index];
                return _buildActivityCard(activity);
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateActivityForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                if (icon != null) ...[
                  icon,
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    '$label:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      color: _getActivityStatusColor(activity.status)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getActivityStatusColor(activity.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      activity.status,
                      style: TextStyle(
                        color: _getActivityStatusColor(activity.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (activity.description != null &&
                  activity.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  activity.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
                    const SizedBox(width: 16),
                  ],
                  if (activity.startTime != null ||
                      activity.endTime != null) ...[
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _getTimeRange(activity.startTime, activity.endTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
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
      case 'OPEN':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.green;
      case 'BLOCKED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getActivityStatusColor(String status) {
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

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.blue;
      case 5:
        return Colors.green;
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

  String _formatDateOnly(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
