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
import '../shop_search/nearby_shop_finder.dart';
import '../shop_search/overpass.dart';
import '../records/models.dart';
import '../records/record_repository.dart';
import '../wishes/wish_dialog.dart';
import '../wishes/wish_providers.dart';
import '../wishes/wishes.dart';
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
  List<FoundShop> _nearby = const [];
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
          .read(nearbyShopFinderProvider)
          .searchNearby(
            GeoPoint(center.latitude, center.longitude),
            radiusMeters: nearbySearchRadiusMeters,
            // 店内で急ぐ記録と違い待てる場面なので、混んでいるサーバーにも長めに待つ。
            timeout: const Duration(seconds: 25),
          );
      if (!mounted) return;
      // 位置のわからない手入力の店や、撤退しただけの店も「行った店」として除く。
      final visited = {
        for (final entry in ref.read(scoredVisitsProvider))
          entry.shop.id: entry.shop,
      };
      final nearby = unvisitedShops(
        found: found,
        eatenShops: visited.values.toList(),
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
    final pendingWishes = [
      for (final status in ref.watch(wishStatusesProvider))
        if (!status.isFulfilled &&
            wishLocation(status.wish) != null &&
            // 行ったことのある店に掛けた（再訪の）願は、その店のピンで見せる。
            !pins.any((pin) => wishMatchesShop(status.wish, pin.shop)))
          status.wish,
    ];
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
                    if (!pendingWishes.any(
                      (wish) => wishMatchesPlace(
                        wish,
                        osmId: shop.osmId,
                        name: shop.name,
                        location: shop.location,
                      ),
                    ))
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
                  for (final wish in pendingWishes)
                    Marker(
                      point: LatLng(wish.latitude!, wish.longitude!),
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: _WishPin(wish: wish),
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
          if (_nearby.isNotEmpty)
            Positioned(
              left: 8,
              top: 8,
              right: 8,
              child: ColoredBox(
                color: const Color(0xCCFFFFFF),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(
                    l10n.openPoiAttribution,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          if (pins.isEmpty && _nearby.isEmpty && pendingWishes.isEmpty)
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

class _UnvisitedPin extends ConsumerWidget {
  const _UnvisitedPin({required this.shop, required this.here});

  final FoundShop shop;
  final GeoPoint? here;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.bookmark_add),
                  label: Text(l10n.wishMakeButton),
                  onPressed: () {
                    Navigator.of(context).pop();
                    addWishFor(
                      context,
                      ref,
                      ShopInput(
                        osmId: shop.osmId,
                        name: shop.name,
                        latitude: shop.location.latitude,
                        longitude: shop.location.longitude,
                        dataSource: shop.dataSource,
                      ),
                    );
                  },
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
    final l10n = AppLocalizations.of(context);
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
                  shopRankLabel(l10n, rank),
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
      if (rank != null) l10n.mapShopRank(shopRankLabel(l10n, rank)),
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

/// 願を掛けた（まだ行っていない）店。輪郭だけの朱のピンに「願」の字。
class _WishPin extends StatelessWidget {
  const _WishPin({required this.wish});

  final Wish wish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
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
                Text(wish.name, style: textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(l10n.mapWished),
                if (wish.note.isNotEmpty) Text(wish.note),
                if (wish.trigger.isNotEmpty)
                  Text(l10n.wishTriggerLine(wish.trigger)),
              ],
            ),
          ),
        ),
      ),
      child: Semantics(
        button: true,
        label: l10n.mapWishedLabel(wish.name),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Icon(Icons.location_on_outlined, size: 40, color: colors.primary),
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                l10n.wishSealChar,
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
