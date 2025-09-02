import 'package:asconscai/app_localizations.dart';
import 'package:asconscai/models/permissions/permission_request_model.dart';
import 'package:asconscai/models/permissions/permission_type_model.dart';
import 'package:asconscai/models/user_model.dart';
import 'package:asconscai/services/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../main.dart';


class MyPermissionsScreen extends StatefulWidget {
  final UserModel user;
  const MyPermissionsScreen({super.key, required this.user});

  @override
  State<MyPermissionsScreen> createState() => _MyPermissionsScreenState();
}

class _MyPermissionsScreenState extends State<MyPermissionsScreen> {
  late Future<Map<String, dynamic>> _dataFuture;
  final PermissionService _permissionService = PermissionService();

  List<PermissionRequest> _allRequests = [];
  List<PermissionRequest> _filteredRequests = [];

  PermissionType? _selectedFilterType;
  int? _selectedFilterStatus;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      final requests = await _permissionService.getPermissionRequests(widget.user.usersCode.toString());
      final types = await _permissionService.getPermissionTypes();
      _allRequests = requests..sort((a, b) => b.exitDate.compareTo(a.exitDate));
      _filteredRequests = List.from(_allRequests);
      return {'requests': _allRequests, 'types': types};
    } catch (e) {
      rethrow;
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRequests = _allRequests.where((request) {
        final isTypeMatch = _selectedFilterType == null || request.reasonCode == _selectedFilterType!.code;
        final isStatusMatch = _selectedFilterStatus == null || request.acceptFlag == _selectedFilterStatus;
        final isDateMatch = _selectedDateRange == null ||
            (request.exitDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                request.exitDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
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
        title: Text(localizations.translate('my_permission_requests')!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
            onPressed: () => _showFilterSheet(context, localizations),
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
          if (snapshot.hasError) {
            return Center(child: Text('${localizations.translate('error')}: ${snapshot.error}'));
          }
          if (!snapshot.hasData || (snapshot.data!['requests'] as List).isEmpty) {
            return Center(child: Text(localizations.translate('no_requests_found')!));
          }

          final List<PermissionType> types = snapshot.data!['types'];
          final typeMap = {for (var type in types) type.code: type};

          if (_filteredRequests.isEmpty) {
            return Center(child: Text(localizations.translate('no_requests_found_after_filter')!));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredRequests.length,
            itemBuilder: (context, index) {
              final request = _filteredRequests[index];
              final type = typeMap[request.reasonCode];
              return _buildRequestCard(context, request, type);
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
        return {'text': localizations.translate('status_approved')!, 'color': Colors.green.shade700};
      case -1:
        return {'text': localizations.translate('status_rejected')!, 'color': Colors.red.shade700};
      case 0:
      default:
        return {'text': localizations.translate('status_pending')!, 'color': Colors.orange.shade800};
    }
  }

  Widget _buildRequestCard(BuildContext context, PermissionRequest request, PermissionType? type) {
    final isRtl = Bidi.isRtlLanguage(Localizations.localeOf(context).languageCode);
    final localizations = AppLocalizations.of(context)!;
    final permissionName = type != null ? type.getLocalizedName(isRtl) : localizations.translate('unknown');
    final status = _getStatusInfo(context, request.acceptFlag);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _showRequestDetails(context, request, permissionName, status),
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
                    child: Text(permissionName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: status['color']!.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(status['text']!, style: TextStyle(color: status['color'], fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn(localizations.translate('exit_date')!, DateFormat('yyyy/MM/dd').format(request.exitDate)),
                  _buildInfoColumn(localizations.translate('return_date')!, DateFormat('yyyy/MM/dd').format(request.enterDate), crossAxisAlignment: CrossAxisAlignment.end),
                ],
              )
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

  void _showRequestDetails(BuildContext context, PermissionRequest request, String permissionName, Map<String, dynamic> status) {
    final localizations = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(permissionName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
              const Divider(height: 24),
              _buildDetailRow(localizations.translate('status')!, status['text']),
              _buildDetailRow(localizations.translate('exit_date_time')!, '${DateFormat('yyyy/MM/dd').format(request.exitDate)} - ${DateFormat.jm().format(request.exitTime)}'),
              _buildDetailRow(localizations.translate('return_date_time')!, '${DateFormat('yyyy/MM/dd').format(request.enterDate)} - ${DateFormat.jm().format(request.enterTime)}'),
              _buildDetailRow(localizations.translate('exit_reason')!, request.exitReason ?? localizations.translate('no_reason_provided')!),
              _buildDetailRow(localizations.translate('notes')!, request.notes ?? localizations.translate('no_notes')!),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title: ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, AppLocalizations localizations) {
    final isRtl = Bidi.isRtlLanguage(Localizations.localeOf(context).languageCode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return FutureBuilder<Map<String, dynamic>>(
              future: _dataFuture, // Reuse the same future
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));

                final List<PermissionType> types = snapshot.data!['types'];
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
                        Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)))),
                        const SizedBox(height: 20),
                        Text(localizations.translate('filter_requests')!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        // Filter by Type
                        DropdownButtonFormField<PermissionType>(
                          value: _selectedFilterType,
                          decoration: InputDecoration(hintText: localizations.translate('all_types')),
                          items: [
                            DropdownMenuItem<PermissionType>(value: null, child: Text(localizations.translate('all_types')!)),
                            ...types.map((type) => DropdownMenuItem<PermissionType>(value: type, child: Text(isRtl ? type.reasonAr : type.reasonEn ?? type.reasonAr))),
                          ],
                          onChanged: (value) => setModalState(() => _selectedFilterType = value),
                        ),
                        const SizedBox(height: 24),
                        // Filter by Status
                        Text(localizations.translate('filter_by_status')!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Wrap(
                          spacing: 8.0,
                          children: [
                            ChoiceChip(label: Text(localizations.translate('all')!), selected: _selectedFilterStatus == null, onSelected: (s) => setModalState(() => _selectedFilterStatus = null)),
                            ...statuses.entries.map((entry) => ChoiceChip(label: Text(entry.key), selected: _selectedFilterStatus == entry.value, onSelected: (s) => setModalState(() => _selectedFilterStatus = s ? entry.value : null))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Filter by Date
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_month_outlined),
                          title: Text(_selectedDateRange == null ? localizations.translate('select_date_range')! : '${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.end)}'),
                          trailing: _selectedDateRange != null ? IconButton(icon: const Icon(Icons.close), onPressed: () => setModalState(() => _selectedDateRange = null)) : null,
                          onTap: () async {
                            final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (picked != null) setModalState(() => _selectedDateRange = picked);
                          },
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(child: TextButton(onPressed: () { _resetFilters(); Navigator.pop(context);}, child: Text(localizations.translate('reset_filters')!))),
                            const SizedBox(width: 12),
                            Expanded(flex: 2, child: ElevatedButton(onPressed: () { _applyFilters(); Navigator.pop(context); }, child: Text(localizations.translate('apply_filters')!))),
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