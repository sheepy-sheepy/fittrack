import 'package:flutter/material.dart';
import '../../models/meal.dart' as app_meal;
import '../../models/meal_entry.dart' as app_entry;

class MealCard extends StatelessWidget {
  final app_meal.MealType mealType;
  final List<app_entry.MealEntry> entries;
  final double totalCalories;
  final VoidCallback onTap;
  
  const MealCard({
    super.key,
    required this.mealType,
    required this.entries,
    required this.totalCalories,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
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
                        _getIcon(),
                        color: _getColor(),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        mealType.displayName,
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
                      color: totalCalories > 0
                          ? Colors.green[100]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${totalCalories.round()} ккал',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: totalCalories > 0 ? Colors.green[800] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...entries.take(2).map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${entry.name} (${entry.grams.round()}г)',
                    style: const TextStyle(fontSize: 14),
                  ),
                )),
                if (entries.length > 2)
                  Text(
                    'и еще ${entries.length - 2}...',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Добавить продукты',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getIcon() {
    switch (mealType) {
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
  
  Color _getColor() {
    switch (mealType) {
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