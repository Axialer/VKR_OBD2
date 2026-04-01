import 'package:flutter/foundation.dart';

import '../../core/services/notification_service.dart';
import '../../data/autodiag_repository.dart';
import '../../data/models/autodiag_models.dart';

class MaintenanceProvider extends ChangeNotifier {
  MaintenanceProvider(this._repo);
  final AutodiagRepository _repo;

  List<MaintenanceRow> items = [];
  int? _carId;

  Future<void> loadForCar(int? carId, Car? car, bool notifyEnabled) async {
    _carId = carId;
    if (carId == null) {
      items = [];
      notifyListeners();
      return;
    }
    items = await _repo.listMaintenance(carId);
    notifyListeners();
    if (car != null) {
      try {
        await NotificationService.instance.syncMaintenanceNotifications(
          enabled: notifyEnabled,
          rows: items,
          car: car,
        );
      } catch (_) {}
    }
  }

  Future<void> addOperation({
    required int carId,
    required String title,
    required String intervalType,
    required int intervalValue,
    required int baselineMileage,
    required DateTime baselineDate,
    Car? car,
    bool notifyEnabled = true,
  }) async {
    await _repo.insertMaintenance(
      carId: carId,
      title: title,
      intervalType: intervalType,
      intervalValue: intervalValue,
      baselineMileage: baselineMileage,
      baselineDate: baselineDate,
    );
    await loadForCar(_carId ?? carId, car, notifyEnabled);
  }

  Future<void> markDone(int opId, Car car, bool notifyEnabled) async {
    await _repo.markMaintenanceDone(
      opId,
      car.currentMileage,
      DateTime.now(),
    );
    await loadForCar(car.id, car, notifyEnabled);
  }

  Future<void> updateOp(
    int id, {
    String? title,
    int? intervalValue,
    String? intervalType,
  }) async {
    await _repo.updateMaintenance(
      id: id,
      title: title,
      intervalValue: intervalValue,
      intervalType: intervalType,
    );
    if (_carId != null) {
      items = await _repo.listMaintenance(_carId!);
      notifyListeners();
    }
  }

  Future<void> deleteOp(int id) async {
    await _repo.deleteMaintenance(id);
    if (_carId != null) {
      items = await _repo.listMaintenance(_carId!);
      notifyListeners();
    }
  }
}
