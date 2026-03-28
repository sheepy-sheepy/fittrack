import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/food.dart' as app_food;
import '../../services/local_database/local_database.dart';
import '../../widgets/custom_button.dart';

class AddProductScreen extends StatefulWidget {
  final app_food.Food? food;
  
  const AddProductScreen({super.key, this.food});
  
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  
  bool _isSaving = false;
  final LocalDatabase _localDb = LocalDatabase();
  
  @override
  void initState() {
    super.initState();
    if (widget.food != null) {
      _nameController.text = widget.food!.name;
      _caloriesController.text = widget.food!.calories.toString();
      _proteinsController.text = widget.food!.proteins.toString();
      _fatsController.text = widget.food!.fats.toString();
      _carbsController.text = widget.food!.carbs.toString();
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinsController.dispose();
    _fatsController.dispose();
    _carbsController.dispose();
    super.dispose();
  }
  
  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty) {
      _showError('Введите название продукта');
      return;
    }
    
    final calories = double.tryParse(_caloriesController.text);
    if (calories == null || calories < 0) {
      _showError('Введите корректную калорийность');
      return;
    }
    
    final proteins = double.tryParse(_proteinsController.text);
    if (proteins == null || proteins < 0) {
      _showError('Введите корректное количество белков');
      return;
    }
    
    final fats = double.tryParse(_fatsController.text);
    if (fats == null || fats < 0) {
      _showError('Введите корректное количество жиров');
      return;
    }
    
    final carbs = double.tryParse(_carbsController.text);
    if (carbs == null || carbs < 0) {
      _showError('Введите корректное количество углеводов');
      return;
    }
    
    if (!mounted) return;
    setState(() => _isSaving = true);
    
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final food = app_food.Food(
          id: widget.food?.id ?? const Uuid().v4(),
          name: _nameController.text,
          calories: calories,
          proteins: proteins,
          fats: fats,
          carbs: carbs,
          isCustom: true,
          userId: session.user.id,
          createdAt: widget.food?.createdAt ?? DateTime.now(),
        );
        
        if (widget.food != null) {
          await _localDb.foodDao.updateFood(food);
        } else {
          await _localDb.foodDao.insertFood(food);
        }
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      _showError('Ошибка сохранения: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.food != null ? 'Редактировать продукт' : 'Создать продукт'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название продукта',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fastfood),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Калорийность (ккал на 100г)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_fire_department),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proteinsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Белки (г)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _fatsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Жиры (г)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Углеводы (г)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Сохранить',
              onPressed: _saveProduct,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}