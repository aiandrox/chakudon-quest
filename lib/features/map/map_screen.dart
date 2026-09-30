import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../l10n/app_localizations.dart';
import '../records/date_format.dart';
import '../scoring/rank_labels.dart';
import '../scoring/ranks.dart';
import '../scoring/scoring_providers.dart';
import 'shop_pins.dart';

/// 地図の画像は OpenStreetMap のタイルサーバーから取る。送るのは表示範囲だけ（issue #8）。
const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pins = shopPins(ref.watch(scoredVisitsProvider));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapTitle)),
      body: pins.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.mapEmpty, textAlign: TextAlign.center),
              ),
            )
          : _ShopMap(pins: pins),
    );
  }
}

class _ShopMap extends StatelessWidget {
  const _ShopMap({required this.pins});

  final List<ShopPin> pins;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: [
            for (final pin in pins) LatLng(pin.latitude, pin.longitude),
          ],
          padding: const EdgeInsets.all(48),
          maxZoom: 16,
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: _tileUrl,
          userAgentPackageName: 'com.aiandrox.chakudon_quest',
        ),
        MarkerLayer(
          markers: [
            for (final pin in pins)
              Marker(
                point: LatLng(pin.latitude, pin.longitude),
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: _Pin(pin: pin),
              ),
          ],
        ),
        // 「flutter_map | © 」は部品が付けるため、出典の名前だけを渡す。
        SimpleAttributionWidget(source: Text(l10n.mapAttribution)),
      ],
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
