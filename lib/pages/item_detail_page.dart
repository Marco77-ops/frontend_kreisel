import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/widgets/rent_item_dialog.dart';

class ItemDetailPage extends StatelessWidget {
  final Item item;

  const ItemDetailPage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Icon(
                      CupertinoIcons.back,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Item details
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Availability badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: item.available 
                            ? Color(0xFF32D74B) 
                            : Color(0xFFFF453A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.available ? 'Verfügbar' : 'Ausgeliehen',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Brand
                    if (item.brand != null) ...[
                      Text(
                        'Marke',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        item.brand!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Size
                    if (item.size != null) ...[
                      Text(
                        'Größe',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        item.size!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Description
                    if (item.description != null) ...[
                      Text(
                        'Beschreibung',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        item.description!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Categories
                    Text(
                      'Kategorien',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDetailChip(item.gender),
                        _buildDetailChip(item.category),
                        _buildDetailChip(item.subcategory),
                        if (item.zustand != null) 
                          _buildDetailChip(item.zustand!),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Rent button
            if (item.available)
              Padding(
                padding: EdgeInsets.all(16),
                child: CupertinoButton(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  color: Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => RentItemDialog(
                        item: item,
                        onRented: () => Navigator.pop(context),
                      ),
                    );
                  },
                  child: Text(
                    'Ausleihen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toLowerCase(),
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }
}