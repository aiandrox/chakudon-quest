import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../records/photo_storage.dart';

final onboardingStoreProvider = Provider<OnboardingStore>(
  (ref) => OnboardingStore(ref.watch(documentsDirectoryProvider)),
);

/// 起動したときに案内を出すか。テストでは出さない。
final showOnboardingOnLaunchProvider = Provider<bool>((ref) => true);

/// 案内を終えた（閉じた）かを、documents の `onboarding.json` に残す。
class OnboardingStore {
  OnboardingStore(this._documents);

  static const fileName = 'onboarding.json';

  final Directory _documents;

  File get _file => File(p.join(_documents.path, fileName));

  Future<bool> isCompleted() async {
    try {
      final json = jsonDecode(await _file.readAsString());
      return json is Map<String, dynamic> && json['completedAt'] is String;
    } on FileSystemException {
      return false;
    } on FormatException {
      return false;
    }
  }

  Future<void> markCompleted(DateTime now) => _file.writeAsString(
    jsonEncode({'completedAt': now.toUtc().toIso8601String()}),
  );
}
