import 'package:asconscai/models/loan_request_model.dart';
import 'package:asconscai/models/permissions/permission_request_model.dart';
import 'package:asconscai/models/user_model.dart';
import 'package:asconscai/models/vacation_balance_model.dart';
import 'package:asconscai/models/vacation_order_model.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────
// HrContext — يحمل كل داتا الموظف اللي هتتحول لـ system prompt
// ─────────────────────────────────────────────────────────────
class HrContext {
  final UserModel? user;
  final List<VacationBalance> vacationBalances;
  final List<VacationOrder> vacationOrders;
  final List<LoanRequest> loanRequests;
  final List<PermissionRequest> permissionRequests;

  const HrContext({
    this.user,
    this.vacationBalances = const [],
    this.vacationOrders = const [],
    this.loanRequests = const [],
    this.permissionRequests = const [],
  });

  bool get isEmpty =>
      user == null &&
      vacationBalances.isEmpty &&
      vacationOrders.isEmpty &&
      loanRequests.isEmpty &&
      permissionRequests.isEmpty;
}

// ─────────────────────────────────────────────────────────────
// AiService — الخدمة الرئيسية للتواصل مع Gemini
// ─────────────────────────────────────────────────────────────
class AiService {
  static const String _apiKey = 'AIzaSyBLyY9BOlWyS_zqa9wM8cipadIXqL6QvBU';
  late ChatSession _chat;
  HrContext _hrContext = const HrContext();

  final _dateFormatter = DateFormat('yyyy/MM/dd');

  AiService() {
    _initChat();
  }

