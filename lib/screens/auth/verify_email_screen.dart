import 'package:fittrack/models/registration_status.dart';
import 'package:fittrack/services/local_database/local_database.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../services/database_singleton.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  
  const VerifyEmailScreen({super.key, required this.email});
  
  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final TextEditingController _pinController = TextEditingController();
  final SupabaseService _supabase = SupabaseService();
  final LocalDatabase _localDb = DatabaseSingleton.instance;
  bool _isLoading = false;
  String? _error;
  
  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
  
  Future<void> _verifyCode() async {
    if (_pinController.text.length != 6) {
      setState(() => _error = 'Введите 6-значный код');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Верифицируем email
      await _supabase.client.auth.verifyOTP(
        email: widget.email,
        token: _pinController.text,
        type: OtpType.email,
      );
      
      // Получаем текущую сессию
      final session = _supabase.client.auth.currentSession;
      if (session != null) {
        final userId = session.user.id;
        
        // Обновляем статус в Supabase
        await _supabase.updateUserStatus(
          userId,
          RegistrationStatus.onboardingNotCompleted,
        );
        
        // Обновляем статус в локальной БД
        await _localDb.userDao.updateUserStatus(
          userId,
          RegistrationStatus.onboardingNotCompleted,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email подтвержден! Теперь войдите в аккаунт.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
          
          // Небольшая задержка для показа уведомления
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      } else {
        setState(() => _error = 'Ошибка: сессия не найдена');
      }
    } catch (e) {
      debugPrint('Verification error: $e');
      if (e.toString().contains('otp_expired')) {
        setState(() => _error = 'Код истек. Запросите новый код.');
      } else if (e.toString().contains('invalid')) {
        setState(() => _error = 'Неверный код подтверждения.');
      } else {
        setState(() => _error = 'Ошибка подтверждения. Попробуйте еще раз.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    
    try {
      await _supabase.client.auth.resend(
        email: widget.email,
        type: OtpType.signup,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Код подтверждения отправлен повторно на почту'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Resend error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при отправке кода. Проверьте подключение к интернету.'),
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение email'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.email,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              const Text(
                'Подтверждение email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Мы отправили 6-значный код на ${widget.email}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
              Pinput(
                controller: _pinController,
                length: 6,
                onCompleted: (pin) => _verifyCode(),
                pinAnimationType: PinAnimationType.fade,
                autofocus: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 30),
              CustomButton(
                text: 'Подтвердить',
                onPressed: _verifyCode,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resendCode,
                child: const Text('Отправить код повторно'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}