import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/home/incho_months.dart';

import '../../support/builders.dart';

void main() {
  test('新しい順の記録を、新しい月から月ごとにまとめる', () {
    final months = inchoMonths([
      buildEntry(eatenAt: DateTime(2026, 10, 3, 12)),
      buildEntry(eatenAt: DateTime(2026, 10, 1, 12)),
      buildEntry(eatenAt: DateTime(2026, 9, 30, 12)),
      buildEntry(eatenAt: DateTime(2025, 10, 5, 12)),
    ]);

    expect(months.map((m) => m.month), [
      DateTime(2026, 10),
      DateTime(2026, 9),
      DateTime(2025, 10),
    ]);
    expect(months.map((m) => m.entries.length), [2, 1, 1]);
  });

  test('記録が無ければ空', () {
    expect(inchoMonths(const []), isEmpty);
  });
}
