import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cars_provider.dart';
import '../../providers/diagnostics_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/settings_provider.dart';
import 'cars_tab.dart';
import 'diagnostics_tab.dart';
import 'history_tab.dart';
import 'home_tab.dart';
import 'maintenance_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  static const _titles = ['Главная', 'Диагностика', 'История', 'ТО', 'Авто'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cars = context.read<CarsProvider>();
      final hist = context.read<HistoryProvider>();
      final maint = context.read<MaintenanceProvider>();
      final diag = context.read<DiagnosticsProvider>();
      final settings = context.read<SettingsProvider>();
      await hist.refresh();
      final active = cars.active;
      await maint.loadForCar(
        active?.id,
        active,
        settings.maintenanceNotify,
      );
      await diag.tryAutoConnect();
    });
  }

  void _goDiagnostics({int? subTab}) {
    setState(() => index = 1);
    if (subTab != null) {
      DiagnosticsTab.pendingSubTab = subTab;
    }
  }

  void _goMaintenance() => setState(() => index = 3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          HomeTab(
            onStartDiagnostic: () async {
              final diag = context.read<DiagnosticsProvider>();
              final settings = context.read<SettingsProvider>();
              setState(() => index = 1);
              if (settings.lastBtAddress != null &&
                  settings.lastBtAddress!.isNotEmpty) {
                await diag.connectTo(settings.lastBtAddress!, save: false);
              }
            },
            onOpenErrors: () => _goDiagnostics(subTab: 1),
            onOpenMaintenance: _goMaintenance,
          ),
          const DiagnosticsTab(),
          const HistoryTab(),
          const MaintenanceTab(),
          const CarsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (i) async {
          final prev = index;
          setState(() => index = i);
          if (prev == 1 && i != 1) {
            final st = context.read<SettingsProvider>();
            if (st.autoSaveSessionOnLeave) {
              final diag = context.read<DiagnosticsProvider>();
              final cars = context.read<CarsProvider>();
              final active = cars.active;
              if (diag.isConnected && active != null) {
                await diag.saveSession(car: active);
                if (context.mounted) {
                  await context.read<HistoryProvider>().refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Сеанс сохранён автоматически')),
                  );
                }
              }
            }
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
            tooltip: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: 'OBD',
            tooltip: 'Диагностика',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'История',
            tooltip: 'История сеансов',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_circle_outlined),
            selectedIcon: Icon(Icons.build_circle),
            label: 'ТО',
            tooltip: 'Техобслуживание',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Авто',
            tooltip: 'Автомобили и настройки',
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(_titles[index]),
      ),
    );
  }
}
