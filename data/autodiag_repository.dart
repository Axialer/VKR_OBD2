// autodiag_repository.dart (добавлен метод sessionParamsHistory)

import 'package:sqflite/sqflite.dart';
import '../core/obd/dtc_hints.dart';
import '../core/diagnostics/recommendation_engine.dart';
import 'db/app_database.dart';
import 'models/autodiag_models.dart';

class AutodiagRepository {
  AutodiagRepository(this._db);
  final AppDatabase _db;

  Future<Database> get _d => _db.database;

  // ------------------- Car management -------------------
  Future<Car?> getActiveCar() async {
    final db = await _d;
    final maps = await db.query(
      'car',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Car.fromMap(maps.first);
  }

  Future<List<Car>> getAllCars() async {
    final db = await _d;
    final maps = await db.query('car', orderBy: 'id ASC');
    return maps.map(Car.fromMap).toList();
  }

  Future<int> insertCar({
    required String brand,
    required String model,
    String? generation,
    int? year,
    String? vin,
    int mileage = 0,
    bool setActive = false,
  }) async {
    final db = await _d;
    if (setActive) {
      await db.update('car', {'is_active': 0});
    }
    return db.insert('car', {
      'brand': brand,
      'model': model,
      'generation': generation,
      'year': year,
      'vin': vin,
      'current_mileage': mileage,
      'is_active': setActive ? 1 : 0,
    });
  }

  Future<void> updateCar({
    required int id,
    String? brand,
    String? model,
    String? generation,
    int? year,
    String? vin,
    int? currentMileage,
  }) async {
    final db = await _d;
    final map = <String, Object?>{};
    if (brand != null) map['brand'] = brand;
    if (model != null) map['model'] = model;
    if (generation != null) map['generation'] = generation;
    if (year != null) map['year'] = year;
    if (vin != null) map['vin'] = vin;
    if (currentMileage != null) map['current_mileage'] = currentMileage;
    if (map.isEmpty) return;
    await db.update('car', map, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setActiveCar(int id) async {
    final db = await _d;
    await db.transaction((txn) async {
      await txn.update('car', {'is_active': 0});
      await txn.update('car', {'is_active': 1}, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> deleteCar(int id) async {
    final db = await _d;
    await db.delete('car', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------- Brands, models, generations -------------------
  Future<List<CarBrand>> getAllBrands() async {
    final db = await _d;
    final maps = await db.query('car_brands', orderBy: 'name');
    return maps.map(CarBrand.fromMap).toList();
  }

  Future<List<CarModel>> getModelsByBrand(int brandId) async {
    final db = await _d;
    final maps = await db.query(
      'car_models',
      where: 'brand_id = ?',
      whereArgs: [brandId],
      orderBy: 'name',
    );
    return maps.map(CarModel.fromMap).toList();
  }

  Future<List<CarGeneration>> getGenerationsByModel(int modelId) async {
    final db = await _d;
    final maps = await db.query(
      'car_generations',
      where: 'model_id = ?',
      whereArgs: [modelId],
      orderBy: 'years_start',
    );
    return maps.map(CarGeneration.fromMap).toList();
  }

  Future<int> addBrand(String name) async {
    final db = await _d;
    return db.insert('car_brands', {'name': name});
  }

  Future<int> addModel(int brandId, String name) async {
    final db = await _d;
    return db.insert('car_models', {'brand_id': brandId, 'name': name});
  }

  Future<int> addGeneration(int modelId, String name, int? start, int? end) async {
    final db = await _d;
    return db.insert('car_generations', {
      'model_id': modelId,
      'name': name,
      'years_start': start,
      'years_end': end,
    });
  }

  // ------------------- PID parameters -------------------
  Future<List<PidMeta>> allPidMeta() async {
    final db = await _d;
    final m = await db.query('pid_parameter', orderBy: 'pid_code ASC');
    return m.map(PidMeta.fromMap).toList();
  }

  // ------------------- Diagnostic sessions -------------------
  Future<int> saveDiagnosticSession({
    required int carId,
    required List<LiveDtc> dtcs,
    required Map<String, double> pidSnapshot,
    String notes = '',
    int? mileageAtSession,
    int? obdDistanceWithMilKm,
  }) async {
    final db = await _d;
    final now = DateTime.now().millisecondsSinceEpoch;
    final pidHistory = await _loadPidHistoryByCar(
      carId: carId,
      pids: pidSnapshot.keys,
      limitPerPid: 12,
    );
    final recurringDtcs = await _loadRecurringDtcCodes(
      carId: carId,
      dtcCodes: dtcs.map((d) => d.code),
      lookbackSessions: 8,
    );
    final engine = const RecommendationEngine();
    return db.transaction<int>((txn) async {
      final sid = await txn.insert('diagnostic_session', {
        'car_id': carId,
        'date_time': now,
        'mileage_at_session': mileageAtSession,
        'obd_distance_with_mil_km': obdDistanceWithMilKm,
        'notes': notes,
      });
      for (final d in dtcs) {
        final did = await _ensureDtcTxn(txn, d.code, d.description);
        await txn.insert('session_dtc', {
          'session_id': sid,
          'dtc_id': did,
          'dtc_type': d.type,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        final ref = await _findDtcReferenceTxn(txn, d.code);
        final rec = (ref?['recommendation'] as String?) ?? dtcRecommendationRu(d.code);
        if (rec != null) {
          await txn.insert('recommendation', {
            'text': rec,
            'severity': (ref?['severity'] as num?)?.toInt() ?? 2,
            'session_id': sid,
            'dtc_id': did,
          });
        }
      }
      for (final e in pidSnapshot.entries) {
        final pidUpper = e.key.toUpperCase().padLeft(2, '0');
        final pRow = await txn.query(
          'pid_parameter',
          where: 'pid_code = ?',
          whereArgs: [pidUpper],
          limit: 1,
        );
        int paramId;
        if (pRow.isEmpty) {
          paramId = await txn.insert('pid_parameter', {
            'pid_code': pidUpper,
            'name': 'PID $pidUpper',
            'unit': '',
            'normal_min': null,
            'normal_max': null,
          });
        } else {
          paramId = pRow.first['id'] as int;
        }
        await txn.insert('session_parameter', {
          'session_id': sid,
          'parameter_id': paramId,
          'value': e.value,
          'timestamp': now,
        });
      }

      // Рекомендации по PID+DTC (расширенный движок).
      final engineRecs = engine.build(
        pidSnapshot: pidSnapshot,
        dtcs: dtcs,
        pidHistory: pidHistory,
        recurringDtcs: recurringDtcs,
      );
      for (final r in engineRecs) {
        await txn.insert('recommendation', {
          'text': r.text,
          'severity': r.severity,
          'session_id': sid,
          'dtc_id': null,
        });
      }
      return sid;
    });
  }

  Future<Map<String, List<double>>> _loadPidHistoryByCar({
    required int carId,
    required Iterable<String> pids,
    int limitPerPid = 10,
  }) async {
    final db = await _d;
    final out = <String, List<double>>{};
    for (final rawPid in pids) {
      final pid = rawPid.toUpperCase().padLeft(2, '0');
      final rows = await db.rawQuery('''
SELECT sp.value
FROM session_parameter sp
JOIN pid_parameter p ON p.id = sp.parameter_id
JOIN diagnostic_session s ON s.id = sp.session_id
WHERE s.car_id = ? AND p.pid_code = ?
ORDER BY sp.timestamp DESC
LIMIT ?
''', [carId, pid, limitPerPid]);
      if (rows.isEmpty) continue;
      out[pid] = rows.map((r) => (r['value'] as num).toDouble()).toList().reversed.toList();
    }
    return out;
  }

  Future<Set<String>> _loadRecurringDtcCodes({
    required int carId,
    required Iterable<String> dtcCodes,
    int lookbackSessions = 8,
  }) async {
    final db = await _d;
    final out = <String>{};
    for (final c in dtcCodes) {
      final code = c.toUpperCase();
      final rows = await db.rawQuery('''
SELECT COUNT(*) AS cnt
FROM session_dtc sd
JOIN dtc_dictionary d ON d.id = sd.dtc_id
JOIN diagnostic_session s ON s.id = sd.session_id
WHERE s.car_id = ? AND d.code = ? AND s.id IN (
  SELECT id FROM diagnostic_session
  WHERE car_id = ?
  ORDER BY date_time DESC
  LIMIT ?
)
''', [carId, code, carId, lookbackSessions]);
      final cnt = (rows.first['cnt'] as num?)?.toInt() ?? 0;
      if (cnt >= 2) out.add(code);
    }
    return out;
  }

  Future<Map<String, Object?>?> _findDtcReferenceTxn(Transaction txn, String code) async {
    final rows = await txn.query(
      'dtc_reference',
      where: 'code = ?',
      whereArgs: [code.toUpperCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<int> _ensureDtcTxn(Transaction txn, String code, String description) async {
    final existing = await txn.query(
      'dtc_dictionary',
      where: 'code = ?',
      whereArgs: [code.toUpperCase()],
      limit: 1,
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return txn.insert('dtc_dictionary', {
      'code': code.toUpperCase(),
      'description': description,
    });
  }

  Future<List<DiagnosticSessionRow>> listSessions({int? carIdFilter}) async {
    final db = await _d;
    final where = carIdFilter != null ? 'WHERE s.car_id = ?' : '';
    final args = carIdFilter != null ? [carIdFilter] : <Object?>[];
    final rows = await db.rawQuery('''
SELECT s.id, s.car_id, s.date_time, s.notes,
  s.mileage_at_session, s.obd_distance_with_mil_km,
  (SELECT COUNT(*) FROM session_dtc sd WHERE sd.session_id = s.id) AS dtc_count,
  printf('%s %s', c.brand, c.model) AS car_label
FROM diagnostic_session s
JOIN car c ON c.id = s.car_id
$where
ORDER BY s.date_time DESC
''', args);
    return rows
        .map((m) => DiagnosticSessionRow(
      id: (m['id'] as num).toInt(),
      carId: (m['car_id'] as num).toInt(),
      dateTime: DateTime.fromMillisecondsSinceEpoch(
          (m['date_time'] as num).toInt()),
      notes: m['notes'] as String?,
      carLabel: m['car_label'] as String? ?? '',
      dtcCount: (m['dtc_count'] as num?)?.toInt() ?? 0,
      mileageAtSession: (m['mileage_at_session'] as num?)?.toInt(),
      obdDistanceWithMilKm: (m['obd_distance_with_mil_km'] as num?)?.toInt(),
    ))
        .toList();
  }

  Future<void> updateSessionNotes(int sessionId, String notes) async {
    final db = await _d;
    await db.update(
      'diagnostic_session',
      {'notes': notes},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<SessionDtcRow>> sessionDtcs(int sessionId) async {
    final db = await _d;
    final rows = await db.rawQuery('''
SELECT d.code, d.description, sd.dtc_type
FROM session_dtc sd
JOIN dtc_dictionary d ON d.id = sd.dtc_id
WHERE sd.session_id = ?
ORDER BY d.code
''', [sessionId]);
    return rows
        .map((m) => SessionDtcRow(
      code: m['code'] as String,
      description: m['description'] as String,
      type: m['dtc_type'] as String,
    ))
        .toList();
  }

  Future<List<SessionParamRow>> sessionParams(int sessionId) async {
    final db = await _d;
    final rows = await db.rawQuery('''
SELECT p.pid_code, p.name, p.unit, sp.value, sp.timestamp
FROM session_parameter sp
JOIN pid_parameter p ON p.id = sp.parameter_id
WHERE sp.session_id = ?
ORDER BY p.pid_code, sp.timestamp DESC
''', [sessionId]);
    // Возвращаем только последние значения для каждого PID (можно оставить как есть, но лучше использовать DISTINCT)
    // Здесь мы возвращаем все записи, но для статистики нужна история
    return rows.map((m) => SessionParamRow(
      pidCode: m['pid_code'] as String,
      name: m['name'] as String,
      unit: m['unit'] as String?,
      value: (m['value'] as num).toDouble(),
      at: DateTime.fromMillisecondsSinceEpoch((m['timestamp'] as num).toInt()),
    )).toList();
  }

  // Новый метод для получения всех записей параметров (истории)
  Future<List<SessionParamRow>> sessionParamsHistory(int sessionId) async {
    final db = await _d;
    final rows = await db.rawQuery('''
SELECT p.pid_code, p.name, p.unit, sp.value, sp.timestamp
FROM session_parameter sp
JOIN pid_parameter p ON p.id = sp.parameter_id
WHERE sp.session_id = ?
ORDER BY p.pid_code, sp.timestamp ASC
''', [sessionId]);
    return rows.map((m) => SessionParamRow(
      pidCode: m['pid_code'] as String,
      name: m['name'] as String,
      unit: m['unit'] as String?,
      value: (m['value'] as num).toDouble(),
      at: DateTime.fromMillisecondsSinceEpoch((m['timestamp'] as num).toInt()),
    )).toList();
  }

  Future<List<Map<String, Object?>>> sessionRecommendations(int sessionId) async {
    final db = await _d;
    return db.query(
      'recommendation',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'severity DESC',
    );
  }

  // ------------------- Maintenance -------------------
  Future<int> insertMaintenance({
    required int carId,
    required String title,
    required String intervalType,
    required int intervalValue,
    required int baselineMileage,
    required DateTime baselineDate,
  }) async {
    final db = await _d;
    int? nextM;
    int? nextD;
    if (intervalType == 'mileage') {
      nextM = baselineMileage + intervalValue;
    } else {
      nextD = baselineDate.add(Duration(days: intervalValue)).millisecondsSinceEpoch;
    }
    return db.insert('maintenance_operation', {
      'car_id': carId,
      'title': title,
      'interval_type': intervalType,
      'interval_value': intervalValue,
      'last_done_mileage': intervalType == 'mileage' ? baselineMileage : null,
      'last_done_date':
      intervalType == 'date' ? baselineDate.millisecondsSinceEpoch : null,
      'next_due_mileage': nextM,
      'next_due_date': nextD,
      'last_notified_stage': null,
      'last_notified_at': null,
      'is_completed': 0,
    });
  }

  Future<void> markMaintenanceDone(int opId, int currentMileage, DateTime now) async {
    final db = await _d;
    final row = await db.query(
      'maintenance_operation',
      where: 'id = ?',
      whereArgs: [opId],
      limit: 1,
    );
    if (row.isEmpty) return;
    final m = row.first;
    final type = m['interval_type'] as String;
    final val = (m['interval_value'] as num).toInt();
    final Map<String, Object?> upd = {
      'is_completed': 0,
      'last_notified_stage': null,
      'last_notified_at': null,
    };
    if (type == 'mileage') {
      upd['last_done_mileage'] = currentMileage;
      upd['next_due_mileage'] = currentMileage + val;
      upd['next_due_date'] = null;
    } else {
      upd['last_done_date'] = now.millisecondsSinceEpoch;
      final nd = now.millisecondsSinceEpoch + val * 86400000;
      upd['next_due_date'] = nd;
      upd['next_due_mileage'] = null;
    }
    await db.update('maintenance_operation', upd, where: 'id = ?', whereArgs: [opId]);
  }

  Future<void> updateMaintenance({
    required int id,
    String? title,
    int? intervalValue,
    String? intervalType,
  }) async {
    final db = await _d;
    final map = <String, Object?>{};
    if (title != null) map['title'] = title;
    if (intervalValue != null) map['interval_value'] = intervalValue;
    if (intervalType != null) map['interval_type'] = intervalType;
    if (map.isEmpty) return;
    await db.update('maintenance_operation', map, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteMaintenance(int id) async {
    final db = await _d;
    await db.delete('maintenance_operation', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setMaintenanceNotifiedStage(int opId, String stage) async {
    final db = await _d;
    await db.update(
      'maintenance_operation',
      {
        'last_notified_stage': stage,
        'last_notified_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [opId],
    );
  }

  Future<List<MaintenanceRow>> listMaintenance(int carId) async {
    final db = await _d;
    final maps = await db.query(
      'maintenance_operation',
      where: 'car_id = ?',
      whereArgs: [carId],
      orderBy: 'id ASC',
    );
    return maps.map(MaintenanceRow.fromMap).toList();
  }

  // ------------------- Export -------------------
  Future<List<Map<String, Object?>>> exportSessionsFlat() async {
    final db = await _d;
    return db.rawQuery('''
SELECT s.id, s.date_time, c.brand, c.model, s.notes
FROM diagnostic_session s
JOIN car c ON c.id = s.car_id
ORDER BY s.date_time DESC
''');
  }

  Future<List<Map<String, Object?>>> exportMaintenanceFlat() async {
    final db = await _d;
    return db.rawQuery('''
SELECT m.id, m.title, m.interval_type, m.interval_value,
  m.next_due_mileage, m.next_due_date,
  printf('%s %s', c.brand, c.model) AS car
FROM maintenance_operation m
JOIN car c ON c.id = m.car_id
''');
  }

  // ------------------- Demo data -------------------
  static const kDemoVin = '__AUTODIAG_DEMO__';

  Future<int?> getDemoCarId() async {
    final db = await _d;
    final r = await db.query(
      'car',
      columns: ['id'],
      where: 'vin = ?',
      whereArgs: [kDemoVin],
      limit: 1,
    );
    if (r.isEmpty) return null;
    return (r.first['id'] as num).toInt();
  }

  Future<void> seedDemoData() async {
    final db = await _d;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.update('car', {'is_active': 0});
      int carId;
      final existing =
      await txn.query('car', where: 'vin = ?', whereArgs: [kDemoVin], limit: 1);
      if (existing.isEmpty) {
        carId = await txn.insert('car', {
          'brand': 'Demo',
          'model': 'AutoDiag (образец)',
          'year': 2020,
          'vin': kDemoVin,
          'current_mileage': 98765,
          'is_active': 1,
        });
      } else {
        carId = (existing.first['id'] as num).toInt();
        await txn.update(
          'car',
          {'is_active': 1, 'current_mileage': 98765},
          where: 'id = ?',
          whereArgs: [carId],
        );
      }
      await txn.delete('maintenance_operation', where: 'car_id = ?', whereArgs: [carId]);
      await txn.insert('maintenance_operation', {
        'car_id': carId,
        'title': 'Замена моторного масла',
        'interval_type': 'mileage',
        'interval_value': 10000,
        'last_done_mileage': 90000,
        'next_due_mileage': 100000,
        'is_completed': 0,
      });
      await txn.insert('maintenance_operation', {
        'car_id': carId,
        'title': 'Свечи зажигания',
        'interval_type': 'mileage',
        'interval_value': 30000,
        'last_done_mileage': 78000,
        'next_due_mileage': 108000,
        'is_completed': 0,
      });
      final base = DateTime.now();
      await txn.insert('maintenance_operation', {
        'car_id': carId,
        'title': 'Осмотр по календарю',
        'interval_type': 'date',
        'interval_value': 365,
        'last_done_date': base.subtract(const Duration(days: 300)).millisecondsSinceEpoch,
        'next_due_date': base.add(const Duration(days: 65)).millisecondsSinceEpoch,
        'is_completed': 0,
      });
      final sid = await txn.insert('diagnostic_session', {
        'car_id': carId,
        'date_time':
        DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        'notes': 'Демо-сеанс: проверка истории и экспорта',
      });
      for (final code in ['P0301', 'P0171']) {
        final did = await _ensureDtcTxn(txn, code, dtcDescriptionRu(code));
        await txn.insert('session_dtc', {
          'session_id': sid,
          'dtc_id': did,
          'dtc_type': 'current',
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        final rec = dtcRecommendationRu(code);
        if (rec != null) {
          await txn.insert('recommendation', {
            'text': rec,
            'severity': 2,
            'session_id': sid,
            'dtc_id': did,
          });
        }
      }
      for (final row in <List<dynamic>>[
        ['0C', 2450.0],
        ['0D', 0.0],
        ['05', 92.0],
      ]) {
        final pid = row[0] as String;
        final val = row[1] as double;
        final prow = await txn.query('pid_parameter',
            where: 'pid_code = ?', whereArgs: [pid], limit: 1);
        final pidId = prow.isEmpty
            ? await txn.insert('pid_parameter', {
          'pid_code': pid,
          'name': 'PID $pid',
          'unit': '',
        })
            : (prow.first['id'] as num).toInt();
        await txn.insert('session_parameter', {
          'session_id': sid,
          'parameter_id': pidId,
          'value': val,
          'timestamp': nowMs,
        });
      }
    });
  }

  Future<void> removeDemoData() async {
    final id = await getDemoCarId();
    if (id == null) return;
    final db = await _d;
    final others = await db.query(
      'car',
      where: 'id != ?',
      whereArgs: [id],
      orderBy: 'id ASC',
      limit: 1,
    );
    await db.delete('car', where: 'id = ?', whereArgs: [id]);
    await db.update('car', {'is_active': 0});
    if (others.isNotEmpty) {
      final nid = (others.first['id'] as num).toInt();
      await db.update('car', {'is_active': 1}, where: 'id = ?', whereArgs: [nid]);
    }
  }
}