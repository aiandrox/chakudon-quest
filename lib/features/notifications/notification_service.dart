import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

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

  /// 通知の許可を尋ねる（まだ尋ねていないときだけ、OSが画面を出す）。
  Future<void> requestPermission();

  /// 連続記録が途切れそうなことを[at]に知らせる。前の予約は置き換える。
  Future<void> scheduleStreakReminder({
    required DateTime at,
    required String title,
    required String body,
  });

  Future<void> cancelStreakReminder();
}

const _checkinNotificationId = 1;
const _streakNotificationId = 2;

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
          // アプリを開いている最中に出すので、上から出るバナーは出さず通知センターにだけ置く。
          iOS: const DarwinNotificationDetails(
            presentAlert: false,
            presentBanner: false,
            presentSound: false,
            presentList: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Checkin notification failed: $e');
    }
  }

  @override
  Future<void> requestPermission() async {
    try {
      await _initialize();
      await _requestPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }

  @override
  Future<void> scheduleStreakReminder({
    required DateTime at,
    required String title,
    required String body,
  }) async {
    try {
      await _initialize();
      await _plugin.zonedSchedule(
        id: _streakNotificationId,
        // 1回きりの通知は時刻そのもの（瞬間）で決まるので、端末のタイムゾーン名を
        // 調べなくてもUTCで表せば端末の[at]どおりに届く。
        scheduledDate: tz.TZDateTime.from(at, tz.UTC),
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak',
            '連続記録',
            channelDescription: '連続記録が途切れそうなときのお知らせ',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // 正確な時刻の予約には追加の許可が要るため、多少ずれてもよい方式にする。
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Streak reminder schedule failed: $e');
    }
  }

  @override
  Future<void> cancelStreakReminder() async {
    try {
      await _initialize();
      await _plugin.cancel(id: _streakNotificationId);
    } catch (e) {
      debugPrint('Streak reminder cancel failed: $e');
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
