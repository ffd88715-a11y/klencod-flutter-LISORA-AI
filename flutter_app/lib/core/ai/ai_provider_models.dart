import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';

/// Wire protocol family used to communicate with any AI provider.
enum AiWireFormat {
  openAiCompatible,
  googleGemini,
  anthropicClaude,
}

/// Built-in + Custom AI provider catalog (supports any API key and any model ID).
enum AiProviderType {
  openai,
  gemini,
  claude,
  deepseek,
  groq,
  openrouter,
  xai,
  mistral,
  ollama,
  custom,
}

class AiProviderPreset {
  final AiProviderType type;
  final String id;
  final String name;
  final String shortName;
  final String descriptionEn;
  final String descriptionAr;
  final String defaultBaseUrl;
  final String defaultModel;
  final List<String> suggestedModels;
  final AiWireFormat wireFormat;
  final bool requiresApiKey;
  final String apiKeyPlaceholder;
  final Color badgeColor;
  final IconData icon;

  const AiProviderPreset({
    required this.type,
    required this.id,
    required this.name,
    required this.shortName,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.defaultBaseUrl,
    required this.defaultModel,
    required this.suggestedModels,
    required this.wireFormat,
    this.requiresApiKey = true,
    required this.apiKeyPlaceholder,
    required this.badgeColor,
    required this.icon,
  });
}

class AiProviderCatalog {
  const AiProviderCatalog._();

  static const List<AiProviderPreset> all = [
    AiProviderPreset(
      type: AiProviderType.openai,
      id: 'openai',
      name: 'OpenAI (GPT)',
      shortName: 'OpenAI',
      descriptionEn: 'GPT-4o, GPT-4.1, o3-mini & all OpenAI models',
      descriptionAr: 'نماذج GPT-4o و GPT-4.1 و o3-mini من OpenAI',
      defaultBaseUrl: 'https://api.openai.com/v1',
      defaultModel: 'gpt-4o-mini',
      suggestedModels: ['gpt-4o-mini', 'gpt-4o', 'gpt-4.1', 'gpt-4.1-mini', 'o3-mini'],
      wireFormat: AiWireFormat.openAiCompatible,
      apiKeyPlaceholder: 'sk-proj-...',
      badgeColor: TalkoraColors.iosGreen,
      icon: CupertinoIcons.sparkles,
    ),
    AiProviderPreset(
      type: AiProviderType.gemini,
      id: 'gemini',
      name: 'Google Gemini',
      shortName: 'Gemini',
      descriptionEn: 'Gemini 2.5 Pro, 2.5 Flash & 2.0 Flash via Google AI Studio',
      descriptionAr: 'نماذج Gemini 2.5 Pro و Flash عبر Google AI Studio',
      defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      defaultModel: 'gemini-2.5-flash',
      suggestedModels: ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-2.0-flash', 'gemini-2.0-flash-lite'],
      wireFormat: AiWireFormat.googleGemini,
      apiKeyPlaceholder: 'AIzaSy...',
      badgeColor: TalkoraColors.iosBlue,
      icon: CupertinoIcons.wand_stars,
    ),
    AiProviderPreset(
      type: AiProviderType.claude,
      id: 'claude',
      name: 'Anthropic Claude',
      shortName: 'Claude',
      descriptionEn: 'Claude 3.7 Sonnet, 3.5 Sonnet & 3.5 Haiku',
      descriptionAr: 'نماذج Claude 3.7 Sonnet و 3.5 Haiku من Anthropic',
      defaultBaseUrl: 'https://api.anthropic.com/v1',
      defaultModel: 'claude-3-5-sonnet-latest',
      suggestedModels: [
        'claude-3-7-sonnet-latest',
        'claude-3-5-sonnet-latest',
        'claude-3-5-haiku-latest',
      ],
      wireFormat: AiWireFormat.anthropicClaude,
      apiKeyPlaceholder: 'sk-ant-api03-...',
      badgeColor: TalkoraColors.iosOrange,
      icon: CupertinoIcons.chat_bubble_2_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.deepseek,
      id: 'deepseek',
      name: 'DeepSeek AI',
      shortName: 'DeepSeek',
      descriptionEn: 'DeepSeek V3 Chat & DeepSeek R1 Reasoner',
      descriptionAr: 'نماذج DeepSeek V3 و DeepSeek R1 الاقتصادية فائقة الذكاء',
      defaultBaseUrl: 'https://api.deepseek.com/v1',
      defaultModel: 'deepseek-chat',
      suggestedModels: ['deepseek-chat', 'deepseek-reasoner'],
      wireFormat: AiWireFormat.openAiCompatible,
      apiKeyPlaceholder: 'sk-...',
      badgeColor: TalkoraColors.iosIndigo,
      icon: CupertinoIcons.compass_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.groq,
      id: 'groq',
      name: 'Groq (Ultra-Fast)',
      shortName: 'Groq',
      descriptionEn: 'Instant Llama 3.3 70B & Mixtral inference',
      descriptionAr: 'تشغيل فائق السرعة لنماذج Llama 3.3 و Mixtral',
      defaultBaseUrl: 'https://api.groq.com/openai/v1',
      defaultModel: 'llama-3.3-70b-versatile',
      suggestedModels: ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant', 'gemma2-9b-it'],
      wireFormat: AiWireFormat.openAiCompatible,
      apiKeyPlaceholder: 'gsk_...',
      badgeColor: TalkoraColors.iosPink,
      icon: CupertinoIcons.bolt_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.openrouter,
      id: 'openrouter',
      name: 'OpenRouter (All Models)',
      shortName: 'OpenRouter',
      descriptionEn: 'Single API key for 200+ models (GPT, Claude, Llama, Qwen)',
      descriptionAr: 'مفتاح واحد لتشغيل أكثر من 200 نموذج ذكاء اصطناعي',
      defaultBaseUrl: 'https://openrouter.ai/api/v1',
      defaultModel: 'openai/gpt-4o-mini',
      suggestedModels: [
        'openai/gpt-4o-mini',
        'anthropic/claude-3.5-sonnet',
        'google/gemini-2.5-flash',
        'deepseek/deepseek-chat',
        'meta-llama/llama-3.3-70b-instruct',
      ],
      wireFormat: AiWireFormat.openAiCompatible,
      apiKeyPlaceholder: 'sk-or-v1-...',
      badgeColor: TalkoraColors.iosPurple,
      icon: CupertinoIcons.globe,
    ),
    AiProviderPreset(
      type: AiProviderType.xai,
      id: 'xai',
      name: 'xAI (Grok)',
      shortName: 'Grok',
      descriptionEn: 'Grok-3 Mini & Grok-2 models from xAI',
      descriptionAr: 'نماذج Grok من شركة xAI',
      defaultBaseUrl: 'https://api.x.ai/v1',
      defaultModel: 'grok-2-latest',
      suggestedModels: ['grok-2-latest', 'grok-3-mini-beta'],
      wireFormat: AiWireFormat.openAiCompatible,
      apiKeyPlaceholder: 'xai-...',
      badgeColor: Color(0xFF3A3A3C),
      icon: CupertinoIcons.flame_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.mistral,
      id: 'mistral',
      name: 'Mistral AI',
      shortName: 'Mistral',
      descriptionEn: 'Mistral Large, Small & Codestral',
      descriptionAr: 'نماذج Mistral الأوروبية عالية الدقة',
      defaultBaseUrl: 'https://api.mistral.ai/v1',
      defaultModel: 'mistral-small-latest',
      suggestedModels: ['mistral-small-latest', 'mistral-large-latest', 'open-mistral-nemo'],
      wireFormat: AiWireFormat.openAiCompatible,
      apiKeyPlaceholder: 'mistral-...',
      badgeColor: TalkoraColors.iosTeal,
      icon: CupertinoIcons.wind,
    ),
    AiProviderPreset(
      type: AiProviderType.ollama,
      id: 'ollama',
      name: 'Ollama / LM Studio',
      shortName: 'Local AI',
      descriptionEn: 'Run local open-source LLMs on your PC / LAN without keys',
      descriptionAr: 'تشغيل النماذج محلياً على جهازك بدون مفاتيح مدفوعة',
      defaultBaseUrl: 'http://10.0.2.2:11434/v1',
      defaultModel: 'llama3.2',
      suggestedModels: ['llama3.2', 'qwen2.5', 'mistral', 'gemma2'],
      wireFormat: AiWireFormat.openAiCompatible,
      requiresApiKey: false,
      apiKeyPlaceholder: 'Optional local key',
      badgeColor: Color(0xFF636366),
      icon: CupertinoIcons.desktopcomputer,
    ),
    AiProviderPreset(
      type: AiProviderType.custom,
      id: 'custom',
      name: 'Custom Any AI API',
      shortName: 'Custom API',
      descriptionEn: 'Connect ANY OpenAI-compatible URL, model ID & API key',
      descriptionAr: 'ربط أي رابط API مخصص وأي اسم نموذج وأي مفتاح بحرية كاملة',
      defaultBaseUrl: 'https://api.openai.com/v1',
      defaultModel: 'custom-model',
      suggestedModels: ['gpt-4o-mini', 'llama-3.3-70b', 'qwen-2.5-72b'],
      wireFormat: AiWireFormat.openAiCompatible,
      apiKeyPlaceholder: 'Enter any API key...',
      badgeColor: TalkoraColors.iosRed,
      icon: CupertinoIcons.slider_horizontal_3,
    ),
  ];

