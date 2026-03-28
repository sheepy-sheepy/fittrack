import 'package:equatable/equatable.dart';
import 'recipe_ingredient.dart';

class Recipe extends Equatable {
  final String id;
  final String userId;
  final String name;
  final List<RecipeIngredient> ingredients;
  final double totalCalories;
  final double totalProteins;
  final double totalFats;
  final double totalCarbs;
  final double totalWeight;
  final DateTime createdAt;
  
  const Recipe({
    required this.id,
    required this.userId,
    required this.name,
    required this.ingredients,
    required this.totalCalories,
    required this.totalProteins,
    required this.totalFats,
    required this.totalCarbs,
    required this.totalWeight,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'total_calories': totalCalories,
    'total_proteins': totalProteins,
    'total_fats': totalFats,
    'total_carbs': totalCarbs,
    'created_at': createdAt.toIso8601String(),
  };
  
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      ingredients: const [],
      totalCalories: json['total_calories'].toDouble(),
      totalProteins: json['total_proteins'].toDouble(),
      totalFats: json['total_fats'].toDouble(),
      totalCarbs: json['total_carbs'].toDouble(),
      totalWeight: 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Recipe copyWith({
    String? id,
    String? userId,
    String? name,
    List<RecipeIngredient>? ingredients,
    double? totalCalories,
    double? totalProteins,
    double? totalFats,
    double? totalCarbs,
    double? totalWeight,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      ingredients: ingredients ?? this.ingredients,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProteins: totalProteins ?? this.totalProteins,
      totalFats: totalFats ?? this.totalFats,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalWeight: totalWeight ?? this.totalWeight,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [id, userId, name, totalCalories, totalProteins, totalFats, totalCarbs, totalWeight];
}