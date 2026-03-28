import 'package:flutter/material.dart';

class NutritionCard extends StatelessWidget {
  final String title;
  final String norm;
  final String remaining;
  final Color? color;
  
  const NutritionCard({
    super.key,
    required this.title,
    required this.norm,
    required this.remaining,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final remainingColor = remaining.startsWith('-') 
        ? Colors.red 
        : Colors.green;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            norm,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).primaryColor,
            ),
          ),
          Text(
            remaining,
            style: TextStyle(
              fontSize: 10,
              color: remainingColor,
            ),
          ),
        ],
      ),
    );
  }
}