  static AiProviderPreset byId(String id) {
    return all.firstWhere(
      (p) => p.id == id,
      orElse: () => all.first,
    );
  }
}

/// Stored configuration for a single provider.
class ProviderCredential {
  final String apiKey;
  final String model;
  final String baseUrl;

  const ProviderCredential({
    this.apiKey = '',
    this.model = '',
    this.baseUrl = '',
  });

  ProviderCredential copyWith({
    String? apiKey,
    String? model,
    String? baseUrl,
  }) {
    return ProviderCredential(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'model': model,
        'baseUrl': baseUrl,
      };

  factory ProviderCredential.fromJson(Map<String, dynamic> json) {
    return ProviderCredential(
      apiKey: (json['apiKey'] as String?) ?? '',
      model: (json['model'] as String?) ?? '',
      baseUrl: (json['baseUrl'] as String?) ?? '',
    );
  }
}

/// Chat message model used across AI Chat Studio & Roleplay Arena.
class AiChatMessage {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime timestamp;
  final String? modelUsed;

  const AiChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.modelUsed,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'modelUsed': modelUsed,
      };

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      role: (json['role'] as String?) ?? 'assistant',
      content: (json['content'] as String?) ?? '',
      timestamp: DateTime.tryParse((json['timestamp'] as String?) ?? '') ?? DateTime.now(),
      modelUsed: json['modelUsed'] as String?,
    );
  }
}

/// Result of an AI request or connection test.
class AiResponseResult {
  final bool success;
  final String text;
  final String? error;
  final int latencyMs;
  final String providerName;
  final String modelName;

  const AiResponseResult({
    required this.success,
    required this.text,
    this.error,
    required this.latencyMs,
    required this.providerName,
    required this.modelName,
  });
}
