import 'package:fittrack/services/local_database/local_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart';
import 'services/supabase_service.dart';
import 'services/database_singleton.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Игнорировать предупреждение о множественных экземплярах базы данных
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  
  // Initialize Supabase
  await SupabaseService().init();
  
  // Initialize local database
  final localDb = DatabaseSingleton.instance;
  
  runApp(MyApp(localDb: localDb));
}

class MyApp extends StatelessWidget {
  final LocalDatabase localDb;
  
  const MyApp({super.key, required this.localDb});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'FitTrack',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          cardTheme: CardThemeData(  // Исправлено: CardThemeData вместо CardTheme
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}