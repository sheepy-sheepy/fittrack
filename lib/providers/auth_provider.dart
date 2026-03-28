import 'package:fittrack/services/local_database/local_database.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;
import '../services/auth_service.dart';
import '../services/database_singleton.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final LocalDatabase _localDb = DatabaseSingleton.instance;
  
  app_models.User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  app_models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentUser = await _authService.login(email, password);
      return _currentUser != null;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.register(email, password);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    await _authService.logout();
    _currentUser = null;
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> loadCurrentUser() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _currentUser = await _localDb.userDao.getUser(session.user.id);
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}