import 'package:equatable/equatable.dart';

class Food extends Equatable {
  final String id;
  final String name;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
  final bool isCustom;
  final String? userId;
  final DateTime createdAt;
  
  const Food({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
    this.isCustom = false,
    this.userId,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'calories': calories,
    'proteins': proteins,
    'fats': fats,
    'carbs': carbs,
    'is_custom': isCustom,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
  };
  
  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      name: json['name'],
      calories: json['calories'].toDouble(),
      proteins: json['proteins'].toDouble(),
      fats: json['fats'].toDouble(),
      carbs: json['carbs'].toDouble(),
      isCustom: json['is_custom'] ?? false,
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  @override
  List<Object?> get props => [id, name, calories, proteins, fats, carbs, isCustom, userId];
}