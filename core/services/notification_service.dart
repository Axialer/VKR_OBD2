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
    Future<void> Function(int opId, String stage)? persistStage,
  }) async {
    if (!_inited) await init();
    if (!enabled) return;

    for (final op in rows) {
      final stage = _notificationStage(op, car.currentMileage);
      if (stage == null) continue;
      if (op.lastNotifiedStage == stage) continue;

      final st = maintenanceStatus(op, car.currentMileage);
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
        op.id,
        st == MaintUiStatus.overdue ? 'Просрочено ТО' : 'Скоро ТО',
        _body(op, st, car),
        details,
      );
      if (persistStage != null) {
        await persistStage(op.id, stage);
      }
    }
  }

  String? _notificationStage(MaintenanceRow op, int currentMileage) {
    if (op.intervalType == 'date') {
      final next = op.nextDueDate;
      if (next == null) return null;
      final days = next.difference(DateTime.now()).inDays;
      if (days <= 0) return 'date_overdue';
      if (days <= 1) return 'date_d1';
      if (days <= 3) return 'date_d3';
      if (days <= 5) return 'date_d5';
      if (days <= 7) return 'date_d7';
      return null;
    }

    final next = op.nextDueMileage;
    if (next == null) return null;
    final left = next - currentMileage;
    if (left <= 0) return 'km_overdue';
    if (left > 10000) return null;
    final bucket = ((left + 4999) ~/ 5000) * 5000;
    if (bucket <= 0) return 'km_0';
    return 'km_$bucket';
  }
}
