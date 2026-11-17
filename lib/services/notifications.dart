import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:verdant/data/care_schedule.dart';
import 'package:verdant/data/settings.dart';

/// Phone notifications for care reminders (Android only).
///
/// The schedule is the source of truth: every time it or the push setting
/// changes, pending notifications are cancelled and the next ones are
/// scheduled again (up to [_maxScheduled], within [_horizon]).
abstract final class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static String? _timeZone;

  static const _maxScheduled = 40;
  static const _horizon = Duration(days: 30);
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'care_reminders',
      'Care reminders',
      channelDescription: 'Gentle nudges when a plant needs care.',
    ),
  );

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// IANA id of the phone's time zone (e.g. "Europe/Rome"), once known.
  static String? get timeZone => _timeZone;

  static Future<void> init() async {
    if (!_supported) return;
    try {
      tz_data.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      final location = _locationFor(info.identifier);
      _timeZone = location.name;
      tz.setLocalLocation(location);
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
      return;
    }
    careSchedule.addListener(sync);
    appSettings.addListener(sync);
    await sync();
  }

  /// Maps the phone's zone id to the tz database. Some devices report
  /// aliases such as "GMT"; fall back to a zone with the same offset.
  static tz.Location _locationFor(String id) {
    try {
      return tz.getLocation(id);
    } catch (_) {
      if (const {'GMT', 'UTC', 'Z'}.contains(id.toUpperCase())) {
        return tz.getLocation('Etc/UTC');
      }
      final offset = DateTime.now().timeZoneOffset;
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.timeZone(now).offset == offset) return loc;
      }
      return tz.getLocation('Etc/UTC');
    }
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Asks Android 13+ for permission. Returns true when allowed.
  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    return await _android?.requestNotificationsPermission() ?? false;
  }

  static Future<bool> areEnabled() async {
    if (!_ready) return false;
    return await _android?.areNotificationsEnabled() ?? false;
  }

  static Future<void> sync() async {
    if (!_ready) return;
    await _plugin.cancelAll();
    if (!appSettings.push) return;

    final now = DateTime.now();
    final tasks = careSchedule
        .tasksBetween(now, now.add(_horizon))
        .where((t) => t.plan.push && t.due.isAfter(now))
        .take(_maxScheduled);

    var id = 0;
    for (final task in tasks) {
      await _plugin.zonedSchedule(
        id: id++,
        scheduledDate: tz.TZDateTime.from(task.due, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: task.title,
        body: task.plan.note ?? 'A gentle nudge from Verdant.',
      );
    }
  }
}
