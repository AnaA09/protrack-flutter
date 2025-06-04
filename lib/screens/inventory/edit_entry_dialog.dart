import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/entry.dart';
import '../../services/inventory_service.dart';

class EditEntryDialog extends StatefulWidget {
  final Entry entry;
  final VoidCallback onEntryUpdated;

  const EditEntryDialog({
    Key? key,
    required this.entry,
    required this.onEntryUpdated,
  }) : super(key: key);

  @override
  State<EditEntryDialog> createState() => _EditEntryDialogState();
}

class _EditEntryDialogState extends State<EditEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController();
  final _availableQuantityController = TextEditingController();
  String _selectedStatus = 'AVAILABLE';
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'AVAILABLE',
    'IN_USE',
    'MAINTENANCE',
    'UNAVAILABLE'
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.entry.name;
    _modelController.text = widget.entry.model ?? '';
    _manufacturerController.text = widget.entry.manufacturer ?? '';
    _serialNumberController.text = widget.entry.serialNumber ?? '';
    _descriptionController.text = widget.entry.description;
    _locationController.text = widget.entry.location ?? '';
    _quantityController.text = widget.entry.quantity.toString();
    _availableQuantityController.text =
        widget.entry.availableQuantity.toString();
    _selectedStatus = widget.entry.status;
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final inventoryService = context.read<InventoryService>();
      final entryData = {
        'name': _nameController.text.trim(),
        'model': _modelController.text.trim(),
        'manufacturer': _manufacturerController.text.trim(),
        'serialNumber': _serialNumberController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'quantity': int.parse(_quantityController.text.trim()),
        'availableQuantity':
            int.parse(_availableQuantityController.text.trim()),
        'status': _selectedStatus,
      };

      await inventoryService.updateEntry(widget.entry.instrumentId, entryData);

      if (mounted) {
        Navigator.pop(context);
        widget.onEntryUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Entry'),
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
                      Text('Entry ID: ${widget.entry.entryId}',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 11)),
                      Text('Category ID: ${widget.entry.categoryId}',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 11)),
                      Text('Lab ID: ${widget.entry.labId}',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Entry Name *',
                    hintText: 'Enter entry name',
                  ),
                  validator: (value) => value?.trim().isEmpty == true
                      ? 'Entry name is required'
                      : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          hintText: 'Enter model',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _manufacturerController,
                        decoration: const InputDecoration(
                          labelText: 'Manufacturer',
                          hintText: 'Enter manufacturer',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _serialNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Serial Number',
                          hintText: 'Enter serial number',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'Enter location',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Total Quantity *',
                          hintText: 'Enter quantity',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.trim().isEmpty == true) {
                            return 'Quantity is required';
                          }
                          final quantity = int.tryParse(value!);
                          if (quantity == null || quantity <= 0) {
                            return 'Enter valid quantity';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _availableQuantityController,
                        decoration: const InputDecoration(
                          labelText: 'Available Quantity *',
                          hintText: 'Enter available qty',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.trim().isEmpty == true) {
                            return 'Available quantity is required';
                          }
                          final availableQty = int.tryParse(value!);
                          final totalQty =
                              int.tryParse(_quantityController.text);
                          if (availableQty == null || availableQty < 0) {
                            return 'Enter valid available quantity';
                          }
                          if (totalQty != null && availableQty > totalQty) {
                            return 'Cannot exceed total quantity';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
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
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter description',
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
          onPressed: _isLoading ? null : _saveEntry,
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
      case 'AVAILABLE':
        return Colors.green;
      case 'IN_USE':
        return Colors.orange;
      case 'MAINTENANCE':
        return Colors.red;
      case 'UNAVAILABLE':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _manufacturerController.dispose();
    _serialNumberController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _availableQuantityController.dispose();
    super.dispose();
  }
}
