/*
// مسار الملف: lib/screens/new_loan_request_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/loan_type_model.dart';
import '../services/loan_service.dart';
import '../widgets/info_dialog.dart';
import '../app_localizations.dart';
import '../main.dart';

class NewLoanRequestScreen extends StatefulWidget {
  final UserModel user;
  final int maxSerial;
  const NewLoanRequestScreen({super.key, required this.user, required this.maxSerial});

  @override
  State<NewLoanRequestScreen> createState() => _NewLoanRequestScreenState();
}

class _NewLoanRequestScreenState extends State<NewLoanRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final LoanService _loanService = LoanService();

  LoanType? _selectedType;
  DateTime? _startDate;
  final _loanValueController = TextEditingController();
  final _installmentsController = TextEditingController();
  double _installmentValue = 0.0;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  late Future<List<LoanType>> _typesFuture;

  @override
  void initState() {
    super.initState();
    _typesFuture = _loanService.getLoanTypes();
    _loanValueController.addListener(_calculateInstallment);
    _installmentsController.addListener(_calculateInstallment);
  }

  @override
  void dispose() {
    _loanValueController.dispose();
    _installmentsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateInstallment() {
    final double totalValue = double.tryParse(_loanValueController.text) ?? 0;
    final int installments = int.tryParse(_installmentsController.text) ?? 0;
    if (totalValue > 0 && installments > 0) {
      setState(() => _installmentValue = totalValue / installments);
    } else {
      setState(() => _installmentValue = 0.0);
    }
  }

  // --- تم تعديل هذه الدالة لإضافة التحقق من التاريخ ---
  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // تجاهل الوقت لضمان اختيار اليوم الحالي

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today, // **لا يمكن اختيار تاريخ في الماضي**
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _submitRequest() async {
    final localizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final loanData = {
      "req_serial": widget.maxSerial + 1,
      "emp_code": widget.user.usersCode,
      "comp_emp_code": widget.user.compEmpCode,
      "loan_start_date": _startDate!.toIso8601String(),
      "loan_type": _selectedType!.loanTypeCode,
      "loan_value_pys": double.parse(_loanValueController.text),
      "loan_instl_pys": _installmentValue,
      "auth_flag": 0,
      "loan_nos": int.parse(_installmentsController.text),
      "notes": _notesController.text,
    };

    try {
      final success = await _loanService.addLoanRequest(loanData);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => InfoDialog(
          title: localizations.translate(success ? 'success' : 'failed')!,
          message: localizations.translate(success ? 'request_submitted_success' : 'request_submitted_fail')!,
          isSuccess: success,
          buttonText: localizations.translate('ok'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('new_loan_request')!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
      body: FutureBuilder<List<LoanType>>(
        future: _typesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color((0xFF6C63FF))));

          final types = snapshot.data ?? [];
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  DropdownButtonFormField<LoanType>(
                    decoration: _inputDecoration(label: localizations.translate('loan_type')!, icon: Icons.category_outlined),
                    items: types.map((type) => DropdownMenuItem(value: type, child: Text(isRtl ? type.nameA : (type.nameE ?? type.nameA)))).toList(),
                    onChanged: (value) => setState(() => _selectedType = value),
                    validator: (v) => v == null ? localizations.translate('field_required') : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: _startDate == null ? '' : DateFormat('yyyy/MM/dd').format(_startDate!)),
                    decoration: _inputDecoration(label: localizations.translate('deduction_start_date')!, icon: Icons.calendar_month_outlined),
                    onTap: () => _selectDate(context),
                    validator: (v) => v == null || v.isEmpty ? localizations.translate('field_required') : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _loanValueController,
                    decoration: _inputDecoration(label: localizations.translate('loan_value')!, icon: Icons.monetization_on_outlined),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? localizations.translate('field_required') : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _installmentsController,
                    decoration: _inputDecoration(label: localizations.translate('installments_count')!, icon: Icons.format_list_numbered_rounded),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? localizations.translate('field_required') : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: _inputDecoration(label: localizations.translate('installment_value')!, icon: Icons.payment_outlined),
                    controller: TextEditingController(text: _installmentValue.toStringAsFixed(2)),
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
                      ? const Center(child: CircularProgressIndicator(color: Color((0xFF6C63FF))))
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color((0xFF6C63FF)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  // --- تم تعديل هذه الدالة لإصلاح مشكلة تداخل العنوان ---
  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      // استخدام hintText بدلاً من labelText لتجنب التداخل
      hintText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always, // يجعل العنوان يطفو دائمًا
      label: Text(label), // استخدام label لإظهار العنوان فوق الحقل
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color((0xFF6C63FF))),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color((0xFF6C63FF)), width: 2)),
    );
  }
}

 */


// مسار الملف: lib/screens/new_loan_request_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/loan_type_model.dart';
import '../../services/loan_service.dart';
import '../../widgets/info_dialog.dart';
import '../../app_localizations.dart';
import '../../main.dart';

class NewLoanRequestScreen extends StatefulWidget {
  final UserModel user;
  final int maxSerial;
  const NewLoanRequestScreen({super.key, required this.user, required this.maxSerial});

  @override
  State<NewLoanRequestScreen> createState() => _NewLoanRequestScreenState();
}

