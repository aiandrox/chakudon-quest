import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/washi.dart';
import '../checkin/checkin_rules.dart';
import '../records/clock.dart';
import '../records/date_format.dart';
import '../records/visit_details_form.dart';
import '../shop_search/shop_candidate.dart';
import '../shop_search/shop_search_service.dart';
import '../shop_search/shop_tile.dart';
import 'record_controller.dart';
import 'record_result_screen.dart';
import 'record_state.dart';
import 'star_rating.dart';

/// 保存できたら、得たポイントを見せる画面に切り替わる。
class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key, this.recoveredPhotoPath});

  final String? recoveredPhotoPath;

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  final _nameController = TextEditingController();
  final _memoController = TextEditingController();
  final _waitController = TextEditingController();

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
    _waitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final visitId = await ref.read(recordControllerProvider.notifier).save();
    if (!mounted) return;
    if (visitId != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RecordResultScreen(visitId: visitId),
        ),
      );
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recordTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _PhotoSection(state: state),
          const SizedBox(height: 16),
          SectionTitle(l10n.shopSection),
          _ShopSection(
            state: state,
            nameController: _nameController,
            onSelect: _selectShop,
          ),
          const SizedBox(height: 16),
          SectionTitle(l10n.ratingOptional),
          Center(
            child: StarRating(
              rating: state.rating,
              onChanged: controller.setRating,
            ),
          ),
          ExpansionTile(
            initiallyExpanded: true,
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.optionalSection),
            children: [
              VisitDetailsForm(
                style: state.style,
                isLimited: state.isLimited,
                hoursConditions: state.hoursConditions,
                memoController: _memoController,
                onStyleChanged: controller.setStyle,
                onLimitedChanged: controller.setLimited,
                onHoursConditionsChanged: controller.setHoursConditions,
                onMemoChanged: controller.setMemo,
                // 並んだ店を選んでいれば、待ち時間は並んだ時刻から自動で計算する。
                waitController: state.isCheckinShopSelected
                    ? null
                    : _waitController,
                onWaitChanged: controller.setWaitMinutes,
              ),
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
              minimumSize: const Size.fromHeight(60),
              textStyle: const TextStyle(
                fontFamily: Washi.brush,
                fontSize: 26,
                letterSpacing: 4,
              ),
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
        if (hasPhoto) ...[
          PastedPhoto(
            border: 6,
            child: SizedBox(
              height: 220,
              child: Image.file(File(photoPath), fit: BoxFit.cover),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: controller.takePhoto,
                  icon: const Icon(Icons.photo_camera),
                  label: Text(l10n.retakePhoto),
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
        ] else
          // 写真は任意。片手で押しやすいよう、大きなボタンを2つ並べる。
          Row(
            children: [
              Expanded(
                child: _PhotoButton(
                  icon: Icons.photo_camera,
                  label: l10n.takePhoto,
                  onPressed: controller.takePhoto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PhotoButton(
                  icon: Icons.photo_library,
                  label: l10n.pickFromGallery,
                  onPressed: controller.pickFromGallery,
                ),
              ),
            ],
          ),
        if (state.photoDateFromPhoto)
          if (state.photoTakenAt case final takenAt?)
            Text(
              l10n.recordPhotoDate(formatDateTime(takenAt)),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
      ],
    );
  }
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(120),
        backgroundColor: Washi.page,
        side: const BorderSide(color: Washi.line),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
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
    final checkinShop = state.checkinShop;
    final candidates = [
      for (final shop in state.candidates)
        if (checkinShop == null || !isSameShop(shop, checkinShop)) shop,
    ];
    final shops = [
      ?checkinShop,
      ...candidates,
      if (selected != null &&
          !state.isCheckinShopSelected &&
          !candidates.contains(selected))
        selected,
    ];
    final checkin = state.checkin;
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
          ShopTile(
            shop: shop,
            selected: identical(shop, checkinShop)
                ? state.isCheckinShopSelected
                : identical(shop, selected),
            note: checkin != null && identical(shop, checkinShop)
                ? l10n.checkinWaiting(
                    checkinElapsedMinutes(
                      checkin,
                      state.photoTakenAt ?? ref.watch(currentTimeProvider),
                    ),
                  )
                : null,
            onTap: () => onSelect(shop),
          ),
        if (selected?.strategyMemo case final memo? when memo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(l10n.shopMemoInline(memo), style: textTheme.bodyMedium),
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
            child: Text(
              l10n.shopSearchAttribution,
              style: textTheme.labelSmall,
            ),
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
          ShopTile(shop: shop, selected: false, onTap: () => onSelect(shop)),
      ],
    );
  }

  String? _message(AppLocalizations l10n) {
    // 店が決まっていれば、店名の入力を促す案内は要らない。
    if (state.searchStatus != ShopSearchStatus.done || state.hasShop) {
      return null;
    }
    return switch (state.searchFailure) {
      ShopSearchFailure.noLocation => l10n.shopNoLocation,
      ShopSearchFailure.searchFailed when state.candidates.isEmpty =>
        l10n.shopSearchFailed,
      ShopSearchFailure.searchFailed => l10n.shopSearchPartial,
      null when state.candidates.isEmpty => l10n.shopNoCandidates,
      _ => null,
    };
  }
}
