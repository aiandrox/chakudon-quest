import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import 'labels.dart';
import 'models.dart';

/// 系統・限定・攻略しにくさ・メモの入力欄。記録画面と編集画面で共有する。
class VisitDetailsForm extends StatelessWidget {
  const VisitDetailsForm({
    super.key,
    required this.style,
    required this.isLimited,
    required this.hoursConditions,
    required this.memoController,
    required this.onStyleChanged,
    required this.onLimitedChanged,
    required this.onHoursConditionsChanged,
    required this.onMemoChanged,
    this.waitController,
    this.onWaitChanged,
  });

  final RamenStyle? style;
  final bool isLimited;
  final Set<HoursCondition> hoursConditions;
  final TextEditingController memoController;
  final ValueChanged<RamenStyle?> onStyleChanged;
  final ValueChanged<bool> onLimitedChanged;
  final ValueChanged<Set<HoursCondition>> onHoursConditionsChanged;
  final ValueChanged<String> onMemoChanged;

  /// 待ち時間（分）の入力欄。nullなら出さない（並んだ時刻から自動で計算するときなど）。
  final TextEditingController? waitController;
  final ValueChanged<int?>? onWaitChanged;

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
        if (waitController case final controller?) ...[
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.waitMinutesLabel,
              helperText: l10n.waitMinutesHint,
              helperMaxLines: 2,
              suffixText: l10n.waitMinutesUnit,
            ),
            onChanged: (text) => onWaitChanged?.call(parseWaitMinutes(text)),
          ),
          const SizedBox(height: 8),
        ],
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

/// 入力された待ち時間（分）。空や0はnull（並ばなかった）。
int? parseWaitMinutes(String text) {
  final minutes = int.tryParse(text.trim());
  return minutes == null || minutes <= 0 ? null : minutes;
}
