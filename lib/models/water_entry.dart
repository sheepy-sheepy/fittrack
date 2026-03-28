import 'package:equatable/equatable.dart';

class WaterEntry extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final double amount;
  final DateTime updatedAt;
  
  const WaterEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.amount,
    required this.updatedAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'date': date.toIso8601String(),
    'amount': amount,
    'updated_at': updatedAt.toIso8601String(),
  };
  
  factory WaterEntry.fromJson(Map<String, dynamic> json) {
    return WaterEntry(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      amount: json['amount'].toDouble(),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  
  @override
  List<Object?> get props => [id, userId, date, amount];
}