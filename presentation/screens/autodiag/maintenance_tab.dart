import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/autodiag_models.dart';
import '../../providers/cars_provider.dart';
import '../../providers/diagnostics_provider.dart';
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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MaintenanceAddScreen(car: car),
      ),
    );
    _reload();
  }

  Future<void> _editDialog(
    BuildContext context,
    MaintenanceRow op,
    MaintenanceProvider maint,
  ) async {
    final title = TextEditingController(text: op.title);
    final interval = TextEditingController(text: op.intervalValue.toString());
    String type = op.intervalType;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Редактирование'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'mileage', child: Text('Пробег (км)')),
                  DropdownMenuItem(value: 'date', child: Text('Интервал (дни)')),
                ],
                onChanged: (v) => setSt(() => type = v ?? 'mileage'),
              ),
              TextField(
                controller: interval,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: type == 'mileage' ? 'Интервал, км' : 'Интервал, дней',
                ),
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
                  intervalType: type,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _reload();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceAddScreen extends StatefulWidget {
  const _MaintenanceAddScreen({required this.car});
  final Car car;

  @override
  State<_MaintenanceAddScreen> createState() => _MaintenanceAddScreenState();
}

class _MaintenanceAddScreenState extends State<_MaintenanceAddScreen> {
  final _title = TextEditingController();
  final _interval = TextEditingController(text: '10000');
  final _baselineMileage = TextEditingController();
  String _type = 'mileage';
  DateTime _baselineDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _baselineMileage.text = widget.car.currentMileage.toString();
  }

  @override
  void dispose() {
    _title.dispose();
    _interval.dispose();
    _baselineMileage.dispose();
    super.dispose();
  }

  Future<void> _fillFromObd() async {
    final diag = context.read<DiagnosticsProvider>();
    final v = await diag.readPidValue('21');
    if (v == null || !mounted) return;
    _baselineMileage.text = v.round().toString();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Подтянут PID 21 (дистанция с MIL). Это не общий одометр.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новая операция ТО')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Название операции'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            items: const [
              DropdownMenuItem(value: 'mileage', child: Text('По пробегу (км)')),
              DropdownMenuItem(value: 'date', child: Text('По времени (дни)')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'mileage'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _interval,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _type == 'mileage' ? 'Интервал, км' : 'Интервал, дней',
            ),
          ),
          const SizedBox(height: 12),
          if (_type == 'mileage') ...[
            TextField(
              controller: _baselineMileage,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Базовый пробег, км'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _fillFromObd,
                  icon: const Icon(Icons.sensors),
                  label: const Text('Подтянуть из OBD'),
                ),
                OutlinedButton(
                  onPressed: () => _baselineMileage.text = widget.car.currentMileage.toString(),
                  child: const Text('Взять из карточки авто'),
                ),
              ],
            ),
          ] else
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Базовая дата'),
              subtitle: Text(
                '${_baselineDate.year.toString().padLeft(4, '0')}-${_baselineDate.month.toString().padLeft(2, '0')}-${_baselineDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _baselineDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _baselineDate = picked);
              },
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              final t = _title.text.trim();
              final iv = int.tryParse(_interval.text.trim()) ?? 0;
              if (t.isEmpty || iv <= 0) return;
              await context.read<MaintenanceProvider>().addOperation(
                    carId: widget.car.id,
                    title: t,
                    intervalType: _type,
                    intervalValue: iv,
                    baselineMileage: int.tryParse(_baselineMileage.text.trim()) ?? widget.car.currentMileage,
                    baselineDate: _baselineDate,
                    car: widget.car,
                    notifyEnabled: context.read<SettingsProvider>().maintenanceNotify,
                  );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}
