import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../models/entry.dart';
import '../../models/booking.dart';
import '../../services/inventory_service.dart';

class EntryDetailScreen extends StatefulWidget {
  final Entry entry;

  const EntryDetailScreen({Key? key, required this.entry}) : super(key: key);

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final inventoryService = Provider.of<InventoryService>(context, listen: false);
      final bookings = await inventoryService.getBookingsByEntry(widget.entry.entryId);
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load bookings: $e';
        _isLoading = false;
      });
    }
  }

  Booking? get _currentBooking {
    final now = DateTime.now();
    return _bookings.firstWhereOrNull(
      (b) => b.isActive && b.startDateTime.isBefore(now) && b.endDateTime.isAfter(now),
    );
  }

  void _showBookingDialog() async {
    final result = await showDialog<Booking>(
      context: context,
      builder: (context) => _BookingDialog(entry: widget.entry),
    );
    if (result != null) {
      _loadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Model: \t${widget.entry.model ?? '-'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Manufacturer: \t${widget.entry.manufacturer ?? '-'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Serial Number: \t${widget.entry.serialNumber ?? '-'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Location: \t${widget.entry.location ?? '-'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Quantity: \t${widget.entry.quantity}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Available: \t${widget.entry.availableQuantity}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Status: \t${widget.entry.status}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Description:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(widget.entry.description, style: const TextStyle(fontSize: 15)),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ElevatedButton.icon(
                  onPressed: _showBookingDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Book'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_currentBooking != null)
              Card(
                color: Colors.blue[50],
                child: ListTile(
                  title: Text('Purpose: \t${_currentBooking!.purpose}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User: \t${_currentBooking!.userId}'),
                      Text('From: \t${_currentBooking!.startDate}'),
                      Text('To: \t${_currentBooking!.endDate}'),
                      Text('Status: \t${_currentBooking!.status}'),
                      if (_currentBooking!.notes.isNotEmpty) Text('Notes: \t${_currentBooking!.notes}'),
                    ],
                  ),
                ),
              )
            else
              const Text('No current booking.'),
          ],
        ),
      ),
    );
  }
}

class _BookingDialog extends StatefulWidget {
  final Entry entry;
  const _BookingDialog({required this.entry});

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _startDate == null || _endDate == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final inventoryService = Provider.of<InventoryService>(context, listen: false);
      await inventoryService.createBooking(widget.entry.entryId, {
        'purpose': _purposeController.text.trim(),
        'notes': _notesController.text.trim(),
        'startDate': _startDate!.toIso8601String().split('T').first,
        'endDate': _endDate!.toIso8601String().split('T').first,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _error = 'Failed to create booking: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Book Entry'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(labelText: 'Purpose'),
                validator: (v) => v == null || v.isEmpty ? 'Enter purpose' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                      child: Text(_startDate == null ? 'Start Date' : _startDate!.toLocal().toString().split(' ')[0]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 366)),
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                      child: Text(_endDate == null ? 'End Date' : _endDate!.toLocal().toString().split(' ')[0]),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Book')),
      ],
    );
  }
}
