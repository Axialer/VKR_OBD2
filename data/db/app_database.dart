// lib/core/database/app_database.dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/obd/pid_metadata.dart';
import '../car_metadata.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  static const int _version = 3;

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
  is_completed INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (car_id) REFERENCES car(id) ON DELETE CASCADE
)''');
    await db.execute('CREATE INDEX idx_session_car ON diagnostic_session(car_id)');
    await db.execute('CREATE INDEX idx_session_date ON diagnostic_session(date_time)');
    await db.execute('CREATE INDEX idx_maintenance_car ON maintenance_operation(car_id)');
    await db.execute('CREATE INDEX idx_session_param_session ON session_parameter(session_id)');

    // Таблицы для марок/моделей/поколений
    await _createNewTablesV2(db);
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