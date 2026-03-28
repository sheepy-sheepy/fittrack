import 'package:fittrack/services/local_database/local_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart' as app_models;
import '../models/registration_status.dart';
import 'supabase_service.dart';
import 'database_singleton.dart';

class AuthService {
  final SupabaseService _supabase = SupabaseService();
  final LocalDatabase _localDb = DatabaseSingleton.instance;
  
  Future<void> register(String email, String password) async {
    try {
      final response = await _supabase.client.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        final user = app_models.User(
          id: response.user!.id,
          email: email,
          status: RegistrationStatus.emailNotVerified,
          createdAt: DateTime.now(),
        );
        
        await _localDb.userDao.insertUser(user);
        await _supabase.updateUserStatus(user.id, RegistrationStatus.emailNotVerified);
        
        debugPrint('User registered successfully. Check email for verification code.');
      } else {
        throw Exception('Registration failed: No user returned');
      }
    } catch (e) {
      debugPrint('Error registering: $e');
      throw Exception('Registration failed: $e');
    }
  }
  
  Future<app_models.User?> login(String email, String password) async {
    try {
      final response = await _supabase.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        final userId = response.user!.id;
        
        // Получаем статус из Supabase (это Map<String, dynamic>)
        final supabaseUser = await _supabase.getUser(userId);
        RegistrationStatus actualStatus;
        
        if (supabaseUser != null) {
          // Извлекаем статус из мапы
          final statusValue = supabaseUser['status'] as int?;
          actualStatus = RegistrationStatus.fromInt(statusValue ?? 0);
          debugPrint('Status from Supabase: $actualStatus (value: $statusValue)');
        } else {
          // Если пользователя нет в Supabase, определяем статус по подтверждению email
          actualStatus = response.user!.emailConfirmedAt != null 
              ? RegistrationStatus.onboardingNotCompleted 
              : RegistrationStatus.emailNotVerified;
          debugPrint('Status determined: $actualStatus');
        }
        
        // Проверяем, существует ли пользователь в локальной БД
        var localUser = await _localDb.userDao.getUser(userId);
        
        if (localUser == null) {
          // Создаем пользователя в локальной БД с правильным статусом
          localUser = app_models.User(
            id: userId,
            email: response.user!.email ?? email,
            status: actualStatus,
            createdAt: DateTime.now(),
          );
          await _localDb.userDao.insertUser(localUser);
          
          // Создаем пользователя в Supabase таблице users
          await _supabase.saveUser(localUser);
          
          debugPrint('Created new local user with status: ${localUser.status}');
        } else {
          // Обновляем локального пользователя, если статус изменился
          if (localUser.status != actualStatus) {
            debugPrint('Updating local user status from ${localUser.status} to $actualStatus');
            await _localDb.userDao.updateUserStatus(userId, actualStatus);
            localUser = await _localDb.userDao.getUser(userId);
          } else {
            debugPrint('Local user status matches: ${localUser.status}');
          }
        }
        
        return localUser;
      }
      return null;
    } catch (e) {
      debugPrint('Error logging in: $e');
      throw Exception('Login failed: $e');
    }
  }
  
  Future<void> updatePassword(String oldPassword, String newPassword) async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user != null) {
        await _supabase.client.auth.signInWithPassword(
          email: user.email!,
          password: oldPassword,
        );
        
        await _supabase.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      }
    } catch (e) {
      debugPrint('Error updating password: $e');
      throw Exception('Password update failed: $e');
    }
  }
  
  Future<void> logout() async {
    try {
      await _supabase.client.auth.signOut();
    } catch (e) {
      debugPrint('Error logging out: $e');
      throw Exception('Logout failed: $e');
    }
  }
  
  Future<void> verifyEmail(String email, String token) async {
    try {
      await _supabase.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
    } catch (e) {
      debugPrint('Error verifying email: $e');
      throw Exception('Verification failed: $e');
    }
  }
  
  Future<void> resendVerification(String email) async {
    try {
      await _supabase.client.auth.resend(
        email: email,
        type: OtpType.signup,
      );
    } catch (e) {
      debugPrint('Error resending verification: $e');
      throw Exception('Failed to resend verification: $e');
    }
  }
}