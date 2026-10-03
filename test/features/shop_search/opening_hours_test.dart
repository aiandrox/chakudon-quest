import 'package:flutter_test/flutter_test.dart';

import 'package:ramen_in_cho/features/records/models.dart';
import 'package:ramen_in_cho/features/shop_search/opening_hours.dart';

void main() {
  test('毎日ふつうに開いている店は、条件なし', () {
    expect(conditionsFromOpeningHours('Mo-Su 10:00-23:00'), isEmpty);
    expect(conditionsFromOpeningHours('08:00-23:00'), isEmpty);
    expect(conditionsFromOpeningHours('24/7'), isEmpty);
    expect(
      conditionsFromOpeningHours(
        'Mo-Fr 11:00-15:00,17:00-21:00; Sa 11:00-15:00',
      ),
      isEmpty,
    );
  });

  test('16時までに閉まるなら昼のみ。15:59と16:00、16:01の境目', () {
    expect(conditionsFromOpeningHours('11:00-16:00'), {
      HoursCondition.lunchOnly,
    });
    expect(conditionsFromOpeningHours('11:00-15:59'), {
      HoursCondition.lunchOnly,
    });
    expect(conditionsFromOpeningHours('11:00-16:01'), isEmpty);
  });

  test('17時以降に開くなら夜のみ。日をまたぐ営業も夜のみ', () {
    expect(conditionsFromOpeningHours('17:00-23:00'), {
      HoursCondition.nightOnly,
    });
    expect(conditionsFromOpeningHours('18:00-02:00'), {
      HoursCondition.nightOnly,
    });
    expect(conditionsFromOpeningHours('16:59-23:00'), isEmpty);
  });

  test('平日のみ・土日のみ・週3日以下', () {
    expect(conditionsFromOpeningHours('Mo-Fr 11:00-20:00; Sa,Su off'), {
      HoursCondition.weekdaysOnly,
    });
    expect(conditionsFromOpeningHours('Sa,Su 11:00-20:00'), {
      HoursCondition.weekendsOnly,
      HoursCondition.fewDays,
    });
    expect(conditionsFromOpeningHours('Th-Sa 11:00-20:00'), {
      HoursCondition.fewDays,
    });
    expect(conditionsFromOpeningHours('We-Sa 11:00-20:00'), isEmpty);
  });

  test('いくつも当てはまれば、すべて出す', () {
    expect(conditionsFromOpeningHours('Mo,We,Fr 11:00-14:30'), {
      HoursCondition.lunchOnly,
      HoursCondition.weekdaysOnly,
      HoursCondition.fewDays,
    });
  });

  test('後の決まりが前の決まりを上書きし、週をまたぐ曜日の書き方も読める', () {
    expect(conditionsFromOpeningHours('Mo-Su 11:00-20:00; Mo-Th off'), {
      HoursCondition.fewDays,
    });
    expect(conditionsFromOpeningHours('Fr-Mo 18:00-23:00'), {
      HoursCondition.nightOnly,
    });
  });

  test('祝日（PH）は読み飛ばす', () {
    expect(conditionsFromOpeningHours('Mo-Fr 11:00-15:00; PH off'), {
      HoursCondition.lunchOnly,
      HoursCondition.weekdaysOnly,
    });
    expect(conditionsFromOpeningHours('Sa,Su,PH 11:00-15:00'), {
      HoursCondition.lunchOnly,
      HoursCondition.weekendsOnly,
      HoursCondition.fewDays,
    });
  });

  test('読めない書き方や、営業日が無いときはnull', () {
    expect(conditionsFromOpeningHours(null), isNull);
    expect(conditionsFromOpeningHours(''), isNull);
    expect(conditionsFromOpeningHours('Jan-Mar Mo-Fr 11:00-15:00'), isNull);
    expect(conditionsFromOpeningHours('Mo-Fr 11:00+'), isNull);
    expect(conditionsFromOpeningHours('Mo-Fr 11:00-15:00 "売り切れ次第終了"'), isNull);
    expect(conditionsFromOpeningHours('sunrise-sunset'), isNull);
    expect(conditionsFromOpeningHours('Mo-Su off'), isNull);
    expect(conditionsFromOpeningHours('Mo[1] 11:00-15:00'), isNull);
  });
}
