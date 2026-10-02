import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../backup/backup_screen.dart';
import '../credits/credits_screen.dart';
import '../checkin/checkin_banner.dart';
import '../checkin/checkin_controller.dart';
import '../checkin/checkin_screen.dart';
import '../notifications/notification_service.dart';
import '../record/photo_picker.dart';
import '../record/record_screen.dart';
import '../records/clock.dart';
import '../records/date_format.dart';
import '../records/models.dart';
import '../records/record_repository.dart';
import '../records/visit_photo.dart';
import '../records/wait_time.dart';
import '../inkan/inkan.dart';
import '../inkan/inkan_stamp.dart';
import '../../theme/washi.dart';
import '../scoring/rank_progress.dart';
import '../streak/streak.dart';
import 'rating_prompt.dart';
import '../scoring/scoring_providers.dart';
import '../visit_detail/visit_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recoverLostPhoto();
      // 通知の文言に画面の言語設定を使うため、最初の描画のあとで見張りはじめる。
      if (mounted) _listenForNotifications();
    });
  }

  void _listenForNotifications() {
    // チェックインの始め方・終わり方（記録・撤退・取り消し・期限切れ）によらず、
    // 並んでいる間だけ通知を出す。
    ref.listenManual<AsyncValue<Checkin?>>(activeCheckinProvider, (
      previous,
      next,
    ) {
      if (next.isLoading) return;
      final checkin = next.value;
      final notifications = ref.read(notificationServiceProvider);
      if (checkin == null || next.hasError) {
        // 起動時に期限切れで取り消された場合なども、前の通知が残らないよう必ず消す。
        notifications.cancelCheckin();
        return;
      }
      if (previous?.value?.checkedInAt == checkin.checkedInAt &&
          previous?.value?.name == checkin.name) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      notifications.showCheckin(
        title: l10n.checkinBanner(checkin.name),
        body: l10n.checkinNotificationBody(
          DateFormat.Hm().format(checkin.checkedInAt),
        ),
        checkedInAt: checkin.checkedInAt,
      );
    }, fireImmediately: true);
    ref.listenManual<Streak>(streakProvider, (_, streak) {
      final notifications = ref.read(notificationServiceProvider);
      final now = ref.read(currentTimeProvider);
      final remindAt = streakReminderTime(streak, now);
      if (remindAt == null || !remindAt.isAfter(now)) {
        notifications.cancelStreakReminder();
        return;
      }
      final l10n = AppLocalizations.of(context);
      notifications.scheduleStreakReminder(
        at: remindAt,
        title: l10n.streakReminderTitle(streak.weeks),
        body: l10n.streakReminderBody,
      );
    }, fireImmediately: true);
  }

  Future<void> _recoverLostPhoto() async {
    final path = await ref.read(photoPickerProvider).retrieveLostPhoto();
    if (path == null || !mounted) return;
    await _openRecord(recoveredPhotoPath: path);
  }

  Future<void> _openRecord({String? recoveredPhotoPath}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RecordScreen(recoveredPhotoPath: recoveredPhotoPath),
      ),
    );
  }

  Future<void> _openCheckin() async {
    final shopName = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const CheckinScreen()));
    if (shopName == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).checkinDone(shopName)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visits = ref.watch(visitsProvider);
    final checkinState = ref.watch(activeCheckinProvider);
    final checkin = checkinState.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            tooltip: l10n.creditsTitle,
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CreditsScreen()),
            ),
          ),
          IconButton(
            tooltip: l10n.backupTitle,
            icon: const Icon(Icons.settings_backup_restore),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: RankProgress(totalPoints: ref.watch(totalPointsProvider)),
          ),
          const _StreakLine(),
          if (checkin != null) CheckinBanner(checkin: checkin),
          if (_ratingPromptTarget(visits.value) case final entry?)
            RatingPrompt(entry: entry),
          Expanded(child: _buildVisits(l10n, visits)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (checkin == null && !checkinState.isLoading) ...[
            FloatingActionButton.extended(
              heroTag: 'checkin',
              backgroundColor: Washi.paper,
              foregroundColor: Washi.ink,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: Washi.ink),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
              onPressed: _openCheckin,
              icon: const Icon(Icons.groups),
              label: Text(l10n.checkinButton),
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton.large(
            heroTag: 'record',
            shape: const CircleBorder(),
            tooltip: l10n.addRecord,
            onPressed: _openRecord,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  /// 食べてから12時間以内で、まだ★の無い最新の記録。
  VisitWithShop? _ratingPromptTarget(List<VisitWithShop>? visits) {
    final now = ref.watch(currentTimeProvider);
    for (final entry in visits ?? const <VisitWithShop>[]) {
      final visit = entry.visit;
      if (visit.result != VisitResult.eaten) continue;
      if (now.difference(visit.eatenAt) > const Duration(hours: 12)) break;
      if (visit.rating == null) return entry;
    }
    return null;
  }

  Widget _buildVisits(
    AppLocalizations l10n,
    AsyncValue<List<VisitWithShop>> visits,
  ) {
    return switch (visits) {
      AsyncData(:final value) when value.isEmpty => Center(
        child: Text(l10n.homeEmpty, textAlign: TextAlign.center),
      ),
      AsyncData(:final value) => ColoredBox(
        color: Washi.desk,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _InchoHeader(visits: value)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 200),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 288,
                ),
                itemCount: value.length,
                itemBuilder: (context, index) =>
                    _VisitPage(entry: value[index]),
              ),
            ),
          ],
        ),
      ),
      AsyncError() => Center(child: Text(l10n.homeLoadFailed)),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _InchoHeader extends StatelessWidget {
  const _InchoHeader({required this.visits});

  final List<VisitWithShop> visits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final shops = {for (final entry in visits) entry.shop.id};
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              l10n.inchoTitle,
              style: textTheme.titleMedium?.copyWith(fontFamily: Washi.brush),
            ),
          ),
          Text(
            l10n.inchoCount(visits.length, shops.length),
            style: textTheme.bodySmall?.copyWith(color: Washi.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// 印帳の1ページ（1杯）。貼った写真と、縦書きの店名と印。
class _VisitPage extends ConsumerWidget {
  const _VisitPage({required this.entry});

  final VisitWithShop entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final visit = entry.visit;
    final rating = visit.rating;
    final waited = waitMinutes(visit);
    final isRetreat = visit.result == VisitResult.retreated;
    final scored = ref.watch(scoredVisitByIdProvider)[visit.id];
    final points = scored?.points.total;
    final meta = [
      formatMonthDay(visit.eatenAt),
      if (isRetreat) l10n.retreatBadge,
      if (waited != null) l10n.inchoMetaWait(waited),
      if (!isRetreat && rating != null) l10n.ratingStar(rating),
      if (!isRetreat && rating == null) l10n.inchoMetaUnrated,
      if (!isRetreat && points != null) l10n.pointsGained(points),
    ].join('  ');

    return Material(
      color: isRetreat ? const Color(0xFFF6F1E6) : Washi.page,
      shape: const RoundedRectangleBorder(side: BorderSide(color: Washi.line)),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VisitDetailScreen(visitId: visit.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
          child: Column(
            children: [
              if (isRetreat && visit.photoPath == null)
                SizedBox(
                  height: 116,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Washi.line),
                    ),
                    child: Center(
                      child: Text(
                        l10n.retreatBadge,
                        style: textTheme.bodySmall?.copyWith(
                          color: Washi.faded,
                        ),
                      ),
                    ),
                  ),
                )
              else
                PastedPhoto(
                  angle: inkanAngle(visit.id) * 0.3,
                  child: SizedBox(
                    height: 108,
                    width: double.infinity,
                    child: VisitPhoto(
                      photoPath: visit.photoPath,
                      cacheWidth: 400,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VerticalText(
                      entry.shop.name,
                      maxChars: 6,
                      style: TextStyle(
                        fontFamily: Washi.brush,
                        fontSize: 17,
                        color: isRetreat ? Washi.inkSoft : Washi.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (scored != null) InkanStamp(scored: scored, size: 96),
                  ],
                ),
              ),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(color: Washi.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakLine extends ConsumerWidget {
  const _StreakLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final streak = ref.watch(streakProvider);
    if (streak.weeks == 0) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, size: 18, color: colors.primary),
          const SizedBox(width: 4),
          Text(l10n.streakWeeks(streak.weeks), style: textTheme.bodyMedium),
          if (streak.isAtRisk) ...[
            const SizedBox(width: 8),
            Text(
              l10n.streakAtRisk,
              style: textTheme.bodyMedium?.copyWith(color: colors.error),
            ),
          ],
        ],
      ),
    );
  }
}
