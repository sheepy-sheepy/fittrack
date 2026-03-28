import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/meal.dart' as app_meal;
import '../../models/meal_entry.dart' as app_entry;
import '../../models/user_profile.dart' as app_profile;
import '../../services/local_database/local_database.dart';
import '../../services/calculation_service.dart';
import 'add_meal_screen.dart';
import 'meal_details_screen.dart';

class FoodDiaryScreen extends StatefulWidget {
  const FoodDiaryScreen({Key? key}) : super(key: key);
  
  @override
  _FoodDiaryScreenState createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, double> _nutritionNorm = {
    'calories': 0,
    'proteins': 0,
    'fats': 0,
    'carbs': 0,
    'water': 0,
  };
  Map<String, double> _totalNutrition = {
    'calories': 0,
    'proteins': 0,
    'fats': 0,
    'carbs': 0,
  };
  List<app_meal.Meal> _meals = [];
  final Map<String, List<app_entry.MealEntry>> _mealEntries = {};
  double _waterIntake = 0;
  double _waterNorm = 0;
  app_profile.UserProfile? _userProfile;
  final TextEditingController _waterController = TextEditingController(text: '250');
  
  final LocalDatabase _localDb = LocalDatabase();
  final CalculationService _calculationService = CalculationService();
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _userProfile = await _localDb.profileDao.getProfile(session.user.id);
        
        if (_userProfile != null) {
          final norms = _calculationService.calculateNutritionNorm(_userProfile!);
          _nutritionNorm = {
            'calories': norms['calories'] ?? 0,
            'proteins': norms['proteins'] ?? 0,
            'fats': norms['fats'] ?? 0,
            'carbs': norms['carbs'] ?? 0,
            'water': norms['water'] ?? 0,
          };
          _waterNorm = _nutritionNorm['water'] ?? 0;
        }
        
        await _loadMeals();
        await _loadWater();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _loadMeals() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final meals = await _localDb.mealDao.getMeals(session.user.id, _selectedDate);
      setState(() => _meals = meals);
      
      _mealEntries.clear();
      _totalNutrition = {
        'calories': 0,
        'proteins': 0,
        'fats': 0,
        'carbs': 0,
      };
      
