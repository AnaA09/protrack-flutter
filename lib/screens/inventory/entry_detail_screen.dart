import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../models/entry.dart';
import '../../models/booking.dart';
import '../../services/inventory_service.dart';
import '../../services/cognito_service.dart';

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
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadBookings();
  }

  Future<void> _loadCurrentUserId() async {
    final cognitoService = Provider.of<CognitoService>(context, listen: false);
    setState(() {
      _currentUserId = cognitoService.userId;
    });
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final inventoryService =
          Provider.of<InventoryService>(context, listen: false);
      final bookings =
          await inventoryService.getBookingsByEntry(widget.entry.entryId);
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
      (b) =>
          b.isActive &&
          b.startDateTime.isBefore(now) &&
          b.endDateTime.isAfter(now),
    );
  }

  List<Booking> get _upcomingBookings {
    final now = DateTime.now();
    return _bookings
        .where((b) => b.isActive && b.startDateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  }

  List<Booking> get _pastBookings {
    final now = DateTime.now();
    return _bookings
        .where((b) => b.isActive && b.endDateTime.isBefore(now))
        .toList()
      ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
  }

  void _showBookingDialog() async {
    final result = await showDialog<Booking>(
      context: context,
      builder: (context) => _BookingDialog(entry: widget.entry),
    );
    if (result != null) {
      _loadBookings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Booking created successfully for ${result.startDate} to ${result.endDate}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
            Text('Model: \t${widget.entry.model ?? '-'}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Manufacturer: \t${widget.entry.manufacturer ?? '-'}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Serial Number: \t${widget.entry.serialNumber ?? '-'}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Location: \t${widget.entry.location ?? '-'}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Quantity: \t${widget.entry.quantity}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Available: \t${widget.entry.availableQuantity}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Status: \t${widget.entry.status}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Description:',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(widget.entry.description,
                style: const TextStyle(fontSize: 15)),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Bookings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showBookingDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Book'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else ...[
              // Current Booking
              if (_currentBooking != null) ...[
                const Text(
                  'Current Booking',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.green),
                ),
                const SizedBox(height: 4),
                Card(
                  color: Colors.green[50],
                  child: ListTile(
                    title: Text('Purpose: ${_currentBooking!.purpose}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'From: ${_currentBooking!.formattedStartDateTime}'),
                        Text('To: ${_currentBooking!.formattedEndDateTime}'),
                        Text('Status: ${_currentBooking!.status}'),
                        if (_currentBooking!.notes.isNotEmpty)
                          Text('Notes: ${_currentBooking!.notes}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Upcoming Bookings
              if (_upcomingBookings.isNotEmpty) ...[
                const Text(
                  'Upcoming Bookings',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.blue),
                ),
                const SizedBox(height: 4),
                ..._upcomingBookings.map((booking) {
                  // Debug print for userId matching (optional, remove if not needed)
                  // print('DEBUG: booking.userId = \\${booking.userId}, _currentUserId = \\${_currentUserId}');
                  return Card(
                    color: Colors.blue[50],
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('Purpose: \\${booking.purpose}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From: \\${booking.formattedStartDateTime}'),
                          Text('To: \\${booking.formattedEndDateTime}'),
                          Text('Status: \\${booking.status}'),
                          if (booking.notes.isNotEmpty)
                            Text('Notes: \\${booking.notes}'),
                        ],
                      ),
                      trailing: (booking.userId == _currentUserId)
                          ? IconButton(
                              icon: Icon(Icons.cancel, color: Colors.red),
                              tooltip: 'Cancel Booking',
                              onPressed: () async {
                                final inventoryService = Provider.of<InventoryService>(context, listen: false);
                                await inventoryService.deleteBooking(widget.entry.entryId, booking.bookingId);
                                _loadBookings();
                              },
                            )
                          : null,
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Past Bookings
              if (_pastBookings.isNotEmpty) ...[
                const Text(
                  'Past Bookings',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.grey),
                ),
                const SizedBox(height: 4),
                ..._pastBookings.take(3).map((booking) => Card(
                      color: Colors.grey[100],
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('Purpose: ${booking.purpose}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('From: ${booking.formattedStartDateTime}'),
                            Text('To: ${booking.formattedEndDateTime}'),
                            Text('Status: ${booking.status}'),
                            if (booking.notes.isNotEmpty)
                              Text('Notes: ${booking.notes}'),
                          ],
                        ),
                      ),
                    )),
                if (_pastBookings.length > 3)
                  Text(
                      '... and ${_pastBookings.length - 3} more past bookings'),
              ],

              // No bookings message
              if (_bookings.isEmpty) const Text('No bookings for this entry.'),
            ],
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
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _endDate == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final inventoryService =
          Provider.of<InventoryService>(context, listen: false);
      final booking =
          await inventoryService.createBooking(widget.entry.entryId, {
        'purpose': _purposeController.text.trim(),
        'notes': _notesController.text.trim(),
        'startDate': _startDate!.toIso8601String().split('T').first,
        'endDate': _endDate!.toIso8601String().split('T').first,
        'startTime': _startTime != null
            ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00'
            : null,
        'endTime': _endTime != null
            ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00'
            : null,
      });

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context, booking);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to create booking: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartTime
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: isStartTime
            ? (_startTime ?? TimeOfDay.now())
            : (_endTime ?? TimeOfDay.now()),
      );

      if (pickedTime != null) {
        setState(() {
          if (isStartTime) {
            _startDate = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            _startTime = pickedTime;
          } else {
            _endDate = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            _endTime = pickedTime;
          }
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$formattedDate ${hour12}:$minute $period';
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
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter purpose' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDateTime(context, true),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_startDate == null
                          ? 'Pick Start Time'
                          : _formatDateTime(_startDate!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDateTime(context, false),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_endDate == null
                          ? 'Pick End Time'
                          : _formatDateTime(_endDate!)),
                    ),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
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
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Book'),
        ),
      ],
    );
  }
}
