import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../record/star_rating.dart';
import '../records/models.dart';
import '../records/record_repository.dart';

/// ★をすぐに保存する。失敗したら知らせる。
Future<void> saveRating(
  BuildContext context,
  WidgetRef ref,
  String visitId,
  int rating,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = AppLocalizations.of(context).editSaveFailed;
  try {
    await ref.read(recordRepositoryProvider).setRating(visitId, rating);
  } catch (e) {
    debugPrint('Rating save failed: $e');
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// 食べ終わったあとに★を付けてもらうための案内。★をタップするとその場で保存する。
class RatingPrompt extends ConsumerWidget {
  const RatingPrompt({super.key, required this.entry});

  final VisitWithShop entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerHigh,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          children: [
            Text(
              l10n.ratingPrompt(entry.shop.name),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            StarRating(
              rating: null,
              onChanged: (rating) =>
                  saveRating(context, ref, entry.visit.id, rating),
            ),
          ],
        ),
      ),
    );
  }
}
