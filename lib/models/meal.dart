import 'package:equatable/equatable.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;
  
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Завтрак';
      case MealType.lunch:
        return 'Обед';
      case MealType.dinner:
        return 'Ужин';
      case MealType.snack:
        return 'Перекус';
    }
  }
  
  static MealType fromString(String value) {
    switch (value) {
      case 'breakfast':
        return MealType.breakfast;
      case 'lunch':
        return MealType.lunch;
      case 'dinner':
        return MealType.dinner;
      case 'snack':
        return MealType.snack;
      default:
        return MealType.breakfast;
    }
  }
  
  @override
  String toString() => displayName;
}

class Meal extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final MealType type;
  final DateTime createdAt;
  
  const Meal({
    required this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'date': date.toIso8601String(),
    'type': type.toString().split('.').last,
    'created_at': createdAt.toIso8601String(),
  };
  
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      type: MealType.fromString(json['type']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  @override
  List<Object?> get props => [id, userId, date, type];
}