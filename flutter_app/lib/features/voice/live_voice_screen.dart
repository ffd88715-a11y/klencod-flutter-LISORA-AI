import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/audio/voice_socket_service.dart';
import 'package:talkora_ai/core/permissions/mic_permission_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/talkora_waveform.dart';

/// Core TALKORA AI Screen: Real-Time Voice Conversation with actual mic amplitude waveform & barge-in interruption.
class LiveVoiceScreen extends ConsumerStatefulWidget {
  const LiveVoiceScreen({super.key});

  @override
  ConsumerState<LiveVoiceScreen> createState() => _LiveVoiceScreenState();
}

class _LiveVoiceScreenState extends ConsumerState<LiveVoiceScreen> {
  final _voiceService = VoiceSocketService();
  final _micPermission = const MicPermissionService();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  StreamSubscription<VoiceTurnEvent>? _wsSub;
  StreamSubscription<Amplitude>? _ampSub;

  VoiceEngineState _engineState = VoiceEngineState.connecting;
  bool _isMuted = false;
  bool _isRecording = false;
  bool _showArabic = true;
  String _mode = 'Free Conversation';
  String _userTranscript = '';
  String _assistantReply = 'Tap the microphone and speak naturally — I am TALKORA AI, your English speaking companion.';
  String _arabicTranslation = 'اضغط على الميكروفون وتحدث بحرية — أنا TALKORA AI، رفيقك لممارسة الإنجليزية.';
  Map<String, dynamic>? _correction;

  final List<double> _amplitudes = List<double>.filled(28, 0.08, growable: true);
  double _currentLevel = 0.08;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final profile = ref.read(learnerProfileProvider);
    _wsSub = _voiceService.events.listen((event) {
      if (!mounted) return;
      setState(() {
        if (event.state != null) _engineState = event.state!;
        if (event.userTranscript != null) _userTranscript = event.userTranscript!;
        if (event.assistantText != null) _assistantReply = event.assistantText!;
        if (event.arabicTranslation != null) _arabicTranslation = event.arabicTranslation!;
        if (event.correction != null) _correction = event.correction;
        if (event.vadLevel != null) _pushAmplitude(event.vadLevel!);
      });
      if (event.stopPlayback) {
        _player.stop();
      }
    });

