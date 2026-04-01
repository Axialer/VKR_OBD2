class CarBrand {
  final int id;
  final String name;
  final String? logo;

  CarBrand({required this.id, required this.name, this.logo});

  factory CarBrand.fromMap(Map<String, dynamic> map) {
    return CarBrand(
      id: map['id'],
      name: map['name'],
      logo: map['logo'],
    );
  }
}

class CarModel {
  final int id;
  final int brandId;
  final String name;

  CarModel({required this.id, required this.brandId, required this.name});

  factory CarModel.fromMap(Map<String, dynamic> map) {
    return CarModel(
      id: map['id'],
      brandId: map['brand_id'],
      name: map['name'],
    );
  }
}

class CarGeneration {
  final int id;
  final int modelId;
  final String name;
  final int? yearsStart;
  final int? yearsEnd;

  CarGeneration({
    required this.id,
    required this.modelId,
    required this.name,
    this.yearsStart,
    this.yearsEnd,
  });

  factory CarGeneration.fromMap(Map<String, dynamic> map) {
    return CarGeneration(
      id: map['id'],
      modelId: map['model_id'],
      name: map['name'],
      yearsStart: map['years_start'],
      yearsEnd: map['years_end'],
    );
  }

  String get yearsString {
    if (yearsStart != null && yearsEnd != null) {
      return '$yearsStart-$yearsEnd';
    } else if (yearsStart != null) {
      return 'с $yearsStart';
    } else if (yearsEnd != null) {
      return 'до $yearsEnd';
    }
    return '';
  }
}

class Car {
  final int id;
  final String brand;
  final String model;
  final String? generation;
  final int? year;
  final String? vin;
  final int currentMileage;
  final bool isActive;

  Car({
    required this.id,
    required this.brand,
    required this.model,
    this.generation,
    this.year,
    this.vin,
    required this.currentMileage,
    required this.isActive,
  });

  String get displayName => generation != null
      ? '$brand $model ($generation)'
      : '$brand $model';

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'],
      brand: map['brand'],
      model: map['model'],
      generation: map['generation'],
      year: map['year'],
      vin: map['vin'],
      currentMileage: map['current_mileage'],
      isActive: map['is_active'] == 1,
    );
  }
}

class PidMeta {
  final int id;
  final String pidCode;
  final String name;
  final String? unit;
  final double? normalMin;
  final double? normalMax;

  const PidMeta({
    required this.id,
    required this.pidCode,
    required this.name,
    this.unit,
    this.normalMin,
    this.normalMax,
  });

  factory PidMeta.fromMap(Map<String, Object?> m) {
    return PidMeta(
      id: (m['id'] as num).toInt(),
      pidCode: m['pid_code'] as String,
      name: m['name'] as String,
      unit: m['unit'] as String?,
      normalMin: (m['normal_min'] as num?)?.toDouble(),
      normalMax: (m['normal_max'] as num?)?.toDouble(),
    );
  }
}

class LiveDtc {
  final String code;
  final String description;
  final String type; // current | pending

  const LiveDtc({
    required this.code,
    required this.description,
    required this.type,
  });
}

class DiagnosticSessionRow {
  final int id;
  final int carId;
  final DateTime dateTime;
  final String? notes;
  final String carLabel;
  final int dtcCount;

  const DiagnosticSessionRow({
    required this.id,
    required this.carId,
    required this.dateTime,
    this.notes,
    required this.carLabel,
    required this.dtcCount,
  });
}

class SessionDtcRow {
  final String code;
  final String description;
  final String type;

  const SessionDtcRow({
    required this.code,
    required this.description,
    required this.type,
  });
}

class SessionParamRow {
  final String pidCode;
  final String name;
  final String? unit;
  final double value;
  final DateTime at;

  const SessionParamRow({
    required this.pidCode,
    required this.name,
    this.unit,
    required this.value,
    required this.at,
  });
}

class MaintenanceRow {
  final int id;
  final int carId;
  final String title;
  final String intervalType;
  final int intervalValue;
  final int? lastDoneMileage;
  final DateTime? lastDoneDate;
  final int? nextDueMileage;
  final DateTime? nextDueDate;
  final int isCompleted;

  const MaintenanceRow({
    required this.id,
    required this.carId,
    required this.title,
    required this.intervalType,
    required this.intervalValue,
    this.lastDoneMileage,
    this.lastDoneDate,
    this.nextDueMileage,
    this.nextDueDate,
    required this.isCompleted,
  });

  factory MaintenanceRow.fromMap(Map<String, Object?> m) {
    return MaintenanceRow(
      id: (m['id'] as num).toInt(),
      carId: (m['car_id'] as num).toInt(),
      title: m['title'] as String,
      intervalType: m['interval_type'] as String,
      intervalValue: (m['interval_value'] as num).toInt(),
      lastDoneMileage: (m['last_done_mileage'] as num?)?.toInt(),
      lastDoneDate: (m['last_done_date'] as num?) != null
          ? DateTime.fromMillisecondsSinceEpoch((m['last_done_date'] as num).toInt())
          : null,
      nextDueMileage: (m['next_due_mileage'] as num?)?.toInt(),
      nextDueDate: (m['next_due_date'] as num?) != null
          ? DateTime.fromMillisecondsSinceEpoch((m['next_due_date'] as num).toInt())
          : null,
      isCompleted: (m['is_completed'] as num?)?.toInt() ?? 0,
    );
  }
}

enum MaintUiStatus { ok, soon, overdue }

MaintUiStatus maintenanceStatus(MaintenanceRow row, int currentMileage, {int warnMileageRemaining = 500}) {
  final now = DateTime.now();
  if (row.intervalType == 'mileage') {
    final next = row.nextDueMileage;
    if (next == null) return MaintUiStatus.ok;
    if (currentMileage >= next) return MaintUiStatus.overdue;
    if (next - currentMileage <= warnMileageRemaining) return MaintUiStatus.soon;
    return MaintUiStatus.ok;
  } else {
    final next = row.nextDueDate;
    if (next == null) return MaintUiStatus.ok;
    if (now.isAfter(next)) return MaintUiStatus.overdue;
    if (next.difference(now).inDays <= 7) return MaintUiStatus.soon;
    return MaintUiStatus.ok;
  }
}
