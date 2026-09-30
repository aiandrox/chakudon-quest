import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../records/labels.dart';
import '../records/models.dart';
import '../shop_search/shop_candidate.dart';
import 'record_controller.dart';
import 'record_state.dart';
import 'star_rating.dart';

/// 保存できたら`true`を返して閉じる。
class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key, this.recoveredPhotoPath});

  final String? recoveredPhotoPath;

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  final _nameController = TextEditingController();
  final _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(recordControllerProvider.notifier)
          .start(recoveredPhotoPath: widget.recoveredPhotoPath);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await ref.read(recordControllerProvider.notifier).save();
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).recordSaveFailed)),
      );
    }
  }

  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.discardTitle),
        content: Text(l10n.discardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.discardCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.discardConfirm),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  void _selectShop(ShopCandidate shop) {
    _nameController.clear();
    FocusScope.of(context).unfocus();
    ref.read(recordControllerProvider.notifier).selectShop(shop);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordControllerProvider);

    return PopScope(
      canPop: !state.hasInput,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: _buildScaffold(context, state),
    );
  }

  Widget _buildScaffold(BuildContext context, RecordState state) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(recordControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recordTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _PhotoSection(state: state),
          const SizedBox(height: 16),
          Text(l10n.shopSection, style: textTheme.titleMedium),
          _ShopSection(
            state: state,
            nameController: _nameController,
            onSelect: _selectShop,
          ),
          const SizedBox(height: 16),
          Text(l10n.ratingSection, style: textTheme.titleMedium),
          StarRating(rating: state.rating, onChanged: controller.setRating),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.optionalSection),
            children: [
              _OptionalSection(state: state, memoController: _memoController),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              textStyle: textTheme.titleLarge,
            ),
            onPressed: state.canSave ? _save : null,
            child: state.isSaving
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text(l10n.save),
          ),
        ),
      ),
    );
  }
}

class _PhotoSection extends ConsumerWidget {
  const _PhotoSection({required this.state});

  final RecordState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(recordControllerProvider.notifier);
    final photoPath = state.photoPath;
    final hasPhoto = photoPath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            child: hasPhoto
                ? Image.file(File(photoPath), fit: BoxFit.cover)
                : ColoredBox(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: Center(
                      child: state.photoStepDone
                          ? const Icon(Icons.ramen_dining, size: 48)
                          : const CircularProgressIndicator(),
                    ),
                  ),
          ),
        ),
        if (state.photoStepDone)
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: controller.takePhoto,
                  icon: const Icon(Icons.photo_camera),
                  label: Text(hasPhoto ? l10n.retakePhoto : l10n.takePhoto),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: controller.pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: Text(l10n.pickFromGallery),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ShopSection extends ConsumerWidget {
  const _ShopSection({
    required this.state,
    required this.nameController,
    required this.onSelect,
  });

  final RecordState state;
  final TextEditingController nameController;
  final ValueChanged<ShopCandidate> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(recordControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final selected = state.selectedShop;
    final shops = [
      ...state.candidates,
      if (selected != null && !state.candidates.contains(selected)) selected,
    ];
    final message = _message(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.searchStatus == ShopSearchStatus.searching)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text(l10n.shopSearching),
          ),
        for (final shop in shops)
          _ShopTile(
            shop: shop,
            selected: identical(shop, selected),
            onTap: () => onSelect(shop),
          ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(message, style: textTheme.bodySmall),
          ),
        if (state.searchStatus == ShopSearchStatus.done &&
            state.searchFailure != ShopSearchFailure.noLocation)
          Align(
            alignment: Alignment.centerRight,
            child: Text(l10n.osmAttribution, style: textTheme.labelSmall),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: nameController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.shopNameLabel,
            hintText: l10n.shopNameHint,
          ),
          onChanged: controller.setManualName,
        ),
        for (final shop in state.nameMatches)
          _ShopTile(shop: shop, selected: false, onTap: () => onSelect(shop)),
      ],
    );
  }

  String? _message(AppLocalizations l10n) {
    if (state.searchStatus != ShopSearchStatus.done) return null;
    return switch (state.searchFailure) {
      ShopSearchFailure.noLocation => l10n.shopNoLocation,
      ShopSearchFailure.searchFailed when state.candidates.isEmpty =>
        l10n.shopSearchFailed,
      null when state.candidates.isEmpty => l10n.shopNoCandidates,
      _ => null,
    };
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.shop,
    required this.selected,
    required this.onTap,
  });

  final ShopCandidate shop;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final distance = shop.distanceMeters;
    final details = [
      if (distance != null) l10n.distanceMeters(distance.round()),
      if (shop.shopId != null) l10n.shopVisited,
    ];
    return Card(
      elevation: 0,
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          selected ? Icons.check_circle : Icons.storefront,
          color: selected ? colors.primary : null,
        ),
        title: Text(shop.name),
        subtitle: details.isEmpty ? null : Text(details.join('・')),
        onTap: onTap,
      ),
    );
  }
}

class _OptionalSection extends ConsumerWidget {
  const _OptionalSection({required this.state, required this.memoController});

  final RecordState state;
  final TextEditingController memoController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(recordControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.styleSection, style: textTheme.labelLarge),
        Wrap(
          spacing: 8,
          children: [
            for (final style in RamenStyle.values)
              ChoiceChip(
                label: Text(styleLabel(l10n, style)),
                selected: state.style == style,
                onSelected: (selected) =>
                    controller.setStyle(selected ? style : null),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.isLimited),
          value: state.isLimited,
          onChanged: controller.setLimited,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.hasTicket),
          value: state.hasTicket,
          onChanged: controller.setHasTicket,
        ),
        const SizedBox(height: 8),
        Text(l10n.hoursSection, style: textTheme.labelLarge),
        const SizedBox(height: 4),
        SegmentedButton<HoursType>(
          showSelectedIcon: false,
          segments: [
            for (final type in HoursType.values)
              ButtonSegment(
                value: type,
                label: Text(hoursTypeLabel(l10n, type)),
              ),
          ],
          selected: {state.hoursType},
          onSelectionChanged: (selection) =>
              controller.setHoursType(selection.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: memoController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.memoLabel,
          ),
          onChanged: controller.setMemo,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
