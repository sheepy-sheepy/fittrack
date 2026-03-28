class AppConstants {
  static const String appName = 'FitTrack';
  
  // Activity multipliers
  static const Map<String, double> activityMultipliers = {
    'sedentary': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'active': 1.725,
    'very_active': 1.9,
  };
  
  static const Map<String, double> waterActivityMultipliers = {
    'sedentary': 1.0,
    'light': 1.2,
    'moderate': 1.4,
    'active': 1.6,
    'very_active': 1.8,
  };
  
  // Goal macros distribution
  static const Map<String, Map<String, double>> goalMacros = {
    'lose': {'proteins': 0.4, 'fats': 0.25, 'carbs': 0.35},
    'maintain': {'proteins': 0.25, 'fats': 0.25, 'carbs': 0.5},
    'gain': {'proteins': 0.35, 'fats': 0.2, 'carbs': 0.45},
  };
  
  static const double maleWaterBase = 35;
  static const double femaleWaterBase = 31;
}