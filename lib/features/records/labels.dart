import '../../l10n/app_localizations.dart';
import 'models.dart';

String styleLabel(AppLocalizations l10n, RamenStyle style) => switch (style) {
  RamenStyle.shoyu => l10n.styleShoyu,
  RamenStyle.miso => l10n.styleMiso,
  RamenStyle.shio => l10n.styleShio,
  RamenStyle.tonkotsu => l10n.styleTonkotsu,
  RamenStyle.iekei => l10n.styleIekei,
  RamenStyle.jiro => l10n.styleJiro,
  RamenStyle.tsukemen => l10n.styleTsukemen,
  RamenStyle.shirunashi => l10n.styleShirunashi,
  RamenStyle.other => l10n.styleOther,
};

String hoursConditionLabel(AppLocalizations l10n, HoursCondition condition) =>
    switch (condition) {
      HoursCondition.lunchOnly => l10n.hoursLunchOnly,
      HoursCondition.nightOnly => l10n.hoursNightOnly,
      HoursCondition.weekdaysOnly => l10n.hoursWeekdaysOnly,
      HoursCondition.weekendsOnly => l10n.hoursWeekendsOnly,
      HoursCondition.fewDays => l10n.hoursFewDays,
      HoursCondition.irregular => l10n.hoursIrregular,
      HoursCondition.badAccess => l10n.hoursBadAccess,
    };

/// 条件を定義順に並べて「・」でつなぐ。
String hoursConditionsLabel(
  AppLocalizations l10n,
  Set<HoursCondition> conditions,
) => [
  for (final condition in HoursCondition.values)
    if (conditions.contains(condition)) hoursConditionLabel(l10n, condition),
].join('・');
