import 'package:flutter_test/flutter_test.dart';

import 'package:ramen_in_cho/features/checkin/checkin_rules.dart';
import 'package:ramen_in_cho/features/records/models.dart';

void main() {
  final checkedInAt = DateTime(2026, 9, 30, 11);
  final checkin = Checkin(name: '麺屋', checkedInAt: checkedInAt);

  test('店から100m以内のときだけチェックインできる', () {
    expect(canCheckIn(0), isTrue);
    expect(canCheckIn(100), isTrue);
    expect(canCheckIn(100.1), isFalse);
    expect(canCheckIn(300), isFalse);
    expect(canCheckIn(null), isFalse);
  });

  test('3時間を超えたチェックインは期限切れ。ちょうど3時間はまだ有効', () {
    DateTime after(Duration d) => checkedInAt.add(d);

    expect(isCheckinExpired(checkin, after(Duration.zero)), isFalse);
    expect(isCheckinExpired(checkin, after(const Duration(hours: 3))), isFalse);
    expect(
      isCheckinExpired(checkin, after(const Duration(hours: 3, seconds: 1))),
      isTrue,
    );
    expect(isCheckinExpired(checkin, after(const Duration(days: 1))), isTrue);
  });

  test('並び始めてからの分数は端数を切り捨て、負にならない', () {
    expect(
      checkinElapsedMinutes(
        checkin,
        checkedInAt.add(const Duration(minutes: 9, seconds: 59)),
      ),
      9,
    );
    expect(
      checkinElapsedMinutes(
        checkin,
        checkedInAt.subtract(const Duration(minutes: 5)),
      ),
      0,
    );
  });
}
