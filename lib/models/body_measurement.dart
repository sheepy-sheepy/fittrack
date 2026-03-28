import 'package:equatable/equatable.dart';

class BodyMeasurement extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final double weight;
  final double neck;
  final double waist;
  final double hip;
  
  const BodyMeasurement({
    required this.id,
    required this.userId,
    required this.date,
    required this.weight,
    required this.neck,
    required this.waist,
    required this.hip,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'date': date.toIso8601String(),
    'weight': weight,
    'neck': neck,
    'waist': waist,
    'hip': hip,
  };
  
  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      weight: json['weight'].toDouble(),
      neck: json['neck'].toDouble(),
      waist: json['waist'].toDouble(),
      hip: json['hip'].toDouble(),
    );
  }
  
  @override
  List<Object?> get props => [id, userId, date, weight, neck, waist, hip];
}