import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/autodiag_models.dart';
import '../../../data/autodiag_repository.dart';
import '../../providers/cars_provider.dart';
import '../../providers/diagnostics_provider.dart';
import '../../../core/services/vin_decoder.dart';

class VinDetectionScreen extends StatelessWidget {
  const VinDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final diag = context.watch<DiagnosticsProvider>();
    final cars = context.watch<CarsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Автоопределение автомобиля'),
        actions: [
          if (diag.detectedVinInfo != null)
            IconButton(
              onPressed: () {
                diag.clearVinDetection();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.clear),
              tooltip: 'Сбросить',
            ),
        ],
      ),
      body: _buildBody(context, diag, cars),
    );
  }

  Widget _buildBody(BuildContext context, DiagnosticsProvider diag, CarsProvider cars) {
    final repo = context.read<AutodiagRepository>();
    
    if (diag.isDetectingCar) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Чтение VIN с автомобиля...'),
            SizedBox(height: 8),
            Text(
              'Это может занять несколько секунд',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (diag.detectedVinInfo == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Не удалось определить автомобиль',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Убедитесь, что автомобиль поддерживает OBD-II\nи VIN доступен для чтения',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Назад'),
            ),
          ],
        ),
      );
    }

    final vinInfo = diag.detectedVinInfo!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Статус определения
          Card(
            color: vinInfo.isValid 
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    vinInfo.isValid ? Icons.check_circle : Icons.error,
                    color: vinInfo.isValid 
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      vinInfo.isValid 
                          ? 'Автомобиль успешно определен'
                          : 'Ошибка чтения VIN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: vinInfo.isValid 
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Информация об автомобиле
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Информация об автомобиле',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('VIN', vinInfo.vin, context),
                  _buildInfoRow('Производитель', vinInfo.manufacturer, context),
                  _buildInfoRow('Бренд', vinInfo.brand, context),
                  _buildInfoRow('Модель', vinInfo.model, context),
                  if (vinInfo.year != null)
                    _buildInfoRow('Год выпуска', vinInfo.year.toString(), context),
                  if (diag.ecuName != null && diag.ecuName!.isNotEmpty)
                    _buildInfoRow('ECU', diag.ecuName!, context),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Действия
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Действия',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Проверка на существующий автомобиль
                  FutureBuilder<List<Car>>(
                    future: repo.getAllCars(),
                    builder: (context, snapshot) {
                      final existingCars = snapshot.data ?? [];
                      Car? existingCar;
                      try {
                        existingCar = existingCars.firstWhere(
                          (car) => car.vin == vinInfo.vin,
                        );
                      } catch (e) {
                        existingCar = null;
                      }

                      if (existingCar != null) {
                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Автомобиль уже существует',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    existingCar.displayName,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  await repo.setActiveCar(existingCar!.id);
                                  await cars.refresh();
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Сделать активным'),
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: vinInfo.isValid ? () => _createCar(context, diag, cars) : null,
                              icon: const Icon(Icons.add),
                              label: const Text('Добавить автомобиль'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/add_car'),
                              icon: const Icon(Icons.edit),
                              label: const Text('Добавить с редактированием'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Техническая информация
          ExpansionTile(
            title: const Text('Техническая информация'),
            leading: const Icon(Icons.info_outline),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статус VIN:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(vinInfo.isValid ? 'Валидный' : 'Невалидный'),
                    const SizedBox(height: 8),
                    Text(
                      'WMI (World Manufacturer Identifier):',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(vinInfo.vin.substring(0, 3)),
                    if (vinInfo.year != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Год выпуска (из VIN):',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(vinInfo.year.toString()),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createCar(BuildContext context, DiagnosticsProvider diag, CarsProvider cars) async {
    try {
      final car = await diag.createCarFromVin();
      if (car != null) {
        await cars.refresh();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Автомобиль успешно добавлен')),
          );
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка при добавлении автомобиля')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}
