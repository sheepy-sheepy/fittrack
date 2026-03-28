import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart' as app_profile;
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/local_database/local_database.dart';
import '../../services/sync_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  app_profile.UserProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  
  // Profile editing controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _neckController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _hipController = TextEditingController();
  String _gender = 'male';
  String _goal = 'lose';
  String _activityLevel = 'sedentary';
  DateTime _birthDate = DateTime.now();
  String _deficit = '300';
  
  // Password change
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  
  final LocalDatabase _localDb = LocalDatabase();
  final SupabaseService _supabase = SupabaseService();
  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _neckController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _profile = await _localDb.profileDao.getProfile(session.user.id);
        
        if (_profile != null) {
          _nameController.text = _profile!.name;
          _heightController.text = _profile!.height.toString();
          _weightController.text = _profile!.weight.toString();
          _neckController.text = _profile!.neckCircumference.toString();
          _waistController.text = _profile!.waistCircumference.toString();
          _hipController.text = _profile!.hipCircumference.toString();
          _gender = _profile!.gender;
          _goal = _profile!.goal;
          _activityLevel = _profile!.activityLevel;
          _birthDate = _profile!.birthDate;
          _deficit = _profile!.deficit.toString();
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _updateProfile() async {
    if (_profile == null) return;
    
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final neck = double.tryParse(_neckController.text);
    final waist = double.tryParse(_waistController.text);
    final hip = double.tryParse(_hipController.text);
    final deficit = int.tryParse(_deficit) ?? 300;
    
    if (height == null || height <= 0) {
      _showError('Введите корректный рост');
      return;
    }
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
    
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final updatedProfile = _profile!.copyWith(
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
        deficit: deficit,
        updatedAt: DateTime.now(),
      );
      
      await _localDb.profileDao.insertProfile(updatedProfile);
      await _supabase.saveUserProfile(updatedProfile);
      
      if (mounted) {
        setState(() {
          _profile = updatedProfile;
          _isEditing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль обновлен')),
        );
      }
    } catch (e) {
      _showError('Ошибка обновления: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _changePassword() async {
    if (_oldPasswordController.text.isEmpty) {
      _showError('Введите старый пароль');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showError('Новый пароль должен содержать не менее 6 символов');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Пароли не совпадают');
      return;
    }
    
    if (!mounted) return;
    setState(() => _isChangingPassword = true);
    
    try {
      await _authService.updatePassword(
        _oldPasswordController.text,
        _newPasswordController.text,
      );
      
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пароль успешно изменен')),
        );
      }
    } catch (e) {
      _showError('Ошибка смены пароля: $e');
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }
  
  Future<void> _syncData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      await _syncService.syncToCloud();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные синхронизированы')),
        );
      }
    } catch (e) {
      _showError('Ошибка синхронизации: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _loadFromCloud() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      await _syncService.syncFromCloud();
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные загружены из облака')),
        );
      }
    } catch (e) {
      _showError('Ошибка загрузки: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
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
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Профиль',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isEditing)
                          TextButton(
                            onPressed: () => setState(() => _isEditing = true),
                            child: const Text('Изменить'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!_isEditing && _profile != null)
                      Column(
                        children: [
                          _buildInfoRow('Имя', _profile!.name),
                          _buildInfoRow('Рост', '${_profile!.height} см'),
                          _buildInfoRow('Вес', '${_profile!.weight} кг'),
                          _buildInfoRow('Обхват шеи', '${_profile!.neckCircumference} см'),
                          _buildInfoRow('Обхват талии', '${_profile!.waistCircumference} см'),
                          _buildInfoRow('Обхват бедер', '${_profile!.hipCircumference} см'),
                          _buildInfoRow('Пол', _profile!.gender == 'male' ? 'Мужской' : 'Женский'),
                          _buildInfoRow('Цель', _getGoalName(_profile!.goal)),
                          _buildInfoRow('Активность', _getActivityName(_profile!.activityLevel)),
                          _buildInfoRow('Дата рождения', DateFormat('dd.MM.yyyy').format(_profile!.birthDate)),
                          _buildInfoRow('Дефицит', '${_profile!.deficit} ккал'),
                        ],
                      )
                    else
                      Column(
                        children: [
                          CustomTextField(
                            controller: _nameController,
                            label: 'Имя',
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _heightController,
                            label: 'Рост (см)',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _weightController,
                            label: 'Вес (кг)',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _neckController,
                            label: 'Обхват шеи (см)',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _waistController,
                            label: 'Обхват талии (см)',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _hipController,
                            label: 'Обхват бедер (см)',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _gender,
                            decoration: const InputDecoration(
                              labelText: 'Пол',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'male', child: Text('Мужской')),
                              DropdownMenuItem(value: 'female', child: Text('Женский')),
                            ],
                            onChanged: (value) => setState(() => _gender = value!),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _goal,
                            decoration: const InputDecoration(
                              labelText: 'Цель',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'lose', child: Text('Похудеть')),
                              DropdownMenuItem(value: 'maintain', child: Text('Поддерживать вес')),
                              DropdownMenuItem(value: 'gain', child: Text('Набрать массу')),
                            ],
                            onChanged: (value) => setState(() => _goal = value!),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _activityLevel,
                            decoration: const InputDecoration(
                              labelText: 'Уровень активности',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'sedentary', child: Text('Сидячий образ жизни')),
                              DropdownMenuItem(value: 'light', child: Text('Тренировки 1-3 раза в неделю')),
                              DropdownMenuItem(value: 'moderate', child: Text('Тренировки 3-5 раз в неделю')),
                              DropdownMenuItem(value: 'active', child: Text('Тренировки 6-7 раз в неделю')),
                              DropdownMenuItem(value: 'very_active', child: Text('Профессиональный спорт')),
                            ],
                            onChanged: (value) => setState(() => _activityLevel = value!),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Дата рождения'),
                            subtitle: Text(DateFormat('dd.MM.yyyy').format(_birthDate)),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _birthDate,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null && mounted) {
                                setState(() => _birthDate = date);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: TextEditingController(text: _deficit),
                            label: 'Дефицит калорий',
                            keyboardType: TextInputType.number,
                            onChanged: (value) => _deficit = value,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => setState(() => _isEditing = false),
                                  child: const Text('Отмена'),
                                ),
                              ),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _updateProfile,
                                  child: const Text('Сохранить'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Синхронизация',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _syncData,
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Синхронизировать'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loadFromCloud,
                            icon: const Icon(Icons.cloud_download),
                            label: const Text('Загрузить'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Смена пароля',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _oldPasswordController,
                      label: 'Старый пароль',
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _newPasswordController,
                      label: 'Новый пароль',
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Подтвердите новый пароль',
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Сохранить пароль',
                      onPressed: _changePassword,
                      isLoading: _isChangingPassword,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.exit_to_app, color: Colors.red),
              label: const Text(
                'Выход из аккаунта',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  String _getGoalName(String goal) {
    switch (goal) {
      case 'lose':
        return 'Похудеть';
      case 'maintain':
        return 'Поддерживать вес';
      case 'gain':
        return 'Набрать массу';
      default:
        return goal;
    }
  }
  
  String _getActivityName(String activity) {
    switch (activity) {
      case 'sedentary':
        return 'Сидячий образ жизни';
      case 'light':
        return 'Тренировки 1-3 раза в неделю';
      case 'moderate':
        return 'Тренировки 3-5 раз в неделю';
      case 'active':
        return 'Тренировки 6-7 раз в неделю';
      case 'very_active':
        return 'Профессиональный спорт';
      default:
        return activity;
    }
  }
}