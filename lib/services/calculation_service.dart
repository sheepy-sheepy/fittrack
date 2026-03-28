import 'dart:math';
import '../models/user_profile.dart';
import '../models/gender.dart';
import '../models/goal.dart';
import '../models/activity_level.dart';

class CalculationService {
  static const double ln10 = 2.302585092994046;

  double calculateDCI(UserProfile profile) {
    double bmr;

    if (profile.gender == Gender.male.name) {
      bmr = (10 * profile.weight) +
          (6.25 * profile.height) -
          (5 * profile.age) +
          5;
    } else {
      bmr = (10 * profile.weight) +
          (6.25 * profile.height) -
          (5 * profile.age) -
          161;
    }

    final activity = ActivityLevel.values.firstWhere(
      (e) => e.name == profile.activityLevel,
      orElse: () => ActivityLevel.sedentary,
    );

    return bmr * activity.multiplier;
  }

  Map<String, double> calculateNutritionNorm(UserProfile profile) {
    final dci = calculateDCI(profile);
    double calories;

    final goal = Goal.values.firstWhere(
      (e) => e.name == profile.goal,
      orElse: () => Goal.maintain,
    );

    switch (goal) {
      case Goal.lose:
        calories = dci - profile.deficit;
        break;
      case Goal.gain:
        calories = dci + profile.deficit;
        break;
      case Goal.maintain:
        calories = dci;
        break;
    }

    final macros = goal.macros;
    final proteins = (calories * macros['proteins']!) / 4;
    final fats = (calories * macros['fats']!) / 9;
    final carbs = (calories * macros['carbs']!) / 4;

    // Расчет воды
    final gender = Gender.values.firstWhere(
      (e) => e.name == profile.gender,
      orElse: () => Gender.male,
    );

    final activity = ActivityLevel.values.firstWhere(
      (e) => e.name == profile.activityLevel,
      orElse: () => ActivityLevel.sedentary,
    );

    final water = profile.weight * gender.waterBase * activity.waterMultiplier;

    return {
      'calories': calories,
      'proteins': proteins,
      'fats': fats,
      'carbs': carbs,
      'water': water,
    };
  }

  double calculateBodyFatPercentage(
    Gender gender,
    double height,
    double neck,
    double waist,
    double hip,
  ) {
    double bodyFat;
    
    if (gender == Gender.male) {
      // Формула для мужчин: 495 / (1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)) - 450
      final logWaistNeck = log(waist - neck) / ln10;
      final logHeight = log(height) / ln10;
      bodyFat = 495 / (1.0324 - 0.19077 * logWaistNeck + 0.15456 * logHeight) - 450;
    } else {
      // Формула для женщин: 495 / (1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(height)) - 450
      final logWaistHipNeck = log(waist + hip - neck) / ln10;
      final logHeight = log(height) / ln10;
      bodyFat = 495 / (1.29579 - 0.35004 * logWaistHipNeck + 0.22100 * logHeight) - 450;
    }
    
    return bodyFat.clamp(0.0, 100.0);
  }

  Map<String, double> calculateRemainingNutrition(
    Map<String, double> norm,
    Map<String, double> consumed,
  ) {
    return {
      'calories': norm['calories']! - consumed['calories']!,
      'proteins': norm['proteins']! - consumed['proteins']!,
      'fats': norm['fats']! - consumed['fats']!,
      'carbs': norm['carbs']! - consumed['carbs']!,
    };
  }
}