import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/export_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/autodiag_repository.dart';
import '../../../data/models/autodiag_models.dart';
import '../../providers/cars_provider.dart';
import '../../providers/diagnostics_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/settings_provider.dart';
import 'add_car_wizard.dart';
import 'edit_car_screen.dart';

class CarsTab extends StatelessWidget {
  const CarsTab({super.key});

  Future<void> afterDataChange(BuildContext context) async {
    await context.read<CarsProvider>().refresh();
    if (!context.mounted) return;
    await context.read<HistoryProvider>().refresh();
    final a = context.read<CarsProvider>().active;
    await context.read<MaintenanceProvider>().loadForCar(
          a?.id,
          a,
          context.read<SettingsProvider>().maintenanceNotify,
        );
    if (context.read<SettingsProvider>().obdSimulation) {
      await context.read<DiagnosticsProvider>().startSimulation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cars = context.watch<CarsProvider>();
    final settings = context.watch<SettingsProvider>();
    final export = context.read<ExportService>();
    final repo = context.read<AutodiagRepository>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Автомобили',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _addCar(context),
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (cars.cars.isEmpty)
          const Text('Список пуст — добавьте первый автомобиль.'),
        ...cars.cars.map((c) {
          final isDemo = c.vin == AutodiagRepository.kDemoVin;
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: Radio<int>(
                value: c.id,
                groupValue: cars.active?.id,
                onChanged: (v) async {
                  if (v == null) return;
                  await cars.setActive(v);
                  if (!context.mounted) return;
                  final a = context.read<CarsProvider>().active;
                  await context.read<MaintenanceProvider>().loadForCar(
                        a?.id,
                        a,
                        context.read<SettingsProvider>().maintenanceNotify,
                      );
                },
              ),
              title: Text(c.displayName),
              subtitle: Text(
                'Пробег: ${c.currentMileage} км${isDemo ? ' · демо-образец' : ''}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune),
                    tooltip: 'Пробег',
                    onPressed: () => _editMileage(context, c.id, c.currentMileage),
                  ),
                  if (!isDemo)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Редактировать',
                      onPressed: () => _editCar(context, c),
                    ),
                  if (!isDemo)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Удалить',
                      onPressed: () => _deleteCar(context, c.id),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Демонстрация и тесты',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Загружает автомобиль «Demo AutoDiag», операции ТО и сеанс в истории — '
                  'удобно без ELM327. Включите ниже «Демо OBD» для симуляции параметров.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () async {
                        await repo.seedDemoData();
                        if (!context.mounted) return;
                        await afterDataChange(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Демо-данные загружены')),
                        );
                      },
                      child: const Text('Загрузить демо'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await repo.removeDemoData();
                        if (!context.mounted) return;
                        await afterDataChange(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Демо-авто удалено')),
                        );
                      },
                      child: const Text('Удалить демо'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          secondary: const Icon(Icons.science_outlined),
          title: const Text('Демо OBD без адаптера'),
          subtitle: const Text(
              'Имитация DTC и PID на вкладке «Диагностика» (без Bluetooth)'),
          value: settings.obdSimulation,
          onChanged: (v) async {
            await settings.setObdSimulation(v);
            if (!context.mounted) return;
            final diag = context.read<DiagnosticsProvider>();
            if (v) {
              await diag.startSimulation();
            } else {
              await diag.disconnect();
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications_active_outlined),
          title: const Text('Проверить уведомления'),
          subtitle: const Text('Показать тестовое сообщение (как при ТО)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await NotificationService.instance.showTestNotification();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Если не видно — проверьте разрешения и каналы Android')),
              );
            }
          },
        ),
        const Divider(height: 32),
        Text('Тема', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('Авто'),
              icon: Icon(Icons.brightness_auto, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Светлая'),
              icon: Icon(Icons.light_mode, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Тёмная'),
              icon: Icon(Icons.dark_mode, size: 18),
            ),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (s) {
            if (s.isEmpty) return;
            settings.setThemeMode(s.first);
          },
        ),
        const Divider(height: 32),
        Text('Прочее', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SwitchListTile(
          secondary: const Icon(Icons.straighten),
          title: const Text('Метрические единицы'),
          subtitle: const Text('км, °C'),
          value: settings.metricUnits,
          onChanged: (v) => settings.setMetric(v),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.bluetooth),
          title: const Text('Автоподключение к последнему адаптеру'),
          value: settings.autoConnectBt,
          onChanged: settings.obdSimulation ? null : (v) => settings.setAutoConnect(v),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.save_outlined),
          title: const Text('Автосохранение сеанса при выходе с OBD'),
          value: settings.autoSaveSessionOnLeave,
          onChanged: (v) => settings.setAutoSaveSession(v),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('Уведомления о ТО'),
          value: settings.maintenanceNotify,
          onChanged: (v) async {
            await settings.setMaintenanceNotify(v);
            if (!context.mounted) return;
            final a = context.read<CarsProvider>().active;
            await context.read<MaintenanceProvider>().loadForCar(
                  a?.id,
                  a,
                  settings.maintenanceNotify,
                );
          },
        ),
        ListTile(
          leading: const Icon(Icons.speed),
          title: const Text('Интервал опроса PID'),
          subtitle: Slider(
            value: settings.pidPollMs.toDouble(),
            min: 500,
            max: 5000,
            divisions: 9,
            label: '${(settings.pidPollMs / 1000).toStringAsFixed(1)} с',
            onChanged: settings.obdSimulation
                ? null
                : (v) => settings.setPidPollMs(v.round()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.ios_share),
          title: const Text('Экспорт истории и ТО (CSV)'),
          onTap: () async {
            final f = await export.exportHistoryAndMaintenanceCsv();
            await export.shareCsv(f);
          },
        ),
        ListTile(
          leading: const Icon(Icons.save_alt),
          title: const Text('Резервная копия базы (.db)'),
          onTap: () async {
            final f = await export.copyDatabaseBackup();
            await export.shareDb(f);
          },
        ),
      ],
    );
  }

  Future<void> _addCar(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddCarWizard(),
      ),
    );
  }

  Future<void> _editCar(BuildContext context, Car car) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditCarScreen(car: car),
      ),
    );
    if (context.mounted) {
      await afterDataChange(context);
    }
  }

  Future<void> _deleteCar(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить автомобиль?'),
        content: const Text('Все данные, связанные с этим автомобилем, будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await context.read<CarsProvider>().remove(id);
      await afterDataChange(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Автомобиль удалён')),
        );
      }
    }
  }

  Future<void> _editMileage(BuildContext context, int id, int current) async {
    final ctrl = TextEditingController(text: current.toString());
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Текущий пробег'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              final v = int.tryParse(ctrl.text.trim());
              if (v == null) return;
              await context.read<CarsProvider>().updateCarFields(
                    id: id,
                    currentMileage: v,
                  );
              final a = context.read<CarsProvider>().active;
              await context.read<MaintenanceProvider>().loadForCar(
                    a?.id,
                    a,
                    context.read<SettingsProvider>().maintenanceNotify,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
