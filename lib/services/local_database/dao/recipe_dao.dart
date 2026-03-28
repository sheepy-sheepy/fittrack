import 'package:drift/drift.dart';

import '../local_database.dart';
import '../../../models/recipe.dart' as app_recipe;
import '../../../models/recipe_ingredient.dart' as app_ingredient;

class RecipeDao {
  final LocalDatabase db;
  
  RecipeDao(this.db);
  
  Future<void> insertRecipe(app_recipe.Recipe recipe) async {
    await db.into(db.recipes).insert(
      RecipesCompanion(
        id: Value(recipe.id),
        userId: Value(recipe.userId),
        name: Value(recipe.name),
        totalCalories: Value(recipe.totalCalories),
        totalProteins: Value(recipe.totalProteins),
        totalFats: Value(recipe.totalFats),
        totalCarbs: Value(recipe.totalCarbs),
        createdAt: Value(recipe.createdAt),
      ),
      mode: InsertMode.insertOrReplace,
    );
    
    for (var ingredient in recipe.ingredients) {
      await db.into(db.recipeIngredients).insert(
        RecipeIngredientsCompanion(
          id: Value(ingredient.id),
          recipeId: Value(recipe.id),
          foodId: Value(ingredient.foodId),
          grams: Value(ingredient.grams),
          foodName: Value(ingredient.foodName),
          calories: Value(ingredient.calories),
          proteins: Value(ingredient.proteins),
          fats: Value(ingredient.fats),
          carbs: Value(ingredient.carbs),
        ),
      );
    }
  }
  
  Future<List<app_recipe.Recipe>> getUserRecipes(String userId) async {
    final recipesData = await (db.select(db.recipes)
          ..where((t) => t.userId.equals(userId)))
        .get();
    
    final recipes = <app_recipe.Recipe>[];
    for (var r in recipesData) {
      final ingredients = await getRecipeIngredients(r.id);
      final totalWeight = ingredients.fold(0.0, (sum, i) => sum + i.grams);
      recipes.add(app_recipe.Recipe(
        id: r.id,
        userId: r.userId,
        name: r.name,
        ingredients: ingredients,
        totalCalories: r.totalCalories,
        totalProteins: r.totalProteins,
        totalFats: r.totalFats,
        totalCarbs: r.totalCarbs,
        totalWeight: totalWeight,
        createdAt: r.createdAt,
      ));
    }
    return recipes;
  }
  
  Future<List<app_ingredient.RecipeIngredient>> getRecipeIngredients(String recipeId) async {
    final ingredients = await (db.select(db.recipeIngredients)
          ..where((t) => t.recipeId.equals(recipeId)))
        .get();
    
    return ingredients.map((i) => app_ingredient.RecipeIngredient(
      id: i.id,
      foodId: i.foodId,
      grams: i.grams,
      foodName: i.foodName,
      calories: i.calories,
      proteins: i.proteins,
      fats: i.fats,
      carbs: i.carbs,
    )).toList();
  }
  
  Future<app_recipe.Recipe?> getRecipe(String recipeId) async {
    final recipeData = await (db.select(db.recipes)
          ..where((t) => t.id.equals(recipeId)))
        .getSingleOrNull();
    
    if (recipeData != null) {
      final ingredients = await getRecipeIngredients(recipeId);
      final totalWeight = ingredients.fold(0.0, (sum, i) => sum + i.grams);
      return app_recipe.Recipe(
        id: recipeData.id,
        userId: recipeData.userId,
        name: recipeData.name,
        ingredients: ingredients,
        totalCalories: recipeData.totalCalories,
        totalProteins: recipeData.totalProteins,
        totalFats: recipeData.totalFats,
        totalCarbs: recipeData.totalCarbs,
        totalWeight: totalWeight,
        createdAt: recipeData.createdAt,
      );
    }
    return null;
  }
  
  Future<void> updateRecipe(app_recipe.Recipe recipe) async {
    await (db.update(db.recipes)
          ..where((t) => t.id.equals(recipe.id)))
        .write(
          RecipesCompanion(
            name: Value(recipe.name),
            totalCalories: Value(recipe.totalCalories),
            totalProteins: Value(recipe.totalProteins),
            totalFats: Value(recipe.totalFats),
            totalCarbs: Value(recipe.totalCarbs),
          ),
        );
    
    await (db.delete(db.recipeIngredients)
          ..where((t) => t.recipeId.equals(recipe.id)))
        .go();
    
    for (var ingredient in recipe.ingredients) {
      await db.into(db.recipeIngredients).insert(
        RecipeIngredientsCompanion(
          id: Value(ingredient.id),
          recipeId: Value(recipe.id),
          foodId: Value(ingredient.foodId),
          grams: Value(ingredient.grams),
          foodName: Value(ingredient.foodName),
          calories: Value(ingredient.calories),
          proteins: Value(ingredient.proteins),
          fats: Value(ingredient.fats),
          carbs: Value(ingredient.carbs),
        ),
      );
    }
  }
  
  Future<void> deleteRecipe(String recipeId) async {
    await (db.delete(db.recipeIngredients)
          ..where((t) => t.recipeId.equals(recipeId)))
        .go();
    await (db.delete(db.recipes)..where((t) => t.id.equals(recipeId))).go();
  }
  
  Future<List<app_recipe.Recipe>> searchRecipes(String userId, String query) async {
    final searchPattern = '%$query%';
    final recipesData = await (db.select(db.recipes)
          ..where((t) => t.userId.equals(userId) & t.name.like(searchPattern)))
        .get();
    
    final recipes = <app_recipe.Recipe>[];
    for (var r in recipesData) {
      final ingredients = await getRecipeIngredients(r.id);
      final totalWeight = ingredients.fold(0.0, (sum, i) => sum + i.grams);
      recipes.add(app_recipe.Recipe(
        id: r.id,
        userId: r.userId,
        name: r.name,
        ingredients: ingredients,
        totalCalories: r.totalCalories,
        totalProteins: r.totalProteins,
        totalFats: r.totalFats,
        totalCarbs: r.totalCarbs,
        totalWeight: totalWeight,
        createdAt: r.createdAt,
      ));
    }
    return recipes;
  }
}