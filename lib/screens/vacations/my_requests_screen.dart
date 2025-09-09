import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../models/vacation_order_model.dart';
import '../../models/vacation_type_model.dart';
import '../../services/vacation_service.dart';
import '../../app_localizations.dart';

class MyRequestsScreen extends StatefulWidget {
  final UserModel user;
  const MyRequestsScreen({super.key, required this.user});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  late Future<Map<String, dynamic>> _dataFuture;
  final VacationService _vacationService = VacationService();

  List<VacationOrder> _allOrders = [];
  List<VacationOrder> _filteredOrders = [];

  // Filter state
  VacationType? _selectedFilterType;
  int? _selectedFilterStatus;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      final orders = await _vacationService.getVacationOrders(widget.user.usersCode.toString());
      final types = await _vacationService.getVacationTypes();
      _allOrders = orders..sort((a, b) => b.trnsDate.compareTo(a.trnsDate)); // Sort by most recent
      _filteredOrders = List.from(_allOrders);
      return {'orders': _allOrders, 'types': types};
    } catch (e) {
      // تمرير الخطأ ليتم معالجته في FutureBuilder
      rethrow;
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders = _allOrders.where((order) {
        final isTypeMatch = _selectedFilterType == null || order.trnsType == _selectedFilterType!.vcncCode;
        final isStatusMatch = _selectedFilterStatus == null || order.agreeFlag == _selectedFilterStatus;
        final isDateMatch = _selectedDateRange == null ||
            (order.startDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                order.startDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
        return isTypeMatch && isStatusMatch && isDateMatch;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedFilterType = null;
      _selectedFilterStatus = null;
      _selectedDateRange = null;
      _filteredOrders = List.from(_allOrders);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('my_requests')!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
            // (للمطور) طباعة الخطأ الفعلي في الـ Debug Console
            print('Error fetching vacation data: ${snapshot.error}');

            // عرض واجهة خطأ آمنة وسهلة الاستخدام
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
                      onPressed: () {
                        // إعادة محاولة جلب البيانات
                        setState(() {
                          _dataFuture = _fetchData();
                        });
                      },
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
          // -->> 🔚 نهاية الجزء الذي تم تعديله <<--

          if (!snapshot.hasData || (snapshot.data!['orders'] as List).isEmpty) {
            return Center(child: Text(localizations.translate('no_requests_found')!));
          }

          final List<VacationType> types = snapshot.data!['types'];
          final typeMap = {for (var type in types) type.vcncCode: type};

          if (_filteredOrders.isEmpty) {
            return Center(child: Text(localizations.translate('no_requests_found_after_filter') ?? 'لا توجد نتائج تطابق الفلتر'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredOrders.length,
            itemBuilder: (context, index) {
              final order = _filteredOrders[index];
              final type = typeMap[order.trnsType];
              return _buildRequestCard(context, order, type);
            },
          );
        },
      ),
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

  Widget _buildRequestCard(BuildContext context, VacationOrder order, VacationType? type) {
    final isRtl = Bidi.isRtlLanguage(Localizations.localeOf(context).languageCode);
    final localizations = AppLocalizations.of(context)!;
    final vacationName = type != null ? (isRtl ? type.vcncDescA : type.vcncDescE) : localizations.translate('unknown');
    final status = _getStatusInfo(context, order.agreeFlag);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => _showRequestDetails(context, order, vacationName, status),
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
                      vacationName ?? 'Vacation',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: status['color']!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(status['icon'], color: status['color'], size: 14),
                        const SizedBox(width: 6),
                        Text(
                          status['text']!,
                          style: TextStyle(color: status['color'], fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn(localizations.translate('request_date')!, DateFormat('yyyy/MM/dd').format(order.trnsDate)),
                  _buildInfoColumn(localizations.translate('duration')!, '${order.period} ${localizations.translate('days')}', crossAxisAlignment: CrossAxisAlignment.end),
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

  void _showRequestDetails(BuildContext context, VacationOrder order, String? vacationName, Map<String, dynamic> status) {
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
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                vacationName ?? localizations.translate('vacation_details')!,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
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
              _buildDetailRow(localizations.translate('start_date')!, DateFormat('yyyy/MM/dd').format(order.startDate), Icons.calendar_today_outlined),
              _buildDetailRow(localizations.translate('end_date')!, DateFormat('yyyy/MM/dd').format(order.endDate), Icons.calendar_today_rounded),
              _buildDetailRow(localizations.translate('return_date')!, order.returnDate != null ? DateFormat('yyyy/MM/dd').format(order.returnDate!) : '-', Icons.event_available_rounded),
              _buildDetailRow(localizations.translate('notes')!, order.notes != null && order.notes!.isNotEmpty ? order.notes! : localizations.translate('no_notes')!, Icons.notes_rounded),
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

  void _showFilterSheet(BuildContext context, AppLocalizations localizations, Future<Map<String, dynamic>> dataFuture) {
    final isRtl = Directionality.of(context) == TextDirection.RTL;

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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                }

                // معالجة الخطأ هنا أيضاً لتجربة مستخدم أفضل
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(localizations.translate('failed_to_load_filters') ?? 'فشل تحميل الفلاتر'),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const SizedBox(height: 200, child: Center(child: Text('No data')));
                }

                final List<VacationType> types = snapshot.data!['types'];
                final statuses = {
                  localizations.translate('approved')!: 1,
                  localizations.translate('pending')!: 0,
                  localizations.translate('rejected')!: -1,
                };

                return Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 24, right: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(localizations.translate('filter_requests')!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        // Filter by Type
                        Text(localizations.translate('filter_by_type')!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        DropdownButtonFormField<VacationType>(
                          value: _selectedFilterType,
                          decoration: InputDecoration(hintText: localizations.translate('all_types')),
                          items: [
                            DropdownMenuItem<VacationType>(value: null, child: Text(localizations.translate('all_types')!)),
                            ...types.map((type) => DropdownMenuItem<VacationType>(value: type, child: Text(isRtl ? type.vcncDescA : type.vcncDescE))),
                          ],
                          onChanged: (value) => setModalState(() => _selectedFilterType = value),
                        ),
                        const SizedBox(height: 24),
                        // Filter by Status
                        Text(localizations.translate('filter_by_status')!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: [
                            ChoiceChip(
                              label: Text(localizations.translate('all_statuses')!),
                              selected: _selectedFilterStatus == null,
                              onSelected: (selected) => setModalState(() {
                                if (selected) _selectedFilterStatus = null;
                              }),
                            ),
                            ...statuses.entries.map((entry) => ChoiceChip(
                              label: Text(entry.key),
                              selected: _selectedFilterStatus == entry.value,
                              onSelected: (selected) => setModalState(() {
                                _selectedFilterStatus = selected ? entry.value : null;
                              }),
                            )),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Filter by Date
                        Text(localizations.translate('filter_by_date')!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_month_outlined),
                          title: Text(_selectedDateRange == null
                              ? localizations.translate('select_date_range')!
                              : '${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.end)}'),
                          trailing: _selectedDateRange != null ? IconButton(icon: const Icon(Icons.close), onPressed: () => setModalState(() => _selectedDateRange = null)) : null,
                          onTap: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              currentDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() => _selectedDateRange = picked);
                            }
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
}