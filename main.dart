import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'autodiag_app.dart';
import 'core/obd/dtc_catalog.dart';
import 'core/services/notification_service.dart';
import 'data/autodiag_repository.dart';
import 'data/db/app_database.dart';
import 'core/services/export_service.dart';
import 'presentation/providers/cars_provider.dart';
import 'presentation/providers/diagnostics_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/providers/maintenance_provider.dart';
import 'presentation/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.instance;
  await db.database;

  await DtcCatalog.instance.load();

  await NotificationService.instance.init();
  await NotificationService.instance.requestAndroidPermission();

  final settings = SettingsProvider();
  await settings.load();

  final repo = AutodiagRepository(db);
  final export = ExportService(repo);
  final cars = CarsProvider(repo);
  await cars.refresh();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: db),
        Provider.value(value: repo),
        Provider.value(value: export),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: cars),
        ChangeNotifierProvider(
          create: (_) => DiagnosticsProvider(repo, settings),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(repo),
        ),
        ChangeNotifierProvider(
          create: (_) => MaintenanceProvider(repo),
        ),
      ],
      child: const AutoDiagApp(),
    ),
  );
}