class _NewLoanRequestScreenState extends State<NewLoanRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final LoanService _loanService = LoanService();

  LoanType? _selectedType;
  DateTime? _startDate;
  final _loanValueController = TextEditingController();
  final _installmentsController = TextEditingController();
  double _installmentValue = 0.0;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  late Future<List<LoanType>> _typesFuture;

  @override
  void initState() {
    super.initState();
    _typesFuture = _loanService.getLoanTypes();
    _loanValueController.addListener(_calculateInstallment);
    _installmentsController.addListener(_calculateInstallment);
  }

  @override
  void dispose() {
    _loanValueController.dispose();
    _installmentsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateInstallment() {
    final double totalValue = double.tryParse(_loanValueController.text) ?? 0;
    final int installments = int.tryParse(_installmentsController.text) ?? 0;
    if (totalValue > 0 && installments > 0) {
      setState(() => _installmentValue = totalValue / installments);
    } else {
      setState(() => _installmentValue = 0.0);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today,
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
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _submitRequest() async {
    final localizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final loanData = {
      "req_serial": widget.maxSerial + 1,
      "emp_code": widget.user.usersCode,
      "comp_emp_code": widget.user.compEmpCode,
      "loan_start_date": _startDate!.toIso8601String(),
      "loan_type": _selectedType!.loanTypeCode,
      "loan_value_pys": double.parse(_loanValueController.text),
      "loan_instl_pys": _installmentValue,
      "auth_flag": 0,
      "loan_nos": int.parse(_installmentsController.text),
      "notes": _notesController.text,
    };

    try {
      final success = await _loanService.addLoanRequest(loanData);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => InfoDialog(
          title: localizations.translate(success ? 'success' : 'failed')!,
          message: localizations.translate(success ? 'request_submitted_success' : 'request_submitted_fail')!,
          isSuccess: success,
          buttonText: localizations.translate('ok'),
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
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          localizations.translate('new_loan_request')!,
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
      body: FutureBuilder<List<LoanType>>(
        future: _typesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }

          final types = snapshot.data ?? [];
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 600 : double.infinity,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: isTablet ? (screenSize.width - 600) / 2 : 0,
                ),
                child: Column(
                  children: [
                    /*
                    // Header Card
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              localizations.translate('loan_request_subtitle') ??
                                  'Fill out the form below to submit your loan request',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
*/
                    // Form Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.translate('loan_details') ?? 'Loan Details',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Loan Type
                            _buildSectionTitle(localizations.translate('loan_type')!),
                            const SizedBox(height: 8),
                            _buildDropdownField(
                              items: types.map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                  isRtl ? type.nameA : (type.nameE ?? type.nameA),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              )).toList(),
                              value: _selectedType,
                              onChanged: (value) => setState(() => _selectedType = value),
                              icon: Icons.category_outlined,
                              hint: localizations.translate('select_loan_type') ?? 'Select loan type',
                              validator: (v) => v == null ? localizations.translate('field_required') : null,
                            ),
                            const SizedBox(height: 15),

                            // Deduction Start Date
                            _buildSectionTitle(localizations.translate('deduction_start_date')!),
                            const SizedBox(height: 8),
                            _buildDateField(
                              date: _startDate,
                              onTap: () => _selectDate(context),
                              icon: Icons.calendar_today_outlined,
                              hint: localizations.translate('select_start_date') ?? 'Select deduction start date',
                            ),
                            const SizedBox(height: 15),

                            // Loan Value and Installments Row
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(localizations.translate('loan_value')!),
                                const SizedBox(height: 8),
                                _buildNumberField(
                                  controller: _loanValueController,
                                  icon: Icons.monetization_on_outlined,
                                  hint: localizations.translate('enter_loan_value') ?? 'Enter loan amount',
                                  validator: (v) => v == null || v.isEmpty ? localizations.translate('field_required') : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(localizations.translate('installments_count')!),
                                const SizedBox(height: 8),
                                _buildNumberField(
                                  controller: _installmentsController,
                                  icon: Icons.format_list_numbered_outlined,
                                  hint: localizations.translate('enter_installments') ?? 'Number of installments',
                                  validator: (v) => v == null || v.isEmpty ? localizations.translate('field_required') : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            // Installment Value (calculated)
                            _buildSectionTitle(localizations.translate('installment_value')!),
                            const SizedBox(height: 8),
                            _buildInfoCard(
                              value: _installmentValue.toStringAsFixed(2),
                              icon: Icons.payment_outlined,
                              color: const Color(0xFF10B981),
                              suffix: localizations.translate('currency') ?? '',
                            ),
                            const SizedBox(height: 15),

                            // Notes
                            _buildSectionTitle(localizations.translate('notes')!),
                            const SizedBox(height: 8),
                            _buildTextArea(
                              controller: _notesController,
                              hint: localizations.translate('add_notes') ?? 'Add any additional notes...',
                              maxLines: 1,
                            ),
                            const SizedBox(height: 15),

                            // Submit Button
                            _isLoading
                                ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const CircularProgressIndicator(
                                  color: Color(0xFF6C63FF),
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                                : _buildSubmitButton(
                              onPressed: _submitRequest,
                              text: localizations.translate('submit_request')!,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4A5568),
        letterSpacing: 0.5,
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
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6C63FF), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date == null ? hint : DateFormat('yyyy/MM/dd').format(date),
                style: TextStyle(
                  fontSize: 16,
                  color: date == null ? Colors.grey.shade600 : const Color(0xFF2D3748),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: const TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
    );
  }

  Widget _buildInfoCard({
    required String value,
    required IconData icon,
    required Color color,
    String suffix = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$value $suffix',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
            blurRadius: 12,
            offset: const Offset(0, 6),
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
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}