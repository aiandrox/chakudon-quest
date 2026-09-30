import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'geo.dart';
import 'overpass.dart';

final overpassClientProvider = Provider<OverpassClient>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OverpassClient(client);
});

class OverpassClient {
  OverpassClient(this._client, {Uri? endpoint})
    : _endpoint =
          endpoint ?? Uri.parse('https://overpass-api.de/api/interpreter');

  static const timeout = Duration(seconds: 10);

  final http.Client _client;
  final Uri _endpoint;

  /// 通信の失敗・タイムアウト・想定外の応答は例外にする。呼び出し側で手入力に切り替える。
  Future<List<OverpassShop>> searchNearby(GeoPoint center) async {
    final response = await _client
        .post(
          _endpoint,
          headers: const {
            'User-Agent':
                'chakudon-quest (https://github.com/aiandrox/chakudon-quest)',
          },
          body: {
            'data': buildOverpassQuery(
              center,
              timeoutSeconds: timeout.inSeconds,
            ),
          },
        )
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Overpass API: HTTP ${response.statusCode}',
        _endpoint,
      );
    }
    return parseOverpassResponse(response.body);
  }
}
