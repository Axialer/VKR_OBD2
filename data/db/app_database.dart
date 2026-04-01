// lib/core/database/app_database.dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/obd/pid_metadata.dart';
import '../../core/obd/dtc_hints.dart';
import '../car_metadata.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  static const int _version = 6;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'autodiag.db');
    return openDatabase(
      path,
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedPidParameters(db);
        await _seedDtcReference(db);
        await _seedCarData(db); // 👈 теперь данные тянутся из car_metadata
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createNewTablesV2(db);
          await _seedCarData(db);
        }
        if (oldVersion < 3) {
          await _updatePidParameters(db);
        }
        if (oldVersion < 4) {
          await _createReferenceTablesV4(db);
          await _seedDtcReference(db);
        }
        if (oldVersion < 5) {
          await _upgradeMaintenanceNotificationStateV5(db);
        }
        if (oldVersion < 6) {
          await _upgradeSessionMileageStateV6(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // ... [ваши существующие CREATE TABLE без изменений] ...
    // Основные таблицы
    await db.execute('''
CREATE TABLE car (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  brand TEXT NOT NULL,
  model TEXT NOT NULL,
  generation TEXT,
  year INTEGER,
  vin TEXT,
  current_mileage INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 0
)''');
    await db.execute('''
CREATE TABLE dtc_dictionary (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE diagnostic_session (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  car_id INTEGER NOT NULL,
  date_time INTEGER NOT NULL,
  mileage_at_session INTEGER,
  obd_distance_with_mil_km INTEGER,
  notes TEXT,
  FOREIGN KEY (car_id) REFERENCES car(id) ON DELETE CASCADE
)''');
    await db.execute('''
CREATE TABLE session_dtc (
  session_id INTEGER NOT NULL,
  dtc_id INTEGER NOT NULL,
  dtc_type TEXT NOT NULL,
  PRIMARY KEY (session_id, dtc_id, dtc_type),
  FOREIGN KEY (session_id) REFERENCES diagnostic_session(id) ON DELETE CASCADE,
  FOREIGN KEY (dtc_id) REFERENCES dtc_dictionary(id) ON DELETE CASCADE
)''');
    await db.execute('''
CREATE TABLE pid_parameter (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pid_code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  unit TEXT,
  normal_min REAL,
  normal_max REAL
)''');
    await db.execute('''
CREATE TABLE session_parameter (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  parameter_id INTEGER NOT NULL,
  value REAL NOT NULL,
  timestamp INTEGER NOT NULL,
  FOREIGN KEY (session_id) REFERENCES diagnostic_session(id) ON DELETE CASCADE,
  FOREIGN KEY (parameter_id) REFERENCES pid_parameter(id)
)''');
    await db.execute('''
CREATE TABLE recommendation (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  text TEXT NOT NULL,
  severity INTEGER NOT NULL,
  session_id INTEGER,
  dtc_id INTEGER,
  FOREIGN KEY (session_id) REFERENCES diagnostic_session(id) ON DELETE CASCADE,
  FOREIGN KEY (dtc_id) REFERENCES dtc_dictionary(id) ON DELETE CASCADE
)''');
    await db.execute('''
CREATE TABLE maintenance_operation (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  car_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  interval_type TEXT NOT NULL CHECK(interval_type IN ('mileage', 'date')),
  interval_value INTEGER NOT NULL,
  last_done_mileage INTEGER,
  last_done_date INTEGER,
  next_due_mileage INTEGER,
  next_due_date INTEGER,
  last_notified_stage TEXT,
  last_notified_at INTEGER,
  is_completed INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (car_id) REFERENCES car(id) ON DELETE CASCADE
)''');
    await db.execute('CREATE INDEX idx_session_car ON diagnostic_session(car_id)');
    await db.execute('CREATE INDEX idx_session_date ON diagnostic_session(date_time)');
    await db.execute('CREATE INDEX idx_maintenance_car ON maintenance_operation(car_id)');
    await db.execute('CREATE INDEX idx_session_param_session ON session_parameter(session_id)');
    await _createReferenceTablesV4(db);

    // Таблицы для марок/моделей/поколений
    await _createNewTablesV2(db);
  }

  Future<void> _upgradeMaintenanceNotificationStateV5(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(maintenance_operation)');
    final hasStage = columns.any((c) => c['name'] == 'last_notified_stage');
    if (!hasStage) {
      await db.execute('ALTER TABLE maintenance_operation ADD COLUMN last_notified_stage TEXT');
    }
    final hasAt = columns.any((c) => c['name'] == 'last_notified_at');
    if (!hasAt) {
      await db.execute('ALTER TABLE maintenance_operation ADD COLUMN last_notified_at INTEGER');
    }
  }

  Future<void> _upgradeSessionMileageStateV6(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(diagnostic_session)');
    final hasMileage = columns.any((c) => c['name'] == 'mileage_at_session');
    if (!hasMileage) {
      await db.execute('ALTER TABLE diagnostic_session ADD COLUMN mileage_at_session INTEGER');
    }
    final hasObdDistance = columns.any((c) => c['name'] == 'obd_distance_with_mil_km');
    if (!hasObdDistance) {
      await db.execute('ALTER TABLE diagnostic_session ADD COLUMN obd_distance_with_mil_km INTEGER');
    }
  }

  Future<void> _createReferenceTablesV4(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS dtc_reference (
  code TEXT PRIMARY KEY,
  description TEXT NOT NULL,
  recommendation TEXT,
  severity INTEGER NOT NULL DEFAULT 2,
  category TEXT,
  source TEXT NOT NULL DEFAULT 'fallback',
  updated_at INTEGER NOT NULL
)''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_dtc_ref_category ON dtc_reference(category)');
  }

  Future<void> _createNewTablesV2(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(car)');
    final hasGeneration = columns.any((col) => col['name'] == 'generation');
    if (!hasGeneration) {
      await db.execute('ALTER TABLE car ADD COLUMN generation TEXT');
    }

    await db.execute('''
CREATE TABLE IF NOT EXISTS car_brands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  logo TEXT
)''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS car_models (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  brand_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  FOREIGN KEY (brand_id) REFERENCES car_brands (id) ON DELETE CASCADE,
  UNIQUE(brand_id, name)
)''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS car_generations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  model_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  years_start INTEGER,
  years_end INTEGER,
  FOREIGN KEY (model_id) REFERENCES car_models (id) ON DELETE CASCADE,
  UNIQUE(model_id, name)
)''');
  }

  Future<void> _seedPidParameters(Database db) async {
    for (final entry in allPidMeta.entries) {
      final meta = entry.value;
      await db.insert('pid_parameter', {
        'pid_code': meta.pid,
        'name': meta.name,
        'unit': meta.unit,
        'normal_min': meta.normalMin,
        'normal_max': meta.normalMax,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _updatePidParameters(Database db) async {
    for (final entry in allPidMeta.entries) {
      final meta = entry.value;
      final updated = await db.update(
        'pid_parameter',
        {
          'name': meta.name,
          'unit': meta.unit,
          'normal_min': meta.normalMin,
          'normal_max': meta.normalMax,
        },
        where: 'pid_code = ?',
        whereArgs: [meta.pid],
      );
      if (updated == 0) {
        await db.insert('pid_parameter', {
          'pid_code': meta.pid,
          'name': meta.name,
          'unit': meta.unit,
          'normal_min': meta.normalMin,
          'normal_max': meta.normalMax,
        });
      }
    }
  }

  Future<void> _seedDtcReference(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final desc = dtcDescriptionsFallbackRu();
    final recs = dtcRecommendationsFallbackRu();
    for (final e in desc.entries) {
      final code = e.key.toUpperCase();
      await db.insert('dtc_reference', {
        'code': code,
        'description': e.value,
        'recommendation': recs[code],
        'severity': _defaultSeverityByCode(code),
        'category': _categoryByCode(code),
        'source': 'fallback',
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (final e in recs.entries) {
      final code = e.key.toUpperCase();
      await db.insert('dtc_reference', {
        'code': code,
        'description': desc[code] ?? 'Код зарегистрирован ЭБУ',
        'recommendation': e.value,
        'severity': _defaultSeverityByCode(code),
        'category': _categoryByCode(code),
        'source': 'fallback',
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  int _defaultSeverityByCode(String code) {
    if (code == 'P0524' || code == 'P0217') return 3;
    if (code == 'P0562' || code == 'P0563') return 3;
    return 2;
  }

  String _categoryByCode(String code) {
    if (!code.startsWith('P')) return 'generic';
    final two = code.length >= 3 ? code.substring(1, 3) : '';
    switch (two) {
      case '01':
      case '02':
        return 'fuel_air';
      case '03':
        return 'ignition';
      case '04':
        return 'emission';
      case '05':
      case '06':
        return 'electrical_ecu';
      case '07':
      case '08':
      case '09':
        return 'transmission';
      default:
        return 'generic';
    }
  }

  /// 🚗 Сидирование данных об автомобилях из car_metadata.dart
  Future<void> _seedCarData(Database db) async {
    // Проверяем, есть ли уже данные — чтобы не дублировать при перезапуске
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM car_brands'),
    );
    if (count != null && count > 0) return;

    for (final brand in allCarBrands) {
      final brandId = await db.insert(
        'car_brands',
        {'name': brand.name, 'logo': brand.logo},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      for (final model in brand.models) {
        final modelId = await db.insert(
          'car_models',
          {'brand_id': brandId, 'name': model.name},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        for (final gen in model.generations) {
          await db.insert(
            'car_generations',
            {
              'model_id': modelId,
              'name': gen.name,
              'years_start': gen.yearStart,
              'years_end': gen.yearEnd,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}