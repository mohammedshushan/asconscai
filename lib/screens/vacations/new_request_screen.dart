/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/vacation_type_model.dart';
import '../models/vacation_balance_model.dart'; // <-- إضافة جديدة
import '../services/vacation_service.dart';
import '../widgets/info_dialog.dart';
import '../app_localizations.dart';
import '../main.dart';

class NewRequestScreen extends StatefulWidget {
  final UserModel user;
  final int maxSerial;
  final List<VacationBalance> balances; // <-- إضافة جديدة: استقبال الأرصدة

  const NewRequestScreen({
    super.key,
    required this.user,
    required this.maxSerial,
    required this.balances, // <-- إضافة جديدة
  });

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final VacationService _vacationService = VacationService();

  VacationType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _returnDate;
  int _duration = 0;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  late Future<List<VacationType>> _typesFuture;

  @override
  void initState() {
    super.initState();
    _typesFuture = _vacationService.getVacationTypes();
  }

  void _updateDatesAndDuration() {
    if (_startDate != null && _endDate != null) {
      if (_endDate!.isBefore(_startDate!)) {
        _endDate = _startDate; // ضمان أن النهاية ليست قبل البداية
      }
      setState(() {
        _duration = _endDate!.difference(_startDate!).inDays + 1;
        // حساب تاريخ العودة تلقائيًا
        _returnDate = _endDate!.add(const Duration(days: 1));
      });
    } else {
      setState(() {
        _duration = 0;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, {
    required Function(DateTime) onDateSelected,
    required DateTime initialDate,
    required DateTime firstDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      onDateSelected(picked);
      _updateDatesAndDuration();
    }
  }

  void _submitRequest() async {
    final localizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    // --- التحقق من رصيد الإجازات ---
    if (_selectedType != null) {
      final balance = widget.balances.firstWhere(
            (b) => b.vcncCode == _selectedType!.vcncCode,
        orElse: () => VacationBalance(empCode: 0, vcncDescA: '', vcncDescE: '', vcncCode: 0, total: 0, remainBal: 0),
      );
      if (_duration > balance.remainBal) {
        showDialog(
          context: context,
          builder: (_) => InfoDialog(
            title: localizations.translate('insufficient_balance')!,
            message: "${localizations.translate('insufficient_balance_msg_1')!} ${balance.remainBal} ${localizations.translate('days')!}, ${localizations.translate('insufficient_balance_msg_2')!} $_duration ${localizations.translate('days')!}.",
            isSuccess: false,
          ),
        );
        return; // إيقاف الإرسال
      }
    }

    setState(() => _isLoading = true);

    final orderData = {
      "serial_pyv": widget.maxSerial + 1,
      "emp_code": widget.user.usersCode,
      "comp_emp_code": widget.user.compEmpCode,
      "start_dt": _startDate!.toIso8601String(),
      "trns_type": _selectedType!.vcncCode,
      "end_dt": _endDate!.toIso8601String(),
      "period": _duration,
      "agree_flag": 0,
      "type_api":6,
      "return_date": _returnDate!.toIso8601String(),
      "notes": _notesController.text,
    };

    try {
      final success = await _vacationService.addVacationOrder(orderData);
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
      showDialog(context: context, builder: (_) => InfoDialog(title: localizations.translate('error')!, message: e.toString(), isSuccess: false));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRtl = Bidi.isRtlLanguage(Localizations.localeOf(context).languageCode);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('new_vacation_request')!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
      body: FutureBuilder<List<VacationType>>(
        future: _typesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));

          final types = snapshot.data ?? [];
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  DropdownButtonFormField<VacationType>(
                    decoration: _inputDecoration(label: localizations.translate('vacation_type')!, icon: Icons.beach_access_outlined),
                    items: types.map((type) => DropdownMenuItem(value: type, child: Text(isRtl ? type.vcncDescA : type.vcncDescE))).toList(),
                    onChanged: (value) => setState(() => _selectedType = value),
                    validator: (v) => v == null ? localizations.translate('field_required') : null,
                  ),
                  const SizedBox(height: 20),
                  _buildDateField(
                    label: localizations.translate('start_date')!,
                    date: _startDate,
                    onTap: () => _selectDate(context,
                      onDateSelected: (date) => setState(() => _startDate = date),
                      initialDate: _startDate ?? today,
                      firstDate: today, // **لا يمكن اختيار تاريخ في الماضي**
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDateField(
                    label: localizations.translate('end_date')!,
                    date: _endDate,
                    onTap: () => _selectDate(context,
                      onDateSelected: (date) => setState(() => _endDate = date),
                      initialDate: _endDate ?? _startDate ?? today,
                      firstDate: _startDate ?? today, // **لا يمكن أن يكون قبل تاريخ البداية**
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDateField(
                    label: localizations.translate('return_date')!,
                    date: _returnDate,
                    onTap: () => _selectDate(context,
                      onDateSelected: (date) => setState(() => _returnDate = date),
                      initialDate: _returnDate ?? _endDate?.add(const Duration(days: 1)) ?? today,
                      firstDate: _endDate?.add(const Duration(days: 1)) ?? today, // **لا يمكن أن يكون قبل نهاية الإجازة**
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: _inputDecoration(label: localizations.translate('duration')!, icon: Icons.hourglass_empty_outlined),
                    controller: TextEditingController(text: '$_duration ${localizations.translate('days')}'),
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _notesController,
                    decoration: _inputDecoration(label: localizations.translate('notes')!, icon: Icons.notes_outlined),
                    maxLines: 4,
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

  Widget _buildDateField({required String label, required DateTime? date, required VoidCallback onTap}) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: date == null ? '' : DateFormat('yyyy/MM/dd').format(date)),
      decoration: _inputDecoration(label: label, icon: Icons.calendar_month_outlined),
      onTap: onTap,
      validator: (v) => v == null || v.isEmpty ? AppLocalizations.of(context)!.translate('field_required') : null,
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      hintText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      label: Text(label),
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/vacation_type_model.dart';
import '../../models/vacation_balance_model.dart';
import '../../services/vacation_service.dart';
import '../../widgets/info_dialog.dart';
import '../../app_localizations.dart';
import '../../main.dart';

class NewRequestScreen extends StatefulWidget {
  final UserModel user;
  final int maxSerial;
  final List<VacationBalance> balances;

  const NewRequestScreen({
    super.key,
    required this.user,
    required this.maxSerial,
    required this.balances,
  });

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final VacationService _vacationService = VacationService();

  VacationType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _returnDate;
  int _duration = 0;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  late Future<List<VacationType>> _typesFuture;

  @override
  void initState() {
    super.initState();
    _typesFuture = _vacationService.getVacationTypes();
  }

  void _updateDatesAndDuration() {
    if (_startDate != null && _endDate != null) {
      if (_endDate!.isBefore(_startDate!)) {
        _endDate = _startDate;
      }
      setState(() {
        _duration = _endDate!.difference(_startDate!).inDays + 1;
        _returnDate = _endDate!.add(const Duration(days: 1));
      });
    } else {
      setState(() {
        _duration = 0;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, {
    required Function(DateTime) onDateSelected,
    required DateTime initialDate,
    required DateTime firstDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
      _updateDatesAndDuration();
    }
  }

  void _submitRequest() async {
    final localizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType != null) {
      final balance = widget.balances.firstWhere(
            (b) => b.vcncCode == _selectedType!.vcncCode,
        orElse: () => VacationBalance(empCode: 0, vcncDescA: '', vcncDescE: '', vcncCode: 0, total: 0, remainBal: 0),
      );
      if (_duration > balance.remainBal) {
        showDialog(
          context: context,
          builder: (_) => InfoDialog(
            title: localizations.translate('insufficient_balance')!,
            message: "${localizations.translate('insufficient_balance_msg_1')!} ${balance.remainBal} ${localizations.translate('days')!}, ${localizations.translate('insufficient_balance_msg_2')!} $_duration ${localizations.translate('days')!}.",
            isSuccess: false,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final orderData = {
      "serial_pyv": widget.maxSerial + 1,
      "emp_code": widget.user.usersCode,
      "comp_emp_code": widget.user.compEmpCode,
      "start_dt": _startDate!.toIso8601String(),
      "trns_type": _selectedType!.vcncCode,
      "end_dt": _endDate!.toIso8601String(),
      "period": _duration,
      "agree_flag": 0,
      "type_api": 6,
      "return_date": _returnDate!.toIso8601String(),
      "notes": _notesController.text,
    };

    try {
      final success = await _vacationService.addVacationOrder(orderData);
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
      showDialog(context: context, builder: (_) => InfoDialog(title: localizations.translate('error')!, message: e.toString(), isSuccess: false));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRtl = Bidi.isRtlLanguage(Localizations.localeOf(context).languageCode);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          localizations.translate('new_vacation_request')!,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.language_outlined, color: Colors.white),
            onPressed: () {
              final currentLocale = Localizations.localeOf(context);
              final newLocale = currentLocale.languageCode == 'en'
                  ? const Locale('ar', '')
                  : const Locale('en', '');
              MyApp.of(context)?.changeLanguage(newLocale);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<VacationType>>(
        future: _typesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF6C63FF),
                    strokeWidth: 3,
                  ),
                ),
              ),
            );
          }

          final types = snapshot.data ?? [];
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title
                 /*
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.beach_access,
                          size: 32,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          localizations.translate('vacation_details') ?? 'تفاصيل الإجازة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
*/
                  // Vacation Type
                  _buildFieldContainer(
                    title: localizations.translate('vacation_type')!,
                    child: _buildDropdownField(
                      items: types.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          isRtl ? type.vcncDescA : type.vcncDescE,
                          style: const TextStyle(fontSize: 16),
                        ),
                      )).toList(),
                      value: _selectedType,
                      onChanged: (value) => setState(() => _selectedType = value),
                      icon: Icons.category_outlined,
                      hint: localizations.translate('select_vacation_type') ?? 'اختر نوع الإجازة',
                      validator: (v) => v == null ? localizations.translate('field_required') : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Start Date
                  _buildFieldContainer(
                    title: localizations.translate('start_date')!,
                    child: _buildDateField(
                      date: _startDate,
                      onTap: () => _selectDate(
                        context,
                        onDateSelected: (date) => setState(() => _startDate = date),
                        initialDate: _startDate ?? today,
                        firstDate: today,
                      ),
                      icon: Icons.event_outlined,
                      hint: localizations.translate('select_start_date') ?? 'اختر تاريخ البداية',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // End Date
                  _buildFieldContainer(
                    title: localizations.translate('end_date')!,
                    child: _buildDateField(
                      date: _endDate,
                      onTap: () => _selectDate(
                        context,
                        onDateSelected: (date) => setState(() => _endDate = date),
                        initialDate: _endDate ?? _startDate ?? today,
                        firstDate: _startDate ?? today,
                      ),
                      icon: Icons.event_outlined,
                      hint: localizations.translate('select_end_date') ?? 'اختر تاريخ النهاية',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Return Date
                  _buildFieldContainer(
                    title: localizations.translate('return_date')!,
                    child: _buildDateField(
                      date: _returnDate,
                      onTap: () => _selectDate(
                        context,
                        onDateSelected: (date) => setState(() => _returnDate = date),
                        initialDate: _returnDate ?? _endDate?.add(const Duration(days: 1)) ?? today,
                        firstDate: _endDate?.add(const Duration(days: 1)) ?? today,
                      ),
                      icon: Icons.assignment_return_outlined,
                      hint: localizations.translate('select_return_date') ?? 'اختر تاريخ العودة',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Duration
                  _buildFieldContainer(
                    title: localizations.translate('duration')!,
                    child: _buildInfoCard(
                      value: '$_duration ${localizations.translate('days')}',
                      icon: Icons.schedule_outlined,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  _buildFieldContainer(
                    title: localizations.translate('notes')!,
                    child: _buildTextArea(
                      controller: _notesController,
                      hint: localizations.translate('add_notes') ?? 'أضف أي ملاحظات إضافية...',
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  _isLoading
                      ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const CircularProgressIndicator(
                        color: Color(0xFF6C63FF),
                        strokeWidth: 3,
                      ),
                    ),
                  )
                      : _buildSubmitButton(
                    onPressed: _submitRequest,
                    text: localizations.translate('submit_request')!,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldContainer({
    required String title,
    required Widget child,
  }) {
    return Container(
      height: 95,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),

          child,
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required List<DropdownMenuItem<T>> items,
    required T? value,
    required void Function(T?) onChanged,
    required IconData icon,
    required String hint,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dropdownColor: Colors.white,
      style: const TextStyle(color: Color(0xFF2D3748), fontSize: 16),
    );
  }

  Widget _buildDateField({
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
    required String hint,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date == null ? hint : DateFormat('yyyy/MM/dd').format(date),
                style: TextStyle(
                  fontSize: 16,
                  color: date == null ? Colors.grey.shade600 : const Color(0xFF2D3748),
                  fontWeight: date == null ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade600),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
    );
  }

  Widget _buildSubmitButton({
    required VoidCallback onPressed,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}