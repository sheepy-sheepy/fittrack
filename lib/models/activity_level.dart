enum ActivityLevel {
  sedentary,
  light,
  moderate,
  active,
  veryActive;
  
  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Сидячий образ жизни';
      case ActivityLevel.light:
        return 'Тренировки 1-3 раза в неделю';
      case ActivityLevel.moderate:
        return 'Тренировки 3-5 раз в неделю';
      case ActivityLevel.active:
        return 'Тренировки 6-7 раз в неделю';
      case ActivityLevel.veryActive:
        return 'Профессиональный спорт или физическая работа';
    }
  }
  
  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.veryActive:
        return 1.9;
    }
  }
  
  double get waterMultiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.0;
      case ActivityLevel.light:
        return 1.2;
      case ActivityLevel.moderate:
        return 1.4;
      case ActivityLevel.active:
        return 1.6;
      case ActivityLevel.veryActive:
        return 1.8;
    }
  }
  
  static ActivityLevel fromString(String value) {
    switch (value) {
      case 'sedentary':
        return ActivityLevel.sedentary;
      case 'light':
        return ActivityLevel.light;
      case 'moderate':
        return ActivityLevel.moderate;
      case 'active':
        return ActivityLevel.active;
      case 'very_active':
        return ActivityLevel.veryActive;
      default:
        return ActivityLevel.sedentary;
    }
  }
}