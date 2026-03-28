import 'package:flutter/material.dart';
import '../models/user_profile.dart' as app_models;
import '../models/body_measurement.dart' as app_measurement;
import '../services/local_database/local_database.dart';
import '../services/database_singleton.dart';

class UserProvider extends ChangeNotifier {
  final LocalDatabase _localDb = DatabaseSingleton.instance;
  
  app_models.UserProfile? _profile;
  List<app_measurement.BodyMeasurement> _measurements = [];
  bool _isLoading = false;
  String? _error;
  
  // Удаляем конструктор, так как поле уже инициализировано
  // UserProvider(this._localDb);
  
  app_models.UserProfile? get profile => _profile;
  List<app_measurement.BodyMeasurement> get measurements => _measurements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _profile = await _localDb.profileDao.getProfile(userId);
      final measurements = await _localDb.measurementDao.getAllMeasurements(userId);
      _measurements = measurements.cast<app_measurement.BodyMeasurement>().toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateProfile(app_models.UserProfile profile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _localDb.profileDao.insertProfile(profile);
      _profile = profile;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> addMeasurement(app_measurement.BodyMeasurement measurement) async {
    try {
      await _localDb.measurementDao.insertMeasurement(measurement);
      _measurements.add(measurement);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> refreshMeasurements(String userId) async {
    try {
      final measurements = await _localDb.measurementDao.getAllMeasurements(userId);
      _measurements = measurements.cast<app_measurement.BodyMeasurement>().toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}