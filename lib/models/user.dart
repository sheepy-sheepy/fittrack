import 'package:equatable/equatable.dart';
import 'registration_status.dart';

class User extends Equatable {
  final String id;
  final String email;
  final RegistrationStatus status;
  final DateTime createdAt;
  
  const User({
    required this.id,
    required this.email,
    required this.status,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'status': status.toInt(),
    'created_at': createdAt.toIso8601String(),
    // 'password_hash': passwordHash, - удаляем
  };
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      status: RegistrationStatus.fromInt(json['status']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  User copyWith({
    String? id,
    String? email,
    RegistrationStatus? status,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [id, email, status, createdAt];
}