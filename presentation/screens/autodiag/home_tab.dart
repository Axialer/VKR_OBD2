import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/autodiag_models.dart';
import '../../providers/cars_provider.dart';
import '../../providers/diagnostics_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/settings_provider.dart';
import '../../../core/obd/dtc_hints.dart';
import 'diagnostics_tab.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.onStartDiagnostic,
    required this.onOpenErrors,
    required this.onOpenMaintenance,
  });

  final VoidCallback onStartDiagnostic;
  final VoidCallback onOpenErrors;
  final VoidCallback onOpenMaintenance;

  @override
  Widget build(BuildContext context) {
    final cars = context.watch<CarsProvider>();
    final diag = context.watch<DiagnosticsProvider>();
    final maint = context.watch<MaintenanceProvider>();
    final settings = context.watch<SettingsProvider>();
    final active = cars.active;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveCarCard(context, active, settings),
          const SizedBox(height: 16),
          _buildConnectionCard(context, diag),
          const SizedBox(height: 16),
          _buildDiagnosticButtons(context, diag),
          const SizedBox(height: 24),
          _buildMaintenanceAccordion(context, active, maint, onOpenMaintenance),
        ],
      ),
    );
  }

  Widget _buildActiveCarCard(BuildContext context, Car? active, SettingsProvider settings) {
    if (active == null) {
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Добавьте автомобиль на вкладке «Авто»',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.directions_car,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    active.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Пробег: ${active.currentMileage} ${settings.metricUnits ? 'км' : 'ми'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context, DiagnosticsProvider diag) {
    final isConnected = diag.isConnected;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: isConnected ? Colors.green : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diag.status,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isConnected ? Colors.green : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected ? 'Адаптер отвечает' : 'Выберите адаптер в «Диагностика»',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticButtons(BuildContext context, DiagnosticsProvider diag) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onStartDiagnostic,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Диагностика'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final active = context.read<CarsProvider>().active;
              if (active == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Нет активного автомобиля')),
                );
                return;
              }
              if (!diag.isConnected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Сначала подключитесь к OBD адаптеру')),
                );
                return;
              }
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const _AutoDiagnosticDialog(),
              );
            },
            icon: const Icon(Icons.speed),
            label: const Text('Авто-диагностика'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceAccordion(
      BuildContext context,
      Car? active,
      MaintenanceProvider maint,
      VoidCallback onOpenMaintenance,
      ) {
    if (active == null || maint.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpansionTile(
      title: Row(
        children: [
          Icon(
            Icons.build_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text(
            'Ближайшее ТО',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      subtitle: Text(
        '${_nearestMaint(maint.items, active, 3).length} операций',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            children: _nearestMaint(maint.items, active, 3).map(
                  (op) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.event_outlined,
                    color: _getStatusColor(maintenanceStatus(op, active.currentMileage)),
                  ),
                  title: Text(op.title),
                  subtitle: Text(_maintSubtitle(op, active)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onOpenMaintenance,
                ),
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(MaintUiStatus status) {
    switch (status) {
      case MaintUiStatus.overdue:
        return Colors.red;
      case MaintUiStatus.soon:
        return Colors.orange;
      case MaintUiStatus.ok:
        return Colors.green;
    }
  }

  static List<MaintenanceRow> _nearestMaint(
      List<MaintenanceRow> all,
      Car car,
      int n,
      ) {
    final withPri = all.map((op) {
      final st = maintenanceStatus(op, car.currentMileage);
      final pri = st == MaintUiStatus.overdue
          ? 0
          : st == MaintUiStatus.soon
          ? 1
          : 2;
      return MapEntry(pri, op);
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return withPri.take(n).map((e) => e.value).toList();
  }

  static String _maintSubtitle(MaintenanceRow op, Car car) {
    final st = maintenanceStatus(op, car.currentMileage);
    if (op.intervalType == 'mileage') {
      final next = op.nextDueMileage;
      if (next == null) return 'интервал по пробегу';
      final left = next - car.currentMileage;
      if (st == MaintUiStatus.overdue) return 'просрочено (цель $next км)';
      return 'осталось ≈ $left км';
    }
    final next = op.nextDueDate;
    if (next == null) return 'интервал по дате';
    final days = next.difference(DateTime.now()).inDays;
    if (st == MaintUiStatus.overdue) return 'просрочено';
    return 'осталось ≈ $days дн.';
  }
}

class _AutoDiagnosticDialog extends StatefulWidget {
  const _AutoDiagnosticDialog();

  @override
  State<_AutoDiagnosticDialog> createState() => _AutoDiagnosticDialogState();
}

class _AutoDiagnosticDialogState extends State<_AutoDiagnosticDialog> {
  String _stage = 'Подготовка...';
  int _progress = 0;
  bool _finished = false;
  AutoDiagnosticResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final diag = context.read<DiagnosticsProvider>();
    final car = context.read<CarsProvider>().active;
    if (car == null) {
      setState(() {
        _error = 'Нет активного автомобиля';
        _finished = true;
      });
      return;
    }
    try {
      final result = await diag.runAutoDiagnostic(
        car: car,
        onProgress: (stage, progress) {
          if (mounted) {
            setState(() {
              _stage = stage;
              _progress = progress;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _result = result;
          _finished = true;
        });
        await diag.refreshDtc();
        await context.read<HistoryProvider>().refresh();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _finished = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Автоматическая диагностика'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress / 100),
          const SizedBox(height: 16),
          Text(_stage),
          const SizedBox(height: 16),
          if (_finished) ...[
            if (_error != null)
              Text('Ошибка: $_error', style: const TextStyle(color: Colors.red))
            else ...[
              Text('✅ Диагностика завершена'),
              Text('Ошибок: ${_result?.dtcs.length ?? 0}'),
              Text('Параметров: ${_result?.pidSnapshot.length ?? 0}'),
            ],
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
        if (_finished && _error == null)
          FilledButton(
            onPressed: () {
              DiagnosticsTab.pendingSubTab = 1;
              Navigator.of(context).pop();
            },
            child: const Text('Показать ошибки'),
          ),
      ],
    );
  }
}