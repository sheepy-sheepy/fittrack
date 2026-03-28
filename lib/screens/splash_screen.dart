import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_database/local_database.dart';
import '../models/registration_status.dart';
import 'auth/login_screen.dart';
import 'main_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'auth/verify_email_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    final localDb = LocalDatabase();
    final user = await localDb.userDao.getUser(session.user.id);

    debugPrint('SplashScreen - User status: ${user?.status}');
    debugPrint('SplashScreen - User status index: ${user?.status.toInt()}');

    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    if (!mounted) return;

    switch (user.status) {
      case RegistrationStatus.emailNotVerified:
        debugPrint('SplashScreen - Redirecting to VerifyEmailScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyEmailScreen(email: user.email),
          ),
        );
        break;
      case RegistrationStatus.onboardingNotCompleted:
        debugPrint('SplashScreen - Redirecting to OnboardingScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingScreen(userId: user.id),
          ),
        );
        break;
      case RegistrationStatus.fullyRegistered:
        debugPrint('SplashScreen - Redirecting to MainScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'FitTrack',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
