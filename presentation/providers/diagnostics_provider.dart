import 'dart:async';
import 'dart:math' show sin;
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/obd/dtc_hints.dart';
import '../../core/obd/pid_metadata.dart';
import '../../core/services/bluetooth_obd_service.dart';
import '../../core/services/vin_decoder.dart';
import '../../data/autodiag_repository.dart';
import '../../data/models/autodiag_models.dart';
import 'settings_provider.dart';

class DiagnosticsProvider extends ChangeNotifier {
  DiagnosticsProvider(this._repo, this._settings) : _obd = BluetoothObdService();

  final AutodiagRepository _repo;
  final SettingsProvider _settings;
  final BluetoothObdService _obd;

  // Состояние
  final List<BluetoothDevice> discovered = [];
  bool scanning = false;
  bool connecting = false;
  String status = 'Не подключено';
  List<LiveDtc> liveDtcs = [];
  final Map<String, double> livePidValues = {};
  final Map<String, List<double>> chartHistory = {};
  static const int maxChartPoints = 120;

  Set<String> supportedPids = {};
  Set<String> _selectedPids = {}; // больше не используется, но оставим для совместимости

  Timer? _pollTimer;
  bool polling = false;
  int reconnectAttempts = 0;
  bool _simulationActive = false;
  DateTime? _diagnosticStartedAt;

  // VIN detection
  VinInfo? _detectedVinInfo;
  bool _isDetectingCar = false;
  String? _ecuName;

  BluetoothObdService get obd => _obd;
  bool get isConnected => _simulationActive || _obd.isConnected;
  bool get isSimulationActive => _simulationActive;
  VinInfo? get detectedVinInfo => _detectedVinInfo;
  bool get isDetectingCar => _isDetectingCar;
  String? get ecuName => _ecuName;

  // ------------------- Методы доступа к метаданным -------------------
  static Map<String, PidMetaExtended> getAllPidMeta() => allPidMeta;
  PidMetaExtended? getPidMeta(String pid) {
    final upper = pid.toUpperCase().padLeft(2, '0');
    return allPidMeta[upper];
  }
  List<PidMetaExtended> getAvailablePids() {
    return allPidMeta.values.where((m) => !['00','20','32','40','52','60'].contains(m.pid)).toList();
  }

  // ------------------- Определение поддерживаемых PID -------------------
  Future<void> _refreshSupportedPids() async {
    if (!isConnected) return;
    if (_simulationActive) {
      supportedPids = {
        '04','05','0C','0D','0F','10','11','1F','2E','34','36','38','4E','5C'
      };
      notifyListeners();
      return;
    }

    try {
      Set<String> allSupported = {};

      final resp00 = await _obd.sendObd('0100', timeout: const Duration(seconds: 2));
      allSupported.addAll(_parseSupportedPids(resp00, start: 0x01));

      final resp20 = await _obd.sendObd('0120', timeout: const Duration(seconds: 2));
      allSupported.addAll(_parseSupportedPids(resp20, start: 0x21));

      final resp40 = await _obd.sendObd('0140', timeout: const Duration(seconds: 2));
      allSupported.addAll(_parseSupportedPids(resp40, start: 0x41));

      final resp60 = await _obd.sendObd('0160', timeout: const Duration(seconds: 2));
      allSupported.addAll(_parseSupportedPids(resp60, start: 0x61));

      supportedPids = allSupported.where((p) => allPidMeta.containsKey(p)).toSet();
      if (supportedPids.isEmpty) supportedPids = {'04','05','0C','0D','11'};

      notifyListeners();
    } catch (e) {
      status = 'Ошибка чтения поддерживаемых PID: $e';
      notifyListeners();
    }
  }

