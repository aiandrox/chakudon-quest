import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../records/labels.dart';
import '../records/models.dart';

/// 店の攻略しにくさの条件を、いくつでも選ぶ札。
class HoursConditionChips extends StatelessWidget {
  const HoursConditionChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<HoursCondition> selected;
  final ValueChanged<Set<HoursCondition>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      children: [
        for (final condition in HoursCondition.values)
          FilterChip(
            label: Text(hoursConditionLabel(l10n, condition)),
            selected: selected.contains(condition),
            onSelected: (on) => onChanged({
              for (final other in selected)
                if (other != condition) other,
              if (on) condition,
            }),
          ),
      ],
    );
  }
}

/// 店の条件を選び直す。保存するなら選んだ条件、やめるならnullを返す。
Future<Set<HoursCondition>?> showShopConditionsDialog(
  BuildContext context,
  Set<HoursCondition> initial,
) => showDialog<Set<HoursCondition>>(
  context: context,
  builder: (_) => _ShopConditionsDialog(initial: initial),
);

class _ShopConditionsDialog extends StatefulWidget {
  const _ShopConditionsDialog({required this.initial});

  final Set<HoursCondition> initial;

  @override
  State<_ShopConditionsDialog> createState() => _ShopConditionsDialogState();
}

class _ShopConditionsDialogState extends State<_ShopConditionsDialog> {
  late Set<HoursCondition> _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.shopConditionsSection),
      content: SingleChildScrollView(
        child: HoursConditionChips(
          selected: _selected,
          onChanged: (conditions) => setState(() => _selected = conditions),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.editSave),
        ),
      ],
    );
  }
}
