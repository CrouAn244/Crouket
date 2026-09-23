import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category_model.dart';
import '../models/friend_model.dart';
import '../models/transaction_model.dart';

enum TimeFrame { week, month, year }

class DailyExpensePoint {
  final String label; // e.g. "T2", "T3" or day of month
  final double amount;
  final DateTime date;

  const DailyExpensePoint({
    required this.label,
    required this.amount,
    required this.date,
  });
}

class ExpenseService extends ChangeNotifier {
  static final ExpenseService _instance = ExpenseService._internal();
  factory ExpenseService() => _instance;

  ExpenseService._internal() {
    _initSeedData();
  }

  final String currentUserId = 'me';
  final String currentUserName = 'Tôi (Crouket)';
  final String currentUserAvatar =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';

  final List<CategoryModel> _categories = List.from(
    CategoryModel.defaultCategories,
  );
  final List<FriendModel> _friends = List.from(FriendModel.defaultFriends);
  final List<TransactionModel> _transactions = [];

  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<FriendModel> get friends => List.unmodifiable(_friends);
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  CategoryModel getCategory(String id) {
    return _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => _categories.last,
    );
  }

  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(amount).trim();
  }

  void addTransaction({
    String? photoPath,
    required String caption,
    required double amount,
    required TransactionType type,
    required String categoryId,
    bool isPrivate = false,
  }) {
    final newTx = TransactionModel(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      photoPath: photoPath,
      caption: caption,
      amount: amount,
      type: type,
      categoryId: categoryId,
      createdAt: DateTime.now(),
      userId: currentUserId,
      userName: currentUserName,
      userAvatar: currentUserAvatar,
      isPrivate: isPrivate,
      reactions: {},
      userReactedEmojis: {},
    );

    _transactions.insert(0, newTx);
    notifyListeners();
  }

  void toggleReaction(String transactionId, String emoji) {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index == -1) return;

    final tx = _transactions[index];
    final updatedReactions = Map<String, int>.from(tx.reactions);
    final updatedUserReacted = Set<String>.from(tx.userReactedEmojis);

    if (updatedUserReacted.contains(emoji)) {
      // Bỏ reaction
      updatedUserReacted.remove(emoji);
      final count = (updatedReactions[emoji] ?? 1) - 1;
      if (count <= 0) {
        updatedReactions.remove(emoji);
      } else {
        updatedReactions[emoji] = count;
      }
    } else {
      // Thêm reaction
      updatedUserReacted.add(emoji);
      updatedReactions[emoji] = (updatedReactions[emoji] ?? 0) + 1;
    }

    _transactions[index] = tx.copyWith(
      reactions: updatedReactions,
      userReactedEmojis: updatedUserReacted,
    );
    notifyListeners();
  }

  void addCategory({
    required String name,
    required String icon,
    required Color color,
    double? budgetLimit,
  }) {
    final newCat = CategoryModel(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      icon: icon,
      color: color,
      budgetLimit: budgetLimit,
    );
    _categories.add(newCat);
    notifyListeners();
  }

  void addFriend({required String username, required String displayName}) {
    final newFriend = FriendModel(
      id: 'friend_${DateTime.now().millisecondsSinceEpoch}',
      username: username.toLowerCase().replaceAll('@', ''),
      displayName: displayName,
      avatarUrl:
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    );
    _friends.add(newFriend);
    notifyListeners();
  }

  // --- Statistics Calculations ---
  List<TransactionModel> getFilteredTransactions(
    TimeFrame timeFrame, {
    bool onlyMine = true,
  }) {
    final now = DateTime.now();
    DateTime cutoff;

    switch (timeFrame) {
      case TimeFrame.week:
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case TimeFrame.month:
        cutoff = DateTime(now.year, now.month, 1);
        break;
      case TimeFrame.year:
        cutoff = DateTime(now.year, 1, 1);
        break;
    }

    return _transactions.where((t) {
      if (onlyMine && t.userId != currentUserId) return false;
      return t.createdAt.isAfter(cutoff);
    }).toList();
  }

  double getTotalExpense(TimeFrame timeFrame) {
    final list = getFilteredTransactions(timeFrame, onlyMine: true);
    return list
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalIncome(TimeFrame timeFrame) {
    final list = getFilteredTransactions(timeFrame, onlyMine: true);
    return list
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<CategoryModel, double> getCategoryBreakdown(TimeFrame timeFrame) {
    final list = getFilteredTransactions(
      timeFrame,
      onlyMine: true,
    ).where((t) => t.type == TransactionType.expense).toList();

    final Map<CategoryModel, double> result = {};
    for (final t in list) {
      final cat = getCategory(t.categoryId);
      result[cat] = (result[cat] ?? 0.0) + t.amount;
    }
    return result;
  }

  List<DailyExpensePoint> getWeeklyTrend() {
    final now = DateTime.now();
    final List<DailyExpensePoint> points = [];
    final weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayTxs = _transactions.where((t) {
        return t.userId == currentUserId &&
            t.type == TransactionType.expense &&
            t.createdAt.year == day.year &&
            t.createdAt.month == day.month &&
            t.createdAt.day == day.day;
      });

      final total = dayTxs.fold(0.0, (sum, t) => sum + t.amount);
      final label = weekDays[day.weekday - 1];
      points.add(DailyExpensePoint(label: label, amount: total, date: day));
    }
    return points;
  }

  void _initSeedData() {
    final now = DateTime.now();

    _transactions.addAll([
      TransactionModel(
        id: 'seed_1',
        photoPath: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600',
        caption: 'Cold brew cam sả sáng nạp năng lượng làm việc ☕✨',
        amount: 65000,
        type: TransactionType.expense,
        categoryId: 'cat_coffee',
        createdAt: now.subtract(const Duration(minutes: 35)),
        userId: 'friend_1',
        userName: 'Hoàng Nam',
        userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        reactions: {'☕': 4, '💸': 2, '👏': 3},
      ),
      TransactionModel(
        id: 'seed_2',
        photoPath: 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=600',
        caption: 'Chiếc áo cardigan ưng ý săn sale được giảm 40% 🛍️👗',
        amount: 380000,
        type: TransactionType.expense,
        categoryId: 'cat_shopping',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 15)),
        userId: 'friend_2',
        userName: 'Lan Anh',
        userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        reactions: {'🔥': 5, '😍': 6, '💸': 3},
      ),
      TransactionModel(
        id: 'seed_3',
        photoPath: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600',
        caption: 'Phở bò tái lăn nóng hổi trưa nay ấm bụng cực 🍜',
        amount: 55000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        createdAt: now.subtract(const Duration(hours: 4)),
        userId: 'me',
        userName: currentUserName,
        userAvatar: currentUserAvatar,
        reactions: {'🤤': 7, '👏': 4},
      ),
      TransactionModel(
        id: 'seed_4',
        photoPath:
            'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=600',
        caption: 'Tậu thêm tay cầm PS5 để cuối tuần cày game cùng ae 🎮🕹️',
        amount: 1450000,
        type: TransactionType.expense,
        categoryId: 'cat_entertainment',
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        userId: 'friend_3',
        userName: 'Duy Minh',
        userAvatar: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
        reactions: {'😱': 8, '🔥': 4, '💸': 9},
      ),
      TransactionModel(
        id: 'seed_5',
        photoPath: 'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=600',
        caption: 'Ting ting! Lương tháng này đã về ví, quẩy thôi 💵🎉',
        amount: 15000000,
        type: TransactionType.income,
        categoryId: 'cat_income',
        createdAt: now.subtract(const Duration(days: 2)),
        userId: 'friend_4',
        userName: 'Khánh Vy',
        userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        reactions: {'💸': 12, '🔥': 9, '👏': 15},
      ),
      TransactionModel(
        id: 'seed_6',
        photoPath:
            'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=600',
        caption: 'Đổ xăng đầy bình vi vu cuối tuần 🛵⛽',
        amount: 90000,
        type: TransactionType.expense,
        categoryId: 'cat_transport',
        createdAt: now.subtract(const Duration(days: 3)),
        userId: 'me',
        userName: currentUserName,
        userAvatar: currentUserAvatar,
        reactions: {'👏': 3},
      ),
    ]);
  }
}
