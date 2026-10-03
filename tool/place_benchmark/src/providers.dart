import 'dart:convert';

import 'package:ramen_in_cho/features/shop_search/geo.dart';
import 'package:ramen_in_cho/features/shop_search/overpass.dart';
import 'package:http/http.dart' as http;

import 'evaluation.dart';

/// 店舗データの提供元1つ。キーが無ければ [isAvailable] が false になり、飛ばす。
abstract class PlaceProvider {
  String get id;

  bool get isAvailable;

  /// 使えないときの理由（どの環境変数を設定すればよいか）。
  String get unavailableReason;

  Future<List<FoundPlace>> search(
    http.Client client,
    BenchmarkPoint point,
    int radius,
  );
}

const _userAgent =
    'ramen-in-cho-benchmark (https://github.com/aiandrox/ramen-in-cho)';
const _timeout = Duration(seconds: 30);

Map<String, Object?> _decode(http.Response response) {
  if (response.statusCode != 200) {
    throw http.ClientException(
      'HTTP ${response.statusCode}: ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}',
    );
  }
  return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
}

/// 今のアプリと同じ検索（OpenStreetMap の Overpass API）。キー不要。
class OsmProvider implements PlaceProvider {
  @override
  String get id => 'OSM';

  @override
  bool get isAvailable => true;

  @override
  String get unavailableReason => '';

  @override
  Future<List<FoundPlace>> search(
    http.Client client,
    BenchmarkPoint point,
    int radius,
  ) async {
    final response = await client
        .post(
          Uri.parse('https://overpass-api.de/api/interpreter'),
          headers: const {'User-Agent': _userAgent},
          body: {
            'data': buildOverpassQuery(
              GeoPoint(point.latitude, point.longitude),
              radiusMeters: radius,
              timeoutSeconds: 25,
            ),
          },
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}');
    }
    // サーバー側の時間切れ（HTTP 200 のまま remark に理由）は parseOverpassResponse が失敗にする。
    return [
      for (final shop in parseOverpassResponse(utf8.decode(response.bodyBytes)))
        FoundPlace(
          name: shop.name,
          latitude: shop.location.latitude,
          longitude: shop.location.longitude,
        ),
    ];
  }
}

/// Google Places API (New) の Nearby Search。種類 ramen_restaurant、近い順、最大20件。
class GooglePlacesProvider implements PlaceProvider {
  GooglePlacesProvider(this._apiKey);

  final String? _apiKey;

  @override
  String get id => 'Google';

  @override
  bool get isAvailable => _apiKey != null && _apiKey.isNotEmpty;

  @override
  String get unavailableReason => '環境変数 GOOGLE_PLACES_API_KEY が未設定';

  @override
  Future<List<FoundPlace>> search(
    http.Client client,
    BenchmarkPoint point,
    int radius,
  ) async {
    final json = _decode(
      await client
          .post(
            Uri.parse('https://places.googleapis.com/v1/places:searchNearby'),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': _apiKey!,
              'X-Goog-FieldMask':
                  'places.id,places.displayName,places.location,'
                  'places.primaryType,places.businessStatus',
            },
            body: jsonEncode({
              'includedTypes': ['ramen_restaurant'],
              'maxResultCount': 20,
              'rankPreference': 'DISTANCE',
              'languageCode': 'ja',
              'locationRestriction': {
                'circle': {
                  'center': {
                    'latitude': point.latitude,
                    'longitude': point.longitude,
                  },
                  'radius': radius.toDouble(),
                },
              },
            }),
          )
          .timeout(_timeout),
    );
    return [
      for (final place in (json['places'] ?? const []) as List)
        if (place case {
          'displayName': {'text': final String name},
          'location': {
            'latitude': final num latitude,
            'longitude': final num longitude,
          },
        })
          FoundPlace(
            name: name,
            latitude: latitude.toDouble(),
            longitude: longitude.toDouble(),
            category: place['primaryType'] as String?,
            closed:
                (place['businessStatus'] as String?)?.startsWith('CLOSED') ??
                false,
          ),
    ];
  }
}

/// Yahoo!ローカルサーチAPI。グルメ（業種コード 01）の中から「ラーメン」で検索、近い順、最大100件。
class YahooLocalProvider implements PlaceProvider {
  YahooLocalProvider(this._clientId);

  final String? _clientId;

  @override
  String get id => 'Yahoo!';

  @override
  bool get isAvailable => _clientId != null && _clientId.isNotEmpty;

  @override
  String get unavailableReason => '環境変数 YAHOO_CLIENT_ID が未設定';

