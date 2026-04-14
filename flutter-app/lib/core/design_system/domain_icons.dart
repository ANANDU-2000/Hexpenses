import 'package:flutter/material.dart';

/// Maps curated category `systemKey` (API) to a consistent icon.
IconData domainIconForSystemKey(String? systemKey) {
  switch (systemKey) {
    case 'daily_expenses':
      return Icons.shopping_bag_outlined;
    case 'household':
      return Icons.home_outlined;
    case 'vehicle':
      return Icons.directions_car_outlined;
    case 'insurance':
      return Icons.health_and_safety_outlined;
    case 'financial':
      return Icons.account_balance_outlined;
    case 'donations':
      return Icons.volunteer_activism_outlined;
    case 'business':
      return Icons.work_outline_rounded;
    case 'custom':
      return Icons.category_outlined;
    default:
      return Icons.payments_outlined;
  }
}
