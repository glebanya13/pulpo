import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

IconData lucideByKey(String key) {
  switch (key) {
    case 'utensils':
      return LucideIcons.utensils;
    case 'car':
      return LucideIcons.car;
    case 'home':
      return LucideIcons.home;
    case 'heart-pulse':
      return LucideIcons.heart;
    case 'clapperboard':
      return LucideIcons.film;
    case 'shirt':
      return LucideIcons.shirt;
    case 'wifi':
      return LucideIcons.wifi;
    case 'graduation-cap':
      return LucideIcons.graduationCap;
    case 'gift':
      return LucideIcons.gift;
    case 'sparkles':
      return LucideIcons.sparkles;
    case 'briefcase':
      return LucideIcons.briefcase;
    case 'laptop':
      return LucideIcons.laptop;
    case 'trending-up':
      return LucideIcons.trendingUp;
    case 'wallet':
      return LucideIcons.wallet;
    case 'credit-card':
      return LucideIcons.creditCard;
    case 'coins':
      return LucideIcons.coins;
    case 'piggy-bank':
      return LucideIcons.piggyBank;
    case 'target':
      return LucideIcons.target;
    case 'plane':
      return LucideIcons.plane;
    case 'shopping-bag':
      return LucideIcons.shoppingBag;
    default:
      return LucideIcons.circle;
  }
}
