import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/audio/voice_socket_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';
import 'package:talkora_ai/core/widgets/talkora_waveform.dart';

/// iOS 18 Redesigned Home Screen with Active AI Engine Pill, Bento Stats & AI Power Suite.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(learnerProfileProvider);
    final ai = ref.watch(aiSettingsProvider);
    final s = ref.watch(appStringsProvider);
    final isAr = s.isArabic;
    final theme = Theme.of(context);
    final progressRatio = (profile.speakingMinutesToday / profile.dailyTargetMinutes).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            // iOS Top Bar + Active AI Model Pill
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
                        isAr ? 'أهلاً، ${profile.displayName}' : 'Hello, ${profile.displayName}',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 3),
                      IosStatusPill(
                        label: '${ai.activePreset.shortName} • ${ai.activeModel}',
                        color: ai.isConfigured ? TalkoraColors.iosGreen : TalkoraColors.iosOrange,
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isAr ? 'مفاتيح API والإعدادات' : 'API Keys & Settings',
                  icon: const Icon(CupertinoIcons.gear_alt_fill),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // iOS Hero Card (Live Voice + AI Studio Dual CTA)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    TalkoraColors.iosIndigo,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const TalkoraVoiceOrb(state: VoiceEngineState.listening, audioLevel: 0.25, size: 96),
                  const SizedBox(height: 14),
                  Text(
                    s.t('ready_to_speak'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr
                        ? 'تحدث بالصوت أو دردش مع أي نموذج ذكاء اصطناعي تختاره'
                        : 'Practice live voice or chat with any AI model you connect',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: theme.colorScheme.primary,
                          ),
                          onPressed: () => context.push('/voice'),
                          icon: const Icon(CupertinoIcons.mic_fill, size: 18),
                          label: Text(s.t('start_talking'), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.18),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => context.go('/chat'),
                          icon: const Icon(CupertinoIcons.sparkles, size: 18),
                          label: Text(s.t('open_ai_studio'), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // iOS Bento Progress & XP Card
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/progress'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isAr ? 'الهدف اليومي' : 'Daily Goal', style: theme.textTheme.titleMedium),
                          Text(
                            '${profile.speakingMinutesToday} / ${profile.dailyTargetMinutes} ${isAr ? 'د' : 'min'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(value: progressRatio, minHeight: 7),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BentoStat(label: isAr ? 'المستوى' : 'Level', value: profile.englishLevel),
                          _BentoStat(label: isAr ? 'المفردات' : 'Words', value: '${profile.vocabularyLearned}'),
                          _BentoStat(label: isAr ? 'السلسلة' : 'Streak', value: '${profile.streakDays}d'),
                          _BentoStat(label: 'XP', value: '${profile.xpPoints}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // AI Power Suite Grid (6 Huge Features)
            Text(s.t('quick_actions'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.42,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _IosFeatureTile(
                  icon: CupertinoIcons.sparkles,
                  color: TalkoraColors.iosBlue,
                  title: s.t('ai_chat'),
                  subtitle: isAr ? '6 شخصيات + أي نموذج' : '6 Personas • Any AI',
                  onTap: () => context.go('/chat'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.person_2_fill,
                  color: TalkoraColors.iosPurple,
                  title: s.t('roleplay'),
                  subtitle: isAr ? '8 مواقف واقعية' : '8 Real Scenarios',
                  onTap: () => context.push('/roleplay'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.wand_stars,
                  color: TalkoraColors.iosGreen,
                  title: s.t('writing_lab'),
                  subtitle: isAr ? 'تصحيح وتقييم فوري' : 'Rewrite & Score',
                  onTap: () => context.push('/writing'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.globe,
                  color: TalkoraColors.iosTeal,
                  title: s.t('translator'),
                  subtitle: isAr ? 'ترجمة وتعبيرات أصلية' : 'Idioms & Examples',
                  onTap: () => context.push('/translator'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.bolt_fill,
                  color: TalkoraColors.iosOrange,
                  title: s.t('daily_challenge'),
                  subtitle: isAr ? 'تحدي 90 ثانية' : '90s Speaking Sprint',
                  onTap: () => context.push('/practice/challenge'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.lock_shield_fill,
                  color: TalkoraColors.iosIndigo,
                  title: s.t('api_settings'),
                  subtitle: isAr ? '10 مزودين + API مخصص' : '10 Providers + Custom',
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoStat extends StatelessWidget {
  final String label;
  final String value;
  const _BentoStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _IosFeatureTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _IosFeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IosIconBadge(icon: icon, color: color, size: 34),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(subtitle, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
