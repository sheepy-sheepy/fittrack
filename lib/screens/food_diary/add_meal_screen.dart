import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/meal.dart' as app_meal;
import '../../models/meal_entry.dart' as app_entry;
import '../../models/food.dart' as app_food;
import '../../models/recipe.dart' as app_recipe;
import '../../services/local_database/local_database.dart';
import 'search_food_screen.dart';

class AddMealScreen extends StatefulWidget {
  final DateTime date;
  final List<app_meal.Meal> existingMeals;
  final app_meal.MealType? preselectedType;

  const AddMealScreen({
    super.key,
    required this.date,
    required this.existingMeals,
    this.preselectedType,
  });

  @override
  _AddMealScreenState createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  app_meal.MealType? _selectedType;
  final List<app_entry.MealEntry> _entries = [];
  final LocalDatabase _localDb = LocalDatabase();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.preselectedType;
  }

  Future<void> _addFood() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchFoodScreen(
          onSelect: (dynamic item) {
            Navigator.pop(context, item);
          },
        ),
      ),
    );

    if (result != null && mounted) {
      _showGramsDialog(result);
    }
  }

  void _showGramsDialog(dynamic item) {
    final gramsController = TextEditingController(text: '100');
    String name = '';
    double caloriesPer100 = 0;
    double proteinsPer100 = 0;
    double fatsPer100 = 0;
    double carbsPer100 = 0;

    if (item is app_food.Food) {
      name = item.name;
      caloriesPer100 = item.calories;
      proteinsPer100 = item.proteins;
      fatsPer100 = item.fats;
      carbsPer100 = item.carbs;
    } else if (item is app_recipe.Recipe) {
      name = item.name;
      caloriesPer100 = item.totalCalories / (item.totalWeight / 100);
      proteinsPer100 = item.totalProteins / (item.totalWeight / 100);
      fatsPer100 = item.totalFats / (item.totalWeight / 100);
      carbsPer100 = item.totalCarbs / (item.totalWeight / 100);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить $name'),
        content: TextField(
          controller: gramsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Количество (грамм)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final grams = double.tryParse(gramsController.text);
              if (grams != null && grams > 0) {
                final entry = app_entry.MealEntry(
                  id: const Uuid().v4(),
                  mealId: '',
                  foodId: item is app_food.Food ? item.id : null,
                  recipeId: item is app_recipe.Recipe ? item.id : null,
                  grams: grams,
                  name: name,
                  calories: (caloriesPer100 * grams / 100),
                  proteins: (proteinsPer100 * grams / 100),
                  fats: (fatsPer100 * grams / 100),
                  carbs: (carbsPer100 * grams / 100),
                  createdAt: DateTime.now(),
                );
                setState(() {
                  _entries.add(entry);
                });
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _removeEntry(int index) {
    setState(() {
      _entries.removeAt(index);
    });
  }

  void _editEntry(int index) {
    final entry = _entries[index];
    final gramsController = TextEditingController(text: entry.grams.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактировать ${entry.name}'),
        content: TextField(
          controller: gramsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Количество (грамм)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final grams = double.tryParse(gramsController.text);
              if (grams != null && grams > 0) {
                final factor = grams / entry.grams;
                setState(() {
                  _entries[index] = entry.copyWith(
                    grams: grams,
                    calories: entry.calories * factor,
                    proteins: entry.proteins * factor,
                    fats: entry.fats * factor,
                    carbs: entry.carbs * factor,
                  );
                });
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMeal() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите тип приема пищи')),
      );
      return;
    }

    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один продукт')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // Ищем существующий прием пищи с таким типом
        var existingMeal = widget.existingMeals.firstWhere(
          (m) => m.type == _selectedType,
          orElse: () => app_meal.Meal(
            id: '',
            userId: '',
            date: widget.date,
            type: _selectedType!,
            createdAt: DateTime.now(),
          ),
        );

        String mealId;

        if (existingMeal.id.isNotEmpty) {
          // Используем существующий прием пищи
          mealId = existingMeal.id;
        } else {
          // Создаем новый прием пищи
          final meal = app_meal.Meal(
            id: const Uuid().v4(),
            userId: session.user.id,
            date: widget.date,
            type: _selectedType!,
            createdAt: DateTime.now(),
          );
          await _localDb.mealDao.insertMeal(meal);
          mealId = meal.id;
        }

        for (var entry in _entries) {
          final entryWithMealId = entry.copyWith(mealId: mealId);
          await _localDb.mealDao.insertMealEntry(entryWithMealId);
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories =
        _entries.fold<double>(0, (sum, e) => sum + e.calories);
    final totalProteins =
        _entries.fold<double>(0, (sum, e) => sum + e.proteins);
    final totalFats = _entries.fold<double>(0, (sum, e) => sum + e.fats);
    final totalCarbs = _entries.fold<double>(0, (sum, e) => sum + e.carbs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить прием пищи'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: _saveMeal,
              child: const Text('Сохранить'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: app_meal.MealType.values.map((type) {
                final isSelected = _selectedType == type;
                return FilterChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = selected ? type : null;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _addFood,
              icon: const Icon(Icons.add),
              label: const Text('Добавить продукт или рецепт'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _entries.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Нет добавленных продуктов',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return Dismissible(
                        key: Key(entry.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _removeEntry(index),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: ListTile(
                            title: Text(entry.name),
                            subtitle: Text(
                              '${entry.grams.round()} г | '
                              '${entry.calories.round()} ккал | '
                              'Б: ${entry.proteins.round()} | '
                              'Ж: ${entry.fats.round()} | '
                              'У: ${entry.carbs.round()}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editEntry(index),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text(
                  'Итого: ${totalCalories.round()} ккал',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Белки: ${totalProteins.round()}г'),
                    Text('Жиры: ${totalFats.round()}г'),
                    Text('Углеводы: ${totalCarbs.round()}г'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
