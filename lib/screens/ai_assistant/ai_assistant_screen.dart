// ============================================================
// ai_assistant_screen.dart — flutter_chat_ui FREE version
// Works with: flutter_animate, speech_to_text, google_generative_ai
// ============================================================
import 'package:asconscai/models/loan_request_model.dart';
import 'package:asconscai/models/permissions/permission_request_model.dart';
import 'package:asconscai/models/user_model.dart';
import 'package:asconscai/models/vacation_balance_model.dart';
import 'package:asconscai/models/vacation_order_model.dart';
import 'package:asconscai/services/ai_service.dart';
import 'package:asconscai/services/loan_service.dart';
import 'package:asconscai/services/permission_service.dart';
import 'package:asconscai/services/vacation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:developer' as developer;

// ──────────────────────────────────────────────────────────────
// 1. DESIGN TOKENS
// ──────────────────────────────────────────────────────────────
class AiColors {
  static const Color bg = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF16162A);
  static const Color surface2 = Color(0xFF1E1E38);
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4B44CC);
  static const Color accent = Color(0xFF43E5F7);
  static const Color accentPink = Color(0xFFFF6584);
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textMuted = Color(0xFF8888BB);
  static const Color online = Color(0xFF4CAF50);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient avatarGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ──────────────────────────────────────────────────────────────
// 3. DATA MODEL
// ──────────────────────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });
}

// ──────────────────────────────────────────────────────────────
// 4. QUICK SUGGESTIONS
// ──────────────────────────────────────────────────────────────
class _Suggestion {
  final String emoji;
  final String label;
  const _Suggestion(this.emoji, this.label);
}

const _suggestions = [
  _Suggestion('🏖️', 'ما رصيد إجازاتي؟'),
  _Suggestion('💰', 'هل عندي طلبات سلف؟'),
  _Suggestion('�', 'كيف أقدم على إجازة؟'),
  _Suggestion('🚶', 'اعرض تصاريحي الأخيرة'),
];

