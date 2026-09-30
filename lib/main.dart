import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'features/home/app_shell.dart';
import 'features/records/photo_storage.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final documents = await getApplicationDocumentsDirectory();
  runApp(
    ProviderScope(
      overrides: [documentsDirectoryProvider.overrideWithValue(documents)],
      child: const ChakudonQuestApp(),
    ),
  );
}

class ChakudonQuestApp extends StatelessWidget {
  const ChakudonQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      // 日本語に固定しないと、Androidが漢字を中国語系のグリフで描画することがある。
      locale: const Locale('ja'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      home: const AppShell(),
    );
  }
}
