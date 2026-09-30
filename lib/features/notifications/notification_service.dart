import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../checkin/checkin_rules.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => LocalNotificationService(),
);

abstract class NotificationService {
  /// 並んでいる間の通知。Androidでは消えない通知にして経過時間を数え続ける。
  Future<void> showCheckin({
    required String title,
    required String body,
    required DateTime checkedInAt,
  });

  Future<void> cancelCheckin();
}

const _checkinNotificationId = 1;

int? _remainingUntilTimeout(DateTime checkedInAt) {
  final remaining = checkedInAt
      .add(checkinTimeout)
      .difference(DateTime.now())
      .inMilliseconds;
  return remaining > 0 ? remaining : null;
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  Future<void>? _permissionRequest;

  Future<void> _initialize() => _initialization ??= () async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  /// 許可は、初めて通知を出すとき（並んだとき）に尋ねる。起動しただけでは尋ねない。
  Future<void> _requestPermission() => _permissionRequest ??= () async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true);
  }();

  @override
  Future<void> showCheckin({
    required String title,
    required String body,
    required DateTime checkedInAt,
  }) async {
    try {
      await _initialize();
      await _requestPermission();
      await _plugin.show(
        id: _checkinNotificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'checkin',
            '並んでいる店',
            channelDescription: 'チェックイン中の経過時間',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            silent: true,
            showWhen: true,
            when: checkedInAt.millisecondsSinceEpoch,
            usesChronometer: true,
            // アプリを開かないまま3時間を過ぎても、自動の取り消しに合わせて消えるようにする。
            timeoutAfter: _remainingUntilTimeout(checkedInAt),
          ),
          iOS: const DarwinNotificationDetails(presentSound: false),
        ),
      );
    } catch (e) {
      debugPrint('Checkin notification failed: $e');
    }
  }

  @override
  Future<void> cancelCheckin() async {
    try {
      await _initialize();
      await _plugin.cancel(id: _checkinNotificationId);
    } catch (e) {
      debugPrint('Checkin notification cancel failed: $e');
    }
  }
}
