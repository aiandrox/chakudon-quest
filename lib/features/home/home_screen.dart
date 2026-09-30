import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../backup/backup_screen.dart';
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
      final remindAt = streakReminderTimeOf(ref.read(currentTimeProvider));
      if (!streak.isAtRisk ||
          !remindAt.isAfter(ref.read(currentTimeProvider))) {
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
              onPressed: _openCheckin,
              icon: const Icon(Icons.groups),
              label: Text(l10n.checkinButton),
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton.large(
            heroTag: 'record',
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
      AsyncData(:final value) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 200),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: value.length,
        itemBuilder: (context, index) => _VisitTile(entry: value[index]),
      ),
      AsyncError() => Center(child: Text(l10n.homeLoadFailed)),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _VisitTile extends ConsumerWidget {
  const _VisitTile({required this.entry});

  final VisitWithShop entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final visit = entry.visit;
    final rating = visit.rating;
    final points = ref.watch(scoredVisitByIdProvider)[visit.id]?.points.total;
    const textStyle = TextStyle(color: Colors.white, height: 1.2);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          VisitPhoto(photoPath: visit.photoPath, cacheWidth: 600),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
          if (visit.result == VisitResult.retreated)
            Positioned(
              left: 8,
              top: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Text(l10n.retreatBadge, style: textStyle),
                ),
              ),
            ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.shop.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  [
                    formatDate(visit.eatenAt),
                    if (rating != null) l10n.ratingStar(rating),
                    if (rating == null && visit.result == VisitResult.eaten)
                      l10n.ratingUnrated,
                    if (points != null && visit.result == VisitResult.eaten)
                      l10n.pointsGained(points),
                  ].join('  '),
                  style: textStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => VisitDetailScreen(visitId: visit.id),
                ),
              ),
            ),
          ),
        ],
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
