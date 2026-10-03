import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/shop/hours_condition_chips.dart';

void main() {
  test('昼のみと夜のみは、片方を選ぶともう片方が外れる', () {
    expect(
      toggleHoursCondition(
        {HoursCondition.lunchOnly, HoursCondition.fewDays},
        HoursCondition.nightOnly,
        true,
      ),
      {HoursCondition.fewDays, HoursCondition.nightOnly},
    );
    expect(
      toggleHoursCondition(
        {HoursCondition.nightOnly},
        HoursCondition.lunchOnly,
        true,
      ),
      {HoursCondition.lunchOnly},
    );
  });

  test('ほかの条件はいくつでも選べ、外せる', () {
    final selected = toggleHoursCondition(
      {HoursCondition.weekdaysOnly},
      HoursCondition.fewDays,
      true,
    );
    expect(selected, {HoursCondition.weekdaysOnly, HoursCondition.fewDays});
    expect(toggleHoursCondition(selected, HoursCondition.weekdaysOnly, false), {
      HoursCondition.fewDays,
    });
  });
}
