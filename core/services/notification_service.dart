import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/models/autodiag_models.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _inited = true;
  }

  Future<bool?> requestAndroidPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return android?.requestNotificationsPermission();
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Проверка канала уведомлений вручную.
  Future<void> showTestNotification() async {
    if (!_inited) await init();
    const android = AndroidNotificationDetails(
      'autodiag_test',
      'Проверка',
      channelDescription: 'Тестовое уведомление AutoDiag',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      999001,
      'AutoDiag',
      'Тестовое уведомление: канал работает.',
      const NotificationDetails(android: android),
    );
  }

  static String _body(MaintenanceRow op, MaintUiStatus st, Car car) {
    if (op.intervalType == 'mileage') {
      final next = op.nextDueMileage;
      if (next == null) return op.title;
      final left = next - car.currentMileage;
      if (st == MaintUiStatus.overdue) {
        return '${op.title}: пробег просрочен (цель $next км)';
      }
      return '${op.title}: осталось примерно $left км до $next км';
    }
    final next = op.nextDueDate;
    if (next == null) return op.title;
    final days = next.difference(DateTime.now()).inDays;
    if (st == MaintUiStatus.overdue) {
      return '${op.title}: срок по дате прошёл';
    }
    return '${op.title}: осталось примерно $days дн.';
  }

  /// Показать напоминания по операциям «скоро» или «просрочено» (на старте / обновлении списка).
  Future<void> syncMaintenanceNotifications({
    required bool enabled,
    required List<MaintenanceRow> rows,
    required Car car,
  }) async {
    if (!_inited) await init();
    await cancelAll();
    if (!enabled) return;

    var i = 0;
    for (final op in rows) {
      final st = maintenanceStatus(op, car.currentMileage);
      if (st == MaintUiStatus.ok) continue;
      final android = AndroidNotificationDetails(
        'autodiag_to',
        'Техобслуживание',
        channelDescription: 'Напоминания о плановом ТО',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: BigTextStyleInformation(
          _body(op, st, car),
        ),
      );
      final details = NotificationDetails(android: android);
      await _plugin.show(
        op.id + 1000 * i,
        st == MaintUiStatus.overdue ? 'Просрочено ТО' : 'Скоро ТО',
        _body(op, st, car),
        details,
      );
      i++;
    }
  }
}
