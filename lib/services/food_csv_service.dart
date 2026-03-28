import 'package:flutter/services.dart';
import '../models/food.dart';
import 'package:flutter/foundation.dart';

class FoodCsvService {
  Future<List<Food>> loadFoodsFromCsv() async {
    try {
      final String csvString = await rootBundle.loadString('assets/foods.csv');
      final List<String> lines = csvString.split('\n');
      final List<Food> foods = [];
      
      if (lines.isEmpty) return foods;
      
      // Skip header
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        
        final parts = _parseCsvLine(lines[i]);
        if (parts.length >= 5) {
          foods.add(Food(
            id: 'default_${DateTime.now().millisecondsSinceEpoch}_$i',
            name: parts[0].replaceAll('"', '').trim(),
            calories: double.tryParse(parts[1]) ?? 0,
            proteins: double.tryParse(parts[2]) ?? 0,
            fats: double.tryParse(parts[3]) ?? 0,
            carbs: double.tryParse(parts[4]) ?? 0,
            isCustom: false,
            userId: null,
            createdAt: DateTime.now(),
          ));
        }
      }
      
      return foods;
    } catch (e) {
      debugPrint('Error loading CSV: $e');
      return [];
    }
  }
  
  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final RegExp regex = RegExp(r'(?:[^,"]|"(?:\\.|[^"])*")+');
    final matches = regex.allMatches(line);
    
    for (final match in matches) {
      String value = match.group(0)!;
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }
      result.add(value);
    }
    
    return result;
  }
}