import 'package:equatable/equatable.dart';
import 'dart:math';

class UserProfile extends Equatable {
  final String userId;
  final String name;
  final double height;
  final double weight;
  final double neckCircumference;
  final double waistCircumference;
  final double hipCircumference;
  final String gender; // 'male' or 'female'
  final String goal; // 'lose', 'maintain', 'gain'
  final String activityLevel;
  final DateTime birthDate;
  final int deficit;
  final DateTime updatedAt;

  const UserProfile({
    required this.userId,
    required this.name,
    required this.height,
    required this.weight,
    required this.neckCircumference,
    required this.waistCircumference,
    required this.hipCircumference,
    required this.gender,
    required this.goal,
    required this.activityLevel,
    required this.birthDate,
    this.deficit = 300,
    required this.updatedAt,
  });

  int get age {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  double get bodyFatPercentage {
    const double ln10 = 2.302585092994046;
    
    if (gender == 'male') {
      // Формула для мужчин: 495 / (1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)) - 450
      final logWaistNeck = log(waistCircumference - neckCircumference) / ln10;
      final logHeight = log(height) / ln10;
      final bodyFat = 495 / (1.0324 - 0.19077 * logWaistNeck + 0.15456 * logHeight) - 450;
      return bodyFat.clamp(0.0, 100.0);
    } else {
      // Формула для женщин: 495 / (1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(height)) - 450
      final logWaistHipNeck = log(waistCircumference + hipCircumference - neckCircumference) / ln10;
      final logHeight = log(height) / ln10;
      final bodyFat = 495 / (1.29579 - 0.35004 * logWaistHipNeck + 0.22100 * logHeight) - 450;
      return bodyFat.clamp(0.0, 100.0);
    }
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'height': height,
        'weight': weight,
        'neck_circumference': neckCircumference,
        'waist_circumference': waistCircumference,
        'hip_circumference': hipCircumference,
        'gender': gender,
        'goal': goal,
        'activity_level': activityLevel,
        'birth_date': birthDate.toIso8601String(),
        'deficit': deficit,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'],
      name: json['name'],
      height: json['height'].toDouble(),
      weight: json['weight'].toDouble(),
      neckCircumference: json['neck_circumference'].toDouble(),
      waistCircumference: json['waist_circumference'].toDouble(),
      hipCircumference: json['hip_circumference'].toDouble(),
      gender: json['gender'],
      goal: json['goal'],
      activityLevel: json['activity_level'],
      birthDate: DateTime.parse(json['birth_date']),
      deficit: json['deficit'] ?? 300,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  UserProfile copyWith({
    String? userId,
    String? name,
    double? height,
    double? weight,
    double? neckCircumference,
    double? waistCircumference,
    double? hipCircumference,
    String? gender,
    String? goal,
    String? activityLevel,
    DateTime? birthDate,
    int? deficit,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      neckCircumference: neckCircumference ?? this.neckCircumference,
      waistCircumference: waistCircumference ?? this.waistCircumference,
      hipCircumference: hipCircumference ?? this.hipCircumference,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      birthDate: birthDate ?? this.birthDate,
      deficit: deficit ?? this.deficit,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        name,
        height,
        weight,
        neckCircumference,
        waistCircumference,
        hipCircumference,
        gender,
        goal,
        activityLevel,
        birthDate,
        deficit,
        updatedAt
      ];
}