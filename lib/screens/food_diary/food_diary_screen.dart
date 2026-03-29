import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/meal.dart' as app_meal;
import '../../models/meal_entry.dart' as app_entry;
import '../../models/user_profile.dart' as app_profile;
import '../../services/local_database/local_database.dart';
import '../../services/calculation_service.dart';
import '../../widgets/nutrition_card.dart';
import '../../widgets/meal_card.dart';
import 'add_meal_screen.dart';
import 'meal_details_screen.dart';

// Инициализация локализации при запуске приложения

class FoodDiaryScreen extends StatefulWidget {
  const FoodDiaryScreen({super.key});

  @override
  _FoodDiaryScreenState createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, double> _nutritionNorm = {};
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

  final LocalDatabase _localDb = LocalDatabase();
  final CalculationService _calculationService = CalculationService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Инициализируем локализацию для русского языка
    Intl.defaultLocale = 'ru';
    _loadData();
  }

  String _formatDate(DateTime date) {
    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
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
          _nutritionNorm =
              _calculationService.calculateNutritionNorm(_userProfile!);
          _waterNorm = _nutritionNorm['water']!;
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
      final meals =
          await _localDb.mealDao.getMeals(session.user.id, _selectedDate);
      setState(() => _meals = meals.cast<app_meal.Meal>().toList());

      _mealEntries.clear();
      _totalNutrition = {
        'calories': 0,
        'proteins': 0,
        'fats': 0,
        'carbs': 0,
      };

      for (var meal in meals) {
        final entries = await _localDb.mealDao.getMealEntries(meal.id);
        _mealEntries[meal.id] = entries.cast<app_entry.MealEntry>().toList();

        for (var entry in entries) {
          _totalNutrition['calories'] =
              _totalNutrition['calories']! + entry.calories;
          _totalNutrition['proteins'] =
              _totalNutrition['proteins']! + entry.proteins;
          _totalNutrition['fats'] = _totalNutrition['fats']! + entry.fats;
          _totalNutrition['carbs'] = _totalNutrition['carbs']! + entry.carbs;
        }
      }
    }
  }

  Future<void> _loadWater() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final waterEntry =
          await _localDb.mealDao.getWaterEntry(session.user.id, _selectedDate);
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

  Future<void> _addMeal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMealScreen(
          date: _selectedDate,
          existingMeals: _meals,
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

  Map<String, double> _getRemaining() {
    return {
      'calories': _nutritionNorm['calories']! - _totalNutrition['calories']!,
      'proteins': _nutritionNorm['proteins']! - _totalNutrition['proteins']!,
      'fats': _nutritionNorm['fats']! - _totalNutrition['fats']!,
      'carbs': _nutritionNorm['carbs']! - _totalNutrition['carbs']!,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final remaining = _getRemaining();
    final waterRemaining = _waterNorm - _waterIntake;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _formatDate(
                      _selectedDate), // Используем нашу функцию вместо DateFormat
                  style: const TextStyle(fontSize: 16),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Осталось на сегодня',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${remaining['calories']!.round()} ккал',
                        style: TextStyle(
                          color: remaining['calories']! >= 0
                              ? Colors.white
                              : Colors.red,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => _changeDate(-1),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              NutritionCard(
                                title: 'Калории',
                                norm: '${_nutritionNorm['calories']!.round()}',
                                remaining:
                                    _formatRemaining(remaining['calories']!),
                              ),
                              NutritionCard(
                                title: 'Белки',
                                norm: '${_nutritionNorm['proteins']!.round()}г',
                                remaining:
                                    _formatRemaining(remaining['proteins']!),
                              ),
                              NutritionCard(
                                title: 'Жиры',
                                norm: '${_nutritionNorm['fats']!.round()}г',
                                remaining: _formatRemaining(remaining['fats']!),
                              ),
                              NutritionCard(
                                title: 'Углеводы',
                                norm: '${_nutritionNorm['carbs']!.round()}г',
                                remaining:
                                    _formatRemaining(remaining['carbs']!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
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
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _updateWater(-250),
                              ),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: _waterIntake / _waterNorm,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation(
                                    waterRemaining >= 0
                                        ? Colors.blue
                                        : Colors.red,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _updateWater(250),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  '${_waterIntake.round()} / ${_waterNorm.round()} мл',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: waterRemaining >= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildMealSections(),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMeal,
        tooltip: 'Добавить прием пищи',
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildMealSections() {
    const mealTypes = [
      app_meal.MealType.breakfast,
      app_meal.MealType.lunch,
      app_meal.MealType.dinner,
      app_meal.MealType.snack,
    ];

    List<Widget> widgets = [];

    for (var type in mealTypes) {
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

      // Исправление: правильное приведение типов
      List<app_entry.MealEntry> entries = [];
      if (meal.id.isNotEmpty && _mealEntries.containsKey(meal.id)) {
        entries = _mealEntries[meal.id]!.cast<app_entry.MealEntry>().toList();
      }

      final mealCalories =
          entries.fold<double>(0, (sum, e) => sum + e.calories);

      widgets.add(
        MealCard(
          mealType: type,
          entries: entries, // теперь entries имеет правильный тип
          totalCalories: mealCalories,
          onTap: () async {
            if (meal.id.isNotEmpty) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MealDetailsScreen(
                    mealId: meal.id,
                    mealType: type,
                    date: _selectedDate,
                  ),
                ),
              );
              if (result == true && mounted) {
                await _loadMeals();
              }
            } else {
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
              if (result == true && mounted) {
                await _loadMeals();
              }
            }
          },
        ),
      );

      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  String _formatRemaining(double value) {
    if (value >= 0) {
      return 'Осталось: ${value.round()}';
    } else {
      return 'Перебор: ${(-value).round()}';
    }
  }
}
