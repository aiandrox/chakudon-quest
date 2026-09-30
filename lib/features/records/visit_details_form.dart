import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'labels.dart';
import 'models.dart';

/// 系統・限定・整理券・営業の条件・メモの入力欄。記録画面と編集画面で共有する。
class VisitDetailsForm extends StatelessWidget {
  const VisitDetailsForm({
    super.key,
    required this.style,
    required this.isLimited,
    required this.hasTicket,
    required this.hoursConditions,
    required this.memoController,
    required this.onStyleChanged,
    required this.onLimitedChanged,
    required this.onHasTicketChanged,
    required this.onHoursConditionsChanged,
    required this.onMemoChanged,
  });

  final RamenStyle? style;
  final bool isLimited;
  final bool hasTicket;
  final Set<HoursCondition> hoursConditions;
  final TextEditingController memoController;
  final ValueChanged<RamenStyle?> onStyleChanged;
  final ValueChanged<bool> onLimitedChanged;
  final ValueChanged<bool> onHasTicketChanged;
  final ValueChanged<Set<HoursCondition>> onHoursConditionsChanged;
  final ValueChanged<String> onMemoChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.styleSection, style: textTheme.labelLarge),
        Wrap(
          spacing: 8,
          children: [
            for (final option in RamenStyle.values)
              ChoiceChip(
                label: Text(styleLabel(l10n, option)),
                selected: style == option,
                onSelected: (selected) =>
                    onStyleChanged(selected ? option : null),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.isLimited),
          value: isLimited,
          onChanged: onLimitedChanged,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.hasTicket),
          value: hasTicket,
          onChanged: onHasTicketChanged,
        ),
        const SizedBox(height: 8),
        Text(l10n.hoursSection, style: textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(l10n.hoursNote, style: textTheme.bodySmall),
        Wrap(
          spacing: 8,
          children: [
            for (final condition in HoursCondition.values)
              FilterChip(
                label: Text(hoursConditionLabel(l10n, condition)),
                selected: hoursConditions.contains(condition),
                onSelected: (selected) => onHoursConditionsChanged({
                  for (final other in hoursConditions)
                    if (other != condition) other,
                  if (selected) condition,
                }),
              ),
          ],
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
          onChanged: onMemoChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
