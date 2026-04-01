import 'package:flutter/foundation.dart';

import '../../data/autodiag_repository.dart';
import '../../data/models/autodiag_models.dart';

class CarsProvider extends ChangeNotifier {
  CarsProvider(this._repo);
  final AutodiagRepository _repo;

  List<Car> cars = [];
  Car? active;

  Future<void> refresh() async {
    cars = await _repo.getAllCars();
    active = await _repo.getActiveCar();
    notifyListeners();
  }

  Future<void> addCar({
    required String brand,
    required String model,
    String? generation,
    int? year,
    String? vin,
    int mileage = 0,
    bool makeActive = true,
  }) async {
    await _repo.insertCar(
      brand: brand,
      model: model,
      generation: generation,
      year: year,
      vin: vin,
      mileage: mileage,
      setActive: makeActive || cars.isEmpty,
    );
    await refresh();
  }

  Future<void> updateCarFields({
    required int id,
    String? brand,
    String? model,
    String? generation,
    int? year,
    String? vin,
    int? currentMileage,
  }) async {
    await _repo.updateCar(
      id: id,
      brand: brand,
      model: model,
      generation: generation,
      year: year,
      vin: vin,
      currentMileage: currentMileage,
    );
    await refresh();
  }

  Future<void> setActive(int id) async {
    await _repo.setActiveCar(id);
    await refresh();
  }

  Future<void> remove(int id) async {
    await _repo.deleteCar(id);
    await refresh();
  }
}
