import '../obd/pid_metadata.dart';
import '../obd/dtc_hints.dart';
import '../../data/models/autodiag_models.dart';

class EngineRecommendation {
  final String text;
  /// 1..3 (1=инфо, 2=предупреждение, 3=критично)
  final int severity;

  const EngineRecommendation({required this.text, required this.severity});
}

class RecommendationEngine {
  const RecommendationEngine();

  List<EngineRecommendation> build({
    required Map<String, double> pidSnapshot,
    required List<LiveDtc> dtcs,
    Map<String, List<double>> pidHistory = const {},
    Set<String> recurringDtcs = const {},
  }) {
    final out = <EngineRecommendation>[];

    // 1) DTC: если есть DTC без готовой рекомендации — всё равно дать “следующий шаг”
    for (final d in dtcs) {
      final rec = dtcRecommendationRu(d.code);
      if (rec == null || rec.trim().isEmpty) {
        out.add(EngineRecommendation(
          severity: 2,
          text:
              'Код ${d.code.toUpperCase()}: ${d.description}. Рекомендуется проверить сервисную документацию по этому коду и выполнить базовую диагностику по цепи/узлу.',
        ));
      }
      if (recurringDtcs.contains(d.code.toUpperCase())) {
        out.add(EngineRecommendation(
          severity: 3,
          text:
              'Прогноз: код ${d.code.toUpperCase()} повторяется в нескольких последних сессиях. Высокая вероятность устойчивой неисправности — рекомендуется углублённая проверка узла.',
        ));
      }
    }

    // 2) Общие правила по нормальному диапазону из метаданных PID
    for (final e in pidSnapshot.entries) {
      final pid = e.key.toUpperCase().padLeft(2, '0');
      final v = e.value;
      final meta = allPidMeta[pid];
      if (meta == null) continue;
      final nm = meta.normalMin;
      final nx = meta.normalMax;
      if (nm == null && nx == null) continue;
      if (_inRange(v, nm, nx)) continue;

      final sev = _severityFromDistance(v, nm, nx);
      final unit = meta.unit;
      final norm = _formatNorm(nm, nx, unit);
      out.add(EngineRecommendation(
        severity: sev,
        text:
            '${meta.name}: ${_fmt(v)}${unit == null || unit.isEmpty ? '' : ' $unit'} (норма $norm).',
      ));
    }

    // 3) Специфичные эвристики по ключевым PID (более “человеческие” рекомендации)
    final coolant = _pid(pidSnapshot, '05');
    if (coolant != null) {
      if (coolant >= 110) {
        out.add(const EngineRecommendation(
          severity: 3,
          text:
              'Высокая температура охлаждающей жидкости. Остановитесь, дайте двигателю остыть и проверьте уровень ОЖ, работу вентилятора/термостата и утечки.',
        ));
      } else if (coolant < 60) {
        out.add(const EngineRecommendation(
          severity: 1,
          text:
              'Низкая температура охлаждающей жидкости. Если двигатель прогрет, возможен заклинивший в открытом положении термостат (долгий прогрев, повышенный расход).',
        ));
      }
    }

    final batt = _pid(pidSnapshot, '34');
    if (batt != null) {
      if (batt < 11.7) {
        out.add(const EngineRecommendation(
          severity: 3,
          text:
              'Низкое напряжение бортсети. Проверьте АКБ, клеммы/массу, генератор и ремень — возможны проблемы с зарядкой.',
        ));
      } else if (batt > 15.2) {
        out.add(const EngineRecommendation(
          severity: 3,
          text:
              'Высокое напряжение бортсети. Возможна неисправность регулятора напряжения/генератора — есть риск повредить электронику.',
        ));
      } else if (batt < 12.2) {
        out.add(const EngineRecommendation(
          severity: 2,
          text:
              'Пониженное напряжение бортсети. Если двигатель работает — проверьте зарядку; если заглушен — вероятно, АКБ разряжен.',
        ));
      }
    }

    final stft1 = _pid(pidSnapshot, '06');
    final ltft1 = _pid(pidSnapshot, '07');
    final stft2 = _pid(pidSnapshot, '08');
    final ltft2 = _pid(pidSnapshot, '09');
    final trims = <double>[
      if (stft1 != null) stft1,
      if (ltft1 != null) ltft1,
      if (stft2 != null) stft2,
      if (ltft2 != null) ltft2,
    ];
    if (trims.isNotEmpty) {
      final worst = trims.map((x) => x.abs()).reduce((a, b) => a > b ? a : b);
      if (worst >= 25) {
        out.add(const EngineRecommendation(
          severity: 3,
          text:
              'Сильные топливные коррекции (STFT/LTFT). Возможны подсос воздуха, проблемы с ДМРВ/ДАД, давлением топлива или лямбда‑зондом — нужна проверка смеси.',
        ));
      } else if (worst >= 15) {
        out.add(const EngineRecommendation(
          severity: 2,
          text:
              'Топливные коррекции повышены. Рекомендуется проверить подсос воздуха, состояние впуска, датчики MAF/MAP и качество топлива.',
        ));
      }
    }

    final lambda = _pid(pidSnapshot, '36');
    if (lambda != null && (lambda < 0.95 || lambda > 1.05)) {
      out.add(const EngineRecommendation(
        severity: 2,
        text:
            'Отклонение λ от стехиометрии. Проверьте лямбда‑зонд(ы), подсос воздуха и давление топлива; при наличии DTC — следуйте диагностике по коду.',
      ));
    }

    // 4) Прогноз по трендам истории сессий
    final coolantHistory = pidHistory['05'];
    if (coolant != null && coolantHistory != null && coolantHistory.length >= 3) {
      final avg = _avg(coolantHistory);
      if (coolant >= avg + 12) {
        out.add(const EngineRecommendation(
          severity: 2,
          text:
              'Прогноз: температура ОЖ растёт относительно предыдущих сессий. Возможен риск перегрева в ближайших поездках — проверьте систему охлаждения заранее.',
        ));
      }
    }

    final battHistory = pidHistory['34'];
    if (batt != null && battHistory != null && battHistory.length >= 3) {
      final avg = _avg(battHistory);
      if (batt <= avg - 0.7 && batt < 12.4) {
        out.add(const EngineRecommendation(
          severity: 2,
          text:
              'Прогноз: напряжение бортсети снижается относительно последних сессий. Возможна деградация АКБ/зарядки — рекомендуется проверить генератор и аккумулятор до отказа.',
        ));
      }
    }

    if (trims.isNotEmpty) {
      final trimHistory = <double>[
        ...?pidHistory['06'],
        ...?pidHistory['07'],
        ...?pidHistory['08'],
        ...?pidHistory['09'],
      ];
      if (trimHistory.length >= 6) {
        final curr = trims.map((e) => e.abs()).reduce((a, b) => a > b ? a : b);
        final histAvg = _avg(trimHistory.map((e) => e.abs()).toList());
        if (curr > histAvg + 8) {
          out.add(const EngineRecommendation(
            severity: 2,
            text:
                'Прогноз: топливные коррекции ухудшаются от сессии к сессии. Вероятно развитие проблемы по впуску/смесеобразованию — лучше устранить до появления стабильных DTC.',
          ));
        }
      }
    }

    // Дедуп и сортировка
    final uniq = <String, EngineRecommendation>{};
    for (final r in out) {
      final key = r.text.trim();
      if (key.isEmpty) continue;
      final prev = uniq[key];
      if (prev == null || r.severity > prev.severity) uniq[key] = r;
    }
    final list = uniq.values.toList()
      ..sort((a, b) => b.severity.compareTo(a.severity));
    return list;
  }

