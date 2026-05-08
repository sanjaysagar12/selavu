import 'package:flutter/material.dart';

class UIUtil {
  static Color hexToColor(String? hexString, {Color defaultColor = Colors.grey}) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }

  static IconData getIconData(String? iconName, {IconData defaultIcon = Icons.category}) {
    if (iconName == null || iconName.isEmpty) return defaultIcon;
    
    switch (iconName.toLowerCase()) {
      case 'restaurant': return Icons.restaurant;
      case 'directions_car': return Icons.directions_car;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'receipt_long': return Icons.receipt_long;
      case 'home': return Icons.home;
      case 'movie': return Icons.movie;
      case 'local_hospital': return Icons.local_hospital;
      case 'school': return Icons.school;
      case 'flight_takeoff': return Icons.flight_takeoff;
      case 'more_horiz': return Icons.more_horiz;
      case 'work': return Icons.work;
      case 'design_services': return Icons.design_services;
      case 'store': return Icons.store;
      case 'trending_up': return Icons.trending_up;
      case 'payments': return Icons.payments;
      case 'qr_code': return Icons.qr_code;
      case 'credit_card': return Icons.credit_card;
      case 'account_balance': return Icons.account_balance;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'swap_horiz': return Icons.swap_horiz;
      case 'request_page': return Icons.request_page;
      case 'savings': return Icons.savings;
      default: return defaultIcon;
    }
  }
}
