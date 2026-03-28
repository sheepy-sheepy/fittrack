import 'package:drift/drift.dart';

import '../local_database.dart';
import '../../../models/food.dart' as app_models;

class FoodDao {
  final LocalDatabase db;
  
  FoodDao(this.db);
  
  Future<void> insertFood(app_models.Food food) async {
    await db.into(db.foods).insert(
      FoodsCompanion(
        id: Value(food.id),
        name: Value(food.name),
        calories: Value(food.calories),
        proteins: Value(food.proteins),
        fats: Value(food.fats),
        carbs: Value(food.carbs),
        isCustom: Value(food.isCustom),
        userId: Value(food.userId),
        createdAt: Value(food.createdAt),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
  
  Future<void> insertFoods(List<app_models.Food> foods) async {
    await db.batch((batch) {
      for (var food in foods) {
        batch.insert(
          db.foods,
          FoodsCompanion(
            id: Value(food.id),
            name: Value(food.name),
            calories: Value(food.calories),
            proteins: Value(food.proteins),
            fats: Value(food.fats),
            carbs: Value(food.carbs),
            isCustom: Value(food.isCustom),
            userId: Value(food.userId),
            createdAt: Value(food.createdAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }
  
  Future<List<app_models.Food>> getUserFoods(String userId) async {
    final query = await (db.select(db.foods)
          ..where((t) => t.userId.equals(userId)))
        .get();
    
    return query.map((f) => app_models.Food(
      id: f.id,
      name: f.name,
      calories: f.calories,
      proteins: f.proteins,
      fats: f.fats,
      carbs: f.carbs,
      isCustom: f.isCustom,
      userId: f.userId,
      createdAt: f.createdAt,
    )).toList();
  }
  
  Future<List<app_models.Food>> getDefaultFoods() async {
    final query = await (db.select(db.foods)
          ..where((t) => t.isCustom.equals(false)))
        .get();
    
    return query.map((f) => app_models.Food(
      id: f.id,
      name: f.name,
      calories: f.calories,
      proteins: f.proteins,
      fats: f.fats,
      carbs: f.carbs,
      isCustom: f.isCustom,
      userId: f.userId,
      createdAt: f.createdAt,
    )).toList();
  }
  
  Future<app_models.Food?> getFoodById(String foodId) async {
    final query = await (db.select(db.foods)
          ..where((t) => t.id.equals(foodId)))
        .getSingleOrNull();
    
    if (query != null) {
      return app_models.Food(
        id: query.id,
        name: query.name,
        calories: query.calories,
        proteins: query.proteins,
        fats: query.fats,
        carbs: query.carbs,
        isCustom: query.isCustom,
        userId: query.userId,
        createdAt: query.createdAt,
      );
    }
    return null;
  }
  
  Future<List<app_models.Food>> searchFoods(String userId, String query) async {
    final searchPattern = '%$query%';
    final userFoods = await (db.select(db.foods)
          ..where((t) => t.userId.equals(userId) & t.name.like(searchPattern)))
        .get();
    
    final defaultFoods = await (db.select(db.foods)
          ..where((t) => t.isCustom.equals(false) & t.name.like(searchPattern)))
        .get();
    
    final allFoods = [...userFoods, ...defaultFoods];
    
    return allFoods.map((f) => app_models.Food(
      id: f.id,
      name: f.name,
      calories: f.calories,
      proteins: f.proteins,
      fats: f.fats,
      carbs: f.carbs,
      isCustom: f.isCustom,
      userId: f.userId,
      createdAt: f.createdAt,
    )).toList();
  }
  
  Future<void> updateFood(app_models.Food food) async {
    await (db.update(db.foods)
          ..where((t) => t.id.equals(food.id)))
        .write(
          FoodsCompanion(
            name: Value(food.name),
            calories: Value(food.calories),
            proteins: Value(food.proteins),
            fats: Value(food.fats),
            carbs: Value(food.carbs),
          ),
        );
  }
  
  Future<void> deleteFood(String foodId) async {
    await (db.delete(db.foods)..where((t) => t.id.equals(foodId))).go();
  }
}