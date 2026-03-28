import 'package:equatable/equatable.dart';

class RecipeIngredient extends Equatable {
  final String id;
  final String foodId;
  final double grams;
  final String foodName;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
  
  const RecipeIngredient({
    required this.id,
    required this.foodId,
    required this.grams,
    required this.foodName,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });
  
  RecipeIngredient copyWith({
    String? id,
    String? foodId,
    double? grams,
    String? foodName,
    double? calories,
    double? proteins,
    double? fats,
    double? carbs,
  }) {
    return RecipeIngredient(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      grams: grams ?? this.grams,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      proteins: proteins ?? this.proteins,
      fats: fats ?? this.fats,
      carbs: carbs ?? this.carbs,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'food_id': foodId,
    'grams': grams,
    'food_name': foodName,
    'calories': calories,
    'proteins': proteins,
    'fats': fats,
    'carbs': carbs,
  };
  
  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'],
      foodId: json['food_id'],
      grams: json['grams'].toDouble(),
      foodName: json['food_name'],
      calories: json['calories'].toDouble(),
      proteins: json['proteins'].toDouble(),
      fats: json['fats'].toDouble(),
      carbs: json['carbs'].toDouble(),
    );
  }
  
  @override
  List<Object?> get props => [id, foodId, grams, foodName, calories, proteins, fats, carbs];
}