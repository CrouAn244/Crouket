import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon; // Emoji string (e.g. '☕', '🍔') or icon identifier
  final Color color;
  final double? budgetLimit; // Hạn mức ngân sách tối đa/tháng (nếu có)

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budgetLimit,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    Color? color,
    double? budgetLimit,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      budgetLimit: budgetLimit ?? this.budgetLimit,
    );
  }

  // Danh mục mặc định của Crouket
  static List<CategoryModel> defaultCategories = [
    const CategoryModel(
      id: 'cat_food',
      name: 'Ăn uống',
      icon: '🍔',
      color: Color(0xFFFF6B6B),
      budgetLimit: 3500000,
    ),
    const CategoryModel(
      id: 'cat_coffee',
      name: 'Cà phê',
      icon: '☕',
      color: Color(0xFFD97706),
      budgetLimit: 800000,
    ),
    const CategoryModel(
      id: 'cat_shopping',
      name: 'Mua sắm',
      icon: '🛍️',
      color: Color(0xFF8B5CF6),
      budgetLimit: 2000000,
    ),
    const CategoryModel(
      id: 'cat_transport',
      name: 'Di chuyển',
      icon: '🛵',
      color: Color(0xFF3B82F6),
      budgetLimit: 600000,
    ),
    const CategoryModel(
      id: 'cat_entertainment',
      name: 'Giải trí',
      icon: '🎮',
      color: Color(0xFFEC4899),
      budgetLimit: 1000000,
    ),
    const CategoryModel(
      id: 'cat_bills',
      name: 'Hoá đơn',
      icon: '🧾',
      color: Color(0xFF64748B),
      budgetLimit: 1500000,
    ),
    const CategoryModel(
      id: 'cat_income',
      name: 'Lương & Thưởng',
      icon: '💵',
      color: Color(0xFF10B981),
    ),
    const CategoryModel(
      id: 'cat_other',
      name: 'Khác',
      icon: '📦',
      color: Color(0xFF78716C),
    ),
  ];
}
