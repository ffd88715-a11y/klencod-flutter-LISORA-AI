import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkora_ai/app/localization/app_strings.dart';
import 'package:talkora_ai/core/constants/api_config.dart';

class LearnerProfileState {
  final bool onboardingCompleted;
  final String displayName;
  final String nativeLanguage;
  final String englishLevel;
  final String learningGoal;
  final String preferredAccent;
  final int dailyTargetMinutes;
  final String explanationLanguage;
  final String uiLocale;
  final ThemeMode themeMode;
  final bool memoryEnabled;
  final String serverBaseUrl;
  final int speakingMinutesToday;
  final int vocabularyLearned;
  final int streakDays;

  const LearnerProfileState({
    this.onboardingCompleted = false,
    this.displayName = 'Learner',
    this.nativeLanguage = 'Arabic',
    this.englishLevel = 'B1',
    this.learningGoal = 'Fluency',
    this.preferredAccent = 'American',
    this.dailyTargetMinutes = 15,
    this.explanationLanguage = 'Arabic',
    this.uiLocale = 'en',
    this.themeMode = ThemeMode.system,
    this.memoryEnabled = true,
    this.serverBaseUrl = ApiConfig.defaultBaseUrl,
    this.speakingMinutesToday = 9,
    this.vocabularyLearned = 24,
    this.streakDays = 5,
  });

  LearnerProfileState copyWith({
    bool? onboardingCompleted,
    String? displayName,
    String? nativeLanguage,
    String? englishLevel,
    String? learningGoal,
    String? preferredAccent,
    int? dailyTargetMinutes,
    String? explanationLanguage,
    String? uiLocale,
    ThemeMode? themeMode,
    bool? memoryEnabled,
    String? serverBaseUrl,
    int? speakingMinutesToday,
    int? vocabularyLearned,
    int? streakDays,
  }) {
    return LearnerProfileState(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      displayName: displayName ?? this.displayName,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      englishLevel: englishLevel ?? this.englishLevel,
      learningGoal: learningGoal ?? this.learningGoal,
      preferredAccent: preferredAccent ?? this.preferredAccent,
      dailyTargetMinutes: dailyTargetMinutes ?? this.dailyTargetMinutes,
      explanationLanguage: explanationLanguage ?? this.explanationLanguage,
      uiLocale: uiLocale ?? this.uiLocale,
      themeMode: themeMode ?? this.themeMode,
      memoryEnabled: memoryEnabled ?? this.memoryEnabled,
      serverBaseUrl: serverBaseUrl ?? this.serverBaseUrl,
      speakingMinutesToday: speakingMinutesToday ?? this.speakingMinutesToday,
      vocabularyLearned: vocabularyLearned ?? this.vocabularyLearned,
      streakDays: streakDays ?? this.streakDays,
    );
  }
}

class LearnerProfileNotifier extends StateNotifier<LearnerProfileState> {
  LearnerProfileNotifier() : super(const LearnerProfileState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIdx = prefs.getInt('theme_mode') ?? 0;
      state = state.copyWith(
        onboardingCompleted: prefs.getBool('onboarding_completed') ?? false,
        displayName: prefs.getString('display_name') ?? 'Learner',
        nativeLanguage: prefs.getString('native_language') ?? 'Arabic',
        englishLevel: prefs.getString('english_level') ?? 'B1',
        learningGoal: prefs.getString('learning_goal') ?? 'Fluency',
        preferredAccent: prefs.getString('preferred_accent') ?? 'American',
        dailyTargetMinutes: prefs.getInt('daily_target_minutes') ?? 15,
        explanationLanguage: prefs.getString('explanation_language') ?? 'Arabic',
        uiLocale: prefs.getString('ui_locale') ?? 'en',
        themeMode: ThemeMode.values[themeIdx.clamp(0, 2)],
        memoryEnabled: prefs.getBool('memory_enabled') ?? true,
        serverBaseUrl: prefs.getString('server_base_url') ?? ApiConfig.defaultBaseUrl,
      );
    } catch (_) {
      // Safe fallback in unit/widget test environments without platform channels
    }
  }

  Future<void> saveOnboarding({
    required String displayName,
    required String nativeLanguage,
    required String englishLevel,
    required String learningGoal,
    required String preferredAccent,
    required int dailyTargetMinutes,
    required String explanationLanguage,
  }) async {
    state = state.copyWith(
      onboardingCompleted: true,
      displayName: displayName.trim().isEmpty ? 'Learner' : displayName.trim(),
      nativeLanguage: nativeLanguage,
      englishLevel: englishLevel,
      learningGoal: learningGoal,
      preferredAccent: preferredAccent,
      dailyTargetMinutes: dailyTargetMinutes,
      explanationLanguage: explanationLanguage,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setString('display_name', state.displayName);
      await prefs.setString('native_language', state.nativeLanguage);
      await prefs.setString('english_level', state.englishLevel);
      await prefs.setString('learning_goal', state.learningGoal);
      await prefs.setString('preferred_accent', state.preferredAccent);
      await prefs.setInt('daily_target_minutes', state.dailyTargetMinutes);
      await prefs.setString('explanation_language', state.explanationLanguage);
    } catch (_) {}
  }

  Future<void> setLocale(String langCode) async {
    state = state.copyWith(uiLocale: langCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ui_locale', langCode);
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', mode.index);
    } catch (_) {}
  }

  Future<void> setMemoryEnabled(bool enabled) async {
    state = state.copyWith(memoryEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('memory_enabled', enabled);
    } catch (_) {}
  }

  Future<void> setServerUrl(String url) async {
    state = state.copyWith(serverBaseUrl: url.trim());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_base_url', state.serverBaseUrl);
    } catch (_) {}
  }

  void incrementSpeakingMinutes(int delta) {
    state = state.copyWith(speakingMinutesToday: state.speakingMinutesToday + delta);
  }

  void incrementVocabLearned() {
    state = state.copyWith(vocabularyLearned: state.vocabularyLearned + 1);
  }

  void resetProgress() {
    state = state.copyWith(speakingMinutesToday: 0, vocabularyLearned: 0, streakDays: 1);
  }
}

final learnerProfileProvider = StateNotifierProvider<LearnerProfileNotifier, LearnerProfileState>(
  (ref) => LearnerProfileNotifier(),
);

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(learnerProfileProvider.select((s) => s.uiLocale));
  return AppStrings(locale);
});
