import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'shop_candidate.dart';

/// 店の候補1件。[onTap]がnullなら選べない状態で表示する。
class ShopTile extends StatelessWidget {
  const ShopTile({
    super.key,
    required this.shop,
    required this.selected,
    required this.onTap,
    this.note,
  });

  final ShopCandidate shop;
  final bool selected;
  final VoidCallback? onTap;

  /// 距離などの下に添える補足。
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final distance = shop.distanceMeters;
    final details = [
      if (distance != null) l10n.distanceMeters(distance.round()),
      if (shop.wishId != null) l10n.shopWished,
      if (shop.shopId != null) l10n.shopVisited,
      ?note,
    ];
    // 選んだ店は塗りつぶさず、朱の枠で示す（塗ると店名が読めなくなるため）。
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: selected
          ? RoundedRectangleBorder(
              side: BorderSide(color: colors.primary, width: 2),
              borderRadius: BorderRadius.circular(2),
            )
          : null,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        enabled: onTap != null,
        leading: Icon(
          selected
              ? Icons.check_circle
              : shop.wishId != null
              ? Icons.bookmark
              : Icons.storefront,
          color: selected || shop.wishId != null ? colors.primary : null,
        ),
        title: Text(shop.name),
        subtitle: details.isEmpty ? null : Text(details.join('・')),
        onTap: onTap,
      ),
    );
  }
}
