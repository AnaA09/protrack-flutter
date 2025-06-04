import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activity.dart';
import '../../services/activity_service.dart';
import '../../services/api_service.dart';

class EditActivityDialog extends StatefulWidget {
  final Activity activity;
  final VoidCallback onActivityUpdated;

  const EditActivityDialog({
    Key? key,
    required this.activity,
    required this.onActivityUpdated,
  }) : super(key: key);

  @override
  State<EditActivityDialog> createState() => _EditActivityDialogState();
}

class _EditActivityDialogState extends State<EditActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _performedByController = TextEditingController();
  String _selectedStatus = 'IN_PROGRESS';
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'IN_PROGRESS',
    'COMPLETED',
    'FAILED',
    'PAUSED'
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.activity.name;
    _descriptionController.text = widget.activity.description ?? '';
    _performedByController.text = widget.activity.performedBy ?? '';
    _selectedStatus = widget.activity.status;
    _startTime = widget.activity.startTime;
    _endTime = widget.activity.endTime;
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final activityService = ActivityService(apiService);
      final updatedActivity = widget.activity.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        performedBy: _performedByController.text.trim().isEmpty
            ? null
            : _performedByController.text.trim(),
        status: _selectedStatus,
        startTime: _startTime,
        endTime: _endTime,
      );

      await activityService.updateActivity(widget.activity.projectId,
          widget.activity.taskId, widget.activity.activityId, updatedActivity);

      if (mounted) {
        Navigator.pop(context);
        widget.onActivityUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating activity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartTime
          ? (_startTime ?? DateTime.now())
          : (_endTime ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStartTime
            ? (_startTime ?? DateTime.now())
            : (_endTime ?? DateTime.now())),
      );

      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStartTime) {
            _startTime = selectedDateTime;
          } else {
            _endTime = selectedDateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Activity'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Read-only section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Information (Read-only)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Activity ID: ${widget.activity.activityId}',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 11)),
                      Text('Task ID: ${widget.activity.taskId}',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 11)),
                      Text('Project ID: ${widget.activity.projectId}',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 11)),
                      Text('Created: ${_formatDate(widget.activity.createdAt)}',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 11)),
                      if (widget.activity.usedInstruments.isNotEmpty)
                        Text(
                            'Used Instruments: ${widget.activity.usedInstruments.length} items',
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Activity Name *',
                    hintText: 'Enter activity name',
                  ),
                  validator: (value) => value?.trim().isEmpty == true
                      ? 'Activity name is required'
                      : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: _statusOptions.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(status),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedStatus = value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _performedByController,
                        decoration: const InputDecoration(
                          labelText: 'Performed By',
                          hintText: 'Enter performer',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDateTime(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(
                            _startTime != null
                                ? _formatDateTime(_startTime!)
                                : 'Select start time',
                            style: TextStyle(
                              color: _startTime != null
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDateTime(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(
                            _endTime != null
                                ? _formatDateTime(_endTime!)
                                : 'Select end time',
                            style: TextStyle(
                              color:
                                  _endTime != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter activity description',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveActivity,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'PAUSED':
        return Colors.yellow;
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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _performedByController.dispose();
    super.dispose();
  }
}
