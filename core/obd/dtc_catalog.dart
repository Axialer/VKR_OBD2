import 'dart:convert';

import 'package:flutter/services.dart';

/// Расширенный справочник DTC из assets/dtc_extended.json (генерализованные описания OBD-II).
class DtcCatalog {
  DtcCatalog._();
  static final DtcCatalog instance = DtcCatalog._();

  final Map<String, String> _codes = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/dtc_extended.json');
      final o = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in o['codes'] as List<dynamic>) {
        final m = e as Map<String, dynamic>;
        _codes[(m['c'] as String).toUpperCase()] = m['d'] as String;
      }
    } catch (_) {
      // остаётся только встроенный минимум в dtc_hints
    }
    _loaded = true;
  }

  String? lookup(String code) => _codes[code.toUpperCase()];

  int get length => _codes.length;
}
