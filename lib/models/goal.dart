enum Goal {
  lose,
  maintain,
  gain;
  
  String get displayName {
    switch (this) {
      case Goal.lose:
        return 'Похудеть';
      case Goal.maintain:
        return 'Поддерживать вес';
      case Goal.gain:
        return 'Набрать массу';
    }
  }
  
  Map<String, double> get macros {
    switch (this) {
      case Goal.lose:
        return {'proteins': 0.4, 'fats': 0.25, 'carbs': 0.35};
      case Goal.maintain:
        return {'proteins': 0.25, 'fats': 0.25, 'carbs': 0.5};
      case Goal.gain:
        return {'proteins': 0.35, 'fats': 0.2, 'carbs': 0.45};
    }
  }
  
  static Goal fromString(String value) {
    switch (value) {
      case 'lose':
        return Goal.lose;
      case 'maintain':
        return Goal.maintain;
      case 'gain':
        return Goal.gain;
      default:
        return Goal.maintain;
    }
  }
}