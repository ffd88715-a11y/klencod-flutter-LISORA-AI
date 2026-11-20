import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/audio/voice_socket_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/talkora_waveform.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(learnerProfileProvider);
    final s = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final progressRatio = (profile.speakingMinutesToday / profile.dailyTargetMinutes).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
                  child: Text(
                    profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : 'T',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.isArabic ? 'أهلاً، ${profile.displayName}' : 'Hello, ${profile.displayName}',
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        '${profile.englishLevel} • ${profile.learningGoal}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Daily speaking reminder is active for 8:00 PM.')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    TalkoraColors.secondaryAccent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const TalkoraVoiceOrb(state: VoiceEngineState.listening, audioLevel: 0.25, size: 112),
                  const SizedBox(height: 16),
                  Text(
                    s.t('ready_to_speak'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: TalkoraColors.primaryAccent,
                      ),
                      onPressed: () => context.push('/voice'),
                      icon: const Icon(Icons.mic_rounded),
                      label: Text(s.t('start_talking')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Learning Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daily Goal', style: theme.textTheme.titleMedium),
                        Text('${profile.speakingMinutesToday} / ${profile.dailyTargetMinutes} min', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MiniStat(label: 'Level', value: profile.englishLevel),
                        _MiniStat(label: 'Words', value: '${profile.vocabularyLearned}'),
                        _MiniStat(label: 'Streak', value: '${profile.streakDays}d'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(s.t('quick_actions'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _QuickActionTile(
                  icon: Icons.record_voice_over_rounded,
                  title: s.t('free_conversation'),
                  onTap: () => context.push('/voice'),
                ),
                _QuickActionTile(
                  icon: Icons.hearing_rounded,
                  title: s.t('pronunciation'),
                  onTap: () => context.push('/practice/pronunciation'),
                ),
                _QuickActionTile(
                  icon: Icons.bolt_rounded,
                  title: s.t('daily_challenge'),
                  onTap: () => context.push('/practice/challenge'),
                ),
                _QuickActionTile(
                  icon: Icons.style_rounded,
                  title: s.t('vocab_review'),
                  onTap: () => context.go('/vocabulary'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Continue Learning
            Text(s.t('continue_learning'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const CircleAvatar(child: Icon(Icons.play_arrow_rounded)),
                title: const Text('Tech & Daily Stand-Up English'),
                subtitle: const Text('Recommended next activity • 5 min'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/voice'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 28),
              Text(title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
