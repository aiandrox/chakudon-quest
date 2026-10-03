import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../checkin/checkin_banner.dart';
import '../checkin/checkin_controller.dart';
import '../checkin/queue_suggestion_card.dart';
import '../notifications/notification_service.dart';
import '../record/photo_picker.dart';
import '../record/record_screen.dart';
import '../records/clock.dart';
import '../records/models.dart';
import '../records/record_repository.dart';
import '../records/visit_photo.dart';
import '../inkan/inkan.dart';
import '../inkan/inkan_stamp.dart';
import '../../theme/washi.dart';
import '../scoring/rank_progress.dart';
import '../streak/streak.dart';
import '../memory/memory_card.dart';
import 'rating_prompt.dart';
import '../scoring/scoring_providers.dart';
import '../visit_detail/visit_detail_screen.dart';
import '../words/words.dart';

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
        body: streakReminderBody(remindAt),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visits = ref.watch(visitsProvider);
    final checkinState = ref.watch(activeCheckinProvider);
    final checkin = checkinState.value;

    return Scaffold(
      // 印帳のページ（和紙）が浮いて見えるよう、机の色にする。
      backgroundColor: Washi.desk,
      appBar: AppBar(backgroundColor: Washi.desk, title: Text(l10n.appName)),
      body: Column(
        children: [
          // 並んでいる最中は、何より先に見えるよう上に固定する。
          if (checkin != null)
            CheckinBanner(checkin: checkin)
          else if (checkinState.hasValue)
            const QueueSuggestionCard(),
          Expanded(child: _buildVisits(l10n, visits)),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        heroTag: 'record',
        shape: const CircleBorder(),
        tooltip: l10n.addRecord,
        onPressed: _openRecord,
        child: const Icon(Icons.add),
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
    // 段位や★の案内は一覧と一緒にスクロールし、写真のページを広く見せる。
    final header = SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: RankProgress(
              totalPoints: ref.watch(totalPointsProvider),
              compact: true,
            ),
          ),
          if (_ratingPromptTarget(visits.value) case final entry?)
            RatingPrompt(entry: entry),
          const MemoryCard(),
          const SizedBox(height: 12),
        ],
      ),
    );
    return switch (visits) {
      AsyncData(:final value) when value.isEmpty => CustomScrollView(
        slivers: [
          header,
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(l10n.homeEmpty, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
      AsyncData(:final value) => CustomScrollView(
        slivers: [
          header,
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 200),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.76,
              ),
              itemCount: value.length,
              itemBuilder: (context, index) => _VisitPage(entry: value[index]),
            ),
          ),
        ],
      ),
      AsyncError() => Center(child: Text(l10n.homeLoadFailed)),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// 印帳の1ページ（1杯）。貼った写真の端に印を押し、左下に店名を縦書きにする。
/// 日付は印に、待ち時間や点数はページを開くと見られるので、ここには出さない。
class _VisitPage extends ConsumerWidget {
  const _VisitPage({required this.entry});

  final VisitWithShop entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visit = entry.visit;
    final isRetreat = visit.result == VisitResult.retreated;
    final scored = ref.watch(scoredVisitByIdProvider)[visit.id];
    final showPhoto = !isRetreat || visit.photoPath != null;

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
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stampSize = constraints.maxWidth * 0.5;
              return Column(
                children: [
                  if (showPhoto)
                    PastedPhoto(
                      angle: inkanAngle(visit.id) * 0.25,
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: VisitPhoto(
                          photoPath: visit.photoPath,
                          cacheWidth: 400,
                        ),
                      ),
                    )
                  else
                    // 撤退は写真の代わりに「敗」の印を大きく押す。
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Center(
                        child: scored == null
                            ? null
                            : InkanStamp(scored: scored, size: stampSize),
                      ),
                    ),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 4,
                          top: 8,
                          bottom: 0,
                          child: VerticalText(
                            entry.shop.name,
                            maxChars: 5,
                            style: TextStyle(
                              fontFamily: Washi.brush,
                              fontSize: 16,
                              color: isRetreat ? Washi.inkSoft : Washi.ink,
                            ),
                          ),
                        ),
                        if (showPhoto && scored != null)
                          Positioned(
                            right: -4,
                            top: -stampSize * 0.26,
                            child: InkanStamp(scored: scored, size: stampSize),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
