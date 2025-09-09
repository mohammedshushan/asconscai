import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart';
import '../../models/loan_request_model.dart';
import '../../models/loan_type_model.dart';
import '../../services/loan_service.dart';
import '../../app_localizations.dart';
import '../../main.dart';

class MyLoanRequestsScreen extends StatefulWidget {
  final UserModel user;
  const MyLoanRequestsScreen({super.key, required this.user});

  @override
  State<MyLoanRequestsScreen> createState() => _MyLoanRequestsScreenState();
}

class _MyLoanRequestsScreenState extends State<MyLoanRequestsScreen> {
  late Future<Map<String, dynamic>> _dataFuture;
  final LoanService _loanService = LoanService();

  List<LoanRequest> _allRequests = [];
  List<LoanRequest> _filteredRequests = [];

  // متغيرات لحفظ حالة الفلتر
  LoanType? _selectedFilterType;
  int? _selectedFilterStatus;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = _fetchData();
    });
  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      final requests = await _loanService.getLoanRequests(widget.user.usersCode.toString());
      final types = await _loanService.getLoanTypes();
      _allRequests = requests..sort((a, b) => b.reqLoanDate.compareTo(a.reqLoanDate));
      _filteredRequests = List.from(_allRequests);
      return {'requests': _allRequests, 'types': types};
    } catch (e) {
      // FutureBuilder سيلتقط الخطأ ويعالجه بأمان
      rethrow;
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRequests = _allRequests.where((request) {
        final isTypeMatch = _selectedFilterType == null || request.loanType == _selectedFilterType!.loanTypeCode;
        final isStatusMatch = _selectedFilterStatus == null || request.authFlag == _selectedFilterStatus;
        final isDateMatch = _selectedDateRange == null ||
            (request.reqLoanDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                request.reqLoanDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
        return isTypeMatch && isStatusMatch && isDateMatch;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedFilterType = null;
      _selectedFilterStatus = null;
      _selectedDateRange = null;
      _filteredRequests = List.from(_allRequests);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('my_loan_requests')!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              _showFilterSheet(context, localizations, _dataFuture);
            },
          ),

        ],
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }
          // -->> ✅ بداية الجزء الذي تم تعديله <<--
          if (snapshot.hasError) {
            // طباعة الخطأ للمطور فقط
            print("Error fetching loan requests: ${snapshot.error}");
            // عرض واجهة خطأ آمنة للمستخدم
            return _buildErrorWidget(localizations);
          }
          // -->> 🔚 نهاية الجزء الذي تم تعديله <<--
          if (!snapshot.hasData || (snapshot.data!['requests'] as List).isEmpty) {
            return Center(child: Text(localizations.translate('no_requests_found')!));
          }

          final List<LoanType> types = snapshot.data!['types'];
          final typeMap = {for (var type in types) type.loanTypeCode: type};

          if (_filteredRequests.isEmpty) {
            return Center(child: Text(localizations.translate('no_matching_results')!));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredRequests.length,
            itemBuilder: (context, index) {
              final request = _filteredRequests[index];
              final type = typeMap[request.loanType];
              return _buildRequestCard(context, request, type);
            },
          );
        },
      ),
    );
  }

  // -->> ✅ واجهة جديدة لعرض الأخطاء بشكل آمن <<--
  Widget _buildErrorWidget(AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              localizations.translate('failed_to_load_data') ?? 'فشل تحميل البيانات',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('please_check_connection') ?? 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(localizations.translate('retry') ?? 'إعادة المحاولة', style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, AppLocalizations localizations, Future<Map<String, dynamic>> dataFuture) {
    final isRtl = Bidi.isRtlLanguage(Localizations.localeOf(context).languageCode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return FutureBuilder<Map<String, dynamic>>(
              future: dataFuture,
              builder: (context, snapshot) {
                // -->> ✅ بداية الجزء الذي تم تعديله في الفلتر <<--
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return SizedBox(height: 200, child: Center(child: Text(localizations.translate('failed_to_load_filters') ?? 'Failed to load filters')));
                }
                // -->> 🔚 نهاية الجزء الذي تم تعديله في الفلتر <<--

                final List<LoanType> types = snapshot.data!['types'];
                final statuses = {
                  localizations.translate('status_approved')!: 1,
                  localizations.translate('status_pending')!: 0,
                  localizations.translate('status_rejected')!: -1,
                };

                return Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 24, right: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)))),
                        const SizedBox(height: 20),
                        Text(localizations.translate('filter_requests')!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        Text(localizations.translate('filter_by_type')!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        DropdownButtonFormField<LoanType>(
                          value: _selectedFilterType,
                          decoration: InputDecoration(hintText: localizations.translate('all_types')),
                          items: [
                            DropdownMenuItem<LoanType>(value: null, child: Text(localizations.translate('all_types')!)),
                            ...types.map((type) => DropdownMenuItem<LoanType>(value: type, child: Text(isRtl ? type.nameA : (type.nameE ?? type.nameA)))),
                          ],
                          onChanged: (value) => setModalState(() => _selectedFilterType = value),
                        ),
                        const SizedBox(height: 24),
                        Text(localizations.translate('filter_by_status')!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: [
                            ChoiceChip(
                              label: Text(localizations.translate('all_statuses')!),
                              selected: _selectedFilterStatus == null,
                              onSelected: (selected) => setModalState(() { if (selected) _selectedFilterStatus = null; }),
                            ),
                            ...statuses.entries.map((entry) => ChoiceChip(
                              label: Text(entry.key),
                              selected: _selectedFilterStatus == entry.value,
                              onSelected: (selected) => setModalState(() { _selectedFilterStatus = selected ? entry.value : null; }),
                            )),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(localizations.translate('filter_by_date')!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_month_outlined),
                          title: Text(_selectedDateRange == null
                              ? localizations.translate('select_date_range')!
                              : '${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.end)}'),
                          trailing: _selectedDateRange != null ? IconButton(icon: const Icon(Icons.close), onPressed: () => setModalState(() => _selectedDateRange = null)) : null,
                          onTap: () async {
                            final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (picked != null) setModalState(() => _selectedDateRange = picked);
                          },
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  _resetFilters();
                                  Navigator.pop(context);
                                },
                                child: Text(localizations.translate('reset_filters')!, style: const TextStyle(color: Colors.grey)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), padding: const EdgeInsets.symmetric(vertical: 12)),
                                onPressed: () {
                                  _applyFilters();
                                  Navigator.pop(context);
                                },
                                child: Text(localizations.translate('apply_filters')!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Map<String, dynamic> _getStatusInfo(BuildContext context, int flag) {
    final localizations = AppLocalizations.of(context)!;
    switch (flag) {
      case 1:
        return {'text': localizations.translate('status_approved')!, 'color': Colors.green.shade700, 'icon': Icons.check_circle_rounded};
      case -1:
        return {'text': localizations.translate('status_rejected')!, 'color': Colors.red.shade700, 'icon': Icons.cancel_rounded};
      case 0:
      default:
        return {'text': localizations.translate('status_pending')!, 'color': Colors.orange.shade800, 'icon': Icons.hourglass_empty_rounded};
    }
  }

  Widget _buildRequestCard(BuildContext context, LoanRequest request, LoanType? type) {
    final isRtl = Bidi.isRtlLanguage(Localizations.localeOf(context).languageCode);
    final localizations = AppLocalizations.of(context)!;
    final loanName = type != null ? (isRtl ? type.nameA : (type.nameE ?? type.nameA)) : localizations.translate('unknown');
    final status = _getStatusInfo(context, request.authFlag);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => _showRequestDetails(context, request, loanName, status),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      loanName ?? 'Loan',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: status['color']!.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Icon(status['icon'], color: status['color'], size: 14),
                        const SizedBox(width: 6),
                        Text(status['text']!, style: TextStyle(color: status['color'], fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn(localizations.translate('request_date')!, DateFormat('yyyy/MM/dd').format(request.reqLoanDate)),
                  _buildInfoColumn(localizations.translate('loan_value')!, request.loanValuePys.toStringAsFixed(2), crossAxisAlignment: CrossAxisAlignment.end),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  void _showRequestDetails(BuildContext context, LoanRequest request, String? loanName, Map<String, dynamic> status) {
    final localizations = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 20),
              Text(loanName ?? localizations.translate('loan_details')!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: status['color']!.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(status['text']!, style: TextStyle(color: status['color'], fontWeight: FontWeight.bold)),
                ),
              ),
              const Divider(height: 32),
              _buildDetailRow(localizations.translate('deduction_start_date')!, DateFormat('yyyy/MM/dd').format(request.loanStartDate), Icons.calendar_today_outlined),
              _buildDetailRow(localizations.translate('installments_count')!, request.loanNos.toString(), Icons.format_list_numbered_rounded),
              _buildDetailRow(localizations.translate('installment_value')!, request.loanInstlPys.toStringAsFixed(2), Icons.payment_rounded),
              _buildDetailRow(localizations.translate('notes')!, request.notes != null && request.notes!.isNotEmpty ? request.notes! : localizations.translate('no_notes')!, Icons.notes_rounded),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}