// ──────────────────────────────────────────────────────────────
// 5. MAIN SCREEN
// ──────────────────────────────────────────────────────────────
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen>
    with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isListening = false;
  String _lastWords = '';

  final _uuid = const Uuid();
  final _speech = stt.SpeechToText();
  final _aiService = AiService();
  final _scrollCtrl = ScrollController();
  bool _isLoadingContext = true;

  late final AnimationController _glowCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Future.delayed(500.ms, _addWelcome);
    _loadHrContext();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _scrollCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  // ── HR Context Loader ────────────────────────────────────
  Future<void> _loadHrContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('loggedInUser');
      if (userJson == null) {
        if (mounted) setState(() => _isLoadingContext = false);
        return;
      }
      final user = UserModel.fromJson(jsonDecode(userJson));
      final empCode = user.compEmpCode.toString();

      final vacSvc = VacationService();
      final loanSvc = LoanService();
      final permSvc = PermissionService();

      final results = await Future.wait([
        vacSvc
            .getVacationBalance(empCode)
            .catchError((_) => <VacationBalance>[]),
        vacSvc.getVacationOrders(empCode).catchError((_) => <VacationOrder>[]),
        loanSvc.getLoanRequests(empCode).catchError((_) => <LoanRequest>[]),
        permSvc
            .getPermissionRequests(empCode)
            .catchError((_) => <PermissionRequest>[]),
      ]);

      _aiService.updateContext(
        HrContext(
          user: user,
          vacationBalances: results[0] as dynamic,
          vacationOrders: results[1] as dynamic,
          loanRequests: results[2] as dynamic,
          permissionRequests: results[3] as dynamic,
        ),
      );

      developer.log(
        'HR Context loaded ✔️ | Vacations:${results[0].length} Loans:${results[2].length}',
        name: 'AiAssistant',
      );

      if (!mounted) return;
      setState(() => _isLoadingContext = false);
      _push(
        ChatMessage(
          id: _uuid.v4(),
          text:
              'تم تحميل بياناتك بنجاح ✅\nمرحباً ${user.empName}، كيف يمكنني مساعدتك اليوم؟ 😊',
          isUser: false,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      developer.log('Error loading HR context: $e', name: 'AiAssistant');
      if (mounted) setState(() => _isLoadingContext = false);
    }
  }

  // ── helpers ───────────────────────────────────────────────
  void _addWelcome() => _push(
    ChatMessage(
      id: _uuid.v4(),
      text:
          'مرحباً بك! 👋\nأنا مساعد HR الذكي الخاص بك.\nجاري تحميل بياناتك... ⏳',
      isUser: false,
      createdAt: DateTime.now(),
    ),
  );

  void _push(ChatMessage msg) {
    setState(() => _messages.insert(0, msg));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0, duration: 300.ms, curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;

    _push(
      ChatMessage(
        id: _uuid.v4(),
        text: t,
        isUser: true,
        createdAt: DateTime.now(),
      ),
    );
    setState(() => _isTyping = true);

    final reply = await _aiService.sendMessage(t);
    if (!mounted) return;

    setState(() => _isTyping = false);
    _push(
      ChatMessage(
        id: _uuid.v4(),
        text: reply,
        isUser: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  // ── voice ─────────────────────────────────────────────────
  Future<void> _toggleListen() async {
    if (_isListening) {
      _stopListen();
      return;
    }

    final ok = await _speech.initialize(
      onStatus: (s) => debugPrint('STT: $s'),
      onError: (e) => debugPrint('STT err: $e'),
    );
    if (!ok) return;

    setState(() {
      _isListening = true;
      _lastWords = '';
    });

    _speech.listen(
      listenFor: const Duration(seconds: 30),
      localeId: 'ar_SA',
      onResult: (res) {
        setState(() => _lastWords = res.recognizedWords);
        if (res.finalResult && res.recognizedWords.isNotEmpty) {
          _stopListen();
          _send(res.recognizedWords);
        }
      },
    );
  }

  void _stopListen() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiColors.bg,
      body: Stack(
        children: [
          _AnimatedBg(ctrl: _glowCtrl),
          Column(
            children: [
              _Header(glowCtrl: _glowCtrl),
              Expanded(child: _buildList()),
              if (_messages.isEmpty && !_isLoadingContext) _buildSuggestions(),
              _InputBar(
                onSend: _send,
                onMic: _toggleListen,
                isListening: _isListening,
              ),
            ],
          ),
          if (_isListening)
            _VoiceOverlay(lastWords: _lastWords, onStop: _stopListen),
        ],
      ),
    );
  }

  // ── message list ──────────────────────────────────────────
  Widget _buildList() {
    return ListView.builder(
      controller: _scrollCtrl,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (_, i) {
        if (_isTyping && i == 0) {
          return const _TypingIndicator()
              .animate()
              .fadeIn(duration: 200.ms)
              .slideY(begin: 0.3, end: 0);
        }
        final msg = _messages[_isTyping ? i - 1 : i];
        return _Bubble(msg: msg)
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(
              begin: 0.15,
              end: 0,
              curve: Curves.easeOutBack,
              duration: 350.ms,
            );
      },
    );
  }

  // ── suggestions ───────────────────────────────────────────
  Widget _buildSuggestions() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = _suggestions[i];
          return GestureDetector(
            onTap: () => _send(s.label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AiColors.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AiColors.primary.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.emoji),
                  const SizedBox(width: 6),
                  Text(
                    s.label,
                    style: const TextStyle(
                      color: AiColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ).animate(delay: (i * 80).ms).fadeIn().slideX(begin: 0.3, end: 0),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 6. HEADER
// ──────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final AnimationController glowCtrl;
  const _Header({required this.glowCtrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AiColors.surface.withOpacity(0.85),
          border: Border(
            bottom: BorderSide(color: AiColors.primary.withOpacity(0.15)),
          ),
        ),
        child: Row(
          children: [
            _IconBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.maybePop(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  _GlowAvatar(ctrl: glowCtrl),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مساعد الذكاء الاصطناعي',
                        style: TextStyle(
                          color: AiColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AiColors.online,
                                  shape: BoxShape.circle,
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.5, 1.5),
                                duration: 1200.ms,
                              )
                              .then()
                              .scale(
                                begin: const Offset(1.5, 1.5),
                                end: const Offset(1, 1),
                                duration: 1200.ms,
                              ),
                          const SizedBox(width: 5),
                          const Text(
                            'Chat-gpt · متصل',
                            style: TextStyle(
                              color: AiColors.online,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _IconBtn(icon: Icons.more_vert_rounded, onTap: () {}),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 7. INPUT BAR
// ──────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final ValueChanged<String> onSend;
  final VoidCallback onMic;
  final bool isListening;
  const _InputBar({
    required this.onSend,
    required this.onMic,
    required this.isListening,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: AiColors.surface.withOpacity(0.95),
          border: Border(
            top: BorderSide(color: AiColors.primary.withOpacity(0.15)),
          ),
        ),
        child: Row(
          children: [
            Expanded(child: _InputField(onSubmit: onSend)),
            const SizedBox(width: 10),
            _MicBtn(isListening: isListening, onTap: onMic),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 8. BUBBLE
// ──────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AiColors.avatarGradient,
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser ? AiColors.primaryGradient : null,
                    color: isUser ? null : AiColors.surface2,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border:
                        isUser
                            ? null
                            : Border.all(
                              color: AiColors.primary.withOpacity(0.2),
                            ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isUser
                                ? AiColors.primary.withOpacity(0.25)
                                : Colors.black.withOpacity(0.2),
                        blurRadius: isUser ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: isUser ? Colors.white : AiColors.textPrimary,
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${msg.createdAt.hour.toString().padLeft(2, '0')}'
                      ':${msg.createdAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: AiColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.done_all_rounded,
                        size: 13,
                        color: AiColors.accent,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 9. TYPING INDICATOR
// ──────────────────────────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AiColors.avatarGradient,
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AiColors.surface2,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AiColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0, color: AiColors.primary),
                const SizedBox(width: 5),
                _Dot(delay: 200, color: AiColors.accent),
                const SizedBox(width: 5),
                _Dot(delay: 400, color: AiColors.accentPink),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final int delay;
  final Color color;
  const _Dot({required this.delay, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        )
        .animate(delay: delay.ms, onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -7, curve: Curves.easeInOut, duration: 500.ms);
  }
}

// ──────────────────────────────────────────────────────────────
// 10. VOICE OVERLAY
// ──────────────────────────────────────────────────────────────
class _VoiceOverlay extends StatelessWidget {
  final String lastWords;
  final VoidCallback onStop;
  const _VoiceOverlay({required this.lastWords, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStop,
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AiColors.accentPink, Color(0xFFCC4466)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AiColors.accentPink.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.15, 1.15),
                    duration: 700.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 28),
              const Text(
                'جاري الاستماع...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: 200.ms,
                child: Text(
                  lastWords.isEmpty ? 'تحدث الآن...' : lastWords,
                  key: ValueKey(lastWords),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              TextButton.icon(
                onPressed: onStop,
                icon: const Icon(
                  Icons.stop_circle_outlined,
                  color: AiColors.accentPink,
                ),
                label: const Text(
                  'إيقاف',
                  style: TextStyle(color: AiColors.accentPink, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 250.ms),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 11. SMALL WIDGETS
// ──────────────────────────────────────────────────────────────
class _AnimatedBg extends StatelessWidget {
  final AnimationController ctrl;
  const _AnimatedBg({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder:
          (_, __) => Stack(
            children: [
              Positioned(
                top: -80,
                left: -60,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AiColors.primary.withOpacity(0.12 + ctrl.value * 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                right: -40,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AiColors.accentPink.withOpacity(
                          0.09 + ctrl.value * 0.05,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

class _GlowAvatar extends StatelessWidget {
  final AnimationController ctrl;
  const _GlowAvatar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder:
          (_, __) => Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AiColors.primary, AiColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AiColors.primary.withOpacity(0.3 + ctrl.value * 0.2),
                  blurRadius: 14 + ctrl.value * 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: AiColors.surface,
              child: Text('✨', style: TextStyle(fontSize: 16)),
            ),
          ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AiColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AiColors.primary.withOpacity(0.2)),
          ),
          child: Icon(icon, color: AiColors.textMuted, size: 18),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 12. INPUT FIELD
// ──────────────────────────────────────────────────────────────
class _InputField extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  const _InputField({required this.onSubmit});

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final h = _ctrl.text.isNotEmpty;
      if (h != _hasText) setState(() => _hasText = h);
    });
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_ctrl.text.trim().isEmpty) return;
    widget.onSubmit(_ctrl.text.trim());
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 200.ms,
      decoration: BoxDecoration(
        color: AiColors.surface2,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color:
              _focus.hasFocus
                  ? AiColors.primary.withOpacity(0.6)
                  : AiColors.primary.withOpacity(0.2),
          width: _focus.hasFocus ? 1.5 : 1,
        ),
        boxShadow:
            _focus.hasFocus
                ? [
                  BoxShadow(
                    color: AiColors.primary.withOpacity(0.15),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
                : [],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              style: const TextStyle(color: AiColors.textPrimary, fontSize: 15),
              textDirection: TextDirection.rtl,
              maxLines: 4,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'اكتب رسالتك هنا...',
                hintStyle: TextStyle(color: AiColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          AnimatedSwitcher(
            duration: 200.ms,
            transitionBuilder:
                (child, anim) => ScaleTransition(scale: anim, child: child),
            child:
                _hasText
                    ? GestureDetector(
                      key: const ValueKey('send'),
                      onTap: _submit,
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          gradient: AiColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    )
                    : const SizedBox(key: ValueKey('empty'), width: 12),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 13. MIC BUTTON
// ──────────────────────────────────────────────────────────────
class _MicBtn extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;
  const _MicBtn({required this.isListening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
            duration: 300.ms,
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  isListening
                      ? const LinearGradient(
                        colors: [AiColors.accentPink, Color(0xFFCC4466)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : AiColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color:
                      isListening
                          ? AiColors.accentPink.withOpacity(0.45)
                          : AiColors.primary.withOpacity(0.45),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              isListening ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 24,
            ),
          )
          .animate(target: isListening ? 1 : 0)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.15, 1.15),
            duration: 600.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}
