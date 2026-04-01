import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/autodiag_repository.dart';
import '../../../data/models/autodiag_models.dart';
import '../../providers/cars_provider.dart';
import 'add_car_wizard.dart';

class EditCarScreen extends StatefulWidget {
  const EditCarScreen({super.key, required this.car});

  final Car car;

  @override
  State<EditCarScreen> createState() => _EditCarScreenState();
}

class _EditCarScreenState extends State<EditCarScreen> {
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _generationController;
  late TextEditingController _yearController;
  late TextEditingController _vinController;
  late TextEditingController _mileageController;

  bool _useWizardForBrandModel = false;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.car.brand);
    _modelController = TextEditingController(text: widget.car.model);
    _generationController = TextEditingController(text: widget.car.generation ?? '');
    _yearController = TextEditingController(text: widget.car.year?.toString() ?? '');
    _vinController = TextEditingController(text: widget.car.vin ?? '');
    _mileageController = TextEditingController(text: widget.car.currentMileage.toString());
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _generationController.dispose();
    _yearController.dispose();
    _vinController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _saveCar() async {
    if (_brandController.text.trim().isEmpty || _modelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Марка и модель обязательны')),
      );
      return;
    }

    final year = int.tryParse(_yearController.text.trim());
    final mileage = int.tryParse(_mileageController.text.trim()) ?? 0;

    await context.read<CarsProvider>().updateCarFields(
      id: widget.car.id,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      generation: _generationController.text.trim().isNotEmpty
          ? _generationController.text.trim()
          : null,
      year: year,
      vin: _vinController.text.trim(),
      currentMileage: mileage,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные автомобиля обновлены')),
      );
    }
  }

  void _openBrandModelWizard() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (context) => const BrandModelWizard(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _brandController.text = result['brand'] ?? '';
        _modelController.text = result['model'] ?? '';
        if (result.containsKey('generation')) {
          _generationController.text = result['generation'] ?? '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование автомобиля'),
        actions: [
          TextButton(
            onPressed: _saveCar,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand, Model, Generation section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Марка и модель',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _useWizardForBrandModel = !_useWizardForBrandModel;
                            });
                          },
                          icon: Icon(_useWizardForBrandModel ? Icons.edit : Icons.list),
                          label: Text(_useWizardForBrandModel ? 'Ручной ввод' : 'Выбрать из списка'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_useWizardForBrandModel) ...[
                      // Manual input fields
                      TextField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Марка *',
                          hintText: 'Например: Toyota',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Модель *',
                          hintText: 'Например: Camry',
                        ),
                      ),
                    ] else ...[
                      // Wizard selection
                      Card(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: ListTile(
                          leading: const Icon(Icons.directions_car),
                          title: Text(
                            _brandController.text.isNotEmpty && _modelController.text.isNotEmpty
                                ? '${_brandController.text} ${_modelController.text}'
                                : 'Выберите марку и модель',
                          ),
                          subtitle: const Text('Нажмите для выбора'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _openBrandModelWizard,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _generationController,
                      decoration: const InputDecoration(
                        labelText: 'Поколение (опционально)',
                        hintText: 'Например: XV70, E90, B8',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Additional data section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Дополнительные данные',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Год выпуска',
                        hintText: 'Например: 2020',
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _vinController,
                      decoration: const InputDecoration(
                        labelText: 'VIN-номер',
                        hintText: '17 символов (опционально)',
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _mileageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Текущий пробег, км',
                        hintText: 'Например: 50000',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveCar,
                    child: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Бренд-модель-поколение визард (полностью исправленный с использованием БД)
class BrandModelWizard extends StatefulWidget {
  const BrandModelWizard({super.key});

  @override
  State<BrandModelWizard> createState() => _BrandModelWizardState();
}

class _BrandModelWizardState extends State<BrandModelWizard> {
  final _pageController = PageController();
  int _currentStep = 0;

  int? _selectedBrandId;
  int? _selectedModelId;
  int? _selectedGenerationId;

  String _customBrand = '';
  String _customModel = '';
  String _customGeneration = '';

  final _brandSearchController = TextEditingController();
  final _modelSearchController = TextEditingController();
  final _genSearchController = TextEditingController();

  List<CarBrand> _brands = [];
  List<CarModel> _models = [];
  List<CarGeneration> _generations = [];

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

  void _selectBrand(int id, String name) {
    setState(() {
      _selectedBrandId = id;
      _customBrand = '';
      _selectedModelId = null;
      _selectedGenerationId = null;
      _models = [];
      _generations = [];
    });
    _loadModels();
  }

  void _selectModel(int id, String name) {
    setState(() {
      _selectedModelId = id;
      _customModel = '';
      _selectedGenerationId = null;
      _generations = [];
    });
    _loadGenerations();
  }

  void _selectGeneration(int id, String name) {
    setState(() {
      _selectedGenerationId = id;
      _customGeneration = '';
    });
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _finishSelection();
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

  void _finishSelection() {
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

    final result = <String, String>{
      'brand': brand,
      'model': model,
    };
    if (generation != null) result['generation'] = generation;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор автомобиля'),
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
              if (step < 2) const SizedBox(width: 8),
              if (step < 2)
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
          const SizedBox(height: 16),

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
                    onTap: () => _selectBrand(brand.id, brand.name),
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
            'Выберите модель',
            style: Theme.of(context).textTheme.headlineSmall,
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
                    onTap: () => _selectModel(model.id, model.name),
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
      return query.isEmpty ||
          g.name.toLowerCase().contains(query) ||
          g.yearsString.toLowerCase().contains(query);
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
                    title: Text(
                      gen.name,
                      style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                    subtitle: gen.yearsString.isNotEmpty ? Text(gen.yearsString) : null,
                    onTap: () => _selectGeneration(gen.id, gen.name),
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
              child: Text(_currentStep == 2 ? 'Готово' : 'Далее'),
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
        return (_selectedModelId != null || _customModel.isNotEmpty) &&
            (_selectedBrandId != null || _customBrand.isNotEmpty);
      case 2:
        return true;
      default:
        return false;
    }
  }
}