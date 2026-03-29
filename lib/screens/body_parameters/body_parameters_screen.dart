import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/body_measurement.dart' as app_measurement;
import '../../models/user_profile.dart' as app_profile;
import '../../models/gender.dart';
import '../../services/local_database/local_database.dart';
import '../../services/calculation_service.dart';
import '../../widgets/custom_button.dart';

class BodyParametersScreen extends StatefulWidget {
  const BodyParametersScreen({super.key});
  
  @override
  _BodyParametersScreenState createState() => _BodyParametersScreenState();
}

class _BodyParametersScreenState extends State<BodyParametersScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _neckController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _hipController = TextEditingController();
  
  bool _hasMeasurementToday = false;
  app_measurement.BodyMeasurement? _todayMeasurement;
  bool _isLoading = true;
  bool _isSaving = false;
  app_profile.UserProfile? _profile;
  
  final LocalDatabase _localDb = LocalDatabase();
  final CalculationService _calculationService = CalculationService();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _weightController.dispose();
    _neckController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _profile = await _localDb.profileDao.getProfile(session.user.id);
        await _checkTodayMeasurement(session.user.id);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _checkTodayMeasurement(String userId) async {
    final today = DateTime.now();
    final measurement = await _localDb.measurementDao.getMeasurementByDate(
      userId,
      today,
    );
    
    if (mounted) {
      setState(() {
        _hasMeasurementToday = measurement != null;
        _todayMeasurement = measurement;
        
        if (measurement != null) {
          _weightController.text = measurement.weight.toString();
          _neckController.text = measurement.neck.toString();
          _waistController.text = measurement.waist.toString();
          _hipController.text = measurement.hip.toString();
        }
      });
    }
  }
  
  Future<void> _saveMeasurement() async {
    if (_hasMeasurementToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Параметры на сегодня уже введены'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final weight = double.tryParse(_weightController.text);
    final neck = double.tryParse(_neckController.text);
    final waist = double.tryParse(_waistController.text);
    final hip = double.tryParse(_hipController.text);
    
    if (weight == null || weight <= 0) {
      _showError('Введите корректный вес');
      return;
    }
    if (neck == null || neck <= 0) {
      _showError('Введите корректный обхват шеи');
      return;
    }
    if (waist == null || waist <= 0) {
      _showError('Введите корректный обхват талии');
      return;
    }
    if (hip == null || hip <= 0) {
      _showError('Введите корректный обхват бедер');
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final measurement = app_measurement.BodyMeasurement(
          id: const Uuid().v4(),
          userId: session.user.id,
          date: DateTime.now(),
          weight: weight,
          neck: neck,
          waist: waist,
          hip: hip,
        );
        
        await _localDb.measurementDao.insertMeasurement(measurement);
        
        if (_profile != null) {
          final updatedProfile = _profile!.copyWith(
            weight: weight,
            updatedAt: DateTime.now(),
          );
          await _localDb.profileDao.insertProfile(updatedProfile);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Параметры сохранены')),
          );
          await _loadData();
        }
      }
    } catch (e) {
      _showError('Ошибка сохранения: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
  
  double _calculateBodyFat() {
    if (_profile == null) return 0;
    
    final neck = double.tryParse(_neckController.text);
    final waist = double.tryParse(_waistController.text);
    final hip = double.tryParse(_hipController.text);
    
    if (neck == null || waist == null || hip == null) return 0;
    
    final gender = _profile!.gender == 'male' ? Gender.male : Gender.female;
    
    return _calculationService.calculateBodyFatPercentage(
      gender,
      _profile!.height,
      neck,
      waist,
      hip,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final bodyFat = _calculateBodyFat();
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hasMeasurementToday)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[800]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Параметры на сегодня уже введены',
                        style: TextStyle(color: Colors.green[800]),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[800]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Введите параметры тела за сегодня',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            Text(
              'Параметры тела',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Вес (кг)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monitor_weight),
              ),
              enabled: !_hasMeasurementToday,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _neckController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Обхват шеи (см)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
              ),
              enabled: !_hasMeasurementToday,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _waistController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Обхват талии (см)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
              ),
              enabled: !_hasMeasurementToday,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _hipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Обхват бедер (см)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
              ),
              enabled: !_hasMeasurementToday,
            ),
            
            if (bodyFat > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Процент жира:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${bodyFat.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            if (!_hasMeasurementToday)
              CustomButton(
                text: 'Сохранить',
                onPressed: _saveMeasurement,
                isLoading: _isSaving,
              ),
            
            if (_todayMeasurement != null)
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Вчерашние параметры',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildParameterRow('Вес', _todayMeasurement!.weight, 'кг'),
                    _buildParameterRow('Шея', _todayMeasurement!.neck, 'см'),
                    _buildParameterRow('Талия', _todayMeasurement!.waist, 'см'),
                    _buildParameterRow('Бедра', _todayMeasurement!.hip, 'см'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildParameterRow(String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}