    await _voiceService.connect(
      baseUrl: profile.serverBaseUrl,
      sessionId: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      displayName: profile.displayName,
      cefrLevel: profile.englishLevel,
      accent: profile.preferredAccent,
      mode: _mode.toLowerCase().replaceAll(' ', '_'),
    );
  }

  void _pushAmplitude(double normalized) {
    _currentLevel = normalized.clamp(0.06, 1.0);
    _amplitudes.removeAt(0);
    _amplitudes.add(_currentLevel);
  }

  Future<void> _toggleMic() async {
    if (_isRecording) {
      await _stopListeningAndSend();
      return;
    }

    // Immediate barge-in interruption if AI is speaking
    if (_engineState == VoiceEngineState.speaking) {
      await _interruptAi();
    }

    final perm = await _micPermission.requestMicrophone();
    if (perm != MicPermissionResult.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for live voice conversation.')),
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _engineState = VoiceEngineState.listening;
    });

    try {
      if (await _recorder.hasPermission()) {
        await _recorder.startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1));
        _ampSub?.cancel();
        _ampSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 90)).listen((amp) {
          if (!mounted || _isMuted) return;
          // Convert real microphone dBFS (-60..0) to normalized 0.06..1.0
          final norm = ((amp.current + 60.0) / 60.0).clamp(0.06, 1.0);
          setState(() => _pushAmplitude(norm));
        });
      }
    } catch (_) {
      // Safe fallback when running on emulator without physical audio capture
    }
  }

  Future<void> _stopListeningAndSend() async {
    await _ampSub?.cancel();
    try {
      await _recorder.stop();
    } catch (_) {}
    setState(() {
      _isRecording = false;
      _engineState = VoiceEngineState.thinking;
      _pushAmplitude(0.08);
    });
    _voiceService.sendEndOfSpeech(
      transcriptOverride: _voiceService.isConnected ? null : 'I want to practice natural English conversation today.',
    );
    if (!_voiceService.isConnected && mounted) {
      setState(() {
        _engineState = VoiceEngineState.listening;
        _userTranscript = 'Local offline preview (connect self-hosted backend in Settings for live STT/LLM/TTS).';
      });
    }
  }

  Future<void> _interruptAi() async {
    await _player.stop();
    _voiceService.sendInterrupt();
    if (mounted) {
      setState(() {
        _engineState = VoiceEngineState.interrupted;
        _pushAmplitude(0.06);
      });
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _voiceService.sendMute(_isMuted);
  }

  String _stateLabel(BuildContext context) {
    final s = ref.read(appStringsProvider);
    switch (_engineState) {
      case VoiceEngineState.connecting:
        return s.t('state_connecting');
      case VoiceEngineState.listening:
        return s.t('state_listening');
      case VoiceEngineState.understanding:
        return s.t('state_understanding');
      case VoiceEngineState.thinking:
        return s.t('state_thinking');
      case VoiceEngineState.speaking:
        return s.t('state_speaking');
      case VoiceEngineState.interrupted:
        return s.t('state_interrupted');
      case VoiceEngineState.reconnecting:
        return s.t('state_reconnecting');
      case VoiceEngineState.error:
        return s.t('state_error');
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ampSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_mode, style: theme.textTheme.titleMedium),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _voiceService.isConnected ? TalkoraColors.success : TalkoraColors.secondaryAccent,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _voiceService.isConnected ? 'Self-Hosted Engine Connected' : 'Local Ready Mode',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const Spacer(),
              TalkoraVoiceOrb(state: _engineState, audioLevel: _currentLevel, size: 176),
              const SizedBox(height: 16),
              Text(_stateLabel(context), style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              TalkoraWaveform(amplitudeHistory: _amplitudes, height: 52),
              const SizedBox(height: 20),

              // Live Transcript + Optional Arabic + Correction Card
              Expanded(
                flex: 3,
                child: ListView(
                  children: [
                    if (_userTranscript.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'You: $_userTranscript',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_assistantReply, style: theme.textTheme.bodyLarge),
                            if (_showArabic && _arabicTranslation.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  _arabicTranslation,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_correction != null && _correction!['has_issue'] == true) ...[
                      const SizedBox(height: 10),
                      Card(
                        color: TalkoraColors.success.withValues(alpha: 0.10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Suggested Phrasing', style: theme.textTheme.labelLarge?.copyWith(color: TalkoraColors.success)),
                              const SizedBox(height: 4),
                              Text(_correction!['corrected'] as String? ?? '', style: theme.textTheme.bodyLarge),
                              const SizedBox(height: 4),
                              Text(_correction!['explanation_en'] as String? ?? '', style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Toggle Arabic translation chip
              Align(
                alignment: Alignment.centerEnd,
                child: FilterChip(
                  label: Text(s.t('show_arabic')),
                  selected: _showArabic,
                  onSelected: (v) => setState(() => _showArabic = v),
                ),
              ),
              const SizedBox(height: 12),

              // Bottom Voice Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    onPressed: _toggleMute,
                    icon: Icon(_isMuted ? Icons.mic_off_rounded : Icons.mic_none_rounded),
                    tooltip: _isMuted ? s.t('unmute') : s.t('mute'),
                  ),
                  IconButton.filledTonal(
                    onPressed: _interruptAi,
                    icon: const Icon(Icons.stop_rounded),
                    tooltip: s.t('interrupt'),
                  ),
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: _isRecording ? TalkoraColors.error : theme.colorScheme.primary,
                      ),
                      onPressed: _toggleMic,
                      child: Icon(_isRecording ? Icons.check_rounded : Icons.mic_rounded, size: 32),
                    ),
                  ),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: TalkoraColors.error.withValues(alpha: 0.14),
                      foregroundColor: TalkoraColors.error,
                    ),
                    onPressed: () {
                      ref.read(learnerProfileProvider.notifier).incrementSpeakingMinutes(2);
                      context.pop();
                    },
                    icon: const Icon(Icons.call_end_rounded),
                    tooltip: s.t('end_call'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
