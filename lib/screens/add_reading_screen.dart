import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/blood_pressure_reading.dart';
import '../providers/readings_provider.dart';
import '../widgets/category_chip.dart';

typedef _Reading = BloodPressureReading;

class AddReadingScreen extends StatefulWidget {
  final BloodPressureReading? reading; // null for new, provided for edit

  const AddReadingScreen({super.key, this.reading});

  @override
  State<AddReadingScreen> createState() => _AddReadingScreenState();
}

class _AddReadingScreenState extends State<AddReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isSaving = false;

  bool get _isEditing => widget.reading != null;

  @override
  void initState() {
    super.initState();

    final reading = widget.reading;
    final timestamp = reading?.timestamp ?? DateTime.now();
    _selectedDate = timestamp;
    _selectedTime = TimeOfDay.fromDateTime(timestamp);

    if (reading != null) {
      // Edit mode - populate fields
      _systolicController.text = reading.systolic.toString();
      _diastolicController.text = reading.diastolic.toString();
      _heartRateController.text = reading.heartRate.toString();
      _notesController.text = reading.notes ?? '';
    }

    // Refresh the category preview as values change.
    _systolicController.addListener(_onValuesChanged);
    _diastolicController.addListener(_onValuesChanged);
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onValuesChanged() => setState(() {});

  DateTime get _timestamp => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  BpCategory? get _previewCategory {
    final systolic = int.tryParse(_systolicController.text);
    final diastolic = int.tryParse(_diastolicController.text);
    if (systolic == null || diastolic == null) return null;
    if (_rangeError(systolic, _Reading.minSystolic, _Reading.maxSystolic) !=
            null ||
        _rangeError(diastolic, _Reading.minDiastolic, _Reading.maxDiastolic) !=
            null ||
        systolic <= diastolic) {
      return null;
    }
    return BpCategory.classify(systolic, diastolic);
  }

  static String? _rangeError(int? value, int min, int max) {
    if (value == null || value < min || value > max) {
      return 'Enter $min–$max';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final category = _previewCategory;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit reading' : 'New reading'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete reading',
              onPressed: _isSaving ? null : _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 24),
          children: [
            Text('Blood pressure', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _systolicController,
                    key: const Key('systolic_field'),
                    decoration: const InputDecoration(
                      labelText: 'Systolic',
                      hintText: '120',
                      suffixText: 'mmHg',
                      helperText: 'Upper number',
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      return _rangeError(int.tryParse(value),
                          _Reading.minSystolic, _Reading.maxSystolic);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _diastolicController,
                    key: const Key('diastolic_field'),
                    decoration: const InputDecoration(
                      labelText: 'Diastolic',
                      hintText: '80',
                      suffixText: 'mmHg',
                      helperText: 'Lower number',
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final diastolic = int.tryParse(value);
                      final error = _rangeError(diastolic,
                          _Reading.minDiastolic, _Reading.maxDiastolic);
                      if (error != null) return error;

                      final systolic = int.tryParse(_systolicController.text);
                      if (systolic != null && systolic <= diastolic!) {
                        return 'Must be below systolic';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _heartRateController,
              key: const Key('heart_rate_field'),
              decoration: const InputDecoration(
                labelText: 'Pulse',
                hintText: '70',
                suffixText: 'bpm',
                prefixIcon: Icon(Icons.favorite_outline),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your pulse';
                }
                return _rangeError(int.tryParse(value), _Reading.minHeartRate,
                    _Reading.maxHeartRate);
              },
            ),

            if (category != null) ...[
              const SizedBox(height: 16),
              _CategoryPreview(category: category),
            ],

            const SizedBox(height: 24),
            Text('When', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('date_button'),
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(DateFormat.yMMMd().format(_selectedDate)),
                    style: _pickerStyle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('time_button'),
                    onPressed: _selectTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_selectedTime.format(context)),
                    style: _pickerStyle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            TextFormField(
              controller: _notesController,
              key: const Key('notes_field'),
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. after exercise, before medication',
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLength: _Reading.maxNotesLength,
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            FilledButton(
              key: const Key('save_button'),
              onPressed: _isSaving ? null : _saveReading,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Save reading'),
            ),
          ],
        ),
      ),
    );
  }

  static final ButtonStyle _pickerStyle = OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    alignment: Alignment.centerLeft,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

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
    // Revalidate everything, including the systolic/diastolic cross-check.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final timestamp = _timestamp;
    if (timestamp.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      messenger.showSnackBar(
        const SnackBar(content: Text('The time of the reading is in the future')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notes = _notesController.text.trim();
      final reading = BloodPressureReading(
        id: widget.reading?.id,
        systolic: int.parse(_systolicController.text),
        diastolic: int.parse(_diastolicController.text),
        heartRate: int.parse(_heartRateController.text),
        timestamp: timestamp,
        notes: notes.isEmpty ? null : notes,
      );

      final provider = context.read<ReadingsProvider>();

      if (_isEditing) {
        await provider.updateReading(reading);
      } else {
        await provider.addReading(reading);
      }

      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Reading updated' : 'Reading saved'),
        ),
      );
    } catch (e) {
      debugPrint('Saving reading failed: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the reading')),
      );
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reading?'),
        content: const Text('This reading will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ReadingsProvider>().deleteReading(widget.reading!.id!);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Reading deleted')));
    } catch (e) {
      debugPrint('Deleting reading failed: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete the reading')),
      );
    }
  }
}

class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview({required this.category});

  final BpCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCrisis = category == BpCategory.crisis;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCrisis
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Category', style: theme.textTheme.labelLarge),
              CategoryChip(category: category),
            ],
          ),
          if (isCrisis) ...[
            const SizedBox(height: 8),
            Text(
              'Wait a few minutes and measure again. If it stays this high, '
              'or you have chest pain, shortness of breath, weakness, vision '
              'changes or difficulty speaking, call emergency services.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
