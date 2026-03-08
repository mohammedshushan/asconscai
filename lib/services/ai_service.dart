import 'dart:convert';
import 'package:asconscai/services/local_storage_manager/shared_prefrences_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// استيراد النماذج (غيّرهم حسب مسار المشروع عندك)
// import 'package:asconscai/models/loan_request_model.dart';
// import 'package:asconscai/models/permissions/permission_request_model.dart';
// import 'package:asconscai/models/user_model.dart';
// import 'package:asconscai/models/vacation_balance_model.dart';
// import 'package:asconscai/models/vacation_order_model.dart';

// ─────────────────────────────────────────────────────────────
// HrContext — يحمل كل داتا الموظف اللي هتتحول لـ system prompt
// ─────────────────────────────────────────────────────────────
class HrContext {
  final dynamic user; // UserModel?
  final List<dynamic> vacationBalances;
  final List<dynamic> vacationOrders;
  final List<dynamic> loanRequests;
  final List<dynamic> permissionRequests;

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
// Message model for chat history
// ─────────────────────────────────────────────────────────────
class ChatMessage {
  final String role; // 'system', 'user', 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: json['role'] as String,
    content: json['content'] as String,
  );
}

// ─────────────────────────────────────────────────────────────
// AiService — خدمة ChatGPT (OpenAI)
// ─────────────────────────────────────────────────────────────
class AiService {
  // ⬇️ ضع مفتاح OpenAI هنا
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // النموذج — اختر واحد:
  // 'gpt-4o' ← الأقوى والأحدث (مكلف شوية)
  // 'gpt-4o-mini' ← سريع ورخيص
  // 'gpt-3.5-turbo' ← الأرخص
  static const String _model = 'gpt-4o-mini';

  late List<ChatMessage> _chatHistory;
  HrContext _hrContext = const HrContext();

  final _dateFormatter = DateFormat('yyyy/MM/dd');

  AiService() {
    _initChat();
  }

  void _initChat() {
    _chatHistory = [ChatMessage(role: 'system', content: _buildSystemPrompt())];
  }

  /// تحديث بيانات الموظف وإعادة بناء الـ System Prompt مع الإبقاء على المحادثة
  void updateContext(HrContext context) {
    _hrContext = context;
    // نحتفظ بالرسائل الموجودة ونحدّث الـ system prompt فقط
    final existingConversation =
        _chatHistory.where((m) => m.role != 'system').toList();
    _chatHistory = [
      ChatMessage(role: 'system', content: _buildSystemPrompt()),
      ...existingConversation,
    ];
  }

  /// مسح تاريخ المحادثة (للبدء من الصفر)
  void clearChat() {
    _initChat();
  }

  // ── بناء الـ System Prompt ────────────────────────────────
  String _buildSystemPrompt() {
    final buffer = StringBuffer();

    buffer.writeln('أنت مساعد HR ذكي لشركة ASCON SCAI.');
    buffer.writeln(
      'مهمتك مساعدة الموظفين في الاستفسار عن شؤونهم الوظيفية بأسلوب ودود ومحترف.',
    );
    buffer.writeln('رد دائماً بالعربية بشكل واضح ومنظم.');
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
      buffer.writeln('الاسم: ${u.empName ?? "غير متوفر"}');
      if (u.empNameE != null) {
        buffer.writeln('الاسم بالإنجليزية: ${u.empNameE}');
      }
      if (u.jobDesc != null) buffer.writeln('الوظيفة: ${u.jobDesc}');
      buffer.writeln('كود الموظف: ${u.usersCode ?? "غير متوفر"}');
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

  // ── إرسال الرسالة إلى ChatGPT ─────────────────────────────
  Future<String> sendMessage(String message) async {
    _printPromptDebug(message);

    String reply;

    try {
      // إضافة رسالة المستخدم إلى التاريخ
      _chatHistory.add(ChatMessage(role: 'user', content: message));

      // تجهيز جسم الطلب
      final requestBody = jsonEncode({
        'model': _model,
        'messages': _chatHistory.map((msg) => msg.toJson()).toList(),
        'temperature': 0.7,
        'max_tokens': 2000,
        'top_p': 0.95,
        'frequency_penalty': 0.3,
        'presence_penalty': 0.3,
      });

      // إرسال الطلب
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_apiKey',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        reply = data['choices'][0]['message']['content'] as String;
        _printResponseDebug(reply);
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        debugPrint('══════════════════════════════════════');
        debugPrint('❌ [OPENAI ERROR]: Status ${response.statusCode}');
        debugPrint('❌ [OPENAI BODY]: $errorBody');
        debugPrint('══════════════════════════════════════');

        if (response.statusCode == 401) {
          reply = 'خطأ: مفتاح API غير صالح. يرجى التحقق من المفتاح.';
        } else if (response.statusCode == 429) {
          reply = 'خطأ: تم تجاوز الحد المسموح. يرجى الانتظار قليلاً.';
        } else if (response.statusCode == 500) {
          reply = 'خطأ: مشكلة في خادم OpenAI. يرجى المحاولة لاحقاً.';
        } else {
          reply = 'عذراً، حدث خطأ في الاتصال. الرجاء المحاولة مرة أخرى.';
        }
      }
    } catch (e) {
      debugPrint('══════════════════════════════════════');
      debugPrint('❌ [EXCEPTION]: $e');
      debugPrint('══════════════════════════════════════');
      reply = 'حدث خطأ: $e';
    }

    // ── إضافة الرد للـ history دائماً (نجاح أو خطأ) ──────────
    _chatHistory.add(ChatMessage(role: 'assistant', content: reply));
    return reply;
  }

