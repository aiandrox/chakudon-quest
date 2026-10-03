import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'found_shop.dart';
import 'geo.dart';
import 'openpoi_client.dart';

/// 店名で全国の店を探し、選んだ店を返す。やめたらnull。
Future<FoundShop?> showShopNameSearch(
  BuildContext context, {
  required String initialName,
  GeoPoint? near,
}) => showModalBottomSheet<FoundShop>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _ShopNameSearchSheet(initialName: initialName, near: near),
);

class _ShopNameSearchSheet extends ConsumerStatefulWidget {
  const _ShopNameSearchSheet({required this.initialName, this.near});

  final String initialName;
  final GeoPoint? near;

  @override
  ConsumerState<_ShopNameSearchSheet> createState() =>
      _ShopNameSearchSheetState();
}

class _ShopNameSearchSheetState extends ConsumerState<_ShopNameSearchSheet> {
  late final _controller = TextEditingController(text: widget.initialName);
  List<FoundShop>? _results;
  bool _isSearching = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialName.trim().isNotEmpty) _search();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _isSearching) return;
    setState(() {
      _isSearching = true;
      _failed = false;
    });
    try {
      final results = await ref
          .read(openPoiClientProvider)
          .searchByName(name, near: widget.near);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      debugPrint('Shop name search failed: $e');
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final results = _results;
    final near = widget.near;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(l10n.nameSearchTitle, style: textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  labelText: l10n.shopNameLabel,
                  suffixIcon: IconButton(
                    tooltip: l10n.nameSearchButton,
                    icon: const Icon(Icons.search),
                    onPressed: _search,
                  ),
                ),
              ),
            ),
            if (_isSearching) const LinearProgressIndicator(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                children: [
                  if (_failed)
                    ListTile(title: Text(l10n.nameSearchFailed))
                  else if (results != null && results.isEmpty)
                    ListTile(title: Text(l10n.nameSearchNone)),
                  for (final shop in results ?? const <FoundShop>[])
                    ListTile(
                      leading: const Icon(Icons.storefront),
                      title: Text(shop.name),
                      subtitle: Text(
                        [
                          ?shop.address,
                          if (near != null)
                            l10n.nameSearchDistance(
                              (distanceMeters(near, shop.location) / 1000)
                                  .toStringAsFixed(1),
                            ),
                        ].join('・'),
                      ),
                      onTap: () => Navigator.of(context).pop(shop),
                    ),
                  if (results != null && results.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        l10n.openPoiAttribution,
                        style: textTheme.labelSmall,
                        textAlign: TextAlign.right,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
