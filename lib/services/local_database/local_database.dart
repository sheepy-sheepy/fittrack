import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'tables.dart';
import 'dao/user_dao.dart';
import 'dao/profile_dao.dart';
import 'dao/food_dao.dart';
import 'dao/measurement_dao.dart';
import 'dao/recipe_dao.dart';
import 'dao/meal_dao.dart';
import 'dao/photo_dao.dart';

part 'local_database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(appDir.path, 'fittrack.db'));
    return NativeDatabase.createInBackground(dbFile);
  });
}

@DriftDatabase(
  tables: [
    Users,
    UserProfiles,
    BodyMeasurements,
    Foods,
    Recipes,
    RecipeIngredients,
    Meals,
    MealEntries,
    WaterEntries,
    PhotoEntries,
  ],
)
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 2;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _insertDefaultFoods();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add any new tables or columns here
        }
      },
    );
  }
  
  Future<void> _insertDefaultFoods() async {
    try {
      final csvString = await rootBundle.loadString('assets/foods.csv');
      final lines = csvString.split('\n');
      
      if (lines.isEmpty) return;
      
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        
        final parts = _parseCsvLine(lines[i]);
        if (parts.length >= 5) {
          await into(foods).insert(
            FoodsCompanion(
              id: Value('default_${DateTime.now().millisecondsSinceEpoch}_$i'),
              name: Value(parts[0].replaceAll('"', '').trim()),
              calories: Value(double.tryParse(parts[1]) ?? 0),
              proteins: Value(double.tryParse(parts[2]) ?? 0),
              fats: Value(double.tryParse(parts[3]) ?? 0),
              carbs: Value(double.tryParse(parts[4]) ?? 0),
              isCustom: const Value(false),
              userId: const Value(null),
              createdAt: Value(DateTime.now()),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading default foods: $e');
    }
  }
  
  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final RegExp regex = RegExp(r'(?:[^,"]|"(?:\\.|[^"])*")+');
    final matches = regex.allMatches(line);
    
    for (final match in matches) {
      String value = match.group(0)!;
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }
      result.add(value);
    }
    
    return result;
  }
  
  late final userDao = UserDao(this);
  late final profileDao = ProfileDao(this);
  late final foodDao = FoodDao(this);
  late final measurementDao = MeasurementDao(this);
  late final recipeDao = RecipeDao(this);
  late final mealDao = MealDao(this);
  late final photoDao = PhotoDao(this);
}