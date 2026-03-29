import 'dart:math';

import 'package:fittrack/models/registration_status.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_profile.dart' as app_profile;
import '../../models/body_measurement.dart' as app_measurement;
import '../../services/supabase_service.dart';
import '../../services/local_database/local_database.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/validators.dart';
import '../main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String userId;
  
  const OnboardingScreen({super.key, required this.userId});
  
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _neckController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  String _gender = 'male';
  String _goal = 'lose';
  String _activityLevel = 'sedentary';
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 365 * 25));
  
  final SupabaseService _supabase = SupabaseService();
  final LocalDatabase _localDb = LocalDatabase();
  bool _isLoading = false;
  String? _error;
  
  double? _bodyFatPercentage;
  
  // Функция для форматирования даты без использования DateFormat
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
  
  void _calculateBodyFat() {
    try {
      final height = double.tryParse(_heightController.text);
      final neck = double.tryParse(_neckController.text);
      final waist = double.tryParse(_waistController.text);
      final hip = double.tryParse(_hipController.text);
      
      if (height != null && neck != null && waist != null && hip != null && height > 0 && neck > 0 && waist > 0 && hip > 0) {
        // Проверяем, что waist > neck для мужчин
        if (_gender == 'male' && waist <= neck) {
          setState(() {
            _bodyFatPercentage = null;
          });
          return;
        }
        
        // Проверяем, что waist + hip > neck для женщин
        if (_gender == 'female' && waist + hip <= neck) {
          setState(() {
            _bodyFatPercentage = null;
          });
          return;
        }
        
        double bodyFat;
        
        if (_gender == 'male') {
          // Формула для мужчин: 86.010 * log10(waist - neck) - 70.041 * log10(height) + 36.76
          final logWaistNeck = log10(waist - neck);
          final logHeight = log10(height);
          bodyFat = 86.010 * logWaistNeck - 70.041 * logHeight + 36.76;
        } else {
          // Формула для женщин: 163.205 * log10(waist + hip - neck) - 97.684 * log10(height) - 78.387
          final logWaistHipNeck = log10(waist + hip - neck);
          final logHeight = log10(height);
          bodyFat = 163.205 * logWaistHipNeck - 97.684 * logHeight - 78.387;
        }
        
        // Ограничиваем значение от 0 до 100
        bodyFat = bodyFat.clamp(0.0, 100.0);
        
        setState(() {
          _bodyFatPercentage = bodyFat;
        });
      } else {
        setState(() {
          _bodyFatPercentage = null;
        });
      }
    } catch (e) {
      debugPrint('Error calculating body fat: $e');
      setState(() {
        _bodyFatPercentage = null;
      });
    }
  }
  
  double log10(double value) {
    return log(value) / ln10;
  }
  
  static const double ln10 = 2.302585092994046;
  
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      _error = null;
      
      try {
        final height = double.parse(_heightController.text);
        final weight = double.parse(_weightController.text);
        final neck = double.parse(_neckController.text);
        final waist = double.parse(_waistController.text);
        final hip = double.parse(_hipController.text);
        
        // Проверяем, существует ли пользователь в Supabase
        try {
          final existingUser = await _supabase.client
              .from('users')
              .select()
              .eq('id', widget.userId)
              .maybeSingle();
          
          if (existingUser == null) {
            // Создаем пользователя в Supabase
            await _supabase.client.from('users').insert({
              'id': widget.userId,
              'email': '', // Email будет обновлен позже
              'status': RegistrationStatus.onboardingNotCompleted.toInt(),
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          debugPrint('Error checking/creating user: $e');
          // Если ошибка, продолжаем - возможно пользователь уже существует
        }
        
        final profile = app_profile.UserProfile(
          userId: widget.userId,
          name: _nameController.text,
          height: height,
          weight: weight,
          neckCircumference: neck,
          waistCircumference: waist,
          hipCircumference: hip,
          gender: _gender,
          goal: _goal,
          activityLevel: _activityLevel,
          birthDate: _birthDate,
          deficit: 300,
          updatedAt: DateTime.now(),
        );
        
        // Сохраняем профиль в Supabase
        try {
          await _supabase.saveUserProfile(profile);
        } catch (e) {
          debugPrint('Error saving profile to Supabase: $e');
          rethrow;
        }
        
        // Сохраняем в локальную базу данных
        await _localDb.profileDao.insertProfile(profile);
        
        // Обновляем статус пользователя в Supabase
        await _supabase.updateUserStatus(
          widget.userId,
          RegistrationStatus.fullyRegistered,
        );
        
        // Обновляем статус в локальной БД
        await _localDb.userDao.updateUserStatus(
          widget.userId,
          RegistrationStatus.fullyRegistered,
        );
        
        // Сохраняем начальные параметры тела в body_measurements
        final measurement = app_measurement.BodyMeasurement(
          id: const Uuid().v4(),
          userId: widget.userId,
          date: DateTime.now(),
          weight: weight,
          neck: neck,
          waist: waist,
          hip: hip,
        );
        
        // Сохраняем в локальную БД
        await _localDb.measurementDao.insertMeasurement(measurement);
        
        // Сохраняем в Supabase body_measurements
        try {
          await _supabase.saveBodyMeasurement(measurement);
        } catch (e) {
          debugPrint('Error saving body measurement to Supabase: $e');
          // Не прерываем выполнение, если не сохранилось в Supabase
        }
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } catch (e) {
        debugPrint('Error saving profile: $e');
        if (mounted) {
          _error = e.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка сохранения: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заполните профиль'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      label: 'Имя',
                      validator: Validators.required,
                      prefixIcon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _heightController,
                            label: 'Рост (см)',
                            keyboardType: TextInputType.number,
                            validator: Validators.positiveNumber,
                            onChanged: (_) => _calculateBodyFat(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _weightController,
                            label: 'Вес (кг)',
                            keyboardType: TextInputType.number,
                            validator: Validators.positiveNumber,
                            onChanged: (_) => _calculateBodyFat(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _neckController,
                            label: 'Обхват шеи (см)',
                            keyboardType: TextInputType.number,
                            validator: Validators.positiveNumber,
                            onChanged: (_) => _calculateBodyFat(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _waistController,
                            label: 'Обхват талии (см)',
                            keyboardType: TextInputType.number,
                            validator: Validators.positiveNumber,
                            onChanged: (_) => _calculateBodyFat(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: _hipController,
                      label: 'Обхват бедер (см)',
                      keyboardType: TextInputType.number,
                      validator: Validators.positiveNumber,
                      onChanged: (_) => _calculateBodyFat(),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_bodyFatPercentage != null && _bodyFatPercentage! > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
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
                              '${_bodyFatPercentage!.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Пол',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Мужской')),
                        DropdownMenuItem(value: 'female', child: Text('Женский')),
                      ],
                      onChanged: (value) {
                        setState(() => _gender = value!);
                        _calculateBodyFat();
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      initialValue: _goal,
                      decoration: const InputDecoration(
                        labelText: 'Цель',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'lose', child: Text('Похудеть')),
                        DropdownMenuItem(value: 'maintain', child: Text('Поддерживать вес')),
                        DropdownMenuItem(value: 'gain', child: Text('Набрать массу')),
                      ],
                      onChanged: (value) => setState(() => _goal = value!),
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        initialValue: _activityLevel,
                        decoration: const InputDecoration(
                          labelText: 'Уровень активности',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_run),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'sedentary', child: Text('Сидячий образ жизни')),
                          DropdownMenuItem(value: 'light', child: Text('Тренировки 1-3 раза в неделю')),
                          DropdownMenuItem(value: 'moderate', child: Text('Тренировки 3-5 раз в неделю')),
                          DropdownMenuItem(value: 'active', child: Text('Тренировки 6-7 раз в неделю')),
                          DropdownMenuItem(value: 'very_active', child: Text('Профессиональный спорт')),
                        ],
                        onChanged: (value) => setState(() => _activityLevel = value!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cake),
                      title: const Text('Дата рождения'),
                      subtitle: Text(_formatDate(_birthDate)), // Используем нашу функцию
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _birthDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null && mounted) {
                          setState(() => _birthDate = date);
                          _calculateBodyFat();
                        }
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    CustomButton(
                      text: 'Сохранить',
                      onPressed: _saveProfile,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}