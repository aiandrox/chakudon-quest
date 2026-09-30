// 店舗データの提供元を、同じ地点・同じ半径で比べる検証用のスクリプト（#57）。
// アプリには組み込まない。使い方は同じフォルダの README.md。
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'src/evaluation.dart';
import 'src/providers.dart';

Future<void> main(List<String> args) async {
  final repeat = _intOption(args, '--repeat') ?? 1;
  final only = _option(args, '--providers')?.split(',').toSet();
  final env = Platform.environment;

  final points = [
    ...parsePoints(File('tool/place_benchmark/points.json').readAsStringSync()),
    // 自宅の近くなど、リポジトリに入れたくない地点はこのファイルに書く（.gitignore 済み）。
    if (File('tool/place_benchmark/points.local.json').existsSync())
      ...parsePoints(
        File('tool/place_benchmark/points.local.json').readAsStringSync(),
      ),
  ];
  final providers = <PlaceProvider>[
    OsmProvider(),
    GooglePlacesProvider(env['GOOGLE_PLACES_API_KEY']),
    YahooLocalProvider(env['YAHOO_CLIENT_ID']),
    HotPepperProvider(env['HOTPEPPER_API_KEY']),
    FoursquareProvider(env['FOURSQUARE_API_KEY']),
  ].where((p) => only == null || only.contains(p.id)).toList();

  for (final provider in providers.where((p) => !p.isAvailable)) {
    stderr.writeln('スキップ: ${provider.id}（${provider.unavailableReason}）');
  }

  final client = http.Client();
  final runs = <ProviderRun>[];
  try {
    for (final point in points) {
      for (final radius in point.radii) {
        for (final provider in providers.where((p) => p.isAvailable)) {
          for (var attempt = 1; attempt <= repeat; attempt++) {
            final run = await _run(client, provider, point, radius);
            runs.add(run);
            stderr.writeln(
              '${point.label} ${radius}m ${provider.id} #$attempt: '
              '${run.failed ? '失敗 ${run.error}' : '${run.places.length}件'} '
              '(${run.elapsed.inMilliseconds}ms)',
            );
            // 公開サーバー（特に OSM）に負担をかけないよう、間を空ける。
            await Future<void>.delayed(const Duration(seconds: 3));
          }
        }
      }
    }
  } finally {
    client.close();
  }

  final outDir = Directory('tool/place_benchmark/results')
    ..createSync(recursive: true);
  final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  File('${outDir.path}/$stamp.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ')
        .convert([for (final run in runs) run.toJson()]),
  );
  final report = markdownReport(summarize(points, runs));
  File('${outDir.path}/$stamp.md').writeAsStringSync(report);
  stdout.writeln(report);
  stderr.writeln('生データ: ${outDir.path}/$stamp.json');
}

Future<ProviderRun> _run(
  http.Client client,
  PlaceProvider provider,
  BenchmarkPoint point,
  int radius,
) async {
  // 応答時間は最後の1回だけを測る（やり直しの前の待ち時間を含めない）。
  var watch = Stopwatch()..start();
  try {
    final places = await _withRetry(
      () => provider.search(client, point, radius),
      onRetry: () => watch = Stopwatch()..start(),
    );
    return ProviderRun(
      provider: provider.id,
      pointId: point.id,
      radius: radius,
      elapsed: watch.elapsed,
      places: places,
    );
  } catch (e) {
    return ProviderRun(
      provider: provider.id,
      pointId: point.id,
      radius: radius,
      elapsed: watch.elapsed,
      error: '$e',
    );
  }
}

/// 混雑（429・5xx）での失敗は、少し待って1回だけやり直す。やり直しても失敗なら失敗として数える。
Future<T> _withRetry<T>(
  Future<T> Function() body, {
  required void Function() onRetry,
}) async {
  try {
    return await body();
  } on http.ClientException catch (e) {
    if (!RegExp(r'HTTP (429|5\d\d)').hasMatch(e.message)) rethrow;
    await Future<void>.delayed(const Duration(seconds: 10));
    onRetry();
    return body();
  }
}

String? _option(List<String> args, String name) {
  final index = args.indexOf(name);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}

int? _intOption(List<String> args, String name) {
  final value = _option(args, name);
  return value == null ? null : int.tryParse(value);
}
