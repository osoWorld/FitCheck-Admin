import 'dart:convert';

class Food {
  final String name;
  final String calories;
  final String fats;
  final String proteins;
  final String carbs;
  final String imageUrl;
  final String sodium;
  final String sugar;
  final String cholesterol;
  final String rating;

  // Constructor
  Food({
    required this.name,
    required this.calories,
    required this.fats,
    required this.proteins,
    required this.carbs,
    required this.imageUrl,
    required this.sodium,
    required this.sugar,
    required this.cholesterol,
    required this.rating
  });

  // Factory method to create Food from a Map (e.g., the parsed QR data)
  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      name: map['name'] ?? 'Unknown Food',
      calories: map['calories'] ?? '0',
      fats: map['fats'] ?? '0',
      proteins: map['proteins'] ?? '0',
      carbs: map['carbs'] ?? '0',
      imageUrl: map['imageUrl'] ?? '',
      sodium: map['sodium'] ?? '0',
      sugar: map['sugar'] ?? '0',
      cholesterol: map['cholesterol'] ?? '0',
      rating: map['rating'] ?? 'E',
    );
  }

  // Convert Food object to JSON string
  String toJsonString() {
    Map<String, dynamic> foodData = {
      'name': name,
      'calories': calories,
      'fats': fats,
      'proteins': proteins,
      'carbs': carbs,
      'imageUrl': imageUrl,
      'sodium': sodium,
      'sugar': sugar,
      'cholesterol': cholesterol,
      'rating': rating,
    };

    // Convert the Map to a JSON string
    return json.encode(foodData);
  }
}