import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/lab.dart';
import '../../services/inventory_service.dart';
import 'categories_screen.dart';
import 'add_lab_screen.dart';
import 'edit_lab_screen.dart';

class LabsScreen extends StatefulWidget {
  const LabsScreen({Key? key}) : super(key: key);

  @override
  State<LabsScreen> createState() => _LabsScreenState();
}

class _LabsScreenState extends State<LabsScreen> {
  List<Lab> _labs = [];
  List<Lab> _filteredLabs = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLabs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLabs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final inventoryService = context.read<InventoryService>();
      final labs = await inventoryService.getLabs();

      setState(() {
        _labs = labs;
        _filteredLabs = labs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading labs: $e';
        _isLoading = false;
      });
    }
  }

  void _filterLabs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLabs = List.from(_labs);
      } else {
        _filteredLabs = _labs
            .where((lab) =>
                lab.name.toLowerCase().contains(query.toLowerCase()) ||
                (lab.description ?? '').toLowerCase().contains(query.toLowerCase()) ||
                (lab.location ?? '').toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _navigateToCategories(Lab lab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriesScreen(lab: lab),
      ),
    );
  }

  void _navigateToAddLab() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddLabScreen(),
      ),
    );

    if (result == true) {
      _loadLabs(); // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Labs'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddLab,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLabs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredLabs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No labs found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first lab to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToAddLab,
              icon: const Icon(Icons.add),
              label: const Text('Add Lab'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLabs,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterLabs,
              decoration: InputDecoration(
                hintText: 'Search labs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredLabs.length,
              itemBuilder: (context, index) {
                final lab = _filteredLabs[index];
                return _buildLabCard(lab);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabCard(Lab lab) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToCategories(lab),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.science,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lab.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (lab.location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  lab.location,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editLab(lab),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.red),
                        onPressed: () => _deleteLab(lab),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
              if (lab.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  lab.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: lab.status == 'ACTIVE'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lab.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: lab.status == 'ACTIVE'
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Created: ${_formatDate(lab.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Lab operations
  Future<void> _editLab(Lab lab) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditLabScreen(lab: lab),
      ),
    );

    // If the lab was updated, refresh the list
    if (result == true) {
      _loadLabs();
    }
  }

  Future<void> _deleteLab(Lab lab) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lab'),
        content: Text('Are you sure you want to delete "${lab.name}"?'),
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
        await inventoryService.deleteLab(lab.labId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lab "${lab.name}" deleted')),
        );
        _loadLabs(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting lab: $e')),
        );
      }
    }
  }
}
