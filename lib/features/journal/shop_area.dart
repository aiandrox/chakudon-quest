import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../records/record_repository.dart';
import '../shop_search/geo.dart';
import '../shop_search/openpoi_client.dart';

/// 地名がまだ無く位置のわかる店について、市区町村を1回だけ調べて保存する（道中記で地名に触れるため）。
/// 道中記を見せる画面で読む。調べられなくても何も出さないだけ。
final ensureShopAreaProvider = FutureProvider.autoDispose.family<void, String>((
  ref,
  shopId,
) async {
  try {
    final repository = ref.read(recordRepositoryProvider);
    final shop = (await repository.allShops())
        .where((s) => s.id == shopId)
        .firstOrNull;
    final latitude = shop?.latitude;
    final longitude = shop?.longitude;
    if (shop == null || shop.area != null) return;
    if (latitude == null || longitude == null) return;
    final area = await ref
        .read(openPoiClientProvider)
        .areaAt(GeoPoint(latitude, longitude));
    if (area == null) return;
    await repository.setShopArea(shop.id, area);
  } catch (e) {
    debugPrint('Shop area lookup failed: $e');
  }
});
