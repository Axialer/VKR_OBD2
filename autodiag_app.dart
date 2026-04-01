import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/autodiag/main_shell.dart';

class AutoDiagApp extends StatelessWidget {
  const AutoDiagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final lightScheme =
            ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light);
        final darkScheme =
            ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark);
        return MaterialApp(
          title: 'AutoDiag',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              centerTitle: true,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
              backgroundColor: lightScheme.surface,
              foregroundColor: lightScheme.onSurface,
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 64,
              labelTextStyle: WidgetStateProperty.resolveWith((s) {
                if (s.contains(WidgetState.selected)) {
                  return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
                }
                return const TextStyle(fontSize: 11);
              }),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              centerTitle: true,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              backgroundColor: darkScheme.surface,
              foregroundColor: darkScheme.onSurface,
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 64,
              labelTextStyle: WidgetStateProperty.resolveWith((s) {
                if (s.contains(WidgetState.selected)) {
                  return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
                }
                return const TextStyle(fontSize: 11);
              }),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          home: const MainShell(),
        );
      },
    );
  }
}
