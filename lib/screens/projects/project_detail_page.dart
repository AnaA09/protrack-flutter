import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../services/api_service.dart';
import '../../services/cognito_service.dart';
import '../../services/ai_report_service.dart';
import '../../utils/pdf_utils.dart';
import 'create_task_form.dart';
import '../tasks/task_detail_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;

  const ProjectDetailPage({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  List<Task> _tasks = [];
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
    _loadTasks();
  }

  Future<void> _loadTasks() async {
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

      final taskService = TaskService(apiService);
      final tasks = await taskService.getProjectTasks(widget.project.projectId);

      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: $e')),
        );
      }
    }
  }

  void _showCreateTaskForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTaskForm(
        projectId: widget.project.projectId,
        onTaskCreated: _loadTasks,
      ),
    );
  }

  void _navigateToTaskDetail(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(task: task),
      ),
    );
  }
  Future<void> _generateProjectReport() async {
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
      final response = await aiReportService.generateProjectReport(widget.project.projectId);
      
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
      );      // Generate and download PDF
      await PdfUtils.generateAndDownloadReport(
        title: 'Project Report: ${widget.project.name}',
        content: _aiReportResponse!,
        fileName: 'project_report_${_sanitizeFileName(widget.project.name)}',
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
        title: Text(widget.project.name),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Project Details',
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
                            color: _getStatusColor(widget.project.status)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getStatusColor(widget.project.status),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.project.status,
                            style: TextStyle(
                              color: _getStatusColor(widget.project.status),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),                    const SizedBox(height: 16),
                    
                    // AI Report Generation Button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.auto_awesome), // AI icon
                        label: const Text('Generate Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isGeneratingReport ? null : _generateProjectReport,
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
                    
                    if (widget.project.description != null &&
                        widget.project.description!.isNotEmpty) ...[
                      Text(
                        'Description',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.project.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildInfoRow('Created By', widget.project.createdBy),
                    _buildInfoRow(
                        'Created', _formatDate(widget.project.createdAt)),
                    _buildInfoRow(
                        'Last Updated', _formatDate(widget.project.updatedAt)),
                    if (widget.project.startDate != null)
                      _buildInfoRow('Start Date',
                          _formatDateOnly(widget.project.startDate!)),
                    if (widget.project.endDate != null)
                      _buildInfoRow(
                          'End Date', _formatDateOnly(widget.project.endDate!)),
                    if (widget.project.requiredInstruments.isNotEmpty)
                      _buildInfoRow('Required Instruments',
                          '${widget.project.requiredInstruments.length} items'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tasks Section
            Row(
              children: [
                Text(
                  'Tasks',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_tasks.length} tasks',
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
            else if (_tasks.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first task for this project',
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
              ...List.generate(_tasks.length, (index) {
                final task = _tasks[index];
                return _buildTaskCard(task);
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
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

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToTaskDetail(task),
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
                      task.name,
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
                      color: _getTaskStatusColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getTaskStatusColor(task.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      task.status,
                      style: TextStyle(
                        color: _getTaskStatusColor(task.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (task.priority != null) ...[
                    Icon(
                      Icons.flag,
                      size: 16,
                      color: _getPriorityColor(task.priority!),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Priority ${task.priority}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (task.assignedTo != null &&
                      task.assignedTo!.isNotEmpty) ...[
                    Icon(Icons.person_outline,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      task.assignedTo!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
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
      case 'ON_HOLD':
        return Colors.yellow[700]!;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTaskStatusColor(String status) {
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
}
