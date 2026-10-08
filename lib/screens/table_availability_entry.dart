import 'package:flutter/material.dart';
import 'table_availability_screen.dart';

/// Call this to open the table availability flow.
/// Example: Navigator.push(context, materialPageRoute(builder: (_) => TableAvailabilityEntry(restaurantId: 'rest_001')));
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