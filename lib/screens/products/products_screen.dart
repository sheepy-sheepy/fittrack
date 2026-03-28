import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/food.dart' as app_food;
import '../../services/local_database/local_database.dart';
import 'add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<app_food.Food> _myFoods = [];
  List<app_food.Food> _filteredFoods = [];
  bool _isLoading = true;
  
  final LocalDatabase _localDb = LocalDatabase();
  
  @override
  void initState() {
    super.initState();
    _loadFoods();
  }
  
  Future<void> _loadFoods() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _myFoods = await _localDb.foodDao.getUserFoods(session.user.id);
        _filteredFoods = _myFoods;
      }
    } catch (e) {
      debugPrint('Error loading foods: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _filterFoods(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFoods = _myFoods;
      } else {
        _filteredFoods = _myFoods
            .where((f) => f.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
  
  Future<void> _deleteFood(app_food.Food food) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить продукт'),
        content: Text('Вы уверены, что хотите удалить "${food.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      await _localDb.foodDao.deleteFood(food.id);
      await _loadFoods();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Продукт удален')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои продукты'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск продуктов...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _filterFoods,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredFoods.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fastfood, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Нет созданных продуктов',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Нажмите кнопку "+" чтобы создать продукт',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredFoods.length,
                  itemBuilder: (context, index) {
                    final food = _filteredFoods[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.fastfood, color: Colors.white),
                        ),
                        title: Text(food.name),
                        subtitle: Text(
                          '${food.calories.round()} ккал | '
                          'Б: ${food.proteins.round()}г | '
                          'Ж: ${food.fats.round()}г | '
                          'У: ${food.carbs.round()}г (на 100г)',
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Редактировать'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Удалить'),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddProductScreen(
                                    food: food,
                                  ),
                                ),
                              );
                              if (result == true && mounted) {
                                await _loadFoods();
                              }
                            } else if (value == 'delete') {
                              await _deleteFood(food);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            ),
          );
          if (result == true && mounted) {
            await _loadFoods();
          }
        },
        tooltip: 'Создать продукт',
        child: const Icon(Icons.add),
      ),
    );
  }
}