  void _initChat() {
    final model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: _apiKey,
    );
    _chat = model.startChat(history: [Content.text(_buildSystemPrompt())]);
  }

  /// تحديث بيانات الموظف وإعادة تهيئة المحادثة
  void updateContext(HrContext context) {
    _hrContext = context;
    _initChat();
  }

  // ── بناء الـ System Prompt ────────────────────────────────
  String _buildSystemPrompt() {
    final buffer = StringBuffer();

    buffer.writeln('أنت مساعد HR ذكي لشركة ASCON SCAI.');
    buffer.writeln(
      'مهمتك مساعدة الموظفين في الاستفسار عن شؤونهم الوظيفية بأسلوب ودود ومحترف.',
    );
    buffer.writeln('رد دائماً بالعربية.');
    buffer.writeln(
      'استخدم البيانات المقدمة لك فقط، ولا تخترع معلومات غير موجودة.',
    );
    buffer.writeln(
      'إذا سُئلت عن شيء لا تعرفه، قل "هذه المعلومة غير متوفرة لديّ حالياً".',
    );
    buffer.writeln();

    if (_hrContext.isEmpty) {
      buffer.writeln('ملاحظة: لا تتوفر بيانات موظف حالياً، أجب بشكل عام.');
      return buffer.toString();
    }

    buffer.writeln('══════════════════════════════════════');
    buffer.writeln('📋 بيانات الموظف');
    buffer.writeln('══════════════════════════════════════');
    if (_hrContext.user != null) {
      final u = _hrContext.user!;
      buffer.writeln('الاسم: ${u.empName}');
      if (u.empNameE != null)
        buffer.writeln('الاسم بالإنجليزية: ${u.empNameE}');
      if (u.jobDesc != null) buffer.writeln('الوظيفة: ${u.jobDesc}');
      buffer.writeln('كود الموظف: ${u.usersCode}');
    }
    buffer.writeln();

    // رصيد الإجازات
    buffer.writeln('══════════════════════════════════════');
    buffer.writeln('🏖️ رصيد الإجازات');
    buffer.writeln('══════════════════════════════════════');
    if (_hrContext.vacationBalances.isEmpty) {
      buffer.writeln('لا توجد بيانات رصيد إجازات.');
    } else {
      for (final b in _hrContext.vacationBalances) {
        buffer.writeln(
          '• ${b.vcncDescA}: متبقي ${b.remainBal} يوم | مستخدم ${b.total} يوم | الإجمالي ${b.fullBalance} يوم',
        );
      }
    }
    buffer.writeln();

    // طلبات الإجازات
    buffer.writeln('══════════════════════════════════════');
    buffer.writeln('📅 طلبات الإجازات السابقة (آخر 5)');
    buffer.writeln('══════════════════════════════════════');
    final recentVacations = _hrContext.vacationOrders.take(5).toList();
    if (recentVacations.isEmpty) {
      buffer.writeln('لا توجد طلبات إجازة سابقة.');
    } else {
      for (final v in recentVacations) {
        final status = _vacationStatus(v.agreeFlag);
        buffer.writeln(
          '• من ${_fmtDate(v.startDate)} إلى ${_fmtDate(v.endDate)} | المدة: ${v.period} يوم | الحالة: $status',
        );
      }
    }
    buffer.writeln();

    // طلبات السلف
    buffer.writeln('══════════════════════════════════════');
    buffer.writeln('💰 طلبات السلف');
    buffer.writeln('══════════════════════════════════════');
    if (_hrContext.loanRequests.isEmpty) {
      buffer.writeln('لا توجد طلبات سلف.');
    } else {
      for (final l in _hrContext.loanRequests) {
        final status = _loanStatus(l.authFlag);
        buffer.writeln(
          '• المبلغ: ${l.loanValuePys.toStringAsFixed(2)} | القسط: ${l.loanInstlPys.toStringAsFixed(2)} | عدد الأقساط: ${l.loanNos} | تاريخ الطلب: ${_fmtDate(l.reqLoanDate)} | الحالة: $status',
        );
      }
    }
    buffer.writeln();

    // التصاريح
    buffer.writeln('══════════════════════════════════════');
    buffer.writeln('🚪 التصاريح / طلبات الخروج (آخر 5)');
    buffer.writeln('══════════════════════════════════════');
    final recentPermissions = _hrContext.permissionRequests.take(5).toList();
    if (recentPermissions.isEmpty) {
      buffer.writeln('لا توجد طلبات تصاريح سابقة.');
    } else {
      for (final p in recentPermissions) {
        final exitStr =
            '${p.exitTime.hour.toString().padLeft(2, '0')}:${p.exitTime.minute.toString().padLeft(2, '0')}';
        final enterStr =
            '${p.enterTime.hour.toString().padLeft(2, '0')}:${p.enterTime.minute.toString().padLeft(2, '0')}';
        buffer.writeln(
          '• رقم الطلب: ${p.serial} | التاريخ: ${_fmtDate(p.exitDate)} | خروج: $exitStr | عودة: $enterStr',
        );
      }
    }

    return buffer.toString();
  }

  // ── دوال مساعدة ──────────────────────────────────────────
  String _fmtDate(DateTime? dt) {
    if (dt == null) return 'غير محدد';
    return _dateFormatter.format(dt);
  }

  String _vacationStatus(int flag) {
    switch (flag) {
      case 1:
        return '✅ معتمدة';
      case -1:
        return '❌ مرفوضة';
      default:
        return '⏳ معلقة';
    }
  }

  String _loanStatus(int flag) {
    switch (flag) {
      case 1:
        return '✅ معتمد';
      case -1:
        return '❌ مرفوض';
      default:
        return '⏳ معلق';
    }
  }

  // ── إرسال الرسالة ──────────────────────────────────────────
  Future<String> sendMessage(String message) async {
    // طباعة الـ system prompt مرة واحدة أول مرة + الرسالة دايماً
    _printPromptDebug(message);

    try {
      final response = await _chat.sendMessage(Content.text(message));
      final reply = response.text ?? 'لم أتمكن من توليد رد.';
      _printResponseDebug(reply);
      return reply;
    } catch (e) {
      debugPrint('══════════════════════════════════════');
      debugPrint('❌ [GEMINI ERROR]: $e');
      debugPrint('══════════════════════════════════════');
      return 'حدث خطأ: $e';
    }
  }

  void _printPromptDebug(String userMessage) {
    debugPrint('\n');
    debugPrint('╔════════════════════════════════════════╗');
    debugPrint('║         📋 SYSTEM PROMPT               ║');
    debugPrint('╚════════════════════════════════════════╝');
    // طباعة الـ system prompt سطر بسطر
    final promptLines = _buildSystemPrompt().split('\n');
    for (final line in promptLines) {
      debugPrint(line);
    }
    debugPrint('────────────────────────────────────────');
    debugPrint('💬 [USER]:  $userMessage');
    debugPrint('────────────────────────────────────────');
  }

  void _printResponseDebug(String response) {
    debugPrint('🤖 [AI RESPONSE]:');
    final lines = response.split('\n');
    for (final line in lines) {
      debugPrint('   $line');
    }
    debugPrint('════════════════════════════════════════\n');
  }
}
