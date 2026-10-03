import 'package:flutter/material.dart';

import 'package:ramen_in_cho/l10n/app_localizations.dart';

final ja = lookupAppLocalizations(const Locale('ja'));

MaterialApp localizedApp({required Widget home, ThemeData? theme}) =>
    MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme,
      home: home,
    );
