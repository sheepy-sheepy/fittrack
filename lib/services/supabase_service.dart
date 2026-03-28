import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/registration_status.dart';
import '../models/user.dart' as app_models;
import '../models/user_profile.dart' as app_profile;
import '../models/body_measurement.dart' as app_measurement;
import '../models/food.dart' as app_food;
import '../models/recipe.dart' as app_recipe;
import '../models/meal.dart' as app_meal;
import '../models/meal_entry.dart' as app_entry;
import '../models/water_entry.dart' as app_water;
import '../models/photo_entry.dart' as app_photo;

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  Future<void> init() async {
    await Supabase.initialize(
      url: 'https://xczngsovpkknjsbhpcen.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhjem5nc292cGtrbmpzYmhwY2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NDc0MjksImV4cCI6MjA5MDAyMzQyOX0.kb_wKbLvbjulfYjCxg67vi0JjYxdQHUiyMhdS7fTo4o',
    );
  }

  // User operations
  Future<void> updateUserStatus(
      String userId, RegistrationStatus status) async {
    try {
      await client
          .from('users')
          .update({'status': status.toInt()}).eq('id', userId);
    } catch (e) {
      debugPrint('Error updating user status: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final response =
          await client.from('users').select().eq('id', userId).maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  Future<void> saveUser(app_models.User user) async {
    try {
      await client.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'status': user.status.toInt(),
        'created_at': user.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving user: $e');
      rethrow;
    }
  }

  // Profile operations
  Future<void> saveUserProfile(app_profile.UserProfile profile) async {
    try {
      // Проверяем, существует ли пользователь в Supabase
      final userExists = await client
          .from('users')
          .select()
          .eq('id', profile.userId)
          .maybeSingle();

      if (userExists == null) {
        // Если пользователь не существует, создаем его
        await client.from('users').insert({
          'id': profile.userId,
          'email': '', // Временный email, обновится при следующем входе
          'status': RegistrationStatus.onboardingNotCompleted.toInt(),
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await client.from('user_profiles').upsert(profile.toJson());
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      rethrow;
    }
  }

  Future<app_profile.UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return app_profile.UserProfile.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Body measurements
  Future<void> saveBodyMeasurement(
      app_measurement.BodyMeasurement measurement) async {
    try {
      await client.from('body_measurements').insert(measurement.toJson());
    } catch (e) {
      debugPrint('Error saving body measurement: $e');
      rethrow;
    }
  }

  Future<List<app_measurement.BodyMeasurement>> getBodyMeasurements(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Сначала получаем все измерения
      final response = await client
          .from('body_measurements')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: true);

      // Фильтруем результаты в Dart коде
      List<dynamic> filteredResponse = response;

      if (startDate != null) {
        filteredResponse = filteredResponse.where((item) {
          final date = DateTime.parse(item['date']);
          return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
        }).toList();
      }

      if (endDate != null) {
        filteredResponse = filteredResponse.where((item) {
          final date = DateTime.parse(item['date']);
          return date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        }).toList();
      }

      return filteredResponse
          .map<app_measurement.BodyMeasurement>(
              (json) => app_measurement.BodyMeasurement.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting body measurements: $e');
      return [];
    }
  }

  // Food operations
  Future<List<app_food.Food>> getFoods(String userId) async {
    try {
      final response = await client
          .from('foods')
          .select()
          .or('user_id.eq.$userId,is_custom.eq.false')
          .order('name');

      return response
          .map<app_food.Food>((json) => app_food.Food.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting foods: $e');
      return [];
    }
  }

  Future<void> saveFood(app_food.Food food) async {
    try {
      await client.from('foods').insert(food.toJson());
    } catch (e) {
      debugPrint('Error saving food: $e');
      rethrow;
    }
  }

  Future<void> updateFood(app_food.Food food) async {
    try {
      await client.from('foods').update(food.toJson()).eq('id', food.id);
    } catch (e) {
      debugPrint('Error updating food: $e');
      rethrow;
    }
  }

  Future<void> deleteFood(String foodId) async {
    try {
      await client.from('foods').delete().eq('id', foodId);
    } catch (e) {
      debugPrint('Error deleting food: $e');
      rethrow;
    }
  }

  // Recipe operations
  Future<List<app_recipe.Recipe>> getRecipes(String userId) async {
    try {
      final response = await client
          .from('recipes')
          .select()
          .eq('user_id', userId)
          .order('name');

      return response
          .map<app_recipe.Recipe>((json) => app_recipe.Recipe.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting recipes: $e');
      return [];
    }
  }

  Future<void> saveRecipe(app_recipe.Recipe recipe) async {
    try {
      await client.from('recipes').insert(recipe.toJson());
    } catch (e) {
      debugPrint('Error saving recipe: $e');
      rethrow;
    }
  }

  Future<void> updateRecipe(app_recipe.Recipe recipe) async {
    try {
      await client.from('recipes').update(recipe.toJson()).eq('id', recipe.id);
    } catch (e) {
      debugPrint('Error updating recipe: $e');
      rethrow;
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      await client.from('recipes').delete().eq('id', recipeId);
    } catch (e) {
      debugPrint('Error deleting recipe: $e');
      rethrow;
    }
  }

  // Meal operations
  Future<List<app_meal.Meal>> getMeals(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Получаем все приемы пищи для пользователя
      final response = await client
          .from('meals')
          .select()
          .eq('user_id', userId)
          .order('type');

      // Фильтруем по дате в Dart коде
      final filteredResponse = response.where((item) {
        final itemDate = DateTime.parse(item['date']);
        return itemDate.isAfter(startOfDay) && itemDate.isBefore(endOfDay);
      }).toList();

      return filteredResponse
          .map<app_meal.Meal>((json) => app_meal.Meal.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting meals: $e');
      return [];
    }
  }

  Future<void> saveMeal(app_meal.Meal meal) async {
    try {
      await client.from('meals').insert(meal.toJson());
    } catch (e) {
      debugPrint('Error saving meal: $e');
      rethrow;
    }
  }

  Future<void> saveMealEntry(app_entry.MealEntry entry) async {
    try {
      await client.from('meal_entries').insert(entry.toJson());
    } catch (e) {
      debugPrint('Error saving meal entry: $e');
      rethrow;
    }
  }

  Future<List<app_entry.MealEntry>> getMealEntries(String mealId) async {
    try {
      final response =
          await client.from('meal_entries').select().eq('meal_id', mealId);

      return response
          .map<app_entry.MealEntry>(
              (json) => app_entry.MealEntry.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting meal entries: $e');
      return [];
    }
  }

  Future<void> deleteMealEntry(String entryId) async {
    try {
      await client.from('meal_entries').delete().eq('id', entryId);
    } catch (e) {
      debugPrint('Error deleting meal entry: $e');
      rethrow;
    }
  }

  // Water operations
  Future<void> saveWaterEntry(app_water.WaterEntry entry) async {
    try {
      await client.from('water_entries').upsert(entry.toJson());
    } catch (e) {
      debugPrint('Error saving water entry: $e');
      rethrow;
    }
  }

  Future<app_water.WaterEntry?> getWaterEntry(
      String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response =
          await client.from('water_entries').select().eq('user_id', userId);

      // Фильтруем по дате в Dart коде
      final filteredResponse = response.where((item) {
        final itemDate = DateTime.parse(item['date']);
        return itemDate.isAfter(startOfDay) && itemDate.isBefore(endOfDay);
      }).toList();

      if (filteredResponse.isNotEmpty) {
        return app_water.WaterEntry.fromJson(filteredResponse.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting water entry: $e');
      return null;
    }
  }

  // Photo operations
  Future<List<app_photo.PhotoEntry>> getPhotoEntries(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Получаем все фото
      final response = await client
          .from('photo_entries')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: true);

      // Фильтруем в Dart коде
      List<dynamic> filteredResponse = response;

      if (startDate != null) {
        filteredResponse = filteredResponse.where((item) {
          final date = DateTime.parse(item['date']);
          return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
        }).toList();
      }

      if (endDate != null) {
        filteredResponse = filteredResponse.where((item) {
          final date = DateTime.parse(item['date']);
          return date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        }).toList();
      }

      return filteredResponse
          .map<app_photo.PhotoEntry>(
              (json) => app_photo.PhotoEntry.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting photo entries: $e');
      return [];
    }
  }

  Future<void> savePhotoEntry(app_photo.PhotoEntry entry) async {
    try {
      await client.from('photo_entries').insert(entry.toJson());
    } catch (e) {
      debugPrint('Error saving photo entry: $e');
      rethrow;
    }
  }

  // Sync operations
  Future<Map<String, dynamic>> fetchUserData(String userId) async {
    final profile = await getUserProfile(userId);
    final measurements = await getBodyMeasurements(userId);
    final foods = await getFoods(userId);
    final recipes = await getRecipes(userId);

    return {
      'profile': profile?.toJson(),
      'measurements': measurements.map((m) => m.toJson()).toList(),
      'foods': foods.map((f) => f.toJson()).toList(),
      'recipes': recipes.map((r) => r.toJson()).toList(),
    };
  }
}