  Set<String> _parseSupportedPids(String response, {required int start}) {
    Set<String> result = {};
    final hex = response.replaceAll(' ', '').replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    if (hex.length < 12) return result;
    final dataHex = hex.substring(4);
    if (dataHex.length < 8) return result;

    List<int> bytes = [];
    for (int i = 0; i < dataHex.length; i += 2) {
      bytes.add(int.parse(dataHex.substring(i, i + 2), radix: 16));
    }
    if (bytes.length < 4) return result;

    for (int i = 0; i < 4; i++) {
      int b = bytes[i];
      for (int bit = 0; bit < 8; bit++) {
        if ((b >> (7 - bit)) & 1 == 1) {
          int pidNum = start + i * 8 + bit;
          result.add(pidNum.toRadixString(16).toUpperCase().padLeft(2, '0'));
        }
      }
    }
    return result;
  }

  // ------------------- Чтение значения PID -------------------
  Future<double?> readPidValue(String pid) async {
    if (!isConnected) return null;
    if (_simulationActive) {
      final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final pidInt = int.parse(pid, radix: 16);
      switch (pidInt) {
        case 0x04: return 30 + 20 * sin(t * 0.5);
        case 0x05: return 85 + 5 * sin(t * 0.2);
        case 0x0C: return 800 + 400 * sin(t * 0.3);
        case 0x0D: return 50 + 40 * sin(t * 0.4);
        case 0x0F: return 20 + 5 * sin(t * 0.1);
        case 0x10: return 15 + 10 * sin(t * 0.6);
        case 0x11: return 10 + 15 * sin(t * 0.5);
        case 0x2E: return 400 + 50 * sin(t * 0.05);
        case 0x34: return 13.8 + 0.2 * sin(t);
        case 0x36: return 0.98 + 0.04 * sin(t * 0.2);
        case 0x38: return 15 + 5 * sin(t * 0.1);
        default: return 50 + 20 * sin(t * 0.3);
      }
    }

    try {
      final raw = await _obd.sendObd('01$pid', timeout: const Duration(milliseconds: 800));
      return _decodePidValue(pid, raw);
    } catch (e) {
      return null;
    }
  }

  double? _decodePidValue(String pid, String response) {
    final hex = response.replaceAll(' ', '').replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    if (hex.length < 4) return null;
    final dataHex = hex.substring(4);
    if (dataHex.isEmpty) return null;

    final int pidNum = int.parse(pid, radix: 16);
    switch (pidNum) {
      case 0x04: // нагрузка
        final a = int.parse(dataHex.substring(0, 2), radix: 16);
        return a * 100 / 255;
      case 0x05: // температура ОЖ
        final a = int.parse(dataHex.substring(0, 2), radix: 16);
        return a - 40;
      case 0x0C: // RPM
        final a = int.parse(dataHex.substring(0, 2), radix: 16);
        final b = int.parse(dataHex.substring(2, 4), radix: 16);
        return (a * 256 + b) / 4;
      case 0x0D: // скорость
        final a = int.parse(dataHex.substring(0, 2), radix: 16);
        return a.toDouble();
      case 0x0E: // угол зажигания
        final a = int.parse(dataHex.substring(0, 2), radix: 16);
        return (a / 2) - 64;
      case 0x0F: // температура воздуха
        final a = int.parse(dataHex.substring(0, 2), radix: 16);
        return a - 40;
      case 0x10: // MAF
        final a = int.parse(dataHex.substring(0, 2), radix: 16);
        final b = int.parse(dataHex.substring(2, 4), radix: 16);
        return (a * 256 + b) / 100;
      case 0x11: // дроссель
        final a = int.parse(dataHex.substring(0, 2), radix: 16);
        return a * 100 / 255;
      case 0x1F: // время работы
        final a = int.parse(dataHex.substring(0, 2), radix: 16);
        final b = int.parse(dataHex.substring(2, 4), radix: 16);
        return (a * 256 + b).toDouble();
      case 0x21: // дистанция с горящей MIL (не общий одометр)
        final a = int.parse(dataHex.substring(0, 2), radix: 16);
        final b = int.parse(dataHex.substring(2, 4), radix: 16);
        return (a * 256 + b).toDouble();
      case 0x34: // напряжение
        final a = int.parse(dataHex.substring(0, 2), radix: 16);
        return a / 100;
      case 0x36: // lambda
        final a = int.parse(dataHex.substring(0, 2), radix: 16);
        return a / 128;
      case 0x38: // температура наружного воздуха
        final a = int.parse(dataHex.substring(0, 2), radix: 16);
        return a - 40;
      case 0x4E: // температура масла
        final a = int.parse(dataHex.substring(0, 2), radix: 16);
        return a - 40;
      default:
        if (dataHex.length >= 2) {
          final a = int.parse(dataHex.substring(0, 2), radix: 16);
          return a.toDouble();
        }
        return null;
    }
  }

