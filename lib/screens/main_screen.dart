import 'package:flutter/material.dart';
import 'food_diary/food_diary_screen.dart';
import 'body_parameters/body_parameters_screen.dart';
import 'recipes/recipes_screen.dart';
import 'products/products_screen.dart';
import 'photos/add_photos_screen.dart';
import 'analytics/analytics_screen.dart';
import 'settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = const [
    FoodDiaryScreen(),
    BodyParametersScreen(),
    RecipesScreen(),
    ProductsScreen(),
    AddPhotosScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];
  
  final List<String> _titles = [
    'Дневник питания',
    'Параметры тела',
    'Мои рецепты',
    'Мои продукты',
    'Фото',
    'Аналитика',
    'Настройки',
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant), label: 'Дневник'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Параметры'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Рецепты'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Продукты'),
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Фото'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Аналитика'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}