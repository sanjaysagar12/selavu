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
      case 'shopping_cart': return Icons.shopping_cart;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'receipt_long': return Icons.receipt_long;
      case 'home': return Icons.home;
      case 'local_movies': return Icons.local_movies;
      case 'movie': return Icons.movie;
      case 'local_hospital': return Icons.local_hospital;
      case 'medical_services': return Icons.medical_services;
      case 'school': return Icons.school;
      case 'flight_takeoff': return Icons.flight_takeoff;
      case 'flight': return Icons.flight;
      case 'fitness_center': return Icons.fitness_center;
      case 'build': return Icons.build;
      case 'electric_bolt': return Icons.electric_bolt;
      case 'water_drop': return Icons.water_drop;
      case 'pets': return Icons.pets;
      case 'local_shipping': return Icons.local_shipping;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'work': return Icons.work;
      case 'design_services': return Icons.design_services;
      case 'store': return Icons.store;
      case 'trending_up': return Icons.trending_up;
      case 'payments': return Icons.payments;
      case 'qr_code': return Icons.qr_code;
      case 'credit_card': return Icons.credit_card;
      case 'account_balance': return Icons.account_balance;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'smartphone': return Icons.smartphone;
      case 'currency_rupee': return Icons.currency_rupee;
      case 'person': return Icons.person;
      case 'business': return Icons.business;
      case 'star': return Icons.star;
      case 'swap_horiz': return Icons.swap_horiz;
      case 'request_page': return Icons.request_page;
      case 'savings': return Icons.savings;
      case 'more_horiz': return Icons.more_horiz;
      case 'category': return Icons.category;
      default: return defaultIcon;
    }
  }
}
