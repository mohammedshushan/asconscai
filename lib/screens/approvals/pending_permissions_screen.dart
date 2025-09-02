import 'package:asconscai/models/permissions/permission_type_model.dart';
import 'package:asconscai/services/permission_service.dart';
import 'package:asconscai/widgets/attendance/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../app_localizations.dart';
import '../../main.dart';
import '../../models/pending_permission_model.dart';
import '../../models/user_model.dart';
import '../../services/approvals_service.dart';
import '../../widgets/status_dialogpart2.dart';
import 'package:asconscai/widgets/attendance/error_state_widget.dart';

class PendingPermissionsScreen extends StatefulWidget {
  final UserModel user;
  const PendingPermissionsScreen({super.key, required this.user});

  @override
  State<PendingPermissionsScreen> createState() => _PendingPermissionsScreenState();
}

class _PendingPermissionsScreenState extends State<PendingPermissionsScreen> {
  final ApprovalsService _approvalsService = ApprovalsService();
  final PermissionService _permissionService = PermissionService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final requestsFuture = _approvalsService.getPendingPermissionRequests(widget.user.usersCode.toString());
    final typesFuture = _permissionService.getPermissionTypes();
    final results = await Future.wait([requestsFuture, typesFuture]);
    return {'requests': results[0], 'types': results[1]};
  }

  void _refreshRequests() {
    setState(() {
      _dataFuture = _fetchData();
    });
  }

  String _getPermissionTypeName(int typeCode, List<PermissionType> types, bool isRtl) {
    try {
      final type = types.firstWhere((t) => t.code == typeCode);
      return isRtl ? type.reasonAr : (type.reasonEn ?? type.reasonAr);
    } catch (e) {
      return isRtl ? "غير معروف" : "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(localizations.translate('approve_permissions')!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.language_outlined, color: Colors.white),
            onPressed: () => MyApp.of(context)?.changeLanguage(Localizations.localeOf(context).languageCode == 'en' ? const Locale('ar') : const Locale('en')),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshRequests(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorStateWidget(message: snapshot.error.toString(), onRetry: _refreshRequests);
            }
            if (!snapshot.hasData) {
              return EmptyStateWidget(message: localizations.translate('no_pending_permissions')!, icon: Iconsax.document_cloud);
            }

            final List<PendingPermissionRequest> requests = snapshot.data!['requests'];
            final List<PermissionType> types = snapshot.data!['types'];

            if (requests.isEmpty) {
              return EmptyStateWidget(message: localizations.translate('no_pending_permissions')!, icon: Iconsax.document_cloud);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return _buildRequestCard(context, request, types);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, PendingPermissionRequest request, List<PermissionType> types) {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final empName = isRtl ? request.empName : request.empNameE;
    final permissionType = _getPermissionTypeName(request.exitReasonCode, types, isRtl);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailsSheet(context, request, permissionType),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Iconsax.profile_circle, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(empName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                            ),
                            child: Text(
                              permissionType,
                              style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildEnhancedInfoChip(Iconsax.logout_1, DateFormat.yMMMd().format(request.exitDate), Colors.orange)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildEnhancedInfoChip(Iconsax.login_1, DateFormat.yMMMd().format(request.enterDate), Colors.green)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: color.withOpacity(0.8), fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsSheet(BuildContext context, PendingPermissionRequest request, String permissionType) {
    final localizations = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.RTL;
    final empName = isRtl ? request.empName : request.empNameE;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                height: 4, width: 50,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.1), Theme.of(context).primaryColor.withOpacity(0.05)]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Icon(Iconsax.profile_circle, color: Theme.of(context).primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(empName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(20)),
                                    child: Text(permissionType, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(
                          children: [
                            _buildEnhancedDetailRow(Iconsax.calendar_add, localizations.translate('exit_date')!, DateFormat.yMMMd().format(request.exitDate), Colors.green),
                            const SizedBox(height: 16),
                            _buildEnhancedDetailRow(Iconsax.clock, localizations.translate('exit_time')!, DateFormat.jm().format(request.exitTime), Colors.teal),
                            const SizedBox(height: 16),
                            _buildEnhancedDetailRow(Iconsax.calendar_remove, localizations.translate('return_date')!, DateFormat.yMMMd().format(request.enterDate), Colors.orange),
                            const SizedBox(height: 16),
                            _buildEnhancedDetailRow(Iconsax.clock, localizations.translate('return_time')!, DateFormat.jm().format(request.enterTime), Colors.purple),
                            const SizedBox(height: 16),
                            _buildEnhancedDetailRow(Iconsax.message_question, localizations.translate('exit_reason')!, request.exitReason, Colors.blue),
                            const SizedBox(height: 16),
                            _buildEnhancedDetailRow(Iconsax.note, localizations.translate('notes')!, request.notes ?? localizations.translate('no_notes')!, Colors.indigo),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          icon: const Icon(Iconsax.edit, size: 20),
                          label: Text(localizations.translate('make_decision')!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          onPressed: () { Navigator.pop(ctx); _showDecisionDialog(context, request); },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: Colors.grey.shade800, fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  // ### START: تم نسخ هذا الجزء بالكامل من ملف الإجازات مع حل مشكلة الـ Overflow ###
  void _showDecisionDialog(BuildContext context, PendingPermissionRequest request) {
    final notesController = TextEditingController();
    final localizations = AppLocalizations.of(context)!;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)]),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Iconsax.edit, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text(localizations.translate('make_decision')!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    Flexible( // يسمح للمحتوى بالتقلص عند الحاجة
                      child: SingleChildScrollView( // ### الحل لمشكلة الـ Overflow ###
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(localizations.translate('notes')!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300), color: Colors.grey.shade50),
                              child: TextField(
                                controller: notesController, maxLines: 4, style: const TextStyle(fontSize: 15),
                                decoration: InputDecoration(hintText: '${localizations.translate('notes')}...', hintStyle: TextStyle(color: Colors.grey.shade500), border: InputBorder.none, contentPadding: const EdgeInsets.all(16)),
                              ),
                            ),
                            if (isSubmitting) const Padding(padding: EdgeInsets.only(top: 24.0), child: Center(child: CircularProgressIndicator())),
                          ],
                        ),
                      ),
                    ),
                    if (!isSubmitting)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity, height: 48,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: Text(localizations.translate('cancel')!, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Iconsax.close_circle, size: 18),
                                      label: Text(localizations.translate('reject')!, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      onPressed: () => _handleDecision(ctx, request, notesController.text, -1, (loading) => setDialogState(() => isSubmitting = loading)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Iconsax.tick_circle, size: 18),
                                      label: Text(localizations.translate('approve')!, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      onPressed: () => _handleDecision(ctx, request, notesController.text, 1, (loading) => setDialogState(() => isSubmitting = loading)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  // ### END: تم نسخ هذا الجزء بالكامل من ملف الإجازات ###


  Future<void> _handleDecision(BuildContext dialogContext, PendingPermissionRequest request, String notes, int flag, Function(bool) setLoading) async {
    setLoading(true);
    try {
      final statusData = {
        "users_code": widget.user.usersCode.toString(),
        "trns_flag": flag.toString(),
        "trns_notes": notes,
        "prev_ser": request.prevSer,
        "auth_pk1": request.authPk1,
        "auth_pk2": request.authPk2,
        "trns_status": flag.toString()
      };
      await _approvalsService.updatePermissionStatus(statusData);

      if (request.lastLevel == 1 || (request.lastLevel == 0 && flag == -1)) {
        final orderData = {
          "emp_code": request.empCode,
          "serial": request.serial,
          "accept_flag": flag,
        };
        await _approvalsService.updatePermissionInOrders(orderData);
      }

      if (mounted) {
        Navigator.pop(dialogContext);
        StatusDialog.show(context, AppLocalizations.of(context)!.translate('decision_recorded')!, isSuccess: true);
        _refreshRequests();
      }

    } catch (e) {
      if (mounted) {
        StatusDialog.show(context, e.toString(), isSuccess: false);
      }
    } finally {
      if (mounted) {
        setLoading(false);
      }
    }
  }
}