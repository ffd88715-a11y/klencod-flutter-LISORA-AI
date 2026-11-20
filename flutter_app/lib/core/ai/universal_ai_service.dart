import 'package:dio/dio.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';

/// Universal Multi-Provider AI Client.
/// Supports OpenAI, Google Gemini, Anthropic Claude, DeepSeek, Groq,
/// OpenRouter, xAI Grok, Mistral, Ollama, and ANY custom OpenAI-compatible API.
class UniversalAiService {
  final Dio _dio;

  UniversalAiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 60),
              ),
            );

  /// Sends a multi-turn conversation to whichever AI provider is active in Settings.
  Future<AiResponseResult> sendChat({
    required AiSettingsState settings,
    required List<AiChatMessage> messages,
    String? systemPromptOverride,
  }) async {
    final sw = Stopwatch()..start();
    final preset = settings.activePreset;
    final apiKey = settings.activeApiKey.trim();
    final model = settings.activeModel.trim().isEmpty ? preset.defaultModel : settings.activeModel.trim();
    final baseUrl = _normalizeBaseUrl(
      settings.activeBaseUrl.trim().isEmpty ? preset.defaultBaseUrl : settings.activeBaseUrl.trim(),
    );

    if (preset.requiresApiKey && apiKey.isEmpty) {
      sw.stop();
      return AiResponseResult(
        success: false,
        text: '',
        error: 'MISSING_API_KEY',
        latencyMs: sw.elapsedMilliseconds,
        providerName: preset.shortName,
        modelName: model,
      );
    }

    final sysPrompt = (systemPromptOverride ?? settings.customSystemPrompt).trim();

    try {
      String replyText;
      switch (preset.wireFormat) {
        case AiWireFormat.googleGemini:
          replyText = await _callGemini(
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: model,
            systemPrompt: sysPrompt,
            messages: messages,
            temperature: settings.temperature,
            maxTokens: settings.maxTokens,
          );
          break;
        case AiWireFormat.anthropicClaude:
          replyText = await _callClaude(
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: model,
            systemPrompt: sysPrompt,
            messages: messages,
            temperature: settings.temperature,
            maxTokens: settings.maxTokens,
          );
          break;
        case AiWireFormat.openAiCompatible:
          replyText = await _callOpenAiCompatible(
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: model,
            systemPrompt: sysPrompt,
            messages: messages,
            temperature: settings.temperature,
            maxTokens: settings.maxTokens,
            isOpenRouter: preset.type == AiProviderType.openrouter,
          );
          break;
      }

      sw.stop();
      return AiResponseResult(
        success: true,
        text: replyText.trim(),
        latencyMs: sw.elapsedMilliseconds,
        providerName: preset.shortName,
        modelName: model,
      );
    } on DioException catch (e) {
      sw.stop();
      final status = e.response?.statusCode;
      final serverMsg = _extractErrorMessage(e.response?.data) ?? e.message ?? 'Network error';
      return AiResponseResult(
        success: false,
        text: '',
        error: status != null ? 'HTTP $status: $serverMsg' : serverMsg,
        latencyMs: sw.elapsedMilliseconds,
        providerName: preset.shortName,
        modelName: model,
      );
    } catch (e) {
      sw.stop();
      return AiResponseResult(
        success: false,
        text: '',
        error: e.toString(),
        latencyMs: sw.elapsedMilliseconds,
        providerName: preset.shortName,
        modelName: model,
      );
    }
  }

  /// Sends a tiny ping to verify that the user's API key, Base URL, and Model ID work.
  Future<AiResponseResult> testConnection(AiSettingsState settings) {
    return sendChat(
      settings: settings,
      systemPromptOverride: 'Reply with only: OK - Connected!',
      messages: [
        AiChatMessage(
          role: 'user',
          content: 'Ping',
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<String> _callOpenAiCompatible({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<AiChatMessage> messages,
    required double temperature,
    required int maxTokens,
    required bool isOpenRouter,
  }) async {
    final endpoint = baseUrl.endsWith('/chat/completions') ? baseUrl : '$baseUrl/chat/completions';
    final payloadMessages = <Map<String, String>>[
      if (systemPrompt.isNotEmpty) {'role': 'system', 'content': systemPrompt},
      for (final m in messages)
        if (m.role == 'user' || m.role == 'assistant') {'role': m.role, 'content': m.content},
    ];

    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      if (isOpenRouter) 'HTTP-Referer': 'https://talkora.ai',
      if (isOpenRouter) 'X-Title': 'TALKORA AI',
    };

    final res = await _dio.post<Map<String, dynamic>>(
      endpoint,
      options: Options(headers: headers),
      data: {
        'model': model,
        'messages': payloadMessages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      },
    );

    final data = res.data ?? <String, dynamic>{};
    final choices = data['choices'] as List<dynamic>?;
    if (choices != null && choices.isNotEmpty) {
      final msg = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
      final content = msg?['content'];
      if (content is String && content.isNotEmpty) return content;
    }
    throw Exception('Empty response from OpenAI-compatible API.');
  }

  Future<String> _callGemini({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<AiChatMessage> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    final cleanModel = model.startsWith('models/') ? model.substring(7) : model;
    final endpoint = '$baseUrl/models/$cleanModel:generateContent';

    final contents = <Map<String, dynamic>>[
      for (final m in messages)
        if (m.role == 'user' || m.role == 'assistant')
          {
            'role': m.role == 'assistant' ? 'model' : 'user',
            'parts': [
              {'text': m.content}
            ],
          },
    ];

    final body = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
      },
      if (systemPrompt.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ],
        },
    };

    final res = await _dio.post<Map<String, dynamic>>(
      endpoint,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
      ),
      data: body,
    );

    final data = res.data ?? <String, dynamic>{};
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates != null && candidates.isNotEmpty) {
      final content = (candidates.first as Map<String, dynamic>)['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts != null && parts.isNotEmpty) {
        final buffer = StringBuffer();
        for (final p in parts) {
          final txt = (p as Map<String, dynamic>)['text'] as String?;
          if (txt != null) buffer.write(txt);
        }
        if (buffer.isNotEmpty) return buffer.toString();
      }
    }
    throw Exception('Empty response from Google Gemini API.');
  }

  Future<String> _callClaude({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<AiChatMessage> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    final endpoint = baseUrl.endsWith('/messages') ? baseUrl : '$baseUrl/messages';
    final claudeMessages = <Map<String, String>>[
      for (final m in messages)
        if (m.role == 'user' || m.role == 'assistant') {'role': m.role, 'content': m.content},
    ];

    final res = await _dio.post<Map<String, dynamic>>(
      endpoint,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
      ),
      data: {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        if (systemPrompt.isNotEmpty) 'system': systemPrompt,
        'messages': claudeMessages,
      },
    );

    final data = res.data ?? <String, dynamic>{};
    final contentList = data['content'] as List<dynamic>?;
    if (contentList != null && contentList.isNotEmpty) {
      final buffer = StringBuffer();
      for (final item in contentList) {
        if (item is Map<String, dynamic> && item['type'] == 'text') {
          buffer.write(item['text'] ?? '');
        }
      }
      if (buffer.isNotEmpty) return buffer.toString();
    }
    throw Exception('Empty response from Anthropic Claude API.');
  }

  String _normalizeBaseUrl(String raw) {
    var clean = raw.trim();
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    return clean;
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is Map<String, dynamic>) {
        return (err['message'] ?? err['type'] ?? err.toString()).toString();
      }
      if (err is String) return err;
      if (data['message'] is String) return data['message'] as String;
    } else if (data is String && data.isNotEmpty) {
      return data.length > 180 ? '${data.substring(0, 180)}...' : data;
    }
    return null;
  }
}
