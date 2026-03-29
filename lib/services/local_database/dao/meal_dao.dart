import 'package:drift/drift.dart';
import '../local_database.dart';
import '../../../models/meal.dart' as app_meal;
import '../../../models/meal_entry.dart' as app_entry;
import '../../../models/water_entry.dart' as app_water;

class MealDao {
  final LocalDatabase db;
  
  MealDao(this.db);
  
  // Meal operations
  Future<void> insertMeal(app_meal.Meal meal) async {
    await db.into(db.meals).insert(
      MealsCompanion(
        id: Value(meal.id),
        userId: Value(meal.userId),
        date: Value(meal.date),
        type: Value(meal.type.toString().split('.').last),
        createdAt: Value(meal.createdAt),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
  
  Future<List<app_meal.Meal>> getMeals(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final results = await (db.select(db.meals)
          ..where((t) => t.userId.equals(userId) &
                t.date.isBetweenValues(startOfDay, endOfDay)))
        .get();
    
    return results.map((m) => app_meal.Meal(
      id: m.id,
      userId: m.userId,
      date: m.date,
      type: app_meal.MealType.fromString(m.type),
      createdAt: m.createdAt,
    )).toList();
  }
  
  Future<app_meal.Meal?> getMeal(String mealId) async {
    final result = await (db.select(db.meals)
          ..where((t) => t.id.equals(mealId)))
        .getSingleOrNull();
    
    if (result != null) {
      return app_meal.Meal(
        id: result.id,
        userId: result.userId,
        date: result.date,
        type: app_meal.MealType.fromString(result.type),
        createdAt: result.createdAt,
      );
    }
    return null;
  }
  
  Future<void> deleteMeal(String mealId) async {
    await (db.delete(db.mealEntries)..where((t) => t.mealId.equals(mealId))).go();
    await (db.delete(db.meals)..where((t) => t.id.equals(mealId))).go();
  }
  
  // MealEntry operations
  Future<void> insertMealEntry(app_entry.MealEntry entry) async {
    await db.into(db.mealEntries).insert(
      MealEntriesCompanion(
        id: Value(entry.id),
        mealId: Value(entry.mealId),
        foodId: Value(entry.foodId),
        recipeId: Value(entry.recipeId),
        grams: Value(entry.grams),
        name: Value(entry.name),
        calories: Value(entry.calories),
        proteins: Value(entry.proteins),
        fats: Value(entry.fats),
        carbs: Value(entry.carbs),
        createdAt: Value(entry.createdAt),
      ),
    );
  }
  
  Future<List<app_entry.MealEntry>> getMealEntries(String mealId) async {
    final results = await (db.select(db.mealEntries)
          ..where((t) => t.mealId.equals(mealId)))
        .get();
    
    return results.map((e) => app_entry.MealEntry(
      id: e.id,
      mealId: e.mealId,
      foodId: e.foodId,
      recipeId: e.recipeId,
      grams: e.grams,
      name: e.name,
      calories: e.calories,
      proteins: e.proteins,
      fats: e.fats,
      carbs: e.carbs,
      createdAt: e.createdAt,
    )).toList();
  }
  
  Future<void> updateMealEntry(app_entry.MealEntry entry) async {
    await (db.update(db.mealEntries)
          ..where((t) => t.id.equals(entry.id)))
        .write(
          MealEntriesCompanion(
            grams: Value(entry.grams),
            calories: Value(entry.calories),
            proteins: Value(entry.proteins),
            fats: Value(entry.fats),
            carbs: Value(entry.carbs),
          ),
        );
  }
  
  Future<void> deleteMealEntry(String entryId) async {
    await (db.delete(db.mealEntries)..where((t) => t.id.equals(entryId))).go();
  }
  
  // Water operations
  Future<void> saveWaterEntry(String userId, DateTime date, double amount) async {
    final existing = await (db.select(db.waterEntries)
          ..where((t) => t.userId.equals(userId) & t.date.equals(date)))
        .getSingleOrNull();
    
    if (existing != null) {
      await (db.update(db.waterEntries)
            ..where((t) => t.id.equals(existing.id)))
          .write(
            WaterEntriesCompanion(
              amount: Value(amount),
              updatedAt: Value(DateTime.now()),
            ),
          );
    } else {
      await db.into(db.waterEntries).insert(
        WaterEntriesCompanion(
          id: Value(DateTime.now().millisecondsSinceEpoch.toString()),
          userId: Value(userId),
          date: Value(date),
          amount: Value(amount),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  Future<app_water.WaterEntry?> getWaterEntry(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final result = await (db.select(db.waterEntries)
          ..where((t) => t.userId.equals(userId) &
                t.date.isBetweenValues(startOfDay, endOfDay)))
        .getSingleOrNull();
    
    if (result != null) {
      return app_water.WaterEntry(
        id: result.id,
        userId: result.userId,
        date: result.date,
        amount: result.amount,
        updatedAt: result.updatedAt,
      );
    }
    return null;
  }
  
  Future<List<app_water.WaterEntry>> getAllWaterEntries(String userId) async {
    final results = await (db.select(db.waterEntries)
          ..where((t) => t.userId.equals(userId)))
        .get();
    
    return results.map((w) => app_water.WaterEntry(
      id: w.id,
      userId: w.userId,
      date: w.date,
      amount: w.amount,
      updatedAt: w.updatedAt,
    )).toList();
  }
}