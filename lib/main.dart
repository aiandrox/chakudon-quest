import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'features/home/app_shell.dart';
import 'features/records/photo_storage.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicenses);
  final documents = await getApplicationDocumentsDirectory();
  runApp(
    ProviderScope(
      overrides: [documentsDirectoryProvider.overrideWithValue(documents)],
      child: const RamenInChoApp(),
    ),
  );
}

Stream<LicenseEntry> _fontLicenses() async* {
  for (final font in ['ShipporiMincho', 'YujiSyuku']) {
    yield LicenseEntryWithLineBreaks([
      font,
    ], await rootBundle.loadString('assets/fonts/$font-OFL.txt'));
  }
}

class RamenInChoApp extends StatelessWidget {
  const RamenInChoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      // 日本語に固定しないと、Androidが漢字を中国語系のグリフで描画することがある。
      locale: const Locale('ja'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}