  // ------------------- Опрос -------------------
  void startPolling() {
    if (!isConnected || polling) return;
    polling = true;
    _diagnosticStartedAt = DateTime.now();
    chartHistory.clear();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(milliseconds: _settings.pidPollMs), (_) => _pollOnce());
    notifyListeners();
    _pollOnce();
  }

  void stopPolling() {
    polling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    notifyListeners();
  }

  Future<void> finishDiagnostic() async {
    if (polling) stopPolling();
    notifyListeners();
  }

  Future<void> _pollOnce() async {
    if (!isConnected) {
      await reconnectWithBackoff();
      return;
    }
    // Опрашиваем все поддерживаемые PID
    final pids = supportedPids.toList();
    if (pids.isEmpty) return;

    if (_simulationActive) {
      for (final pid in pids) {
        final value = await readPidValue(pid);
        if (value != null) {
          livePidValues[pid.toUpperCase()] = value;
          final key = pid.toUpperCase();
          chartHistory.putIfAbsent(key, () => []);
          chartHistory[key]!.add(value);
          while (chartHistory[key]!.length > maxChartPoints) {
            chartHistory[key]!.removeAt(0);
          }
        }
      }
      notifyListeners();
      return;
    }

    for (final pid in pids) {
      try {
        final v = await readPidValue(pid);
        if (v != null) {
          livePidValues[pid.toUpperCase()] = v;
          final key = pid.toUpperCase();
          chartHistory.putIfAbsent(key, () => []);
          chartHistory[key]!.add(v);
          while (chartHistory[key]!.length > maxChartPoints) {
            chartHistory[key]!.removeAt(0);
          }
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  // ------------------- DTC -------------------
  Future<void> refreshDtc() async { /* ... */ }
  Future<void> clearDtcConfirmed() async { /* ... */ }

  // ------------------- Сохранение сеанса -------------------
  Future<int?> saveSession({required Car car, String notes = ''}) async {
    final snapshot = Map<String, double>.from(livePidValues);
    int? obdDistanceWithMilKm = snapshot['21']?.round();
    if (obdDistanceWithMilKm == null && isConnected) {
      final v = await readPidValue('21');
      if (v != null) {
        obdDistanceWithMilKm = v.round();
        snapshot['21'] = v;
      }
    }
    return _repo.saveDiagnosticSession(
      carId: car.id,
      dtcs: liveDtcs,
      pidSnapshot: snapshot,
      notes: notes,
      mileageAtSession: car.currentMileage,
      obdDistanceWithMilKm: obdDistanceWithMilKm,
    );
  }

  // ------------------- Автоматическая диагностика -------------------
  Future<AutoDiagnosticResult> runAutoDiagnostic({
    required Car car,
    void Function(String stage, int progress)? onProgress,
  }) async {
    if (!isConnected) throw Exception('Нет подключения к OBD адаптеру');
    if (polling) throw Exception('Уже идёт опрос, остановите его');

    final result = <String, double>{};
    final List<LiveDtc> dtcs = [];

    onProgress?.call('Чтение кодов ошибок...', 10);
    await refreshDtc();
    dtcs.addAll(liveDtcs);

    final pids = supportedPids.toList()..sort();
    final total = pids.length;
    for (int i = 0; i < total; i++) {
      final pid = pids[i];
      onProgress?.call('Опрос параметра ${i+1}/$total: ${getPidMeta(pid)?.name ?? pid}', 10 + (80 * i ~/ total));
      final value = await readPidValue(pid);
      await Future.delayed(const Duration(milliseconds: 100));
      if (value != null) {
        result[pid.toUpperCase()] = value;
      }
    }

    onProgress?.call('Сохранение результатов...', 90);
    final sessionId = await saveSession(car: car, notes: 'Автоматическая диагностика');
    if (sessionId == null) throw Exception('Не удалось сохранить сеанс');

    onProgress?.call('Готово', 100);
    return AutoDiagnosticResult(sessionId: sessionId, dtcs: dtcs, pidSnapshot: result);
  }

  // ------------------- VIN / автоопределение -------------------
  Future<void> _tryAutoDetectCar() async {
    if (_simulationActive) {
      _detectedVinInfo = VinInfo(
        vin: '1HGCM82633A004352',
        manufacturer: 'Honda',
        brand: 'Honda',
        model: 'Unknown',
        year: 2023,
        isValid: true,
      );
      _ecuName = 'Honda ECU Demo';
      notifyListeners();
      return;
    }

    _isDetectingCar = true;
    notifyListeners();

    try {
      final vin = await _obd.readVin();
      if (vin != null) {
        _detectedVinInfo = VinDecoder.decodeVin(vin);
        _ecuName = await _obd.readEcuName();
        status = 'Автомобиль определен: ${_detectedVinInfo!.brand}';
      } else {
        status = 'Не удалось прочитать VIN';
      }
    } catch (e) {
      status = 'Ошибка автоопределения: $e';
    } finally {
      _isDetectingCar = false;
      notifyListeners();
    }
  }

  Future<Car?> createCarFromVin() async {
    if (_detectedVinInfo == null || !_detectedVinInfo!.isValid) return null;
    final vinInfo = _detectedVinInfo!;
    final existingCars = await _repo.getAllCars();
    Car? existingCar;
    try {
      existingCar = existingCars.firstWhere((car) => car.vin == vinInfo.vin);
    } catch (e) {
      existingCar = null;
    }
    if (existingCar != null) return existingCar;

    final carId = await _repo.insertCar(
      brand: vinInfo.brand,
      model: vinInfo.model,
      year: vinInfo.year,
      vin: vinInfo.vin,
      mileage: 0,
      setActive: false,
    );
    if (carId > 0) {
      final allCars = await _repo.getAllCars();
      try {
        return allCars.firstWhere((car) => car.id == carId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void clearVinDetection() {
    _detectedVinInfo = null;
    _ecuName = null;
    notifyListeners();
  }

  // ------------------- Bluetooth -------------------
  Future<bool> ensureBluetoothPermissions() async {
    if (await Permission.bluetoothConnect.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted) {
      return true;
    }
    return await Permission.bluetoothConnect.isGranted &&
        await Permission.bluetoothScan.isGranted;
  }

  Future<void> startDiscovery() async {
    if (_settings.obdSimulation) {
      status = 'Демо-режим: Bluetooth не используется';
      notifyListeners();
      return;
    }
    if (!await ensureBluetoothPermissions()) {
      status = 'Нет разрешений Bluetooth';
      notifyListeners();
      return;
    }
    discovered.clear();
    scanning = true;
    notifyListeners();
    try {
      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      discovered.addAll(bonded);
      FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
        if (!discovered.any((d) => d.address == result.device.address)) {
          discovered.add(result.device);
          notifyListeners();
        }
      }).onDone(() {
        scanning = false;
        notifyListeners();
      });
    } catch (e) {
      scanning = false;
      status = 'Ошибка сканирования: $e';
      notifyListeners();
    }
  }

  Future<void> connectTo(String address, {bool save = true}) async {
    if (_settings.obdSimulation) {
      await startSimulation();
      if (save && address.isNotEmpty) await _settings.setLastBt(address);
      return;
    }
    _simulationActive = false;
    if (!await ensureBluetoothPermissions()) {
      status = 'Нет разрешений Bluetooth';
      notifyListeners();
      return;
    }
    connecting = true;
    status = 'Подключение…';
    notifyListeners();
    try {
      await _obd.connect(address);
      await _obd.initElm();
      if (save) await _settings.setLastBt(address);
      status = 'Подключено';
      reconnectAttempts = 0;
      await refreshDtc();
      await _refreshSupportedPids();
      await _tryAutoDetectCar();
      connecting = false;
      notifyListeners();
    } catch (e) {
      connecting = false;
      status = 'Ошибка: $e';
      await _obd.disconnect();
      notifyListeners();
    }
  }

  Future<void> tryAutoConnect() async {
    if (_settings.obdSimulation) {
      await startSimulation();
      return;
    }
    final addr = _settings.lastBtAddress;
    if (!_settings.autoConnectBt || addr == null || addr.isEmpty) return;
    await connectTo(addr, save: false);
  }

  Future<void> disconnect() async {
    stopPolling();
    _simulationActive = false;
    await _obd.disconnect();
    status = 'Отключено';
    liveDtcs.clear();
    livePidValues.clear();
    notifyListeners();
  }

  Future<void> reconnectWithBackoff() async {
    if (_simulationActive) return;
    final addr = _obd.connectedAddress ?? _settings.lastBtAddress;
    if (addr == null) return;
    for (var i = 0; i < 3; i++) {
      try {
        await _obd.disconnect();
        await Future.delayed(const Duration(seconds: 2));
        await connectTo(addr, save: false);
        if (isConnected) return;
      } catch (_) {}
    }
    status = 'Не удалось восстановить связь';
    notifyListeners();
  }

  Future<void> startSimulation() async {
    stopPolling();
    await _obd.disconnect();
    _simulationActive = true;
    connecting = false;
    status = 'Демо: без адаптера ELM327';
    liveDtcs = [
      LiveDtc(code: 'P0301', description: dtcDescriptionRu('P0301'), type: 'current'),
      LiveDtc(code: 'P0420', description: dtcDescriptionRu('P0420'), type: 'pending'),
    ];
    supportedPids = {
      '04','05','0C','0D','0F','10','11','1F','2E','34','36','38','4E','5C'
    };

    final t = DateTime.now().millisecondsSinceEpoch / 800.0;
    for (final pid in supportedPids) {
      final key = pid.toUpperCase();
      double v;
      switch (key) {
        case '0C': v = 850 + 450 * (0.5 + 0.5 * sin(t)); break;
        case '0D': v = (35 + 35 * sin(t * 0.7)).clamp(0, 200); break;
        case '05': v = 88 + 8 * sin(t * 0.3); break;
        case '04': v = (22 + 18 * sin(t * 0.5)).clamp(0, 100); break;
        case '11': v = (10 + 15 * sin(t * 0.5)).clamp(0, 100); break;
        default: v = 20 + 15 * sin(t + key.hashCode * 0.01);
      }
      livePidValues[key] = v;
      chartHistory.putIfAbsent(key, () => []);
      final list = chartHistory[key]!;
      for (int i = 0; i < 20; i++) {
        final pastT = t - i * 0.1;
        double pastV;
        switch (key) {
          case '0C': pastV = 850 + 450 * (0.5 + 0.5 * sin(pastT)); break;
          case '0D': pastV = (35 + 35 * sin(pastT * 0.7)).clamp(0, 200); break;
          case '05': pastV = 88 + 8 * sin(pastT * 0.3); break;
          case '04': pastV = (22 + 18 * sin(pastT * 0.5)).clamp(0, 100); break;
          case '11': pastV = (10 + 15 * sin(pastT * 0.5)).clamp(0, 100); break;
          default: pastV = 20 + 15 * sin(pastT + key.hashCode * 0.01);
        }
        list.insert(0, pastV);
      }
      while (list.length > maxChartPoints) list.removeAt(0);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    _obd.disconnect();
    super.dispose();
  }
}

class AutoDiagnosticResult {
  final int sessionId;
  final List<LiveDtc> dtcs;
  final Map<String, double> pidSnapshot;
  AutoDiagnosticResult({required this.sessionId, required this.dtcs, required this.pidSnapshot});
}