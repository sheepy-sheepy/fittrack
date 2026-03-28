import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/meal.dart' as app_meal;
import '../../models/meal_entry.dart' as app_entry;
import '../../models/food.dart' as app_food;
import '../../models/recipe.dart' as app_recipe;
import '../../services/local_database/local_database.dart';
import 'search_food_screen.dart';

class MealDetailsScreen extends StatefulWidget {
  final String mealId;
  final app_meal.MealType mealType;
  final DateTime date;
  final app_entry.MealEntry? entryToEdit;

  const MealDetailsScreen({
    super.key,
    required this.mealId,
    required this.mealType,
    required this.date,
    this.entryToEdit,
  });

  @override
  _MealDetailsScreenState createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  List<app_entry.MealEntry> _entries = [];
  bool _isLoading = true;
  final LocalDatabase _localDb = LocalDatabase();

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);

    try {
      _entries = (await _localDb.mealDao.getMealEntries(widget.mealId))
          .cast<app_entry.MealEntry>()
          .toList();
    } catch (e) {
      debugPrint('Error loading entries: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addFood() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchFoodScreen(
          onSelect: (item) => Navigator.pop(context, item),
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
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final grams = double.tryParse(gramsController.text);
              if (grams != null && grams > 0) {
                final entry = app_entry.MealEntry(
                  id: const Uuid().v4(),
                  mealId: widget.mealId,
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

                await _localDb.mealDao.insertMealEntry(entry);
                await _loadEntries();
                // Используем dialogContext для навигации внутри диалога
                if (mounted && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateEntry(app_entry.MealEntry entry) async {
    final gramsController = TextEditingController(text: entry.grams.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final grams = double.tryParse(gramsController.text);
              if (grams != null && grams > 0) {
                final factor = grams / entry.grams;
                final updatedEntry = entry.copyWith(
                  grams: grams,
                  calories: entry.calories * factor,
                  proteins: entry.proteins * factor,
                  fats: entry.fats * factor,
                  carbs: entry.carbs * factor,
                );

                await _localDb.mealDao.updateMealEntry(updatedEntry);
                await _loadEntries();
                if (mounted) {
                  Navigator.pop(context,
                      true); // Возвращаем true для обновления родительского экрана
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(app_entry.MealEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить продукт'),
        content: Text('Вы уверены, что хотите удалить "${entry.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _localDb.mealDao.deleteMealEntry(entry.id);
      await _loadEntries();
      Navigator.pop(
          context, true); // Возвращаем true для обновления родительского экрана
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
        title: Text(widget.mealType.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addFood,
            tooltip: 'Добавить продукт',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_entries.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Нет добавленных продуктов',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _addFood,
                      child: const Text('Добавить продукт'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text(entry.name),
                      subtitle: Text(
                        '${entry.grams.round()} г | '
                        '${entry.calories.round()} ккал | '
                        'Б: ${entry.proteins.round()} | '
                        'Ж: ${entry.fats.round()} | '
                        'У: ${entry.carbs.round()}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _updateEntry(entry),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _deleteEntry(entry),
                          ),
                        ],
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
