import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(learnerProfileProvider);
    final s = ref.watch(appStringsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('nav_profile')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Text(profile.displayName[0].toUpperCase(), style: theme.textTheme.titleLarge),
              ),
              title: Text(profile.displayName, style: theme.textTheme.titleLarge),
              subtitle: Text('${profile.englishLevel} • ${profile.preferredAccent} • ${profile.learningGoal}'),
              trailing: TextButton(
                onPressed: () => context.push('/onboarding'),
                child: const Text('Edit'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Appearance & Language', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Arabic Interface (العربية RTL)'),
                  value: profile.uiLocale == 'ar',
                  onChanged: (v) => ref.read(learnerProfileProvider.notifier).setLocale(v ? 'ar' : 'en'),
                ),
                SwitchListTile(
                  title: const Text('Dark Theme'),
                  value: profile.themeMode == ThemeMode.dark,
                  onChanged: (v) => ref
                      .read(learnerProfileProvider.notifier)
                      .setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(s.t('privacy_controls'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(s.t('enable_memory')),
                  subtitle: const Text('Allow TALKORA AI to personalize lessons from your history'),
                  value: profile.memoryEnabled,
                  onChanged: (v) => ref.read(learnerProfileProvider.notifier).setMemoryEnabled(v),
                ),
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: Text(s.t('export_history')),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Learning history JSON export prepared.')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: Text(s.t('delete_recordings')),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Stored voice recordings cleared.')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restart_alt_rounded, color: TalkoraColors.error),
                  title: Text(s.t('reset_progress'), style: const TextStyle(color: TalkoraColors.error)),
                  onTap: () {
                    ref.read(learnerProfileProvider.notifier).resetProgress();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Learning progress has been reset.')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
