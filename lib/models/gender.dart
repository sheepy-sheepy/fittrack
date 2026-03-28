enum Gender {
  male,
  female;
  
  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Мужской';
      case Gender.female:
        return 'Женский';
    }
  }
  
  double get waterBase {
    switch (this) {
      case Gender.male:
        return 35;
      case Gender.female:
        return 31;
    }
  }
  
  static Gender fromString(String value) {
    switch (value) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.male;
    }
  }
}