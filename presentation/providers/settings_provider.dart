import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _kLastBt = 'last_bt_address';
  static const _kAutoConnect = 'auto_connect_bt';
  static const _kPidMs = 'pid_poll_ms';
  static const _kMetric = 'metric_units';
  static const _kMaintNotify = 'maint_notify';
  static const _kAutoSave = 'auto_save_session';
  static const _kTheme = 'theme_mode_index';
  static const _kObdSimulation = 'obd_simulation';

  String? lastBtAddress;
  bool autoConnectBt = true;
  int pidPollMs = 1000;
  bool metricUnits = true;
  bool maintenanceNotify = true;
  bool autoSaveSessionOnLeave = false;
  ThemeMode themeMode = ThemeMode.system;
  /// Имитация OBD без адаптера (PID/DTC в демо-режиме).
  bool obdSimulation = false;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    lastBtAddress = p.getString(_kLastBt);
    autoConnectBt = p.getBool(_kAutoConnect) ?? true;
    pidPollMs = p.getInt(_kPidMs)?.clamp(500, 5000) ?? 1000;
    metricUnits = p.getBool(_kMetric) ?? true;
    maintenanceNotify = p.getBool(_kMaintNotify) ?? true;
    autoSaveSessionOnLeave = p.getBool(_kAutoSave) ?? false;
    obdSimulation = p.getBool(_kObdSimulation) ?? false;
    final ti = p.getInt(_kTheme);
    themeMode = switch (ti) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final p = await SharedPreferences.getInstance();
    final idx = switch (mode) {
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
      _ => 0,
    };
    await p.setInt(_kTheme, idx);
    notifyListeners();
  }

  Future<void> setObdSimulation(bool v) async {
    obdSimulation = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kObdSimulation, v);
    notifyListeners();
  }

  Future<void> setLastBt(String? address) async {
    final p = await SharedPreferences.getInstance();
    lastBtAddress = address;
    if (address == null) {
      await p.remove(_kLastBt);
    } else {
      await p.setString(_kLastBt, address);
    }
    notifyListeners();
  }

  Future<void> setAutoConnect(bool v) async {
    autoConnectBt = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kAutoConnect, v);
    notifyListeners();
  }

  Future<void> setPidPollMs(int v) async {
    pidPollMs = v.clamp(500, 5000);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kPidMs, pidPollMs);
    notifyListeners();
  }

  Future<void> setMetric(bool v) async {
    metricUnits = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMetric, v);
    notifyListeners();
  }

  Future<void> setMaintenanceNotify(bool v) async {
    maintenanceNotify = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMaintNotify, v);
    notifyListeners();
  }

  Future<void> setAutoSaveSession(bool v) async {
    autoSaveSessionOnLeave = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kAutoSave, v);
    notifyListeners();
  }
}
