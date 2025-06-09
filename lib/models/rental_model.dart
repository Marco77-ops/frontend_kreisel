import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/models/user_model.dart';

class Rental {
  final int id;
  final Item item; // Geändert von itemId zu Item Objekt
  final User user; // Geändert von userId zu User Objekt
  final DateTime rentalDate;
  final DateTime endDate;
  final DateTime? returnDate;
  final bool extended;
  final String status;

  Rental({
    required this.id,
    required this.item,
    required this.user,
    required this.rentalDate,
    required this.endDate,
    this.returnDate,
    this.extended = false,
    String? status,
  }) : status = status ?? _calculateStatus(endDate, returnDate);

  static String _calculateStatus(DateTime endDate, DateTime? returnDate) {
    if (returnDate != null) return 'RETURNED';
    return endDate.isBefore(DateTime.now()) ? 'OVERDUE' : 'ACTIVE';
  }

  factory Rental.fromJson(Map<String, dynamic> json) {
    print('DEBUG: Parsing rental JSON: $json');

    try {
      // Handle both direct IDs and nested objects
      final user =
          json['user'] != null
              ? User.fromJson(json['user'])
              : User(
                userId: json['userId'] ?? 0,
                email: json['userEmail'] ?? '',
                fullName: json['userFullName'] ?? '',
                role: json['userRole'] ?? 'USER',
              );
      final item =
          json['item'] != null
              ? Item.fromJson(json['item'])
              : Item(
                id: json['itemId'] ?? 0,
                name: json['itemName'] ?? '',
                available: true,
                location: json['location'] ?? '',
                gender: json['gender'] ?? '',
                category: json['category'] ?? '',
                subcategory: json['subcategory'] ?? '',
                zustand: json['zustand'] ?? 'GOOD', // Add this line
              );

      return Rental(
        id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        item: item,
        user: user,
        rentalDate: DateTime.parse(json['rentalDate']),
        endDate: DateTime.parse(json['endDate']),
        returnDate:
            json['returnDate'] != null
                ? DateTime.parse(json['returnDate'])
                : null,
        extended: json['extended'] ?? false,
        status: json['status'] ?? 'ACTIVE',
      );
    } catch (e) {
      print('DEBUG: Error parsing rental: $e');
      print('DEBUG: Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'item': item.toJson(), // Konvertiere Item zu JSON
    'user': user.toJson(), // Konvertiere User zu JSON
    'rentalDate': rentalDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    if (returnDate != null) 'returnDate': returnDate!.toIso8601String(),
    'extended': extended,
    'status': status,
  };

  // Helper Getter für Kompatibilität
  int get itemId => item.id;
  int get userId => user.id;
}
