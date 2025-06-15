import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activity.dart';
import '../../models/task.dart';
import '../../models/project.dart';
import '../../services/task_service.dart';
import '../../services/project_service.dart';
import '../../services/api_service.dart';
import '../../services/cognito_service.dart';
import '../../services/ai_report_service.dart';
import '../../utils/pdf_utils.dart';

class ActivityDetailPage extends StatefulWidget {
  final Activity activity;

  const ActivityDetailPage({
    Key? key,
    required this.activity,
  }) : super(key: key);

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  Task? _task;
  Project? _project;
  bool _isLoading = true;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
    // AI Report state variables
  String? _aiReportResponse;
  
  // Helper method to sanitize file names
  String _sanitizeFileName(String input) {
    // Replace invalid file name characters with underscores
    return input
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
  bool _isGeneratingReport = false;

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

      final taskService = TaskService(apiService);
      final projectService = ProjectService(apiService);

      // Load task details
      final tasks =
          await taskService.getProjectTasks(widget.activity.projectId);
      final task = tasks.firstWhere((t) => t.taskId == widget.activity.taskId);

      // Load project details
      final project =
          await projectService.getProject(widget.activity.projectId);

      setState(() {
        _task = task;
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

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset form when exiting edit mode
        _formKey.currentState?.reset();
        _nameController.text = widget.activity.name;
        _descriptionController.text = widget.activity.description ?? '';
      }
    });
  }
  Future<void> _generateActivitySummary() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final aiReportService = AiReportService(apiService);
      
      setState(() {
        _isGeneratingReport = true;
        _aiReportResponse = null; // Reset response
      });
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requesting AI summary...')),
      );
      
      // Call the AI report service
      final response = await aiReportService.generateActivitySummary(
        widget.activity.projectId,
        widget.activity.taskId,
        widget.activity.activityId,
      );
      
      // Update the state with the response
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
          _aiReportResponse = response['summary'] ?? 'No summary data available';
        });
      }
    } catch (e) {      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating summary: $e')),
        );
      }
    } finally {
      setState(() => _isGeneratingReport = false);
    }
  }
    Future<void> _downloadReportAsPdf() async {
    try {
      if (_aiReportResponse == null) {
        throw Exception('No summary available to download');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing PDF summary...')),
      );
      
      // Get task and project names if available
      final taskName = _task != null ? _task!.name : 'Unknown Task';
      final projectName = _project != null ? _project!.name : 'Unknown Project';
        // Generate and download PDF
      await PdfUtils.generateAndDownloadReport(
        title: 'Activity Summary: ${widget.activity.name}',
        content: _aiReportResponse!,
        fileName: 'activity_summary_${_sanitizeFileName(widget.activity.name)}',
        context: context,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Summary downloaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading summary: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.name),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Activity Details',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
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
                                  color: _getStatusColor(widget.activity.status)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        _getStatusColor(widget.activity.status),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  widget.activity.status,
                                  style: TextStyle(
                                    color:
                                        _getStatusColor(widget.activity.status),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Context information
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              children: [
                                if (_project != null) ...[
                                  Row(
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
                                  const SizedBox(height: 8),
                                ],
                                if (_task != null) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.task,
                                          color: Colors.green[700], size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Task: ${_task!.name}',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),                          const SizedBox(height: 16),                          // AI Summary Generation Button
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.auto_awesome), // AI icon
                              label: const Text('Generate Summary'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isGeneratingReport ? null : _generateActivitySummary,
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
                                  'AI Generated Summary', 
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

                          if (widget.activity.description != null &&
                              widget.activity.description!.isNotEmpty) ...[
                            Text(
                              'Description',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Text(
                                widget.activity.description!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (widget.activity.performedBy != null &&
                              widget.activity.performedBy!.isNotEmpty)
                            _buildInfoRow(
                                'Performed By', widget.activity.performedBy!),
                          _buildInfoRow('Created',
                              _formatDate(widget.activity.createdAt)),
                          _buildInfoRow('Last Updated',
                              _formatDate(widget.activity.updatedAt)),
                          if (widget.activity.startTime != null)
                            _buildInfoRow('Start Time',
                                _formatDateTime(widget.activity.startTime!)),
                          if (widget.activity.endTime != null)
                            _buildInfoRow('End Time',
                                _formatDateTime(widget.activity.endTime!)),
                          if (widget.activity.usedInstruments.isNotEmpty)
                            _buildInfoRow('Used Instruments',
                                '${widget.activity.usedInstruments.length} items'),
                        ],
                      ),
                    ),
                  ),

                  // Time Duration Card (if both start and end times are available)
                  if (widget.activity.startTime != null &&
                      widget.activity.endTime != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duration',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    color: Colors.grey[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _calculateDuration(
                                        widget.activity.startTime!,
                                        widget.activity.endTime!),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Instruments Card (if any instruments were used)
                  if (widget.activity.usedInstruments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Used Instruments',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            ...widget.activity.usedInstruments.map(
                              (instrument) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.build,
                                        color: Colors.grey[600], size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        instrument,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // TODO: Add images section here when image upload is implemented
                  // Images Card
                  // const SizedBox(height: 16),
                  // Card(
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(16),
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(
                  //           'Images',
                  //           style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  //                 fontWeight: FontWeight.bold,
                  //               ),
                  //         ),
                  //         const SizedBox(height: 12),
                  //         // Image gallery here
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

  String _calculateDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