  @override
  Future<List<FoundPlace>> search(
    http.Client client,
    BenchmarkPoint point,
    int radius,
  ) async {
    final json = _decode(
      await client
          .get(
            Uri.https('map.yahooapis.jp', '/search/local/V1/localSearch', {
              'appid': _clientId!,
              'lat': '${point.latitude}',
              'lon': '${point.longitude}',
              'dist': '${radius / 1000}',
              'gc': '01',
              'query': 'ラーメン',
              'sort': 'geo',
              'results': '100',
              'detail': 'standard',
              'output': 'json',
            }),
            headers: const {'User-Agent': _userAgent},
          )
          .timeout(_timeout),
    );
    return [
      for (final feature in (json['Feature'] ?? const []) as List)
        if (feature case {
          'Name': final String name,
          'Geometry': {'Coordinates': final String coordinates},
        })
          _yahooPlace(name, coordinates, feature),
    ];
  }

  FoundPlace _yahooPlace(String name, String coordinates, Object? feature) {
    final parts = coordinates.split(',');
    final genres = switch (feature) {
      {'Property': {'Genre': final List genres}} => [
        for (final genre in genres)
          if (genre case {'Name': final String name}) name,
      ],
      _ => const <String>[],
    };
    return FoundPlace(
      name: name,
      longitude: double.parse(parts[0]),
      latitude: double.parse(parts[1]),
      category: genres.join('/'),
    );
  }
}

/// ホットペッパー グルメサーチAPI。ジャンル G013（ラーメン）。半径は 300/500/1000/2000/3000m から近いものを使う。
class HotPepperProvider implements PlaceProvider {
  HotPepperProvider(this._apiKey);

  final String? _apiKey;

  @override
  String get id => 'ホットペッパー';

  @override
  bool get isAvailable => _apiKey != null && _apiKey.isNotEmpty;

  @override
  String get unavailableReason => '環境変数 HOTPEPPER_API_KEY が未設定';

  static int rangeFor(int radius) => switch (radius) {
    <= 300 => 1,
    <= 500 => 2,
    <= 1000 => 3,
    <= 2000 => 4,
    _ => 5,
  };

  @override
  Future<List<FoundPlace>> search(
    http.Client client,
    BenchmarkPoint point,
    int radius,
  ) async {
    final json = _decode(
      await client
          .get(
            Uri.https('webservice.recruit.co.jp', '/hotpepper/gourmet/v1/', {
              'key': _apiKey!,
              'lat': '${point.latitude}',
              'lng': '${point.longitude}',
              'range': '${rangeFor(radius)}',
              'genre': 'G013',
              'count': '100',
              'format': 'json',
            }),
          )
          .timeout(_timeout),
    );
    final results = json['results'] as Map<String, Object?>?;
    if (results?['error'] case final Object error) {
      throw http.ClientException('$error');
    }
    return [
      for (final shop in (results?['shop'] ?? const []) as List)
        if (shop case {
          'name': final String name,
          'lat': final Object lat,
          'lng': final Object lng,
        })
          FoundPlace(
            name: name,
            latitude: double.parse('$lat'),
            longitude: double.parse('$lng'),
            category: switch (shop) {
              {'genre': {'name': final String genre}} => genre,
              _ => null,
            },
          ),
    ];
  }
}

/// Foursquare Places API。「ラーメン」で検索、近い順、最大50件。
class FoursquareProvider implements PlaceProvider {
  FoursquareProvider(this._apiKey);

  final String? _apiKey;

  @override
  String get id => 'Foursquare';

  @override
  bool get isAvailable => _apiKey != null && _apiKey.isNotEmpty;

  @override
  String get unavailableReason => '環境変数 FOURSQUARE_API_KEY が未設定';

  @override
  Future<List<FoundPlace>> search(
    http.Client client,
    BenchmarkPoint point,
    int radius,
  ) async {
    final json = _decode(
      await client
          .get(
            Uri.https('places-api.foursquare.com', '/places/search', {
              'll': '${point.latitude},${point.longitude}',
              'radius': '$radius',
              'query': 'ラーメン',
              'limit': '50',
              'sort': 'DISTANCE',
            }),
            headers: {
              'Authorization': 'Bearer ${_apiKey!}',
              'X-Places-Api-Version': '2025-06-17',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout),
    );
    return [
      for (final place in (json['results'] ?? const []) as List)
        if (place case {
          'name': final String name,
          'latitude': final num latitude,
          'longitude': final num longitude,
        })
          FoundPlace(
            name: name,
            latitude: latitude.toDouble(),
            longitude: longitude.toDouble(),
            category: switch (place) {
              {'categories': [{'name': final String category}, ...]} =>
                category,
              _ => null,
            },
            closed: place['date_closed'] != null,
          ),
    ];
  }
}
