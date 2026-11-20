import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';

class _TutorPersona {
  final String id;
  final String nameEn;
  final String nameAr;
  final IconData icon;
  final Color color;
  final String prompt;

  const _TutorPersona({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
    required this.color,
    required this.prompt,
  });
}

/// iMessage-style iOS AI Chat Studio supporting ANY configured AI model & 6 specialist personas.
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  static const _kHistoryKey = 'talkora_ai_chat_history_v2';

  static const List<_TutorPersona> _personas = [
    _TutorPersona(
      id: 'coach',
      nameEn: 'English Coach',
      nameAr: 'مدرب الإنجليزية',
      icon: CupertinoIcons.chat_bubble_2_fill,
      color: TalkoraColors.iosBlue,
      prompt:
          'You are TALKORA AI English Coach. Reply naturally in English, gently correct any grammar mistake in a short note, and include a concise Arabic translation when helpful.',
    ),
    _TutorPersona(
      id: 'ielts',
      nameEn: 'IELTS Examiner',
      nameAr: 'ممتحن IELTS',
      icon: CupertinoIcons.rosette,
      color: TalkoraColors.iosPurple,
      prompt:
          'You are an official IELTS Speaking & Writing Examiner. Evaluate the user message with an estimated Band score (1-9), highlight vocabulary upgrades, and ask the next follow-up question.',
    ),
    _TutorPersona(
      id: 'interview',
      nameEn: 'Job Interviewer',
      nameAr: 'مقابلات العمل',
      icon: CupertinoIcons.briefcase_fill,
      color: TalkoraColors.iosIndigo,
      prompt:
          'You are a senior hiring manager conducting an English job interview. Ask realistic questions one at a time, give quick feedback on clarity, and suggest stronger corporate phrasing.',
    ),
    _TutorPersona(
      id: 'grammar',
      nameEn: 'Grammar Surgeon',
      nameAr: 'خبير القواعد',
      icon: CupertinoIcons.doc_text_search,
      color: TalkoraColors.iosGreen,
      prompt:
          'You are an expert English grammar teacher for Arabic speakers. Explain grammar rules clearly with bilingual Arabic/English examples and correct every sentence cleanly.',
    ),
    _TutorPersona(
      id: 'travel',
      nameEn: 'Travel & Real Life',
      nameAr: 'السفر والحياة',
      icon: CupertinoIcons.airplane,
      color: TalkoraColors.iosOrange,
      prompt:
          'You are a friendly native English travel companion. Practice real-life airport, hotel, restaurant, and city conversations using everyday natural idioms.',
    ),
    _TutorPersona(
      id: 'general',
      nameEn: 'Super AI',
      nameAr: 'مساعد AI شامل',
      icon: CupertinoIcons.sparkles,
      color: TalkoraColors.iosTeal,
      prompt:
          'You are a super-intelligent, helpful, and concise AI assistant. Answer any question in the same language the user writes (Arabic or English).',
    ),
  ];

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<AiChatMessage> _messages = [];
  String _personaId = 'coach';
  bool _isSending = false;

  _TutorPersona get _activePersona =>
      _personas.firstWhere((p) => p.id == _personaId, orElse: () => _personas.first);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kHistoryKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        setState(() {
          _messages.clear();
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              _messages.add(AiChatMessage.fromJson(item));
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = _messages.length > 40 ? _messages.sublist(_messages.length - 40) : _messages;
      await prefs.setString(_kHistoryKey, jsonEncode(trimmed.map((m) => m.toJson()).toList()));
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _inputCtrl.text).trim();
    if (text.isEmpty || _isSending) return;

    _inputCtrl.clear();
    final userMsg = AiChatMessage(role: 'user', content: text, timestamp: DateTime.now());
    setState(() {
      _messages.add(userMsg);
      _isSending = true;
    });
    _scrollToBottom();

    final aiSettings = ref.read(aiSettingsProvider);
    final aiService = ref.read(universalAiServiceProvider);
    final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';

    final recentContext = _messages.length > 14 ? _messages.sublist(_messages.length - 14) : _messages;
    final result = await aiService.sendChat(
      settings: aiSettings,
      messages: recentContext,
      systemPromptOverride: _activePersona.prompt,
    );

    if (!mounted) return;

    String replyText;
    if (result.success) {
      replyText = result.text;
      ref.read(learnerProfileProvider.notifier).addXp(10);
    } else if (result.error == 'MISSING_API_KEY') {
      replyText = isAr
          ? 'لم تقم بإضافة مفتاح API لـ ${aiSettings.activePreset.name} بعد.\n\nاضغط على شارة النموذج بالأعلى أو افتح (الإعدادات ← مفاتيح AI) لإضافة أي مفتاح API (OpenAI, Gemini, Claude, DeepSeek, Groq, OpenRouter أو أي رابط مخصص) والبدء فوراً!'
          : 'No API key configured for ${aiSettings.activePreset.name} yet.\n\nTap the model badge above or open Settings -> AI API Keys to add any API key (OpenAI, Gemini, Claude, DeepSeek, Groq, OpenRouter, or Custom) and start chatting live!';
    } else {
      replyText = isAr
          ? 'تعذّر الاتصال بالنموذج (${result.providerName}):\n${result.error}'
          : 'Could not reach ${result.providerName}:\n${result.error}';
    }

    setState(() {
      _messages.add(
        AiChatMessage(
          role: 'assistant',
          content: replyText,
          timestamp: DateTime.now(),
          modelUsed: result.success ? '${result.providerName} • ${result.modelName}' : null,
        ),
      );
      _isSending = false;
    });
    await _saveHistory();
    _scrollToBottom();
  }

  void _showQuickModelSwitcher() {
    final ai = ref.read(aiSettingsProvider);
    final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'التبديل السريع بين نماذج AI' : 'Quick Switch AI Model',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/settings');
                    },
                    child: Text(isAr ? 'إدارة المفاتيح' : 'Manage Keys'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...AiProviderCatalog.all.map((p) {
                final active = p.id == ai.activeProviderId;
                final hasKey = !p.requiresApiKey ||
                    (ai.credentials[p.id]?.apiKey.trim().isNotEmpty ?? false);
                final model = ai.credentialFor(p.id).model;

                return ListTile(
                  leading: IosIconBadge(icon: p.icon, color: p.badgeColor),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(model),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasKey)
                        const Icon(CupertinoIcons.checkmark_circle_fill,
                            color: TalkoraColors.iosGreen, size: 18),
                      if (active) ...[
                        const SizedBox(width: 8),
                        Icon(CupertinoIcons.check_mark,
                            color: Theme.of(context).colorScheme.primary, size: 20),
                      ],
                    ],
                  ),
                  onTap: () {
                    ref.read(aiSettingsProvider.notifier).selectProvider(p.id);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ai = ref.watch(aiSettingsProvider);
    final isAr = ref.watch(learnerProfileProvider).uiLocale == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showQuickModelSwitcher,
          child: Column(
            children: [
              Text(isAr ? 'استوديو AI' : 'AI Studio', style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              IosStatusPill(
                label: '${ai.activePreset.shortName} • ${ai.activeModel}',
                color: ai.isConfigured ? theme.colorScheme.primary : TalkoraColors.iosOrange,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: isAr ? 'مسح المحادثة' : 'Clear Chat',
            icon: const Icon(CupertinoIcons.trash, size: 21),
            onPressed: () {
              setState(() => _messages.clear());
              _saveHistory();
            },
          ),
          IconButton(
            tooltip: isAr ? 'إعدادات API' : 'API Settings',
            icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 21),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Persona Selector Bar
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: _personas.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = _personas[i];
                final selected = p.id == _personaId;
                return ChoiceChip(
                  avatar: Icon(p.icon, size: 16, color: selected ? Colors.white : p.color),
                  label: Text(isAr ? p.nameAr : p.nameEn),
                  selected: selected,
                  selectedColor: p.color,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : null,
                  ),
                  onSelected: (_) => setState(() => _personaId = p.id),
                );
              },
            ),
          ),

          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? _EmptyStudioView(
                    persona: _activePersona,
                    isAr: isAr,
                    isConfigured: ai.isConfigured,
                    onOpenSettings: () => context.push('/settings'),
                    onQuickPrompt: _sendMessage,
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isSending && index == _messages.length) {
                        return Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? TalkoraColors.darkFill : TalkoraColors.lightFill,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const CupertinoActivityIndicator(),
                          ),
                        );
                      }

                      final msg = _messages[index];
                      final isUser = msg.role == 'user';
                      final bubbleColor = isUser
                          ? theme.colorScheme.primary
                          : (isDark ? TalkoraColors.darkSurface : TalkoraColors.lightSurface);
                      final textColor = isUser
                          ? Colors.white
                          : (isDark ? TalkoraColors.darkText : TalkoraColors.lightMainText);

                      return Align(
                        alignment: isUser
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: GestureDetector(
                          onLongPress: () {
                            Clipboard.setData(ClipboardData(text: msg.content));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isAr ? 'تم نسخ الرسالة' : 'Message copied'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.80,
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isUser ? 18 : 5),
                                bottomRight: Radius.circular(isUser ? 5 : 18),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableText(
                                  msg.content,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: textColor,
                                    fontSize: 15.5,
                                    height: 1.42,
                                  ),
                                ),
                                if (!isUser && msg.modelUsed != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    msg.modelUsed!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? TalkoraColors.darkSecondaryText
                                          : TalkoraColors.lightSecondaryText,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // iMessage-style Bottom Input Bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: isDark ? TalkoraColors.darkSurface : TalkoraColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: (isDark ? TalkoraColors.darkSeparator : TalkoraColors.lightSeparator)
                        .withValues(alpha: 0.45),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: isAr ? 'اكتب رسالتك بالإنجليزية أو العربية...' : 'Message TALKORA AI...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      onPressed: _isSending ? null : _sendMessage,
                      child: const Icon(CupertinoIcons.arrow_up, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStudioView extends StatelessWidget {
  final _TutorPersona persona;
  final bool isAr;
  final bool isConfigured;
  final VoidCallback onOpenSettings;
  final ValueChanged<String> onQuickPrompt;

  const _EmptyStudioView({
    required this.persona,
    required this.isAr,
    required this.isConfigured,
    required this.onOpenSettings,
    required this.onQuickPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starters = isAr
        ? [
            'صحّح لي هذه الجملة: I am go to work yesterday',
            'ابدأ معي مقابلة عمل بالإنجليزية لمبرمج تطبيقات',
            'علّمني 5 تعبيرات أمريكية شائعة في الحياة اليومية',
            'قيّم مستواي في IELTS بسؤال سريع',
          ]
        : [
            'Correct my sentence: I am go to work yesterday',
            'Start a realistic tech job interview with me',
            'Teach me 5 natural American English idioms',
            'Give me a quick IELTS Speaking Part 2 prompt',
          ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 16),
        Center(child: IosIconBadge(icon: persona.icon, color: persona.color, size: 60)),
        const SizedBox(height: 14),
        Text(
          isAr ? persona.nameAr : persona.nameEn,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          isAr
              ? 'مدعوم بأي نموذج ذكاء اصطناعي تختاره من الإعدادات'
              : 'Powered by any AI model you configure in Settings',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        if (!isConfigured) ...[
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onOpenSettings,
            icon: const Icon(CupertinoIcons.lock_shield),
            label: Text(isAr ? 'إضافة مفتاح API الآن' : 'Add Your AI API Key'),
          ),
        ],
        const SizedBox(height: 22),
        ...starters.map(
          (prompt) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                title: Text(prompt, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14.5)),
                trailing: Icon(CupertinoIcons.arrow_up_circle_fill, color: theme.colorScheme.primary),
                onTap: () => onQuickPrompt(prompt),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
