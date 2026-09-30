import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../record/star_rating.dart';
import '../records/clock.dart';
import '../records/date_format.dart';
import '../records/models.dart';
import '../records/record_repository.dart';
import '../records/visit_details_form.dart';

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
  late DateTime _eatenAt = widget.entry.visit.eatenAt;
  late int? _rating = widget.entry.visit.rating;
  late RamenStyle? _style = widget.entry.visit.style;
  late bool _isLimited = widget.entry.visit.isLimited;
  late bool _hasTicket = widget.entry.visit.hasTicket;
  late HoursType _hoursType = widget.entry.shop.hoursType;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
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

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(recordRepositoryProvider)
          .updateVisit(
            visitId: widget.entry.visit.id,
            shopName: _nameController.text,
            hoursType: _hoursType,
            eatenAt: _eatenAt,
            rating: _rating,
            style: _style,
            isLimited: _isLimited,
            hasTicket: _hasTicket,
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
    final textTheme = Theme.of(context).textTheme;
    final isEaten = widget.entry.visit.result == VisitResult.eaten;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.editShopName,
            ),
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
            Text(l10n.ratingSection, style: textTheme.titleMedium),
            StarRating(
              rating: _rating,
              onChanged: (rating) => setState(() => _rating = rating),
            ),
          ],
          const SizedBox(height: 8),
          VisitDetailsForm(
            style: _style,
            isLimited: _isLimited,
            hasTicket: _hasTicket,
            hoursType: _hoursType,
            memoController: _memoController,
            onStyleChanged: (style) => setState(() => _style = style),
            onLimitedChanged: (value) => setState(() => _isLimited = value),
            onHasTicketChanged: (value) => setState(() => _hasTicket = value),
            onHoursTypeChanged: (type) => setState(() => _hoursType = type),
            onMemoChanged: (_) {},
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
            ),
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
