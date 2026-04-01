import 'dart:async';
import 'dart:convert';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../obd/obd_parser.dart';

class BluetoothObdService {
  BluetoothConnection? _connection;
  StreamSubscription<List<int>>? _sub;
  final StringBuffer _rx = StringBuffer();

  String? connectedAddress;
  bool get isConnected => _connection?.isConnected ?? false;

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _connection?.close();
    } catch (_) {}
    _connection = null;
    connectedAddress = null;
    _rx.clear();
  }

  Future<void> connect(String address) async {
    await disconnect();
    final conn = await BluetoothConnection.toAddress(address);
    _connection = conn;
    connectedAddress = address;
    _rx.clear();
    final stream = conn.input;
    if (stream == null) {
      await disconnect();
      throw StateError('BluetoothConnection не предоставил поток ввода');
    }
    _sub = stream.listen((data) {
      _rx.write(utf8.decode(data, allowMalformed: true));
    }, onDone: () {
      _connection = null;
      connectedAddress = null;
    }, onError: (_) {
      _connection = null;
      connectedAddress = null;
    });
  }

  /// Инициализация ELM327 по ТЗ (упрощённо: ATZ может быть долгим).
  Future<String> initElm({
    Duration atzTimeout = const Duration(seconds: 3),
  }) async {
    await sendRaw('ATZ\r', timeout: atzTimeout);
    await sendRaw('ATE0\r');
    await sendRaw('ATL0\r');
    await sendRaw('ATSP0\r');
    final id = await sendRaw('ATI\r');
    return id;
  }

  Future<String> sendRaw(String line, {Duration? timeout}) async {
    if (_connection == null || !_connection!.isConnected) {
      throw StateError('Нет подключения к адаптеру');
    }
    _rx.clear();
    _connection!.output.add(utf8.encode(line));
    await _connection!.output.allSent;
    return _readUntilPrompt(timeout ?? const Duration(milliseconds: 1200));
  }

  Future<String> sendObd(String commandWithoutCr,
      {Duration? timeout}) async {
    final c =
        commandWithoutCr.endsWith('\r') ? commandWithoutCr : '$commandWithoutCr\r';
    return sendRaw(c, timeout: timeout);
  }

  Future<String> _readUntilPrompt(Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final s = _rx.toString();
      if (s.contains('>')) {
        final i = s.indexOf('>');
        return s.substring(0, i).trim();
      }
      if (s.contains('STOPPED') || s.contains('UNABLE') || s.contains('ERROR')) {
        return s.trim();
      }
      await Future.delayed(const Duration(milliseconds: 30));
    }
    return _rx.toString().trim();
  }

  Future<List<String>> readStoredDtc() async {
    final r = await sendObd('03', timeout: const Duration(seconds: 2));
    return ObdParser.parseDtcResponse(r, mode: 3);
  }

  Future<List<String>> readPendingDtc() async {
    final r = await sendObd('07', timeout: const Duration(seconds: 2));
    return ObdParser.parseDtcResponse(r, mode: 7);
  }

  Future<String> clearDtc() async {
    return sendObd('04', timeout: const Duration(seconds: 3));
  }

  Future<Set<String>> readSupportedPids() async {
    final r = await sendObd('0100', timeout: const Duration(seconds: 2));
    return ObdParser.parseSupportedPids0100(r);
  }

  Future<double?> readPidLive(String pidTwoHex) async {
    final upper = pidTwoHex.toUpperCase().padLeft(2, '0');
    final r = await sendObd('01$upper', timeout: const Duration(milliseconds: 900));
    return ObdParser.parseMode01Value(upper, r);
  }

  /// Read Vehicle Identification Number (VIN) using OBD mode 9 service 2
  Future<String?> readVin() async {
    try {
      final response = await sendObd('0902', timeout: const Duration(seconds: 3));
      return _parseVinResponse(response);
    } catch (e) {
      // VIN reading failed
      return null;
    }
  }

  /// Parse VIN response from OBD
  /// Response format: "0902: 49 4E 4A 00 00 00 00" where hex represents ASCII characters
  String? _parseVinResponse(String response) {
    try {
      // Remove mode and service identifier
      final cleaned = response.replaceAll('0902:', '').trim();
      
      // Split by spaces and filter out empty strings
      final hexParts = cleaned.split(' ').where((part) => part.isNotEmpty).toList();
      
      // Convert hex to ASCII characters
      final vinChars = hexParts.map((hex) {
        if (hex.length == 2) {
          final code = int.parse(hex, radix: 16);
          return String.fromCharCode(code);
        }
        return '';
      }).toList();
      
      final vin = vinChars.join('').trim();
      
      // Validate VIN (17 characters, no I, O, Q)
      if (vin.length == 17 && !vin.contains(RegExp(r'[IOQ]'))) {
        return vin;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Read ECU name using OBD mode 9 service 0A
  Future<String?> readEcuName() async {
    try {
      final response = await sendObd('090A', timeout: const Duration(seconds: 2));
      return _parseEcuNameResponse(response);
    } catch (e) {
      return null;
    }
  }

  /// Parse ECU name response from OBD
  String? _parseEcuNameResponse(String response) {
    try {
      // Remove mode and service identifier
      final cleaned = response.replaceAll('090A:', '').trim();
      
      // Split by spaces and filter out empty strings
      final hexParts = cleaned.split(' ').where((part) => part.isNotEmpty).toList();
      
      // Convert hex to ASCII characters
      final nameChars = hexParts.map((hex) {
        if (hex.length == 2) {
          final code = int.parse(hex, radix: 16);
          return String.fromCharCode(code);
        }
        return '';
      }).toList();
      
      return nameChars.join('').trim();
    } catch (e) {
      return '';
    }
  }

  /// Несколько попыток переподключения.
  static Future<T?> withReconnect<T>(
    Future<T> Function() action,
    Future<void> Function() reconnect, {
    int attempts = 3,
    Duration gap = const Duration(seconds: 2),
  }) async {
    for (var i = 0; i < attempts; i++) {
      try {
        return await action();
      } catch (_) {
        if (i == attempts - 1) rethrow;
        await reconnect();
        await Future.delayed(gap);
      }
    }
    return null;
  }
}
