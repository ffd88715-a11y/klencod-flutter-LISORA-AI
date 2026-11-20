import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/features/challenges/daily_challenge_screen.dart';
import 'package:talkora_ai/features/grammar/grammar_screen.dart';
import 'package:talkora_ai/features/home/home_screen.dart';
import 'package:talkora_ai/features/listening/listening_screen.dart';
import 'package:talkora_ai/features/onboarding/onboarding_screen.dart';
import 'package:talkora_ai/features/practice/practice_hub_screen.dart';
import 'package:talkora_ai/features/profile/profile_screen.dart';
import 'package:talkora_ai/features/progress/progress_screen.dart';
import 'package:talkora_ai/features/pronunciation/pronunciation_screen.dart';
import 'package:talkora_ai/features/settings/settings_screen.dart';
import 'package:talkora_ai/features/splash/splash_screen.dart';
import 'package:talkora_ai/features/vocabulary/vocabulary_screen.dart';
import 'package:talkora_ai/features/voice/live_voice_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/voice', builder: (_, __) => const LiveVoiceScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/practice/pronunciation', builder: (_, __) => const PronunciationScreen()),
      GoRoute(path: '/practice/grammar', builder: (_, __) => const GrammarScreen()),
      GoRoute(path: '/practice/listening', builder: (_, __) => const ListeningScreen()),
      GoRoute(path: '/practice/challenge', builder: (_, __) => const DailyChallengeScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/practice', builder: (_, __) => const PracticeHubScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/vocabulary', builder: (_, __) => const VocabularyScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});

class _MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const _MainShell({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (idx) => navigationShell.goBranch(idx, initialLocation: idx == navigationShell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: s.t('nav_home')),
          NavigationDestination(icon: const Icon(Icons.school_outlined), selectedIcon: const Icon(Icons.school_rounded), label: s.t('nav_practice')),
          NavigationDestination(icon: const Icon(Icons.style_outlined), selectedIcon: const Icon(Icons.style_rounded), label: s.t('nav_vocab')),
          NavigationDestination(icon: const Icon(Icons.insights_outlined), selectedIcon: const Icon(Icons.insights_rounded), label: s.t('nav_progress')),
          NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: s.t('nav_profile')),
        ],
      ),
    );
  }
}
