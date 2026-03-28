import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/food.dart' as app_food;
import '../../models/recipe.dart' as app_recipe;
import '../../services/local_database/local_database.dart';

class SearchFoodScreen extends StatefulWidget {
  final Function(dynamic) onSelect;

  const SearchFoodScreen({super.key, required this.onSelect});

  @override
  _SearchFoodScreenState createState() => _SearchFoodScreenState();
}

class _SearchFoodScreenState extends State<SearchFoodScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  List<app_food.Food> _myFoods = [];
  List<app_recipe.Recipe> _myRecipes = [];
  List<app_food.Food> _defaultFoods = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final LocalDatabase _localDb = LocalDatabase();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _myFoods = (await _localDb.foodDao.getUserFoods(session.user.id))
            .cast<app_food.Food>()
            .toList();
        _myRecipes = (await _localDb.recipeDao.getUserRecipes(session.user.id))
            .cast<app_recipe.Recipe>()
            .toList();
        _defaultFoods = (await _localDb.foodDao.getDefaultFoods())
            .cast<app_food.Food>()
            .toList();

        _updateResults();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateResults() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _results = [
          ..._myFoods.take(5),
          ..._myRecipes.take(5),
          ..._defaultFoods.take(10),
        ];
      });
    } else {
      final query = _searchQuery.toLowerCase();
      setState(() {
        _results = [
          ..._myFoods.where((f) => f.name.toLowerCase().contains(query)),
          ..._myRecipes.where((r) => r.name.toLowerCase().contains(query)),
          ..._defaultFoods.where((f) => f.name.toLowerCase().contains(query)),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск продуктов и рецептов'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Поиск...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                _searchQuery = value;
                _updateResults();
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final item = _results[index];
                return ListTile(
                  leading: Icon(
                    item is app_food.Food ? Icons.fastfood : Icons.book,
                    color: item is app_food.Food ? Colors.orange : Colors.green,
                  ),
                  title: Text(item.name),
                  subtitle: item is app_food.Food
                      ? Text(
                          '${item.calories.round()} ккал | '
                          'Б: ${item.proteins.round()} | '
                          'Ж: ${item.fats.round()} | '
                          'У: ${item.carbs.round()} (на 100г)',
                        )
                      : Text(
                          '${item.totalCalories.round()} ккал (общая) | '
                          'Вес: ${item.totalWeight.round()}г',
                        ),
                  onTap: () => widget.onSelect(item),
                );
              },
            ),
    );
  }
}