      for (var meal in meals) {
        final entries = await _localDb.mealDao.getMealEntries(meal.id);
        _mealEntries[meal.id] = entries;
        
        for (var entry in entries) {
          _totalNutrition['calories'] = (_totalNutrition['calories'] ?? 0) + (entry.calories ?? 0);
          _totalNutrition['proteins'] = (_totalNutrition['proteins'] ?? 0) + (entry.proteins ?? 0);
          _totalNutrition['fats'] = (_totalNutrition['fats'] ?? 0) + (entry.fats ?? 0);
          _totalNutrition['carbs'] = (_totalNutrition['carbs'] ?? 0) + (entry.carbs ?? 0);
        }
      }
    }
  }
  
  Future<void> _loadWater() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final waterEntry = await _localDb.mealDao.getWaterEntry(session.user.id, _selectedDate);
      if (waterEntry != null) {
        setState(() => _waterIntake = waterEntry.amount);
      } else {
        setState(() => _waterIntake = 0);
      }
    }
  }
  
  Future<void> _changeDate(int days) async {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    await _loadMeals();
    await _loadWater();
  }
  
  Future<void> _addMeal(app_meal.MealType? type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMealScreen(
          date: _selectedDate,
          existingMeals: _meals,
          preselectedType: type,
        ),
      ),
    );
    
    if (result == true) {
      await _loadMeals();
    }
  }
  
  Future<void> _openMealDetails(app_meal.Meal meal) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealDetailsScreen(
          mealId: meal.id,
          mealType: meal.type,
          date: _selectedDate,
        ),
      ),
    );
    
    if (result == true) {
      await _loadMeals();
    }
  }
  
  Future<void> _updateWater(double delta) async {
    final newAmount = _waterIntake + delta;
    if (newAmount < 0) return;
    
    setState(() => _waterIntake = newAmount);
    
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await _localDb.mealDao.saveWaterEntry(
        session.user.id,
        _selectedDate,
        newAmount,
      );
    }
  }
  
  void _addWater() {
    final amount = double.tryParse(_waterController.text);
    if (amount != null && amount > 0) {
      _updateWater(amount);
    }
  }
  
  void _removeWater() {
    final amount = double.tryParse(_waterController.text);
    if (amount != null && amount > 0) {
      _updateWater(-amount);
    }
  }
  
  Map<String, double> _getRemaining() {
    return {
      'calories': (_nutritionNorm['calories'] ?? 0) - (_totalNutrition['calories'] ?? 0),
      'proteins': (_nutritionNorm['proteins'] ?? 0) - (_totalNutrition['proteins'] ?? 0),
      'fats': (_nutritionNorm['fats'] ?? 0) - (_totalNutrition['fats'] ?? 0),
      'carbs': (_nutritionNorm['carbs'] ?? 0) - (_totalNutrition['carbs'] ?? 0),
    };
  }
  
  double _getProgress(String key) {
    final norm = _nutritionNorm[key] ?? 0;
    final consumed = _totalNutrition[key] ?? 0;
    if (norm <= 0) return 0;
    return (consumed / norm).clamp(0.0, 1.0);
  }
  
  String _formatRemainingWithArrow(double value, String unit) {
    if (value >= 0) {
      return '↓ ${value.round()}$unit';
    } else {
      return '↑ ${(-value).round()}$unit';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final remaining = _getRemaining();
    final waterRemaining = _waterNorm - _waterIntake;
    final caloriesProgress = _getProgress('calories');
    final proteinsProgress = _getProgress('proteins');
    final fatsProgress = _getProgress('fats');
    final carbsProgress = _getProgress('carbs');
    
    // Создаем приемы пищи для всех типов
    final mealTypes = [
      app_meal.MealType.breakfast,
      app_meal.MealType.lunch,
      app_meal.MealType.dinner,
      app_meal.MealType.snack,
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => _changeDate(-1),
            ),
            const SizedBox(width: 8),
            Text(_formatDate(_selectedDate)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () => _changeDate(1),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Nutrition summary with circular progress
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCircularProgress(
                        title: 'Ккал',
                        progress: caloriesProgress,
                        norm: '${(_nutritionNorm['calories'] ?? 0).round()}',
                        remaining: _formatRemainingWithArrow(remaining['calories'] ?? 0, ''),
                        color: Colors.orange,
                      ),
                      _buildCircularProgress(
                        title: 'Белки',
                        progress: proteinsProgress,
                        norm: '${(_nutritionNorm['proteins'] ?? 0).round()}г',
                        remaining: _formatRemainingWithArrow(remaining['proteins'] ?? 0, 'г'),
                        color: Colors.blue,
                      ),
                      _buildCircularProgress(
                        title: 'Жиры',
                        progress: fatsProgress,
                        norm: '${(_nutritionNorm['fats'] ?? 0).round()}г',
                        remaining: _formatRemainingWithArrow(remaining['fats'] ?? 0, 'г'),
                        color: Colors.green,
                      ),
                      _buildCircularProgress(
                        title: 'Углеводы',
                        progress: carbsProgress,
                        norm: '${(_nutritionNorm['carbs'] ?? 0).round()}г',
                        remaining: _formatRemainingWithArrow(remaining['carbs'] ?? 0, 'г'),
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Water section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Вода',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Норма: ${_waterNorm.round()} мл',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _waterNorm > 0 ? _waterIntake / _waterNorm : 0,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(Colors.blue),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_waterIntake.round()} / ${_waterNorm.round()} мл',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _waterController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Количество (мл)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.red),
                        onPressed: _removeWater,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: _addWater,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Meals section
          Expanded(
            child: ListView.builder(
              itemCount: mealTypes.length,
              itemBuilder: (context, index) {
                final type = mealTypes[index];
                final meal = _meals.firstWhere(
                  (m) => m.type == type,
                  orElse: () => app_meal.Meal(
                    id: '',
                    userId: '',
                    date: _selectedDate,
                    type: type,
                    createdAt: DateTime.now(),
                  ),
                );
                
                final entries = meal.id.isNotEmpty ? (_mealEntries[meal.id] ?? []) : [];
                final mealCalories = entries.fold<double>(0, (sum, e) => sum + (e.calories ?? 0));
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: InkWell(
                    onTap: meal.id.isNotEmpty ? () => _openMealDetails(meal) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getIcon(type),
                                    color: _getColor(type),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    type.displayName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: mealCalories > 0
                                      ? Colors.green[100]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${mealCalories.round()} ккал',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: mealCalories > 0 ? Colors.green[800] : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (entries.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• ${entry.name} (${entry.grams.round()}г)',
                                style: const TextStyle(fontSize: 14),
                              ),
                            )),
                          ] else
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Нажмите на прием пищи, чтобы добавить продукты',
                                style: TextStyle(color: Colors.grey),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addMeal(null),
        child: const Icon(Icons.add),
        tooltip: 'Добавить прием пищи',
      ),
    );
  }
  
  Widget _buildCircularProgress({
    required String title,
    required double progress,
    required String norm,
    required String remaining,
    required Color color,
  }) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  value: progress.isFinite ? progress : 0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeWidth: 6,
                ),
              ),
              Text(
                '${((progress.isFinite ? progress : 0) * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            norm,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            remaining,
            style: TextStyle(fontSize: 8, color: remaining.startsWith('↑') ? Colors.red : Colors.green),
          ),
        ],
      ),
    );
  }
  
  IconData _getIcon(app_meal.MealType type) {
    switch (type) {
      case app_meal.MealType.breakfast:
        return Icons.brightness_5;
      case app_meal.MealType.lunch:
        return Icons.lunch_dining;
      case app_meal.MealType.dinner:
        return Icons.dinner_dining;
      case app_meal.MealType.snack:
        return Icons.cake;
    }
  }
  
  Color _getColor(app_meal.MealType type) {
    switch (type) {
      case app_meal.MealType.breakfast:
        return Colors.orange;
      case app_meal.MealType.lunch:
        return Colors.blue;
      case app_meal.MealType.dinner:
        return Colors.purple;
      case app_meal.MealType.snack:
        return Colors.pink;
    }
  }
}