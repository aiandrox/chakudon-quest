import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/wait_time.dart';

import '../../support/builders.dart';

void main() {
  test('待ち時間は、食べた時刻 − チェックイン時刻（分）', () {
    expect(waitMinutes(buildVisit(waitMinutes: 0)), 0);
    expect(waitMinutes(buildVisit(waitMinutes: 35)), 35);
    expect(waitMinutes(buildVisit(waitMinutes: 125)), 125);
  });

  test('秒の端数は切り捨てる（9分59秒は9分）', () {
    final eatenAt = DateTime(2026, 9, 30, 12);
    final visit = Visit(
      id: 'v',
      shopId: 'shop',
      result: VisitResult.eaten,
      checkedInAt: eatenAt.subtract(const Duration(minutes: 9, seconds: 59)),
      eatenAt: eatenAt,
      isLimited: false,
      hasTicket: false,
      memo: '',
      createdAt: eatenAt,
    );

    expect(waitMinutes(visit), 9);
  });

  test('チェックインしていない記録に待ち時間は無い', () {
    expect(waitMinutes(buildVisit()), isNull);
  });

  test('食べた時刻がチェックインより前なら0分にする', () {
    expect(waitMinutes(buildVisit(waitMinutes: -5)), 0);
  });

  test('撤退の記録に待ち時間は無い', () {
    expect(
      waitMinutes(buildVisit(result: VisitResult.retreated, waitMinutes: 30)),
      isNull,
    );
  });
}
