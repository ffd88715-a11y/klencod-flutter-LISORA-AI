import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';

/// iOS 18 Settings & Universal Multi-Provider AI API Key Control Center.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late String _selectedProviderId;
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _systemPromptCtrl;
  late final TextEditingController _backendUrlCtrl;

  bool _obscureKey = true;
  bool _isTesting = false;
  AiResponseResult? _lastTestResult;

  @override
  void initState() {
    super.initState();
    final ai = ref.read(aiSettingsProvider);
    final profile = ref.read(learnerProfileProvider);
    _selectedProviderId = ai.activeProviderId;
    final cred = ai.credentialFor(_selectedProviderId);

    _apiKeyCtrl = TextEditingController(text: cred.apiKey);
    _modelCtrl = TextEditingController(text: cred.model);
    _baseUrlCtrl = TextEditingController(text: cred.baseUrl);
    _systemPromptCtrl = TextEditingController(text: ai.customSystemPrompt);
    _backendUrlCtrl = TextEditingController(text: profile.serverBaseUrl);
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    _baseUrlCtrl.dispose();
    _systemPromptCtrl.dispose();
    _backendUrlCtrl.dispose();
    super.dispose();
  }

  void _switchProvider(String providerId) {
    final ai = ref.read(aiSettingsProvider);
    final cred = ai.credentialFor(providerId);
    setState(() {
      _selectedProviderId = providerId;
      _apiKeyCtrl.text = cred.apiKey;
      _modelCtrl.text = cred.model;
      _baseUrlCtrl.text = cred.baseUrl;
      _lastTestResult = null;
    });
    ref.read(aiSettingsProvider.notifier).selectProvider(providerId);
  }

  Future<void> _saveCurrentProvider({bool showToast = true}) async {
    final preset = AiProviderCatalog.byId(_selectedProviderId);
    await ref.read(aiSettingsProvider.notifier).saveProviderConfig(
          providerId: _selectedProviderId,
          apiKey: _apiKeyCtrl.text,
          model: _modelCtrl.text.trim().isEmpty ? preset.defaultModel : _modelCtrl.text.trim(),
          baseUrl: _baseUrlCtrl.text.trim().isEmpty ? preset.defaultBaseUrl : _baseUrlCtrl.text.trim(),
        );
    await ref.read(aiSettingsProvider.notifier).updateAdvanced(
          customSystemPrompt: _systemPromptCtrl.text.trim(),
        );
    if (showToast && mounted) {
      final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            isAr
                ? 'تم حفظ إعدادات ${preset.name} بنجاح!'
                : '${preset.name} configuration saved!',
          ),
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    await _saveCurrentProvider(showToast: false);
    setState(() {
      _isTesting = true;
      _lastTestResult = null;
    });
    final settings = ref.read(aiSettingsProvider);
    final service = ref.read(universalAiServiceProvider);
    final result = await service.testConnection(settings);
    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _lastTestResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(learnerProfileProvider);
    final ai = ref.watch(aiSettingsProvider);
    final isAr = profile.uiLocale == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final preset = AiProviderCatalog.byId(_selectedProviderId);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الإعدادات ومفاتيح AI' : 'Settings & AI Keys'),
        actions: [
          TextButton(
            onPressed: _saveCurrentProvider,
            child: Text(
              isAr ? 'حفظ' : 'Save',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          // Active AI Engine Hero Banner
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(
              color: isDark ? TalkoraColors.darkSurface : TalkoraColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IosIconBadge(icon: preset.icon, color: preset.badgeColor, size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'المحرك النشط حالياً' : 'Active AI Engine',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${preset.name} • ${ai.activeModel}',
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      IosStatusPill(
                        label: ai.isConfigured
                            ? (isAr ? 'جاهز للاتصال' : 'API Key Ready')
                            : (isAr ? 'بانتظار مفتاح API' : 'API Key Needed'),
                        color: ai.isConfigured ? TalkoraColors.iosGreen : TalkoraColors.iosOrange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Provider Selector (10 Built-in + Custom Any AI)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Text(
              (isAr ? 'اختر مزود الذكاء الاصطناعي (أي نموذج)' : 'SELECT AI PROVIDER (ANY MODEL)').toUpperCase(),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? TalkoraColors.darkSecondaryText : TalkoraColors.lightSecondaryText,
              ),
            ),
          ),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AiProviderCatalog.all.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = AiProviderCatalog.all[index];
                final isSelected = item.id == _selectedProviderId;
                final hasKey = !item.requiresApiKey ||
                    (ai.credentials[item.id]?.apiKey.trim().isNotEmpty ?? false);

                return GestureDetector(
                  onTap: () => _switchProvider(item.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 108,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12)
                          : (isDark ? TalkoraColors.darkSurface : TalkoraColors.lightSurface),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark ? TalkoraColors.darkSeparator : TalkoraColors.lightSeparator)
                                .withValues(alpha: 0.45),
                        width: isSelected ? 1.8 : 0.6,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IosIconBadge(icon: item.icon, color: item.badgeColor, size: 34),
                            if (hasKey)
                              Positioned(
                                right: -3,
                                top: -3,
                                child: Container(
                                  width: 11,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: TalkoraColors.iosGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? TalkoraColors.darkSurface : Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.shortName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isDark ? TalkoraColors.darkText : TalkoraColors.lightMainText),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Selected Provider API Key, Model & Base URL Card
          IosGroupedSection(
            header: isAr ? 'بيانات الاتصال — ${preset.name}' : '${preset.name} CREDENTIALS',
            footer: isAr ? preset.descriptionAr : preset.descriptionEn,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // API Key Field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr ? 'مفتاح API (API Key)' : 'API Key',
                          style: theme.textTheme.labelLarge,
                        ),
                        Row(
                          children: [
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              onPressed: () async {
                                final clip = await Clipboard.getData(Clipboard.kTextPlain);
                                if (clip?.text != null && clip!.text!.trim().isNotEmpty) {
                                  setState(() => _apiKeyCtrl.text = clip.text!.trim());
                                }
                              },
                              child: Text(
                                isAr ? 'لصق' : 'Paste',
                                style: TextStyle(fontSize: 13, color: theme.colorScheme.primary),
                              ),
                            ),
                            if (_apiKeyCtrl.text.isNotEmpty)
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                onPressed: () {
                                  setState(() => _apiKeyCtrl.clear());
                                  ref.read(aiSettingsProvider.notifier).clearApiKey(_selectedProviderId);
                                },
                                child: Text(
                                  isAr ? 'مسح' : 'Clear',
                                  style: const TextStyle(fontSize: 13, color: TalkoraColors.iosRed),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        controller: _apiKeyCtrl,
                        obscureText: _obscureKey,
                        autocorrect: false,
                        enableSuggestions: false,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: preset.apiKeyPlaceholder,
                          prefixIcon: const Icon(CupertinoIcons.lock_shield, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureKey ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureKey = !_obscureKey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Model Name Input + Quick Chips
                    Text(
                      isAr ? 'اسم النموذج (يمكنك كتابة أي نموذج)' : 'Model ID (Any Model Supported)',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        controller: _modelCtrl,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: preset.defaultModel,
                          prefixIcon: const Icon(CupertinoIcons.cube_box, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: preset.suggestedModels.map((modelId) {
                        final selected = _modelCtrl.text.trim() == modelId;
                        return ChoiceChip(
                          label: Text(modelId, style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.18),
                          onSelected: (_) => setState(() => _modelCtrl.text = modelId),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Base URL (Editable for ANY OpenAI-Compatible Server / Proxy)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr ? 'رابط الخادم (Base URL)' : 'API Base URL',
                          style: theme.textTheme.labelLarge,
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => setState(() => _baseUrlCtrl.text = preset.defaultBaseUrl),
                          child: Text(
                            isAr ? 'الافتراضي' : 'Reset',
                            style: TextStyle(fontSize: 13, color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        controller: _baseUrlCtrl,
                        autocorrect: false,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          hintText: preset.defaultBaseUrl,
                          prefixIcon: const Icon(CupertinoIcons.link, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Save + Test Connection Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saveCurrentProvider,
                            icon: const Icon(CupertinoIcons.checkmark_alt_circle, size: 19),
                            label: Text(isAr ? 'حفظ وتفعيل' : 'Save & Activate'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _isTesting ? null : _testConnection,
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CupertinoActivityIndicator(),
                                  )
                                : const Icon(CupertinoIcons.antenna_radiowaves_left_right, size: 18),
                            label: Text(isAr ? 'اختبار الاتصال' : 'Test API'),
                          ),
                        ),
                      ],
                    ),

                    // Live Test Result Feedback
                    if (_lastTestResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_lastTestResult!.success ? TalkoraColors.iosGreen : TalkoraColors.iosRed)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _lastTestResult!.success
                                      ? CupertinoIcons.checkmark_seal_fill
                                      : CupertinoIcons.exclamationmark_triangle_fill,
                                  color: _lastTestResult!.success
                                      ? TalkoraColors.iosGreen
                                      : TalkoraColors.iosRed,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _lastTestResult!.success
                                        ? (isAr
                                            ? 'متصل بنجاح (${_lastTestResult!.latencyMs} مللي ثانية)'
                                            : 'Connected! (${_lastTestResult!.latencyMs} ms)')
                                        : (isAr ? 'فشل الاتصال' : 'Connection Failed'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _lastTestResult!.success
                                          ? TalkoraColors.iosGreen
                                          : TalkoraColors.iosRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _lastTestResult!.success
                                  ? _lastTestResult!.text
                                  : (_lastTestResult!.error == 'MISSING_API_KEY'
                                      ? (isAr
                                          ? 'يرجى إدخال مفتاح API أولاً.'
                                          : 'Please enter an API key first.')
                                      : (_lastTestResult!.error ?? 'Unknown error')),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // AI Advanced Tuning Section
          IosGroupedSection(
            header: isAr ? 'تخصيص ذكاء النموذج' : 'AI MODEL TUNING',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isAr ? 'درجة الإبداع (Temperature)' : 'Creativity (Temperature)',
                            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15)),
                        Text(ai.temperature.toStringAsFixed(2), style: theme.textTheme.labelLarge),
                      ],
                    ),
                    CupertinoSlider(
                      value: ai.temperature.clamp(0.0, 1.5),
                      min: 0.0,
                      max: 1.5,
                      divisions: 15,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (v) => ref.read(aiSettingsProvider.notifier).updateAdvanced(temperature: v),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isAr ? 'أقصى طول للرد (Max Tokens)' : 'Max Tokens',
                            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15)),
                        Text('${ai.maxTokens}', style: theme.textTheme.labelLarge),
                      ],
                    ),
                    CupertinoSlider(
                      value: ai.maxTokens.toDouble().clamp(256, 4096),
                      min: 256,
                      max: 4096,
                      divisions: 15,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (v) =>
                          ref.read(aiSettingsProvider.notifier).updateAdvanced(maxTokens: v.round()),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'شخصية وتعليمات الذكاء الاصطناعي (System Prompt)' : 'System Instructions',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _systemPromptCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: isAr
                            ? 'اكتب تعليمات مخصصة لكيفية رد الذكاء الاصطناعي...'
                            : 'Customize how TALKORA AI responds and coaches you...',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // iOS Appearance, Theme & Accent Color Section
          IosGroupedSection(
            header: isAr ? 'المظهر وألوان iOS' : 'iOS APPEARANCE & COLORS',
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isAr ? 'وضع الشاشة' : 'Theme Mode', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<ThemeMode>(
                        groupValue: profile.themeMode,
                        children: {
                          ThemeMode.system: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(isAr ? 'تلقائي' : 'Auto'),
                          ),
                          ThemeMode.light: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(isAr ? 'فاتح' : 'Light'),
                          ),
                          ThemeMode.dark: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(isAr ? 'داكن' : 'Dark'),
                          ),
                        },
                        onValueChanged: (mode) {
                          if (mode != null) {
                            ref.read(learnerProfileProvider.notifier).setThemeMode(mode);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(isAr ? 'لون النظام (iOS Accent)' : 'iOS Accent Color', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: TalkoraColors.accentChoices.entries.map((entry) {
                        final active = profile.accentColorKey == entry.key;
                        return GestureDetector(
                          onTap: () => ref.read(learnerProfileProvider.notifier).setAccentColor(entry.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: entry.value,
                              shape: BoxShape.circle,
                              border: active
                                  ? Border.all(
                                      color: isDark ? Colors.white : Colors.black87,
                                      width: 2.5,
                                    )
                                  : null,
                            ),
                            child: active
                                ? const Icon(CupertinoIcons.checkmark_alt, color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              IosSettingsRow(
                icon: CupertinoIcons.globe,
                iconColor: TalkoraColors.iosBlue,
                title: isAr ? 'الواجهة العربية (RTL)' : 'Arabic Interface (العربية)',
                trailing: CupertinoSwitch(
                  value: isAr,
                  activeTrackColor: TalkoraColors.iosGreen,
                  onChanged: (v) => ref.read(learnerProfileProvider.notifier).setLocale(v ? 'ar' : 'en'),
                ),
              ),
            ],
          ),

          // Self-Hosted Local Voice Server (Preserved)
          IosGroupedSection(
            header: isAr ? 'خادم الصوت المحلي (اختياري)' : 'SELF-HOSTED VOICE SERVER (OPTIONAL)',
            footer: isAr
                ? 'استخدمه إذا كنت تشغّل خادم TALKORA الصوتي المحلي عبر Docker أو LAN.'
                : 'Optional endpoint for self-hosted real-time voice WebSocket server.',
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        controller: _backendUrlCtrl,
                        decoration: const InputDecoration(
                          hintText: 'http://192.168.1.100:8000',
                          prefixIcon: Icon(CupertinoIcons.waveform, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: () async {
                          await ref.read(learnerProfileProvider.notifier).setServerUrl(_backendUrlCtrl.text);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isAr ? 'تم حفظ رابط الخادم المحلي.' : 'Self-hosted backend URL saved.',
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(isAr ? 'حفظ رابط الخادم' : 'Save Server Endpoint'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
