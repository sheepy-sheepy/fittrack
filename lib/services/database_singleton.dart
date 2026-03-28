import 'local_database/local_database.dart';

class DatabaseSingleton {
  static LocalDatabase? _instance;
  
  static LocalDatabase get instance {
    _instance ??= LocalDatabase();
    return _instance!;
  }
}