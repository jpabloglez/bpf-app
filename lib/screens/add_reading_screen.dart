import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/blood_pressure_reading.dart';
import '../providers/readings_provider.dart';

class AddReadingScreen extends StatefulWidget {
  final BloodPressureReading? reading; // null for new, provided for edit

  const AddReadingScreen({Key? key, this.reading}) : super(key: key);

  @override
  State<AddReadingScreen> createState() => _AddReadingScreenState();
}

class _AddReadingScreenState extends State<AddReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.reading != null) {
      // Edit mode - populate fields
      _systolicController.text = widget.reading!.systolic.toString();
      _diastolicController.text = widget.reading!.diastolic.toString();
      _heartRateController.text = widget.reading!.heartRate.toString();
      _notesController.text = widget.reading!.notes ?? '';
      _selectedDate = widget.reading!.timestamp;
      _selectedTime = TimeOfDay.fromDateTime(widget.reading!.timestamp);
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reading != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Reading' : 'Add Reading'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Systolic input
            TextFormField(
              controller: _systolicController,
              key: const Key('systolic_field'),
              decoration: const InputDecoration(
                labelText: 'Systolic (mmHg)',
                hintText: '120',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.arrow_upward),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter systolic value';
                }
                final num = int.tryParse(value);
                if (num == null || num < 50 || num > 250) {
                  return 'Enter value between 50 and 250';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Diastolic input
            TextFormField(
              controller: _diastolicController,
              key: const Key('diastolic_field'),
              decoration: const InputDecoration(
                labelText: 'Diastolic (mmHg)',
                hintText: '80',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.arrow_downward),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter diastolic value';
                }
                final num = int.tryParse(value);
                if (num == null || num < 30 || num > 150) {
                  return 'Enter value between 30 and 150';
                }

                // Check systolic > diastolic
                final systolic = int.tryParse(_systolicController.text);
                if (systolic != null && systolic <= num) {
                  return 'Diastolic must be less than systolic';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            // Heart rate input
            TextFormField(
              controller: _heartRateController,
              key: const Key('heart_rate_field'),
              decoration: const InputDecoration(
                labelText: 'Heart Rate (bpm)',
                hintText: '70',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.favorite),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter heart rate';
                }
                final num = int.tryParse(value);
                if (num == null || num < 30 || num > 250) {
                  return 'Enter value between 30 and 250';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Date picker
            ListTile(
              title: const Text('Date'),
              subtitle: Text(DateFormat('MMMM d, y').format(_selectedDate)),
              leading: const Icon(Icons.calendar_today),
              onTap: _selectDate,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const SizedBox(height: 16),

            // Time picker
            ListTile(
              title: const Text('Time'),
              subtitle: Text(_selectedTime.format(context)),
              leading: const Icon(Icons.access_time),
              onTap: _selectTime,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const SizedBox(height: 16),

            // Notes input
            TextFormField(
              controller: _notesController,
              key: const Key('notes_field'),
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., After exercise, before medication',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveReading,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveReading() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final timestamp = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final reading = BloodPressureReading(
        id: widget.reading?.id,
        systolic: int.parse(_systolicController.text),
        diastolic: int.parse(_diastolicController.text),
        heartRate: int.parse(_heartRateController.text),
        timestamp: timestamp,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final provider = context.read<ReadingsProvider>();

      if (widget.reading == null) {
        await provider.addReading(reading);
      } else {
        await provider.updateReading(reading);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.reading == null
                ? 'Reading added successfully'
                : 'Reading updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