  static double? _pid(Map<String, double> snap, String pid) {
    final key = pid.toUpperCase().padLeft(2, '0');
    return snap[key];
  }

  static bool _inRange(double v, double? min, double? max) {
    if (min != null && v < min) return false;
    if (max != null && v > max) return false;
    return true;
  }

  static int _severityFromDistance(double v, double? min, double? max) {
    // Простая шкала: сильный выход за пределы => критично.
    double dist = 0;
    if (min != null && v < min) dist = (min - v).abs();
    if (max != null && v > max) dist = (v - max).abs();

    // Нормируем “на глаз” через ширину диапазона, если она известна.
    double? span;
    if (min != null && max != null && max > min) span = max - min;
    final ratio = span == null ? null : (dist / span);

    if (ratio != null) {
      if (ratio >= 0.35) return 3;
      if (ratio >= 0.15) return 2;
      return 1;
    }

    if (dist >= 20) return 3;
    if (dist >= 10) return 2;
    return 1;
  }

  static String _formatNorm(double? min, double? max, String? unit) {
    final u = (unit == null || unit.isEmpty) ? '' : ' $unit';
    if (min != null && max != null) return '${_fmt(min)}–${_fmt(max)}$u';
    if (min != null) return '≥ ${_fmt(min)}$u';
    if (max != null) return '≤ ${_fmt(max)}$u';
    return '—';
  }

  static String _fmt(double v) {
    final abs = v.abs();
    if (abs >= 100) return v.toStringAsFixed(0);
    if (abs >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

  static double _avg(List<double> values) {
    if (values.isEmpty) return 0;
    final sum = values.fold<double>(0, (a, b) => a + b);
    return sum / values.length;
  }
}

