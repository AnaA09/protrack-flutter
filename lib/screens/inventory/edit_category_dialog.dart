import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../services/inventory_service.dart';

class EditCategoryDialog extends StatefulWidget {
  final Category category;
  final VoidCallback onCategoryUpdated;

  const EditCategoryDialog({
    Key? key,
    required this.category,
    required this.onCategoryUpdated,
  }) : super(key: key);

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'INSTRUMENTS';
  String _selectedStatus = 'ACTIVE';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categoryTypes = [
    {
      'value': 'INSTRUMENTS',
      'label': 'Instruments',
      'icon': Icons.precision_manufacturing,
      'color': Colors.blue
    },
    {
      'value': 'CHEMICALS',
      'label': 'Chemicals',
      'icon': Icons.science,
      'color': Colors.orange
    },
    {
      'value': 'CULTURES',
      'label': 'Cultures',
      'icon': Icons.biotech,
      'color': Colors.green
    },
  ];

  final List<String> _statusOptions = ['ACTIVE', 'INACTIVE'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.category.name;
    _descriptionController.text = widget.category.description;
    _selectedType = widget.category.categoryType;
    _selectedStatus = widget.category.status;
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final inventoryService = context.read<InventoryService>();
      final categoryData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'categoryType': _selectedType,
        'status': _selectedStatus,
      };

      await inventoryService.updateCategory(
          widget.category.instrumentId, categoryData);

      if (mounted) {
        Navigator.pop(context);
        widget.onCategoryUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating category: $e'),
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
      title: const Text('Edit Category'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text('Category ID: ${widget.category.categoryId}',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 11)),
                      Text('Lab ID: ${widget.category.labId}',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                    hintText: 'Enter category name',
                  ),
                  validator: (value) => value?.trim().isEmpty == true
                      ? 'Category name is required'
                      : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Category Type'),
                  items: _categoryTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type['value'] as String,
                      child: Row(
                        children: [
                          Icon(type['icon'] as IconData,
                              color: type['color'] as Color, size: 20),
                          const SizedBox(width: 8),
                          Text(type['label'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
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
                  maxLines: 2,
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
          onPressed: _isLoading ? null : _saveCategory,
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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
