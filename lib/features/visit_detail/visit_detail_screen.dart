import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../home/rating_prompt.dart';
import '../record/star_rating.dart';
import '../records/date_format.dart';
import '../records/labels.dart';
import '../records/models.dart';
import '../records/photo_storage.dart';
import '../records/record_repository.dart';
import '../records/visit_history.dart';
import '../records/visit_photo.dart';
import '../records/wait_time.dart';
import '../inkan/inkan_stamp.dart';
import '../scoring/points.dart';
import '../scoring/points_breakdown_view.dart';
import '../../theme/washi.dart';
import '../shop/shop_memo_dialog.dart';
import '../scoring/scoring_providers.dart';
import '../wishes/wish_dialog.dart';
import '../wishes/wish_providers.dart';
import '../wishes/wishes.dart';
import '../journal/journal.dart';
import '../journal/journal_view.dart';
import '../share/share_screen.dart';
import 'visit_edit_screen.dart';

/// 1つの店のページ。開いた1杯を大きく見せ、この店で集めた印をタップすると切り替わる。
class VisitDetailScreen extends ConsumerStatefulWidget {
  const VisitDetailScreen({super.key, required this.visitId});

  final String visitId;

  @override
  ConsumerState<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends ConsumerState<VisitDetailScreen> {
  late String _visitId = widget.visitId;

  Future<void> _delete(String visitId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // 画面を閉じたあとは`ref`を使えないため、先に取り出しておく。
    final repository = ref.read(recordRepositoryProvider);
    final storage = ref.read(photoStorageProvider);
    final String? photoPath;
    try {
      photoPath = await repository.deleteVisit(visitId);
    } catch (e) {
      debugPrint('Visit delete failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.deleteFailed)));
      return;
    }
    navigator.pop();
    if (photoPath == null) return;
    try {
      await storage.delete(photoPath);
    } catch (e) {
      debugPrint('Photo delete failed: $e');
    }
  }

  Future<void> _editShopMemo(Shop shop) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).editSaveFailed;
    final repository = ref.read(recordRepositoryProvider);
    final memo = await showShopMemoDialog(context, shop.strategyMemo);
    if (memo == null) return;
    try {
      await repository.setShopMemo(shop.id, memo);
    } catch (e) {
      debugPrint('Shop memo save failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visits = ref.watch(visitsProvider).value ?? const [];
    final entry = visits.where((e) => e.visit.id == _visitId).firstOrNull;
    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.visitNotFound)),
      );
    }
    final visit = entry.visit;
    final previous = previousVisitAtShop(visits, visit);
    final scored = ref.watch(scoredVisitByIdProvider)[visit.id];
    final shopStamps = [
      for (final stamp in ref.watch(scoredVisitsProvider))
        if (stamp.visit.shopId == entry.shop.id) stamp,
    ];
    final textTheme = Theme.of(context).textTheme;
    final style = visit.style;
    final waited = waitMinutes(visit);
    final tags = [
      if (visit.result == VisitResult.retreated) l10n.retreatBadge,
      if (waited != null) l10n.waitTime(waited),
      if (style != null) styleLabel(l10n, style),
      if (visit.isLimited) l10n.limitedBadge,
      for (final condition in HoursCondition.values)
        if (entry.shop.hoursConditions.contains(condition))
          hoursConditionLabel(l10n, condition),
    ];

    final statuses = ref.watch(wishStatusesProvider);
    final pendingWish = pendingWishFor(statuses, entry.shop);
    final canFulfill =
        visit.result == VisitResult.eaten &&
        pendingWish != null &&
        wishPrecedes(pendingWish, visit.eatenAt) &&
        !statuses.any((s) => s.fulfilledBy?.visit.id == visit.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.shop.name),
        actions: [
          if (pendingWish != null)
            IconButton(
              tooltip: l10n.wishAlready,
              icon: const Icon(Icons.bookmark),
              onPressed: () =>
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l10n.wishAlready))),
            )
          else
            IconButton(
              tooltip: l10n.wishMakeButton,
              icon: const Icon(Icons.bookmark_add_outlined),
              onPressed: () => addWishFor(
                context,
                ref,
                ShopInput(
                  shopId: entry.shop.id,
                  osmId: entry.shop.osmId,
                  name: entry.shop.name,
                  latitude: entry.shop.latitude,
                  longitude: entry.shop.longitude,
                  dataSource: entry.shop.dataSource,
                ),
              ),
            ),
          IconButton(
            tooltip: l10n.shareTitle,
            icon: const Icon(Icons.ios_share),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ShareScreen(visitId: visit.id),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => VisitEditScreen(entry: entry),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.delete,
            icon: const Icon(Icons.delete),
            onPressed: () => _delete(visit.id),
          ),
        ],
      ),
      backgroundColor: Washi.desk,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _ShopPage(entry: entry, scored: scored),
          ),
          if (canFulfill)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: Text(l10n.wishFulfillPrompt(pendingWish.name)),
                  trailing: TextButton(
                    onPressed: () => ref
                        .read(recordRepositoryProvider)
                        .fulfillWish(
                          pendingWish.id,
                          visitId: visit.id,
                          shopId: entry.shop.id,
                        ),
                    child: Text(l10n.wishFulfillButton),
                  ),
                ),
              ),
            ),
          if (scored != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: JournalView(
                lines: buildJournal(scored, ref.watch(scoredVisitsProvider)),
              ),
            ),
          if (shopStamps.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _ShopStamps(
                stamps: shopStamps,
                selectedId: visit.id,
                onSelect: (id) => setState(() => _visitId = id),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDateTime(visit.eatenAt),
                  style: textTheme.bodyMedium,
                ),
                if (visit.result == VisitResult.eaten) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StarRating(
                      rating: visit.rating,
                      onChanged: (rating) =>
                          saveRating(context, ref, visit.id, rating),
                    ),
                  ),
                  if (visit.rating == null)
                    Text(l10n.ratingTapToRate, style: textTheme.bodySmall),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [for (final tag in tags) Chip(label: Text(tag))],
                  ),
                ],
                if (visit.memo.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(visit.memo, style: textTheme.bodyLarge),
                ],
                const Divider(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.shopMemoSection,
                        style: textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.shopMemoEdit,
                      icon: const Icon(Icons.edit_note),
                      onPressed: () => _editShopMemo(entry.shop),
                    ),
                  ],
                ),
                Text(
                  entry.shop.strategyMemo.isEmpty
                      ? l10n.shopMemoEmpty
                      : entry.shop.strategyMemo,
                  style: textTheme.bodyMedium,
                ),
                if (scored != null) ...[
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.pointsSection,
                          style: textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        l10n.points(scored.points.total),
                        style: textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PointsBreakdownView(scored: scored),
                ],
                if (previous != null) ...[
                  const Divider(height: 32),
                  SectionTitle(l10n.previousVisit),
                  const SizedBox(height: 8),
                  _PreviousVisit(visit: previous.visit),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 台紙に貼った写真と、写真の端にかぶせて押した印、縦書きの店名。
class _ShopPage extends StatelessWidget {
  const _ShopPage({required this.entry, required this.scored});

  final VisitWithShop entry;
  final ScoredVisit? scored;

  @override
  Widget build(BuildContext context) {
    final scored = this.scored;
    final visit = entry.visit;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Washi.page,
        border: Border.all(color: Washi.line),
        boxShadow: const [BoxShadow(color: Washi.line, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 12, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: PastedPhoto(
                      angle: -1.5 * math.pi / 180,
                      border: 6,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: VisitPhoto(photoPath: visit.photoPath),
                      ),
                    ),
                  ),
                  if (scored != null)
                    Positioned(
                      right: 4,
                      bottom: 0,
                      child: InkanStamp(scored: scored, size: 120),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.only(left: 10),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Washi.line)),
              ),
              child: VerticalText(
                entry.shop.name,
                maxChars: 11,
                style: const TextStyle(
                  fontFamily: Washi.brush,
                  fontSize: 28,
                  color: Washi.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// この店で集めた印（古い順）。タップするとその1杯に切り替わる。
class _ShopStamps extends StatelessWidget {
  const _ShopStamps({
    required this.stamps,
    required this.selectedId,
    required this.onSelect,
  });

  final List<ScoredVisit> stamps;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.shopStamps,
          style: textTheme.titleMedium?.copyWith(fontFamily: Washi.brush),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final stamp in stamps)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Material(
                    color: stamp.visit.id == selectedId
                        ? Washi.page
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: stamp.visit.id == selectedId
                            ? Washi.shu
                            : Colors.transparent,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => onSelect(stamp.visit.id),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          children: [
                            InkanStamp(scored: stamp, size: 72),
                            const SizedBox(height: 2),
                            Text(
                              formatDate(stamp.visit.eatenAt),
                              style: textTheme.labelSmall?.copyWith(
                                color: Washi.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 28});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: AppLocalizations.of(context).ratingStar(rating),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var stars = 1; stars <= 5; stars++)
              Icon(
                stars <= rating ? Icons.star : Icons.star_border,
                color: color,
                size: size,
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviousVisit extends StatelessWidget {
  const _PreviousVisit({required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rating = visit.rating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(formatDate(visit.eatenAt), style: textTheme.bodyMedium),
            const SizedBox(width: 12),
            if (rating != null) _Stars(rating: rating, size: 18),
          ],
        ),
        if (visit.memo.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(visit.memo, style: textTheme.bodyMedium),
        ],
      ],
    );
  }
}
