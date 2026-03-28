import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recipe.dart' as app_recipe;
import '../../models/recipe_ingredient.dart' as app_ingredient;
import '../../models/food.dart' as app_food;
import '../../services/local_database/local_database.dart';
import '../food_diary/search_food_screen.dart';

class AddRecipeScreen extends StatefulWidget {
  final app_recipe.Recipe? recipe;
  
  const AddRecipeScreen({super.key, this.recipe});
  
  @override
  _AddRecipeScreenState createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<app_ingredient.RecipeIngredient> _ingredients = [];
  bool _isSaving = false;
  final LocalDatabase _localDb = LocalDatabase();
  
  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _nameController.text = widget.recipe!.name;
      _ingredients.addAll(widget.recipe!.ingredients);
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _addIngredient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchFoodScreen(
          onSelect: (item) => Navigator.pop(context, item),
        ),
      ),
    );
    
    if (result != null && result is app_food.Food && mounted) {
      _showGramsDialog(result);
    }
  }
  
  void _showGramsDialog(app_food.Food food) {
    final gramsController = TextEditingController(text: '100');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить ${food.name}'),
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
                final ingredient = app_ingredient.RecipeIngredient(
                  id: const Uuid().v4(),
                  foodId: food.id,
                  grams: grams,
                  foodName: food.name,
                  calories: (food.calories * grams / 100),
                  proteins: (food.proteins * grams / 100),
                  fats: (food.fats * grams / 100),
                  carbs: (food.carbs * grams / 100),
                );
                setState(() {
                  _ingredients.add(ingredient);
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
  
  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }
  
  void _editIngredient(int index) {
    final ingredient = _ingredients[index];
    final gramsController = TextEditingController(text: ingredient.grams.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактировать ${ingredient.foodName}'),
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
                final factor = grams / ingredient.grams;
                setState(() {
                  _ingredients[index] = ingredient.copyWith(
                    grams: grams,
                    calories: ingredient.calories * factor,
                    proteins: ingredient.proteins * factor,
                    fats: ingredient.fats * factor,
                    carbs: ingredient.carbs * factor,
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
  
  Future<void> _saveRecipe() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название рецепта')),
      );
      return;
    }
    
    if (_ingredients.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте минимум 2 ингредиента')),
      );
      return;
    }
    
    if (!mounted) return;
    setState(() => _isSaving = true);
    
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final totalCalories = _ingredients.fold<double>(0, (sum, i) => sum + i.calories);
        final totalProteins = _ingredients.fold<double>(0, (sum, i) => sum + i.proteins);
        final totalFats = _ingredients.fold<double>(0, (sum, i) => sum + i.fats);
        final totalCarbs = _ingredients.fold<double>(0, (sum, i) => sum + i.carbs);
        final totalWeight = _ingredients.fold<double>(0, (sum, i) => sum + i.grams);
        
        final recipe = app_recipe.Recipe(
          id: widget.recipe?.id ?? const Uuid().v4(),
          userId: session.user.id,
          name: _nameController.text,
          ingredients: _ingredients,
          totalCalories: totalCalories,
          totalProteins: totalProteins,
          totalFats: totalFats,
          totalCarbs: totalCarbs,
          totalWeight: totalWeight,
          createdAt: widget.recipe?.createdAt ?? DateTime.now(),
        );
        
        if (widget.recipe != null) {
          await _localDb.recipeDao.updateRecipe(recipe);
        } else {
          await _localDb.recipeDao.insertRecipe(recipe);
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
    final totalCalories = _ingredients.fold<double>(0, (sum, i) => sum + i.calories);
    final totalProteins = _ingredients.fold<double>(0, (sum, i) => sum + i.proteins);
    final totalFats = _ingredients.fold<double>(0, (sum, i) => sum + i.fats);
    final totalCarbs = _ingredients.fold<double>(0, (sum, i) => sum + i.carbs);
    final totalWeight = _ingredients.fold<double>(0, (sum, i) => sum + i.grams);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe != null ? 'Редактировать рецепт' : 'Создать рецепт'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: _saveRecipe,
              child: const Text('Сохранить'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название рецепта',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ингредиенты',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ingredients.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Добавьте ингредиенты для рецепта',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  final ingredient = _ingredients[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(ingredient.foodName),
                      subtitle: Text(
                        '${ingredient.grams.round()} г | '
                        '${ingredient.calories.round()} ккал',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editIngredient(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _removeIngredient(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            if (_ingredients.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Итого по рецепту',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Вес: ${totalWeight.round()} г'),
                    Text(
                      '${totalCalories.round()} ккал | '
                      'Б: ${totalProteins.round()}г | '
                      'Ж: ${totalFats.round()}г | '
                      'У: ${totalCarbs.round()}г',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'На 100г: ${(totalCalories / totalWeight * 100).round()} ккал',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}