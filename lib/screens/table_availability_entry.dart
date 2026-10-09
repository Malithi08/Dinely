import 'package:flutter/material.dart';
import 'table_availability_screen.dart';

/// Open the table availability flow.
class TableAvailabilityEntry extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;

  const TableAvailabilityEntry({
    super.key,
    required this.restaurantId,
    this.restaurantName = 'Dinely Colombo',
  });

  @override
  Widget build(BuildContext context) {
    return TableAvailabilityScreen(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
    );
  }
}