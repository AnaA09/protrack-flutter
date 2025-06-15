import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../models/entry.dart';
import '../../services/inventory_service.dart';
import 'edit_entry_dialog.dart';
import 'entry_detail_screen.dart';

class EntriesScreen extends StatefulWidget {
  final Category category;

  const EntriesScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  List<Entry> _entries = [];
  List<Entry> _filteredEntries = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final inventoryService = context.read<InventoryService>();
      final entries = await inventoryService
          .getEntriesByCategory(widget.category.categoryId);

      setState(() {
        _entries = entries;
        _filteredEntries = entries; // Initialize filtered list
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading entries: $e';
        _isLoading = false;
      });
    }
  }

  void _showAddEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEntryDialog(
        category: widget.category,
        onEntryAdded: _loadEntries,
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'AVAILABLE':
        return Icons.check_circle;
      case 'IN_USE':
        return Icons.schedule;
      case 'MAINTENANCE':
        return Icons.build;
      case 'UNAVAILABLE':
        return Icons.block;
      default:
        return Icons.help;
    }
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

  void _filterEntries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEntries = List.from(_entries);
      } else {
        _filteredEntries = _entries
            .where((entry) =>
                entry.name.toLowerCase().contains(query.toLowerCase()) ||
                (entry.model?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                (entry.manufacturer?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                (entry.location?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.name} - Entries'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadEntries, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_filteredEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No entries found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Add entries to this category',
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddEntryDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterEntries,
              decoration: InputDecoration(
                hintText: 'Search entries...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredEntries.length,
              itemBuilder: (context, index) {
                final entry = _filteredEntries[index];
                return _buildEntryCard(entry);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(Entry entry) {
    final statusColor = _getStatusColor(entry.status);
    final statusIcon = _getStatusIcon(entry.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EntryDetailScreen(entry: entry),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (entry.model?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            entry.model!,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editEntry(entry),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.red),
                        onPressed: () => _deleteEntry(entry),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.grey[400], size: 16),
                    ],
                  ),
                ],
              ),
              if (entry.manufacturer?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.business, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      entry.manufacturer!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              if (entry.location?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      entry.location!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.inventory_2, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Available: ${entry.availableQuantity}/${entry.quantity}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Entry operations
  Future<void> _editEntry(Entry entry) async {
    await showDialog(
      context: context,
      builder: (context) => EditEntryDialog(
        entry: entry,
        onEntryUpdated: _loadEntries,
      ),
    );
  }

  Future<void> _deleteEntry(Entry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete "${entry.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final inventoryService = context.read<InventoryService>();
        await inventoryService.deleteEntry(entry.entryId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Entry "${entry.name}" deleted')),
        );
        _loadEntries(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting entry: $e')),
        );
      }
    }
  }
}

class _AddEntryDialog extends StatefulWidget {
  final Category category;
  final VoidCallback onEntryAdded;

  const _AddEntryDialog({
    required this.category,
    required this.onEntryAdded,
  });

  @override
  State<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<_AddEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  bool _isLoading = false;

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final inventoryService = context.read<InventoryService>();
      final entryData = {
        'name': _nameController.text.trim(),
        'model': _modelController.text.trim(),
        'manufacturer': _manufacturerController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'quantity': int.parse(_quantityController.text.trim()),
        'labId': widget.category.labId,
      };

      await inventoryService.createEntry(widget.category.categoryId, entryData);

      if (mounted) {
        Navigator.pop(context);
        widget.onEntryAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Entry created successfully'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error creating entry: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Entry to ${widget.category.name}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Entry Name *', hintText: 'Enter entry name'),
                validator: (value) => value?.trim().isEmpty == true
                    ? 'Entry name is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                    labelText: 'Model', hintText: 'Enter model number'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _manufacturerController,
                decoration: const InputDecoration(
                    labelText: 'Manufacturer', hintText: 'Enter manufacturer'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                    labelText: 'Location', hintText: 'Enter location'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                    labelText: 'Quantity *', hintText: 'Enter quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isEmpty == true) {
                    return 'Quantity is required';
                  }
                  final quantity = int.tryParse(value!);
                  if (quantity == null || quantity <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Description', hintText: 'Enter description'),
                maxLines: 3,
              ),
            ],
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
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _manufacturerController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}
