import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';

class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('nav_practice'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _PracticeModuleCard(
            icon: Icons.mic_rounded,
            title: s.t('free_conversation'),
            subtitle: 'Open-ended real-time voice dialogue with instant corrections',
            onTap: () => context.push('/voice'),
          ),
          const SizedBox(height: 12),
          _PracticeModuleCard(
            icon: Icons.record_voice_over_rounded,
            title: s.t('pronunciation'),
            subtitle: 'Phoneme-level feedback, IPA comparison & reference audio',
            onTap: () => context.push('/practice/pronunciation'),
          ),
          const SizedBox(height: 12),
          _PracticeModuleCard(
            icon: Icons.menu_book_rounded,
            title: s.t('grammar'),
            subtitle: 'Bilingual explanations, practical examples & instant drills',
            onTap: () => context.push('/practice/grammar'),
          ),
          const SizedBox(height: 12),
          _PracticeModuleCard(
            icon: Icons.headphones_rounded,
            title: s.t('listening'),
            subtitle: 'Multi-accent audio lessons with transcripts & comprehension checks',
            onTap: () => context.push('/practice/listening'),
          ),
          const SizedBox(height: 12),
          _PracticeModuleCard(
            icon: Icons.bolt_rounded,
            title: s.t('daily_challenge'),
            subtitle: 'Focused 90-second speaking challenge with AI fluency scoring',
            onTap: () => context.push('/practice/challenge'),
          ),
        ],
      ),
    );
  }
}

class _PracticeModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PracticeModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
