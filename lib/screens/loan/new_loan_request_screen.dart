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
    _loadLoanTypes();
    _loanValueController.addListener(_calculateInstallment);
    _installmentsController.addListener(_calculateInstallment);
  }

  void _loadLoanTypes() {
    setState(() {
      _typesFuture = _loanService.getLoanTypes();
    });
  }

  @override
  void dispose() {
    _loanValueController.removeListener(_calculateInstallment);
    _installmentsController.removeListener(_calculateInstallment);
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
      // (للمطور) طباعة الخطأ الفعلي في الكونسول
      print("Error submitting loan request: $e");

      if (!mounted) return;
      // -->> ✅ بداية الجزء الذي تم تعديله <<--
      // عرض رسالة خطأ عامة وآمنة للمستخدم
      showDialog(
          context: context,
          builder: (_) => InfoDialog(
              title: localizations.translate('error')!,
              message: localizations.translate('request_submitted_fail_network') ?? 'An unexpected error occurred. Please try again.',
              isSuccess: false
          )
      );
      // -->> 🔚 نهاية الجزء الذي تم تعديله <<--
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRtl = Bidi.isRtlLanguage(Localizations.localeOf(context).languageCode);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          localizations.translate('new_loan_request')!,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18),
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
              final newLocale = currentLocale.languageCode == 'en' ? const Locale('ar', '') : const Locale('en', '');
              MyApp.of(context)?.changeLanguage(newLocale);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<LoanType>>(
        future: _typesFuture,
        builder: (context, snapshot) {
          // -->> ✅ بداية الجزء الذي تم تعديله <<--
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }

          if (snapshot.hasError) {
            print("Error loading loan types: ${snapshot.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      localizations.translate('failed_to_load_types') ?? 'Failed to load loan types',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadLoanTypes,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: Text(localizations.translate('retry') ?? 'Retry', style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                    ),
                  ],
                ),
              ),
            );
          }
          // -->> 🔚 نهاية الجزء الذي تم تعديله <<--

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(localizations.translate('no_types_found') ?? 'No loan types available.'));
          }

          final types = snapshot.data!;
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.translate('loan_details') ?? 'Loan Details',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                        ),
                        const SizedBox(height: 10),
                        _buildSectionTitle(localizations.translate('loan_type')!),
                        const SizedBox(height: 8),
                        _buildDropdownField(
                          items: types.map((type) => DropdownMenuItem(value: type, child: Text(isRtl ? type.nameA : (type.nameE ?? type.nameA), style: const TextStyle(fontSize: 16)))).toList(),
                          value: _selectedType,
                          onChanged: (value) => setState(() => _selectedType = value),
                          icon: Icons.category_outlined,
                          hint: localizations.translate('select_loan_type') ?? 'Select loan type',
                          validator: (v) => v == null ? localizations.translate('field_required') : null,
                        ),
                        const SizedBox(height: 15),
                        _buildSectionTitle(localizations.translate('deduction_start_date')!),
                        const SizedBox(height: 8),
                        _buildDateField(
                          date: _startDate,
                          onTap: () => _selectDate(context),
                          icon: Icons.calendar_today_outlined,
                          hint: localizations.translate('select_start_date') ?? 'Select deduction start date',
                        ),
                        const SizedBox(height: 15),
                        _buildSectionTitle(localizations.translate('loan_value')!),
                        const SizedBox(height: 8),
                        _buildNumberField(
                          controller: _loanValueController,
                          icon: Icons.monetization_on_outlined,
                          hint: localizations.translate('enter_loan_value') ?? 'Enter loan amount',
                          validator: (v) => v == null || v.isEmpty ? localizations.translate('field_required') : null,
                        ),
                        const SizedBox(height: 15),
                        _buildSectionTitle(localizations.translate('installments_count')!),
                        const SizedBox(height: 8),
                        _buildNumberField(
                          controller: _installmentsController,
                          icon: Icons.format_list_numbered_outlined,
                          hint: localizations.translate('enter_installments') ?? 'Number of installments',
                          validator: (v) => v == null || v.isEmpty ? localizations.translate('field_required') : null,
                        ),
                        const SizedBox(height: 15),
                        _buildSectionTitle(localizations.translate('installment_value')!),
                        const SizedBox(height: 8),
                        _buildInfoCard(
                          value: _installmentValue.toStringAsFixed(2),
                          icon: Icons.payment_outlined,
                          color: const Color(0xFF10B981),
                          suffix: localizations.translate('currency') ?? '',
                        ),
                        const SizedBox(height: 15),
                        _buildSectionTitle(localizations.translate('notes')!),
                        const SizedBox(height: 8),
                        _buildTextArea(
                          controller: _notesController,
                          hint: localizations.translate('add_notes') ?? 'Add any additional notes...',
                          maxLines: 1,
                        ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                            : _buildSubmitButton(
                          onPressed: _submitRequest,
                          text: localizations.translate('submit_request')!,
                        ),
                      ],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A5568)),
    );
  }

  Widget _buildDropdownField<T>({required List<DropdownMenuItem<T>> items, required T? value, required void Function(T?) onChanged, required IconData icon, required String hint, String? Function(T?)? validator}) {
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildDateField({required DateTime? date, required VoidCallback onTap, required IconData icon, required String hint}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6C63FF), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date == null ? hint : DateFormat('yyyy/MM/dd').format(date),
                style: TextStyle(fontSize: 16, color: date == null ? Colors.grey.shade600 : const Color(0xFF2D3748)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({required TextEditingController controller, required IconData icon, required String hint, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildInfoCard({required String value, required IconData icon, required Color color, String suffix = ''}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$value $suffix',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea({required TextEditingController controller, required String hint, required int maxLines}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildSubmitButton({required VoidCallback onPressed, required String text}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}