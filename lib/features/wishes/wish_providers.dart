import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../records/models.dart';
import '../scoring/points.dart';
import '../scoring/scoring_providers.dart';
import 'wish_repository.dart';
import 'wishes.dart';

class WishStatus {
  const WishStatus({required this.wish, this.fulfilledBy});

  final Wish wish;

  /// 願が叶った1杯。まだならnull。
  final ScoredVisit? fulfilledBy;

  bool get isFulfilled => fulfilledBy != null;
}

/// 願掛け帳の全件と、叶ったかどうか。保存せず、記録から毎回求める。
final wishStatusesProvider = Provider<List<WishStatus>>((ref) {
  final fulfilled = {
    for (final entry in ref.watch(scoredVisitsProvider))
      if (entry.fulfilledWish case final wish?) wish.id: entry,
  };
  return [
    for (final wish in ref.watch(wishesProvider).value ?? const <Wish>[])
      WishStatus(wish: wish, fulfilledBy: fulfilled[wish.id]),
  ];
});

/// まだ叶っていない願のうち、[shop]の店に掛けたもの。
Wish? pendingWishFor(List<WishStatus> statuses, Shop shop) => statuses
    .where((s) => !s.isFulfilled && wishMatchesShop(s.wish, shop))
    .map((s) => s.wish)
    .firstOrNull;
