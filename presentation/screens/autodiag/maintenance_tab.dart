import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/autodiag_models.dart';
import '../../providers/cars_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/settings_provider.dart';

class MaintenanceTab extends StatefulWidget {
  const MaintenanceTab({super.key});

  @override
  State<MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends State<MaintenanceTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    if (!mounted) return;
    final cars = context.read<CarsProvider>();
    final maint = context.read<MaintenanceProvider>();
    final settings = context.read<SettingsProvider>();
    final a = cars.active;
    maint.loadForCar(a?.id, a, settings.maintenanceNotify);
  }

  @override
  Widget build(BuildContext context) {
    final maint = context.watch<MaintenanceProvider>();
    final cars = context.watch<CarsProvider>();
    final active = cars.active;

    if (active == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Выберите активный автомобиль на вкладке «Авто»',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: maint.items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Нет операций. Нажмите + чтобы добавить.')),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                itemCount: maint.items.length,
                itemBuilder: (ctx, i) {
                  final op = maint.items[i];
                  final st = maintenanceStatus(op, active.currentMileage);
                  final color = st == MaintUiStatus.overdue
                      ? Theme.of(context).colorScheme.error
                      : st == MaintUiStatus.soon
                          ? Colors.orange
                          : Theme.of(context).colorScheme.primary;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.build_circle, color: color, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      op.title,
                                      style: Theme.of(context)
                                          .textTheme.titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _subtitle(op, active, st),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => _onExecute(context, op.id, active),
                              child: const Text('Выполнить'),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () =>
                                  _editDialog(context, op, maint),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Изменить'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context, active),
        icon: const Icon(Icons.add),
        label: const Text('ТО'),
      ),
    );
  }

  Future<void> _onExecute(BuildContext context, int opId, Car active) async {
    final maint = context.read<MaintenanceProvider>();
    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await maint.markDone(opId, active, settings.maintenanceNotify);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Операция отмечена выполненной. Следующий срок пересчитан.'),
        ),
      );
      _reload();
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  String _subtitle(MaintenanceRow op, Car car, MaintUiStatus st) {
    if (op.intervalType == 'mileage') {
      final n = op.nextDueMileage;
      if (n == null) return 'интервал ${op.intervalValue} км от последней отметки';
      if (st == MaintUiStatus.overdue) {
        return 'Просрочено: цель $n км · одометр ${car.currentMileage} км';
      }
      return 'Следующая цель: $n км (осталось ≈ ${n - car.currentMileage} км)';
    }
    final n = op.nextDueDate;
    if (n == null) return 'Каждые ${op.intervalValue} дн.';
    final ds = n.toString().split(' ').first;
    if (st == MaintUiStatus.overdue) return 'Просрочено: было до $ds';
    return 'Следующий срок: $ds';
  }

  Future<void> _addDialog(BuildContext context, Car car) async {
    final title = TextEditingController();
    String type = 'mileage';
    final interval = TextEditingController(text: '10000');
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              title: const Text('Новая операция ТО'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Название'),
                    ),
                    DropdownButtonFormField<String>(
                      value: type,
                      items: const [
                        DropdownMenuItem(
                            value: 'mileage', child: Text('Пробег (км)')),
                        DropdownMenuItem(
                            value: 'date', child: Text('Интервал (дни)')),
                      ],
                      onChanged: (v) => setSt(() => type = v ?? 'mileage'),
                    ),
                    TextField(
                      controller: interval,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Интервал'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'База: пробег ${car.currentMileage} км, дата сегодня',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () async {
                    final val = int.tryParse(interval.text.trim()) ?? 0;
                    if (title.text.trim().isEmpty || val <= 0) return;
                    await context.read<MaintenanceProvider>().addOperation(
                          carId: car.id,
                          title: title.text.trim(),
                          intervalType: type,
                          intervalValue: val,
                          baselineMileage: car.currentMileage,
                          baselineDate: DateTime.now(),
                          car: car,
                          notifyEnabled:
                              context.read<SettingsProvider>().maintenanceNotify,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _reload();
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editDialog(
    BuildContext context,
    MaintenanceRow op,
    MaintenanceProvider maint,
  ) async {
    final title = TextEditingController(text: op.title);
    final interval = TextEditingController(text: op.intervalValue.toString());
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактирование'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: interval,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Интервал'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await maint.deleteOp(op.id);
              if (ctx.mounted) Navigator.pop(ctx);
              _reload();
            },
            child: Text('Удалить',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          FilledButton(
            onPressed: () async {
              final v = int.tryParse(interval.text.trim());
              await maint.updateOp(
                op.id,
                title: title.text.trim(),
                intervalValue: v,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _reload();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
