import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ramen_in_cho/features/journal/journal_phrases.dart';

/// 道中記の言い回しの一覧（管理用）を `docs/journal/README.md` に作る。
///
/// ふだんは一覧が定義と合っているかを確かめる。言い回しを足したり変えたりしたら、
/// `flutter test --dart-define=UPDATE_JOURNAL_CATALOG=true test/tool/journal_catalog_test.dart`
/// で作り直す。
const _path = 'docs/journal/README.md';
const _update = bool.fromEnvironment('UPDATE_JOURNAL_CATALOG');

String catalogMarkdown() {
  final buffer = StringBuffer()
    ..writeln('# 道中記の言い回し')
    ..writeln()
    ..writeln('1杯ごとの道中記に出てくる文の一覧。管理用。')
    ..writeln()
    ..writeln('- 定義は `lib/features/journal/journal_phrases.dart`')
    ..writeln(
      '- 上から順に、当てはまる文を1つずつつないで道中記にする。候補が複数あるときは、記録ごとに1つに決まる（開くたびには変わらない）',
    )
    ..writeln('- `{ }` の中は、その1杯の数字や名前に置き換わる')
    ..writeln('- 候補の並びを変えたり候補を足したりすると、過去の道中記の文も変わる')
    ..writeln(
      '- 言い回しを足したり変えたりしたら `flutter test --dart-define=UPDATE_JOURNAL_CATALOG=true '
      'test/tool/journal_catalog_test.dart` でこの一覧を作り直す',
    );
  for (final section in journalCatalog) {
    buffer
      ..writeln()
      ..writeln('## ${section.title}')
      ..writeln();
    if (section.note.isNotEmpty) {
      buffer
        ..writeln(section.note)
        ..writeln();
    }
    buffer
      ..writeln('| いつ | 言い回し |')
      ..writeln('|---|---|');
    for (final phrases in section.phrases) {
      final lines = [
        for (final line in phrases.lines) line.isEmpty ? '（何も添えない）' : line,
      ];
      buffer.writeln('| ${phrases.when} | ${lines.join('<br>')} |');
    }
  }
  return buffer.toString();
}

void main() {
  test('道中記の言い回しの一覧が定義と合っている', () {
    final file = File(_path);
    if (_update) {
      file
        ..createSync(recursive: true)
        ..writeAsStringSync(catalogMarkdown());
      return;
    }
    expect(
      file.existsSync() ? file.readAsStringSync() : '',
      catalogMarkdown(),
      reason:
          '道中記の言い回しが変わったので、一覧を作り直してください: '
          'flutter test --dart-define=UPDATE_JOURNAL_CATALOG=true test/tool/journal_catalog_test.dart',
    );
  });

  test('節目の説明が、節目の杯数と合っている', () {
    expect(milestoneMoment.when, '通算 ${milestoneBowls.join('・')} 杯目');
  });

  test('言い回しに | を使わない（一覧の表が崩れるため）', () {
    for (final section in journalCatalog) {
      for (final phrases in section.phrases) {
        for (final line in [phrases.when, ...phrases.lines]) {
          expect(line, isNot(contains('|')), reason: line);
        }
      }
    }
  });
}
