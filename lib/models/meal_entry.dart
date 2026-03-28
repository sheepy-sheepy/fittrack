import 'package:equatable/equatable.dart';

class MealEntry extends Equatable {
  final String id;
  final String mealId;
  final String? foodId;
  final String? recipeId;
  final double grams;
  final String name;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
  final DateTime createdAt;
  
  const MealEntry({
    required this.id,
    required this.mealId,
    this.foodId,
    this.recipeId,
    required this.grams,
    required this.name,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'meal_id': mealId,
    'food_id': foodId,
    'recipe_id': recipeId,
    'grams': grams,
    'name': name,
    'calories': calories,
    'proteins': proteins,
    'fats': fats,
    'carbs': carbs,
    'created_at': createdAt.toIso8601String(),
  };
  
  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: json['id'],
      mealId: json['meal_id'],
      foodId: json['food_id'],
      recipeId: json['recipe_id'],
      grams: json['grams'].toDouble(),
      name: json['name'],
      calories: json['calories'].toDouble(),
      proteins: json['proteins'].toDouble(),
      fats: json['fats'].toDouble(),
      carbs: json['carbs'].toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  MealEntry copyWith({
    String? id,
    String? mealId,
    String? foodId,
    String? recipeId,
    double? grams,
    String? name,
    double? calories,
    double? proteins,
    double? fats,
    double? carbs,
    DateTime? createdAt,
  }) {
    return MealEntry(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      foodId: foodId ?? this.foodId,
      recipeId: recipeId ?? this.recipeId,
      grams: grams ?? this.grams,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      proteins: proteins ?? this.proteins,
      fats: fats ?? this.fats,
      carbs: carbs ?? this.carbs,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [id, mealId, foodId, recipeId, grams, name, calories, proteins, fats, carbs];
}