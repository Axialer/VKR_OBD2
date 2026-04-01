import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/autodiag_repository.dart';
import '../../../data/models/autodiag_models.dart';
import '../../providers/cars_provider.dart';
import '../../providers/diagnostics_provider.dart';
import 'vin_detection_screen.dart';

class AddCarWizard extends StatefulWidget {
  const AddCarWizard({super.key});

  @override
  State<AddCarWizard> createState() => _AddCarWizardState();
}

class _AddCarWizardState extends State<AddCarWizard> {
  final _pageController = PageController();
  int _currentStep = 0;

  int? _selectedBrandId;
  int? _selectedModelId;
  int? _selectedGenerationId;

  String _customBrand = '';
  String _customModel = '';
  String _customGeneration = '';

  final _yearController = TextEditingController();
  final _vinController = TextEditingController();
  final _mileageController = TextEditingController(text: '0');

  List<CarBrand> _brands = [];
  List<CarModel> _models = [];
  List<CarGeneration> _generations = [];

  final _brandSearchController = TextEditingController();
  final _modelSearchController = TextEditingController();
  final _genSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    final repo = context.read<AutodiagRepository>();
    final brands = await repo.getAllBrands();
    setState(() => _brands = brands);
  }

  Future<void> _loadModels() async {
    if (_selectedBrandId == null) return;
    final repo = context.read<AutodiagRepository>();
    final models = await repo.getModelsByBrand(_selectedBrandId!);
    setState(() => _models = models);
  }

  Future<void> _loadGenerations() async {
    if (_selectedModelId == null) return;
    final repo = context.read<AutodiagRepository>();
    final gens = await repo.getGenerationsByModel(_selectedModelId!);
    setState(() => _generations = gens);
  }

  void _selectBrand(int id) {
    setState(() {
      _selectedBrandId = id;
      _customBrand = '';
      _selectedModelId = null;
      _selectedGenerationId = null;
    });
    _loadModels();
  }

  void _selectModel(int id) {
    setState(() {
      _selectedModelId = id;
      _customModel = '';
      _selectedGenerationId = null;
    });
    _loadGenerations();
  }

  void _selectGeneration(int id) {
    setState(() {
      _selectedGenerationId = id;
      _customGeneration = '';
    });
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _saveCar();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveCar() async {
    final brand = _customBrand.isNotEmpty
        ? _customBrand
        : _brands.firstWhere((b) => b.id == _selectedBrandId).name;
    final model = _customModel.isNotEmpty
        ? _customModel
        : _models.firstWhere((m) => m.id == _selectedModelId).name;
    final generation = _customGeneration.isNotEmpty
        ? _customGeneration
        : (_selectedGenerationId != null
        ? _generations.firstWhere((g) => g.id == _selectedGenerationId).name
        : null);

    final year = _yearController.text.isNotEmpty ? int.tryParse(_yearController.text) : null;
    final mileage = int.tryParse(_mileageController.text) ?? 0;
    final vin = _vinController.text.trim().toUpperCase();

    try {
      await context.read<CarsProvider>().addCar(
        brand: brand,
        model: model,
        generation: generation,
        year: year,
        vin: vin.isNotEmpty ? vin : null,
        mileage: mileage,
      );
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Автомобиль успешно добавлен')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  Future<void> _detectCarViaObd() async {
    final diag = context.read<DiagnosticsProvider>();
    if (!diag.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Сначала подключитесь к OBD-II адаптеру'),
          action: SnackBarAction(label: 'Подключить', onPressed: _navigateToDiagnostics),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VinDetectionScreen()),
    );
    final vinInfo = diag.detectedVinInfo;
    if (vinInfo != null && vinInfo.isValid) {
      final repo = context.read<AutodiagRepository>();
      final brands = await repo.getAllBrands();
      final found = brands.firstWhere(
              (b) => b.name.toLowerCase() == vinInfo.brand.toLowerCase(),
          orElse: () => CarBrand(id: 0, name: vinInfo.brand));
      if (found.id > 0) {
        _selectedBrandId = found.id;
        await _loadModels();
      } else {
        _customBrand = vinInfo.brand;
      }
      _vinController.text = vinInfo.vin;
      if (vinInfo.year != null) _yearController.text = vinInfo.year.toString();
      if (_currentStep == 0) _nextStep();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Автоопределение выполнено: ${vinInfo.brand} ${vinInfo.model}'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось определить автомобиль'), backgroundColor: Colors.orange),
      );
    }
  }

  void _navigateToDiagnostics() {
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacementNamed('/diagnostics');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавление автомобиля'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBrandSelectionStep(),
                _buildModelSelectionStep(),
                _buildGenerationSelectionStep(),
                _buildAdditionalDataStep(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildProgressStep(0, 'Марка'),
          _buildProgressSeparator(),
          _buildProgressStep(1, 'Модель'),
          _buildProgressSeparator(),
          _buildProgressStep(2, 'Поколение'),
          _buildProgressSeparator(),
          _buildProgressStep(3, 'Данные'),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String title) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;

    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (step < 3) const SizedBox(width: 8),
              if (step < 3)
                Expanded(
                  child: Container(
                    height: 2,
                    color: step < _currentStep
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSeparator() => const SizedBox(width: 8);

  Widget _buildBrandSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выберите марку автомобиля',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Начните вводить для поиска или выберите из списка',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: OutlinedButton.icon(
              onPressed: _detectCarViaObd,
              icon: const Icon(Icons.sensors),
              label: const Text('Определить через OBD-II'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
            ),
          ),
          TextField(
            controller: _brandSearchController,
            decoration: const InputDecoration(
              labelText: 'Поиск марки',
              prefixIcon: Icon(Icons.search),
              hintText: 'Например: Toyota, Lada, BMW',
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_brandSearchController.text.isNotEmpty &&
              !_brands.any((b) => b.name.toLowerCase().contains(_brandSearchController.text.toLowerCase())))
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Добавить новую марку'),
                subtitle: Text(_brandSearchController.text),
                onTap: () {
                  setState(() {
                    _customBrand = _brandSearchController.text.trim();
                    _selectedBrandId = null;
                  });
                },
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _brands.length,
              itemBuilder: (context, index) {
                final brand = _brands[index];
                final isSelected = brand.id == _selectedBrandId || brand.name == _customBrand;
                return Card(
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                  child: InkWell(
                    onTap: () => _selectBrand(brand.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                brand.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              brand.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelectionStep() {
    final hasBrand = _selectedBrandId != null || _customBrand.isNotEmpty;
    if (!hasBrand) {
      return const Center(child: Text('Сначала выберите марку'));
    }
    final filteredModels = _models.where((m) {
      final query = _modelSearchController.text.toLowerCase();
      return query.isEmpty || m.name.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выберите модель ${_customBrand.isNotEmpty ? _customBrand : _brands.firstWhere((b) => b.id == _selectedBrandId).name}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите из списка или введите вручную',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _modelSearchController,
            decoration: const InputDecoration(
              labelText: 'Поиск модели',
              prefixIcon: Icon(Icons.search),
              hintText: 'Например: Camry, Vesta, Golf',
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_modelSearchController.text.isNotEmpty &&
              !_models.any((m) => m.name.toLowerCase().contains(_modelSearchController.text.toLowerCase())))
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Добавить новую модель'),
                subtitle: Text(_modelSearchController.text),
                onTap: () {
                  setState(() {
                    _customModel = _modelSearchController.text.trim();
                    _selectedModelId = null;
                  });
                },
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filteredModels.length,
              itemBuilder: (context, index) {
                final model = filteredModels[index];
                final isSelected = model.id == _selectedModelId || model.name == _customModel;
                return Card(
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.directions_car, color: Colors.grey),
                    ),
                    title: Text(
                      model.name,
                      style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                    onTap: () => _selectModel(model.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationSelectionStep() {
    final hasModel = _selectedModelId != null || _customModel.isNotEmpty;
    if (!hasModel) {
      return const Center(child: Text('Сначала выберите модель'));
    }
    final filteredGens = _generations.where((g) {
      final query = _genSearchController.text.toLowerCase();
      return query.isEmpty || g.name.toLowerCase().contains(query) || g.yearsString.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выберите поколение (опционально)',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Уточните поколение, если необходимо',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _genSearchController,
            decoration: const InputDecoration(
              labelText: 'Поиск поколения',
              prefixIcon: Icon(Icons.search),
              hintText: 'Например: E90, XV40, 2005-2010',
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_genSearchController.text.isNotEmpty &&
              !_generations.any((g) =>
              g.name.toLowerCase().contains(_genSearchController.text.toLowerCase()) ||
                  g.yearsString.toLowerCase().contains(_genSearchController.text.toLowerCase())))
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Добавить своё поколение'),
                subtitle: Text(_genSearchController.text),
                onTap: () {
                  setState(() {
                    _customGeneration = _genSearchController.text.trim();
                    _selectedGenerationId = null;
                  });
                },
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filteredGens.length,
              itemBuilder: (context, index) {
                final gen = filteredGens[index];
                final isSelected = gen.id == _selectedGenerationId || gen.name == _customGeneration;
                return Card(
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.timeline),
                    title: Text(gen.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: gen.yearsString.isNotEmpty ? Text(gen.yearsString) : null,
                    onTap: () => _selectGeneration(gen.id),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedGenerationId = null;
                _customGeneration = '';
              });
            },
            icon: const Icon(Icons.skip_next),
            label: const Text('Пропустить выбор поколения'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalDataStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Дополнительная информация',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Заполните известные данные или пропустите этот шаг',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Год выпуска',
                      hintText: 'Например: 2020',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _vinController,
                    decoration: const InputDecoration(
                      labelText: 'VIN-номер',
                      hintText: '17 символов (опционально)',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mileageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Текущий пробег, км',
                      hintText: 'Например: 50000',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        _yearController.clear();
                        _vinController.clear();
                        _mileageController.text = '0';
                        _saveCar();
                      },
                      child: const Text('Пропустить и сохранить'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Назад'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: _canProceed() ? _nextStep : null,
              child: Text(_currentStep == 3 ? 'Сохранить' : 'Далее'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedBrandId != null || _customBrand.isNotEmpty;
      case 1:
        return (_selectedModelId != null || _customModel.isNotEmpty) && (_selectedBrandId != null || _customBrand.isNotEmpty);
      case 2:
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }
}