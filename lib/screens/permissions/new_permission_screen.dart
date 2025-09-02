
import 'package:asconscai/app_localizations.dart';
import 'package:asconscai/models/permissions/permission_type_model.dart';
import 'package:asconscai/models/user_model.dart';
import 'package:asconscai/services/permission_service.dart';
import 'package:asconscai/widgets/info_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../main.dart';


class NewPermissionScreen extends StatefulWidget {
  final UserModel user;
  const NewPermissionScreen({super.key, required this.user});

  @override
  State<NewPermissionScreen> createState() => _NewPermissionScreenState();
}

class _NewPermissionScreenState extends State<NewPermissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final PermissionService _permissionService = PermissionService();

  PermissionType? _selectedType;
  DateTime? _exitDate;
  TimeOfDay? _exitTime;
  DateTime? _returnDate;
  TimeOfDay? _returnTime;
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  late Future<List<PermissionType>> _typesFuture;

  @override
  void initState() {
    super.initState();
    _typesFuture = _permissionService.getPermissionTypes();
  }

  Future<void> _selectDate(BuildContext context, {required Function(DateTime) onDateSelected}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _selectTime(BuildContext context, {required Function(TimeOfDay) onTimeSelected}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  void _submitRequest() async {
    final localizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_exitDate != null && _returnDate != null && _exitTime != null && _returnTime != null) {
      final exitDateTime = DateTime(_exitDate!.year, _exitDate!.month, _exitDate!.day, _exitTime!.hour, _exitTime!.minute);
      final returnDateTime = DateTime(_returnDate!.year, _returnDate!.month, _returnDate!.day, _returnTime!.hour, _returnTime!.minute);
      if (returnDateTime.isBefore(exitDateTime)) {
        showDialog(
          context: context,
          builder: (_) => InfoDialog(
            title: localizations.translate('invalid_date_time')!,
            message: localizations.translate('return_date_time_error')!,
            isSuccess: false,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final maxSerial = await _permissionService.getMaxSerial();

      final exitDateTime = DateTime(_exitDate!.year, _exitDate!.month, _exitDate!.day, _exitTime!.hour, _exitTime!.minute);
      final returnDateTime = DateTime(_returnDate!.year, _returnDate!.month, _returnDate!.day, _returnTime!.hour, _returnTime!.minute);

      final requestData = {
        "emp_code": widget.user.usersCode,
        "exit_date": DateFormat('yyyy-MM-dd').format(_exitDate!),
        "enter_date": DateFormat('yyyy-MM-dd').format(_returnDate!),
        "comp_emp_code": widget.user.compEmpCode,
        "exit_reason": _reasonController.text,
        "exit_time": exitDateTime.toUtc().toIso8601String(),
        "enter_time": returnDateTime.toUtc().toIso8601String(),
        "type_api": 6,
        "exit_reason_code": _selectedType!.code,
        "accept_flag": 0,
        "notes": _notesController.text,
        "serial": maxSerial + 1,
      };

      final success = await _permissionService.addPermissionRequest(requestData);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => InfoDialog(
          title: localizations.translate(success ? 'success' : 'failed')!,
          message: localizations.translate(success ? 'request_submitted_success' : 'request_submitted_fail')!,
          isSuccess: success,
        ),
      ).then((_) {
        if (success) Navigator.of(context).pop(true);
      });
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString().replaceAll('Exception: ', '');
      if (errorMessage.contains('No Internet Connection')) {
        errorMessage = localizations.translate('no_internet_connection') ?? 'No Internet Connection';
      }

      showDialog(
        context: context,
        builder: (_) => InfoDialog(
          title: localizations.translate('error')!,
          message: errorMessage,
          isSuccess: false,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRtl = Bidi.isRtlLanguage(Localizations.localeOf(context).languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('new_permission_request')!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.language_outlined, color: Colors.white),
            onPressed: () {
              final currentLocale = Localizations.localeOf(context);
              final newLocale = currentLocale.languageCode == 'en' ? const Locale('ar', '') : const Locale('en', '');
              MyApp.of(context)?.changeLanguage(newLocale);
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: FutureBuilder<List<PermissionType>>(
        future: _typesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }
          if (snapshot.hasError) {
            return Center(child: Text(localizations.translate('error_loading_types') ?? 'Error loading types'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(localizations.translate('no_permission_types_found') ?? 'No permission types found'));
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  DropdownButtonFormField<PermissionType>(
                    decoration: _inputDecoration(label: localizations.translate('permission_type')!),
                    items: snapshot.data!.map((type) => DropdownMenuItem(value: type, child: Text(isRtl ? type.reasonAr : type.reasonEn ?? type.reasonAr))).toList(),
                    onChanged: (value) => setState(() => _selectedType = value),
                    validator: (v) => v == null ? localizations.translate('field_required') : null,
                  ),
                  const SizedBox(height: 20),
                  _buildDateTimePicker(
                    context: context,
                    label: localizations.translate('exit_date_time')!,
                    selectedDate: _exitDate,
                    selectedTime: _exitTime,
                    onDateSelected: (date) => setState(() => _exitDate = date),
                    onTimeSelected: (time) => setState(() => _exitTime = time),
                  ),
                  const SizedBox(height: 20),
                  _buildDateTimePicker(
                    context: context,
                    label: localizations.translate('return_date_time')!,
                    selectedDate: _returnDate,
                    selectedTime: _returnTime,
                    onDateSelected: (date) => setState(() => _returnDate = date),
                    onTimeSelected: (time) => setState(() => _returnTime = time),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _reasonController,
                    decoration: _inputDecoration(label: localizations.translate('exit_reason')!),
                    validator: (v) => v == null || v.isEmpty ? localizations.translate('field_required') : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _notesController,
                    decoration: _inputDecoration(label: localizations.translate('notes')!),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 40),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text(localizations.translate('submit_request')!, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateTimePicker({
    required BuildContext context,
    required String label,
    required DateTime? selectedDate,
    required TimeOfDay? selectedTime,
    required Function(DateTime) onDateSelected,
    required Function(TimeOfDay) onTimeSelected,
  }) {
    final String dateText = selectedDate != null ? DateFormat('yyyy/MM/dd').format(selectedDate) : '';
    final String timeText = selectedTime != null ? selectedTime.format(context) : '';
    final String displayText = dateText.isNotEmpty || timeText.isNotEmpty ? '$dateText - $timeText' : '';

    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: displayText),
      decoration: _inputDecoration(label: label),
      onTap: () async {
        await _selectDate(context, onDateSelected: onDateSelected);
        if (!mounted) return;
        await _selectTime(context, onTimeSelected: onTimeSelected);
      },
      validator: (v) => v == null || v.isEmpty ? AppLocalizations.of(context)!.translate('field_required') : null,
    );
  }

  InputDecoration _inputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
    );
  }
}