import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/washi.dart';
import '../../l10n/app_localizations.dart';
import '../record/star_rating.dart';
import '../records/clock.dart';
import '../records/date_format.dart';
import '../records/models.dart';
import '../records/record_repository.dart';
import '../records/visit_details_form.dart';
import '../records/wait_time.dart';
import '../../theme/washi_buttons.dart';

class VisitEditScreen extends ConsumerStatefulWidget {
  const VisitEditScreen({super.key, required this.entry});

  final VisitWithShop entry;

  @override
  ConsumerState<VisitEditScreen> createState() => _VisitEditScreenState();
}

class _VisitEditScreenState extends ConsumerState<VisitEditScreen> {
  late final _nameController = TextEditingController(
    text: widget.entry.shop.name,
  );
  late final _memoController = TextEditingController(
    text: widget.entry.visit.memo,
  );
  late final _waitController = TextEditingController(
    text: waitMinutes(widget.entry.visit)?.toString() ?? '',
  );
  late DateTime _eatenAt = widget.entry.visit.eatenAt;
  late int? _rating = widget.entry.visit.rating;
  late RamenStyle? _style = widget.entry.visit.style;
  late bool _isLimited = widget.entry.visit.isLimited;
  late Set<HoursCondition> _hoursConditions = widget.entry.shop.hoursConditions;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    _waitController.dispose();
    super.dispose();
  }

  Future<void> _pickEatenAt() async {
    final now = ref.read(clockProvider)();
    final date = await showDatePicker(
      context: context,
      initialDate: _eatenAt,
      firstDate: DateTime(2000),
      lastDate: now.isAfter(_eatenAt) ? now : _eatenAt,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eatenAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _eatenAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  /// 待ち時間に触っていなければ、並んだ時刻を食べた日時と一緒にずらすだけにする
  /// （秒や0分の待ち時間を保つため）。撤退の記録は待ち時間を入れないので変えない。
  DateTime? _checkedInAt() {
    final original = widget.entry.visit;
    final checkedInAt = original.checkedInAt;
    final initialText = waitMinutes(original)?.toString() ?? '';
    if (original.result != VisitResult.eaten ||
        _waitController.text == initialText) {
      return checkedInAt?.add(_eatenAt.difference(original.eatenAt));
    }
    final minutes = parseWaitMinutes(_waitController.text);
    return minutes == null
        ? null
        : _eatenAt.subtract(Duration(minutes: minutes));
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(recordRepositoryProvider)
          .updateVisit(
            visitId: widget.entry.visit.id,
            shopName: _nameController.text,
            hoursConditions:
                setEquals(_hoursConditions, widget.entry.shop.hoursConditions)
                ? null
                : _hoursConditions,
            eatenAt: _eatenAt,
            checkedInAt: _checkedInAt(),
            rating: _rating,
            style: _style,
            isLimited: _isLimited,
            hasTicket: widget.entry.visit.hasTicket,
            memo: _memoController.text.trim(),
            now: ref.read(clockProvider)(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Visit update failed: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).editSaveFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEaten = widget.entry.visit.result == VisitResult.eaten;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: l10n.editShopName),
            onChanged: (_) => setState(() {}),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(l10n.editEatenAt),
            subtitle: Text(formatDateTime(_eatenAt)),
            onTap: _pickEatenAt,
          ),
          if (isEaten) ...[
            SectionTitle(l10n.ratingSection),
            Center(
              child: StarRating(
                rating: _rating,
                onChanged: (rating) => setState(() => _rating = rating),
              ),
            ),
          ],
          const SizedBox(height: 8),
          VisitDetailsForm(
            style: _style,
            isLimited: _isLimited,
            hoursConditions: _hoursConditions,
            memoController: _memoController,
            onStyleChanged: (style) => setState(() => _style = style),
            onLimitedChanged: (value) => setState(() => _isLimited = value),
            onHoursConditionsChanged: (conditions) =>
                setState(() => _hoursConditions = conditions),
            onMemoChanged: (_) {},
            waitController: isEaten ? _waitController : null,
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AiFuda(
            expand: true,
            height: 56,
            onPressed: _isSaving || _nameController.text.trim().isEmpty
                ? null
                : _save,
            child: Text(l10n.editSave),
          ),
        ),
      ),
    );
  }
}