  // ── دوال الطباعة للتصحيح ────────────────────────────────────
  void _printPromptDebug(String userMessage) {
    debugPrint('\n');
    debugPrint('╔════════════════════════════════════════╗');
    debugPrint('║      📋 ChatGPT SYSTEM PROMPT          ║');
    debugPrint('╚════════════════════════════════════════╝');

    final systemPrompt =
        _chatHistory
            .firstWhere(
              (msg) => msg.role == 'system',
              orElse: () => ChatMessage(role: 'system', content: ''),
            )
            .content;

    final promptLines = systemPrompt.split('\n');
    for (final line in promptLines) {
      debugPrint(line);
    }
    debugPrint('────────────────────────────────────────');
    debugPrint('💬 [USER]: $userMessage');
    debugPrint('────────────────────────────────────────');

    // طباعة تاريخ المحادثة (بدون النظام)
    if (_chatHistory.length > 1) {
      debugPrint('📜 [CHAT HISTORY]:');
      for (int i = 1; i < _chatHistory.length; i++) {
        final msg = _chatHistory[i];
        final preview =
            msg.content.length > 50
                ? '${msg.content.substring(0, 50)}...'
                : msg.content;
        debugPrint(
          '   ${msg.role == 'user' ? '👤' : '🤖'} [${msg.role.toUpperCase()}]: $preview',
        );
      }
    }
  }

  void _printResponseDebug(String response) {
    debugPrint('🤖 [ChatGPT RESPONSE]:');
    final lines = response.split('\n');
    for (final line in lines) {
      debugPrint('   $line');
    }
    debugPrint('════════════════════════════════════════\n');
  }

  // ── وظائف إضافية ───────────────────────────────────────────

  /// الحصول على تاريخ المحادثة (للحفظ أو العرض)
  List<ChatMessage> getChatHistory() {
    return List.from(_chatHistory);
  }

  /// تعيين تاريخ محادثة محفوظ
  void setChatHistory(List<ChatMessage> history) {
    _chatHistory = history;
  }

  // ── حفظ وتحميل المحادثة من SharedPreferences ───────────────

  /// حفظ رسائل المستخدم والمساعد فقط (بدون system prompt)
  Future<void> saveChatHistory() async {
    try {
      final helper = await SharedPrefsHelper.getInstance();
      // نحفظ كل الرسائل ما عدا الـ system prompt
      final messagesOnly =
          _chatHistory.where((m) => m.role != 'system').toList();
      final encoded = jsonEncode(messagesOnly.map((m) => m.toJson()).toList());
      await helper.setString(SharedPrefsHelper.chatHistoryKey, encoded);
    } catch (e) {
      debugPrint('❌ [saveChatHistory] $e');
    }
  }

  /// تحميل المحادثة المحفوظة وإضافتها بعد الـ system prompt
  Future<bool> loadChatHistory() async {
    try {
      final helper = await SharedPrefsHelper.getInstance();
      final raw = helper.getString(SharedPrefsHelper.chatHistoryKey);
      if (raw == null || raw.isEmpty) return false;

      final List<dynamic> decoded = jsonDecode(raw);
      final loaded =
          decoded
              .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList();

      if (loaded.isEmpty) return false;

      // نضيف الرسائل المحفوظة بعد system prompt
      _chatHistory = [
        _chatHistory.first, // system prompt
        ...loaded,
      ];
      return true;
    } catch (e) {
      debugPrint('❌ [loadChatHistory] $e');
      return false;
    }
  }

  /// حذف المحادثة المحفوظة نهائياً
  Future<void> clearSavedHistory() async {
    try {
      final helper = await SharedPrefsHelper.getInstance();
      await helper.remove(SharedPrefsHelper.chatHistoryKey);
    } catch (e) {
      debugPrint('❌ [clearSavedHistory] $e');
    }
  }
}
