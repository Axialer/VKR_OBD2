import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/obd/pid_metadata.dart';
import '../../../data/autodiag_repository.dart';
import '../../../data/models/autodiag_models.dart';
import '../../providers/cars_provider.dart';
import '../../providers/diagnostics_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../../core/services/export_service.dart';
import '../../../core/obd/dtc_hints.dart';
import 'device_picker_sheet.dart';
import 'vin_detection_screen.dart';

class DiagnosticsTab extends StatefulWidget {
  const DiagnosticsTab({super.key});

  static int pendingSubTab = 0;

  @override
  State<DiagnosticsTab> createState() => _DiagnosticsTabState();
}

class _DiagnosticsTabState extends State<DiagnosticsTab>
    with TickerProviderStateMixin {
  late TabController _outer;
  late TabController _innerParams;

  Future<void> _makeReport(BuildContext context, Car active) async {
    final diag = context.read<DiagnosticsProvider>();
    final repo = context.read<AutodiagRepository>();
    final export = context.read<ExportService>();
    final hist = context.read<HistoryProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final sid = await diag.saveSession(car: active);
      if (sid == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Не удалось сохранить сеанс')));
        return;
      }

      DateTime sessionTime = DateTime.now();
      String notes = '';
      String carLabel = active.displayName;
      final sessions = await repo.listSessions(carIdFilter: active.id);
      final head = sessions.where((s) => s.id == sid).toList();
      if (head.isNotEmpty) {
        sessionTime = head.first.dateTime;
        notes = head.first.notes ?? '';
        carLabel = head.first.carLabel ?? '';
      }

      final dtcs = await repo.sessionDtcs(sid);
      final params = await repo.sessionParams(sid);
      final file = await export.sessionToPdf(
        sessionId: sid,
        sessionTime: sessionTime,
        dtcs: dtcs,
        params: params,
        notes: notes,
        carLabel: carLabel,
      );
      await export.sharePdf(file);
      await hist.refresh();

      if (context.mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Отчёт сформирован и отправлен')));
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Ошибка отчёта: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    final initial = DiagnosticsTab.pendingSubTab.clamp(0, 1);
    DiagnosticsTab.pendingSubTab = 0;
    _outer = TabController(length: 2, vsync: this, initialIndex: initial);
    _innerParams = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _outer.dispose();
    _innerParams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diag = context.watch<DiagnosticsProvider>();
    final cars = context.watch<CarsProvider>();
    final settings = context.watch<SettingsProvider>();
    final repo = context.read<AutodiagRepository>();
    final active = cars.active;

    if (active == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет активного автомобиля',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Выберите или добавьте автомобиль',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add_car'),
              icon: const Icon(Icons.add),
              label: const Text('Добавить автомобиль'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatusPanel(context, diag, active, repo),
          Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: TabBar(
                  controller: _outer,
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    const Tab(text: 'Параметры'),
                    Tab(text: 'Ошибки (${diag.liveDtcs.length})'),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height - 280,
                child: TabBarView(
                  controller: _outer,
                  children: [
                    _buildParamsTab(context, diag, settings),
                    _buildErrorsTab(diag),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPanel(
      BuildContext context,
      DiagnosticsProvider diag,
      Car active,
      AutodiagRepository repo,
      ) {
    final canStart = diag.isConnected && !diag.polling;
    final canStop = diag.polling;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  active.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => _makeReport(context, active),
                icon: const Icon(Icons.picture_as_pdf, size: 20),
                tooltip: 'PDF отчёт',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showDevicePicker(context),
                  icon: Icon(
                    diag.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                    size: 18,
                  ),
                  label: Text(
                    diag.isConnected ? 'Подключено' : 'Подключить OBD',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: diag.isConnected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (diag.isConnected)
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VinDetectionScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.fingerprint, size: 18),
                  label: const Text('VIN', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: canStart ? () => diag.startPolling() : null,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Старт', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canStop
                      ? () async {
                    final activeCar = context.read<CarsProvider>().active;
                    if (activeCar != null) {
                      await diag.finishDiagnostic();
                      final sid = await diag.saveSession(car: activeCar);
                      if (sid != null && context.mounted) {
                        await context.read<HistoryProvider>().refresh();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Сеанс сохранён')),
                        );
                      }
                    } else {
                      await diag.finishDiagnostic();
                    }
                  }
                      : null,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('Стоп', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: diag.isConnected && !diag.polling
                      ? () async {
                    final activeCar = context.read<CarsProvider>().active;
                    if (activeCar == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Нет активного автомобиля')),
                      );
                      return;
                    }
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => _AutoDiagnosticDialog(car: activeCar),
                    );
                  }
                      : null,
                  icon: const Icon(Icons.speed, size: 18),
                  label: const Text('Авто', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: diag.isConnected && !diag.polling
                      ? () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Сбросить ошибки?'),
                        content: const Text('Команда OBD 04 очистит коды неисправностей. Продолжить?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Отмена'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Сбросить'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      await diag.clearDtcConfirmed();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ошибки сброшены')),
                        );
                      }
                    }
                  }
                      : null,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Сброс', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Chip(
                avatar: CircleAvatar(
                  radius: 10,
                  backgroundColor: diag.isConnected ? Colors.green : Colors.grey,
                  child: Icon(
                    diag.isConnected ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
                label: Text(
                  diag.isConnected ? 'OBD подключен' : 'OBD отключен',
                  style: const TextStyle(fontSize: 11),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              if (diag.isConnected) ...[
                Chip(
                  avatar: CircleAvatar(
                    radius: 10,
                    backgroundColor: diag.liveDtcs.isNotEmpty ? Colors.red : Colors.green,
                  ),
                  label: Text('Ошибок: ${diag.liveDtcs.length}', style: const TextStyle(fontSize: 11)),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                if (diag.polling)
                  Chip(
                    avatar: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    label: const Text('Опрос...', style: TextStyle(fontSize: 11)),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                if (diag.detectedVinInfo != null)
                  Chip(
                    avatar: const CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.fingerprint, color: Colors.white, size: 12),
                    ),
                    label: Text('VIN: ${diag.detectedVinInfo!.vin.substring(0, 7)}...',
                        style: const TextStyle(fontSize: 11)),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParamsTab(
      BuildContext context,
      DiagnosticsProvider diag,
      SettingsProvider settings,
      ) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: TabBar(
            controller: _innerParams,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Список'),
              Tab(text: 'Графики'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _innerParams,
            children: [
              _ParamsListPane(diag: diag),
              _ParamsChartsPane(diag: diag),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorsTab(DiagnosticsProvider diag) {
    if (diag.liveDtcs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет кодов ошибок',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Системы автомобиля в норме',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: diag.liveDtcs.length,
      itemBuilder: (context, index) {
        final dtc = diag.liveDtcs[index];
        final rec = dtcRecommendationRu(dtc.code);
        final isCurrent = dtc.type == 'current';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: isCurrent
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                isCurrent ? Icons.error : Icons.warning,
                color: isCurrent
                    ? Theme.of(context).colorScheme.onErrorContainer
                    : Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            title: Text(
              dtc.code,
              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
            subtitle: Text(
              isCurrent ? 'Активная ошибка' : 'Отложенная ошибка',
              style: TextStyle(
                color: isCurrent
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dtc.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (rec != null && rec.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Рекомендации:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rec,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleChart(
      BuildContext context,
      String pid,
      DiagnosticsProvider diag,
      ) {
    final meta = diag.getPidMeta(pid);
    final values = diag.chartHistory[pid.toUpperCase()] ?? [];
    final currentValue = diag.livePidValues[pid.toUpperCase()];

    if (values.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет данных для построения графика',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Начните опрос параметров',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getPidIcon(pid),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta?.name ?? 'PID $pid',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          if (meta?.unit != null)
                            Text(
                              'Единица: ${meta!.unit}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (currentValue != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentValue.toStringAsFixed(1)} ${meta?.unit ?? ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                if (meta?.normalMin != null && meta?.normalMax != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Норма: ${meta!.normalMin} - ${meta.normalMax}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _calculateYInterval(meta, values),
                    verticalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (values.length > 1) ? (values.length / 5).roundToDouble() : 1.0,
                        getTitlesWidget: (value, titleMeta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        interval: _calculateYInterval(meta, values),
                        getTitlesWidget: (value, titleMeta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: values.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value);
                      }).toList(),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 1,
                            strokeColor: Theme.of(context).colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)} ${meta?.unit ?? ''}',
                            TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                  ),
                  minY: _calculateMinY(meta, values),
                  maxY: _calculateMaxY(meta, values),
                  minX: 0,
                  maxX: (values.length - 1).toDouble().clamp(0, 80),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPidIcon(String pid) {
    switch (pid.toUpperCase()) {
      case '0C':
        return Icons.speed;
      case '0D':
        return Icons.speed;
      case '05':
        return Icons.thermostat;
      case '04':
        return Icons.local_fire_department;
      case '11':
        return Icons.air;
      case '42':
        return Icons.battery_full;
      default:
        return Icons.sensors;
    }
  }

  double _calculateYInterval(PidMetaExtended? meta, List<double> values) {
    if (values.isEmpty) return 10;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    if (range <= 0) return 10;
    if (range <= 10) return 2;
    if (range <= 50) return 5;
    if (range <= 100) return 10;
    if (range <= 500) return 50;
    return 100;
  }

  double _calculateMinY(PidMetaExtended? meta, List<double> values) {
    if (values.isEmpty) return 0;
    final min = values.reduce((a, b) => a < b ? a : b);
    final interval = _calculateYInterval(meta, values);
    return (min - interval).clamp(0, double.infinity);
  }

  double _calculateMaxY(PidMetaExtended? meta, List<double> values) {
    if (values.isEmpty) return 100;
    final max = values.reduce((a, b) => a > b ? a : b);
    final interval = _calculateYInterval(meta, values);
    return (max + interval).clamp(0, double.infinity);
  }
}

class _ParamsListPane extends StatelessWidget {
  const _ParamsListPane({required this.diag});
  final DiagnosticsProvider diag;

  @override
  Widget build(BuildContext context) {
    final allPids = DiagnosticsProvider.getAllPidMeta().values.toList()
      ..sort((a, b) => a.pid.compareTo(b.pid));

    if (allPids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sensors_off,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет доступных параметров',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'База данных не загружена',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allPids.length,
      itemBuilder: (context, index) {
        final pidMeta = allPids[index];
        final pid = pidMeta.pid;
        final isSupported = diag.supportedPids.contains(pid);
        final value = diag.livePidValues[pid.toUpperCase()];
        final isNormal = _isValueNormal(pidMeta, value);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSupported
                  ? (value != null
                  ? (isNormal
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.errorContainer)
                  : Theme.of(context).colorScheme.surfaceVariant)
                  : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              child: Icon(
                _getPidIcon(pid),
                color: isSupported
                    ? (value != null
                    ? (isNormal
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onErrorContainer)
                    : Theme.of(context).colorScheme.onSurfaceVariant)
                    : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            title: Text(
              pidMeta.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSupported ? null : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            subtitle: Text(
              pidMeta.unit ?? '',
              style: TextStyle(
                color: isSupported
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  !isSupported
                      ? 'не поддерживается'
                      : (value != null ? '${value.toStringAsFixed(1)}' : '---'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: !isSupported
                        ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)
                        : (value != null
                        ? (isNormal
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error)
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                if (isSupported && pidMeta.normalMin != null && pidMeta.normalMax != null)
                  Text(
                    'Норма: ${pidMeta.normalMin}-${pidMeta.normalMax}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isValueNormal(PidMetaExtended meta, double? value) {
    if (value == null) return false;
    if (meta.normalMin == null || meta.normalMax == null) return true;
    return value >= meta.normalMin! && value <= meta.normalMax!;
  }

  IconData _getPidIcon(String pid) {
    switch (pid.toUpperCase()) {
      case '0C':
        return Icons.speed;
      case '0D':
        return Icons.speed;
      case '05':
        return Icons.thermostat;
      case '04':
        return Icons.local_fire_department;
      case '11':
        return Icons.air;
      case '42':
        return Icons.battery_full;
      default:
        return Icons.sensors;
    }
  }
}

class _ParamsChartsPane extends StatelessWidget {
  const _ParamsChartsPane({required this.diag});
  final DiagnosticsProvider diag;

  @override
  Widget build(BuildContext context) {
    final supportedPids = diag.supportedPids.toList()..sort();

    if (supportedPids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет поддерживаемых параметров для графиков',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Подключитесь к OBD-II адаптеру',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return PageView.builder(
      itemCount: supportedPids.length,
      itemBuilder: (context, index) {
        final pid = supportedPids[index];
        final parent = context.findAncestorStateOfType<_DiagnosticsTabState>();
        return parent!._buildSingleChart(context, pid, diag);
      },
    );
  }
}

class _AutoDiagnosticDialog extends StatefulWidget {
  const _AutoDiagnosticDialog({required this.car});
  final Car car;

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
    try {
      final result = await diag.runAutoDiagnostic(
        car: widget.car,
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