import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/credits/credits.dart';
import 'package:chakudon_quest/features/records/models.dart';

Shop _shop(String id, [ShopSource? source]) =>
    Shop(id: id, name: id, dataSource: source, createdAt: DateTime(2026));

void main() {
  test('記録した店の出所を、重なりを除いて並べる', () {
    final credits = sourceCredits([
      _shop(
        'a',
        const ShopSource(
          licenses: ['CC BY 4.0'],
          attributions: ['東京都新宿区食品等営業許可・届出一覧'],
        ),
      ),
      _shop(
        'b',
        const ShopSource(
          licenses: ['CDLA-Permissive-2.0', 'CC BY 4.0'],
          attributions: [
            'Overture Maps Foundation, overturemaps.org',
            '東京都新宿区食品等営業許可・届出一覧',
          ],
        ),
      ),
      _shop('osm'),
    ]);

    expect(credits.attributions, [
      'Overture Maps Foundation, overturemaps.org',
      '東京都新宿区食品等営業許可・届出一覧',
    ]);
    expect(credits.licenses, ['CC BY 4.0', 'CDLA-Permissive-2.0']);
  });

  test('OpenPOIの店が無ければ空', () {
    expect(sourceCredits([_shop('osm')]).isEmpty, isTrue);
  });
}
