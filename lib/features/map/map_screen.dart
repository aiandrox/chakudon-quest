import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../l10n/app_localizations.dart';
import '../records/date_format.dart';
import '../scoring/rank_labels.dart';
import '../scoring/ranks.dart';
import '../scoring/scoring_providers.dart';
import '../shop_search/geo.dart';
import '../shop_search/location_service.dart';
import '../shop_search/overpass.dart';
import '../shop_search/overpass_client.dart';
import 'shop_pins.dart';

/// 地図の画像は OpenStreetMap のタイルサーバーから取る。送るのは表示範囲だけ（issue #8）。
const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// テストでは地図の画像を取りに行かないよう、falseに差し替える。
final mapTilesEnabledProvider = Provider<bool>((ref) => true);

/// 「このあたりを探す」で探す半径。記録のときの候補（300m）より広く、歩いて行ける範囲。
const nearbySearchRadiusMeters = 1000;

/// 行った店が無く、現在地もわからないときに最初に見せる場所（東京駅）。
const _fallbackCenter = LatLng(35.6812, 139.7671);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _controller = MapController();
  GeoPoint? _here;
  List<OverpassShop> _nearby = const [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate(move: false));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _locate({required bool move}) async {
    final here = await ref
        .read(locationServiceProvider)
        .currentPosition(requestPermission: true);
    if (!mounted) return;
    if (here == null) {
      if (move) _showMessage(AppLocalizations.of(context).mapNoLocation);
      return;
    }
    setState(() => _here = here);
    // 行った店が無いときは、現在地のまわりを見せる。
    final hasPins = shopPins(ref.read(scoredVisitsProvider)).isNotEmpty;
    if (move || !hasPins) {
      _controller.move(LatLng(here.latitude, here.longitude), 15);
    }
  }

  Future<void> _searchHere() async {
    final l10n = AppLocalizations.of(context);
    final center = _controller.camera.center;
    setState(() => _isSearching = true);
    try {
      final found = await ref
          .read(overpassClientProvider)
          .searchNearby(
            GeoPoint(center.latitude, center.longitude),
            radiusMeters: nearbySearchRadiusMeters,
            // 店内で急ぐ記録と違い待てる場面なので、混んでいるサーバーにも長めに待つ。
            timeout: const Duration(seconds: 25),
          );
      if (!mounted) return;
      final eaten = {
        for (final pin in shopPins(ref.read(scoredVisitsProvider)))
          if (pin.eatenCount > 0) pin.shop.id: pin.shop,
      };
      final nearby = unvisitedShops(
        found: found,
        eatenShops: eaten.values.toList(),
      );
      setState(() => _nearby = nearby);
      _showMessage(
        nearby.isEmpty
            ? l10n.mapNearbyNone
            : l10n.mapNearbyFound(nearby.length),
      );
    } catch (e) {
      debugPrint('Nearby search failed: $e');
      if (mounted) _showMessage(l10n.mapSearchFailed);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pins = shopPins(ref.watch(scoredVisitsProvider));
    final tilesEnabled = ref.watch(mapTilesEnabledProvider);
    final here = _here;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapTitle)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _fallbackCenter,
              initialZoom: 13,
              initialCameraFit: pins.isEmpty
                  ? null
                  : CameraFit.coordinates(
                      coordinates: [
                        for (final pin in pins)
                          LatLng(pin.latitude, pin.longitude),
                      ],
                      padding: const EdgeInsets.all(48),
                      maxZoom: 16,
                    ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              if (tilesEnabled)
                TileLayer(
                  urlTemplate: _tileUrl,
                  userAgentPackageName: 'com.aiandrox.chakudon_quest',
                ),
              MarkerLayer(
                markers: [
                  for (final shop in _nearby)
                    Marker(
                      point: LatLng(
                        shop.location.latitude,
                        shop.location.longitude,
                      ),
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: _UnvisitedPin(shop: shop, here: here),
                    ),
                  for (final pin in pins)
                    Marker(
                      point: LatLng(pin.latitude, pin.longitude),
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: _Pin(pin: pin),
                    ),
                  if (here != null)
                    Marker(
                      point: LatLng(here.latitude, here.longitude),
                      width: 22,
                      height: 22,
                      child: const _HereDot(),
                    ),
                ],
              ),
              // 「flutter_map | © 」は部品が付けるため、出典の名前だけを渡す。
              SimpleAttributionWidget(source: Text(l10n.mapAttribution)),
            ],
          ),
          if (pins.isEmpty && _nearby.isEmpty)
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l10n.mapEmpty),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: 'my-location',
              tooltip: l10n.mapMyLocation,
              onPressed: () => _locate(move: true),
              child: const Icon(Icons.my_location),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'search-here',
              onPressed: _isSearching ? null : _searchHere,
              icon: _isSearching
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(l10n.mapSearchHere),
            ),
          ],
        ),
      ),
    );
  }
}

class _HereDot extends StatelessWidget {
  const _HereDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
    );
  }
}

class _UnvisitedPin extends StatelessWidget {
  const _UnvisitedPin({required this.shop, required this.here});

  final OverpassShop shop;
  final GeoPoint? here;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final here = this.here;
    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(l10n.mapUnvisited),
                if (here != null)
                  Text(
                    l10n.mapDistanceFromHere(
                      distanceMeters(here, shop.location).round(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      child: Semantics(
        button: true,
        label: shop.name,
        child: Icon(
          Icons.location_on_outlined,
          size: 40,
          color: colors.outline,
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.pin});

  final ShopPin pin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rank = pin.rank;
    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => _PinDetails(pin: pin),
      ),
      child: Semantics(
        button: true,
        label: pin.shop.name,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Icon(
              Icons.location_on,
              size: 44,
              color: rank == null
                  ? colors.outline
                  : rank == ShopRank.s
                  ? colors.primary
                  : colors.secondary,
            ),
            if (rank != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  shopRankLabel(rank),
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PinDetails extends StatelessWidget {
  const _PinDetails({required this.pin});

  final ShopPin pin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final rank = pin.rank;
    final details = [
      if (pin.eatenCount > 0) l10n.mapShopBowls(pin.eatenCount),
      if (pin.retreatCount > 0) l10n.mapShopRetreats(pin.retreatCount),
      if (rank != null) l10n.mapShopRank(shopRankLabel(rank)),
    ];
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pin.shop.name, style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(details.join('・'), style: textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(
              l10n.mapLastVisit(formatDate(pin.lastVisitAt)),
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
