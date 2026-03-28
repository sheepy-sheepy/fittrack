class Validators {
  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
    }
    return null;
  }
  
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Введите корректный email';
    }
    return null;
  }
  
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    if (value.length < 6) {
      return 'Пароль должен содержать не менее 6 символов';
    }
    return null;
  }
  
  static String? positiveNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Введите число';
    }
    if (number <= 0) {
      return 'Введите число больше 0';
    }
    return null;
  }
  
  static String? nonNegativeNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Введите число';
    }
    if (number < 0) {
      return 'Введите неотрицательное число';
    }
    return null;
  }
  
  static String? date(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите дату';
    }
    final dateRegex = RegExp(r'^\d{2}\.\d{2}\.\d{4}$');
    if (!dateRegex.hasMatch(value)) {
      return 'Введите дату в формате ДД.ММ.ГГГГ';
    }
    return null;
  }
}