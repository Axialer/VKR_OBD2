/// Парсинг ответов ELM327 / SAE J1979 (режим 01, 03, 07).
class ObdParser {
  static String normalizeHex(String raw) {
    return raw
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll('SEARCHING', '')
        .replaceAll(RegExp(r'[^0-9A-Fa-f]'), '')
        .toUpperCase();
  }

  static List<int> hexToBytes(String hex) {
    final clean = normalizeHex(hex);
    if (clean.length.isOdd) return [];
    final out = <int>[];
    for (var i = 0; i < clean.length; i += 2) {
      out.add(int.parse(clean.substring(i, i + 2), radix: 16));
    }
    return out;
  }

  /// Декодирование пары байт в DTC (P/C/B/U + 4 hex-цифры).
  static String dtcFromTwoBytes(int a, int b) {
    const types = ['P', 'C', 'B', 'U'];
    final t = types[(a >> 6) & 0x03];
    final d2 = (a >> 4) & 0x03;
    final d3 = a & 0x0F;
    final d4 = (b >> 4) & 0x0F;
    final d5 = b & 0x0F;
    String h(int n) => n.toRadixString(16).toUpperCase();
    return '$t$d2${h(d3)}${h(d4)}${h(d5)}';
  }

  /// Режим 03 / 07: полезная нагрузка после заголовка 43 или 47.
  static List<String> parseDtcResponse(String raw, {required int mode}) {
    final bytes = hexToBytes(raw);
    if (bytes.length < 3) return [];
    final expect = 0x40 + mode;
    if (bytes[0] != expect) {
      final ni = bytes.indexOf(expect);
      if (ni < 0) return [];
      return _parseDtcBytes(bytes.sublist(ni));
    }
    return _parseDtcBytes(bytes);
  }

  static List<String> _parseDtcBytes(List<int> bytes) {
    if (bytes.length < 2) return [];
    final list = <String>[];
    var i = 1;
    while (i + 1 < bytes.length) {
      final a = bytes[i];
      final b = bytes[i + 1];
      if (a == 0 && b == 0) break;
      list.add(dtcFromTwoBytes(a, b));
      i += 2;
    }
    return list;
  }

  /// Поддерживаемые PID (01–20): ответ на 0100 — первый байт 41, второй 00.
  static Set<String> parseSupportedPids0100(String raw) {
    final bytes = hexToBytes(raw);
    if (bytes.length < 6) return {};
    var off = 0;
    while (off + 5 < bytes.length) {
      if (bytes[off] == 0x41 && bytes[off + 1] == 0x00) {
        final d = bytes.sublist(off + 2, off + 6);
        return _bitmapToPidHex(d, basePid: 0x01);
      }
      off++;
    }
    if (bytes.length >= 6 && bytes[0] == 0x41 && bytes[1] == 0x00) {
      final d = bytes.sublist(2, 6);
      return _bitmapToPidHex(d, basePid: 0x01);
    }
    return {};
  }

  static Set<String> _bitmapToPidHex(List<int> fourBytes, {required int basePid}) {
    final out = <String>{};
    final bits = <int>[];
    for (final b in fourBytes) {
      for (var i = 7; i >= 0; i--) {
        bits.add((b >> i) & 1);
      }
    }
    for (var i = 0; i < bits.length; i++) {
      if (bits[i] == 1) {
        final pid = basePid + i;
        out.add(pid.toRadixString(16).toUpperCase().padLeft(2, '0'));
      }
    }
    return out;
  }

  /// Режим 01: данные после 41 XX
  static double? parseMode01Value(String pidHex, String raw) {
    final bytes = hexToBytes(raw);
    if (bytes.length < 4) return null;
    var off = 0;
    while (off + 3 < bytes.length) {
      if (bytes[off] == 0x41) {
        final p = bytes[off + 1];
        final want = int.parse(pidHex, radix: 16);
        if (p == want && off + 2 < bytes.length) {
          final a = bytes[off + 2];
          final b = off + 3 < bytes.length ? bytes[off + 3] : 0;
          return _formula(pidHex, a, b, bytes, off + 2);
        }
      }
      off++;
    }
    return null;
  }

  static double? _formula(String pid, int a, int b, List<int> all, int startIndex) {
    switch (pid.toUpperCase()) {
      case '04':
        return a / 2.55;
      case '05':
        return a - 40.0;
      case '0C':
        return ((a * 256) + b) / 4.0;
      case '0D':
        return a.toDouble();
      case '0E':
        return a / 2.0 - 64.0;
      case '0F':
      case '46':
        return a - 40.0;
      case '10':
        return ((a * 256) + b) / 100.0;
      case '11':
        return a / 2.55;
      case '42':
        return ((a * 256) + b) / 1000.0;
      case '5C':
        return a - 40.0;
      default:
        if (startIndex + 1 < all.length) {
          return ((a * 256) + b).toDouble();
        }
        return a.toDouble();
    }
  }
}
