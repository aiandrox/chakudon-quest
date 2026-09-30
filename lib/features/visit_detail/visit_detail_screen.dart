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
import '../scoring/points_breakdown_view.dart';
import '../scoring/scoring_providers.dart';
import 'visit_edit_screen.dart';

class VisitDetailScreen extends ConsumerWidget {
  const VisitDetailScreen({super.key, required this.visitId});

  final String visitId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
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
    if (confirmed != true || !context.mounted) return;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final visits = ref.watch(visitsProvider).value ?? const [];
    final entry = visits.where((e) => e.visit.id == visitId).firstOrNull;
    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.visitNotFound)),
      );
    }
    final visit = entry.visit;
    final previous = previousVisitAtShop(visits, visit);
    final scored = ref.watch(scoredVisitByIdProvider)[visit.id];
    final textTheme = Theme.of(context).textTheme;
    final style = visit.style;
    final waited = waitMinutes(visit);
    final tags = [
      if (visit.result == VisitResult.retreated) l10n.retreatBadge,
      if (waited != null) l10n.waitTime(waited),
      if (style != null) styleLabel(l10n, style),
      if (visit.isLimited) l10n.limitedBadge,
      if (visit.hasTicket) l10n.ticketBadge,
      for (final condition in HoursCondition.values)
        if (entry.shop.hoursConditions.contains(condition))
          hoursConditionLabel(l10n, condition),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.shop.name),
        actions: [
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
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: VisitPhoto(photoPath: visit.photoPath),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.shop.name, style: textTheme.headlineSmall),
                const SizedBox(height: 4),
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
                  Text(l10n.previousVisit, style: textTheme.titleMedium),
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
