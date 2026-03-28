import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'local_database/local_database.dart';
import 'supabase_service.dart';
import '../models/user_profile.dart' as app_profile;
import '../models/body_measurement.dart' as app_measurement;
import '../models/food.dart' as app_food;
import '../models/recipe.dart' as app_recipe;
import 'database_singleton.dart';

class SyncService {
  final LocalDatabase _localDb = DatabaseSingleton.instance;
  final SupabaseService _supabase = SupabaseService();
  final Connectivity _connectivity = Connectivity();
  
  Future<bool> hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  Future<void> syncToCloud() async {
    if (!await hasInternetConnection()) {
      throw Exception('Нет интернет-соединения');
    }
    
    final session = _supabase.client.auth.currentSession;
    if (session == null) {
      throw Exception('Пользователь не авторизован');
    }
    
    final userId = session.user.id;
    
    try {
      final profile = await _localDb.profileDao.getProfile(userId);
      if (profile != null) {
        await _supabase.saveUserProfile(profile);
      }
      
      final measurements = await _localDb.measurementDao.getAllMeasurements(userId);
      for (var measurement in measurements) {
        await _supabase.saveBodyMeasurement(measurement);
      }
      
      final foods = await _localDb.foodDao.getUserFoods(userId);
      for (var food in foods) {
        await _supabase.saveFood(food);
      }
      
      final recipes = await _localDb.recipeDao.getUserRecipes(userId);
      for (var recipe in recipes) {
        await _supabase.saveRecipe(recipe);
      }
      
      final waterEntries = await _localDb.mealDao.getAllWaterEntries(userId);
      for (var entry in waterEntries) {
        await _supabase.saveWaterEntry(entry);
      }
      
      final photos = await _localDb.photoDao.getAllPhotoEntries(userId);
      for (var photo in photos) {
        await _supabase.savePhotoEntry(photo);
      }
    } catch (e) {
      debugPrint('Error syncing to cloud: $e');
      throw Exception('Ошибка синхронизации: $e');
    }
  }
  
  Future<void> syncFromCloud() async {
    if (!await hasInternetConnection()) {
      throw Exception('Нет интернет-соединения');
    }
    
    final session = _supabase.client.auth.currentSession;
    if (session == null) {
      throw Exception('Пользователь не авторизован');
    }
    
    final userId = session.user.id;
    
    try {
      final cloudData = await _supabase.fetchUserData(userId);
      
      if (cloudData['profile'] != null) {
        final profile = app_profile.UserProfile.fromJson(cloudData['profile']);
        await _localDb.profileDao.insertProfile(profile);
      }
      
      if (cloudData['measurements'] != null) {
        for (var m in cloudData['measurements']) {
          final measurement = app_measurement.BodyMeasurement.fromJson(m);
          await _localDb.measurementDao.insertMeasurement(measurement);
        }
      }
      
      if (cloudData['foods'] != null) {
        for (var f in cloudData['foods']) {
          final food = app_food.Food.fromJson(f);
          await _localDb.foodDao.insertFood(food);
        }
      }
      
      if (cloudData['recipes'] != null) {
        for (var r in cloudData['recipes']) {
          final recipe = app_recipe.Recipe.fromJson(r);
          await _localDb.recipeDao.insertRecipe(recipe);
        }
      }
    } catch (e) {
      debugPrint('Error syncing from cloud: $e');
      throw Exception('Ошибка загрузки данных: $e');
    }
  }
}