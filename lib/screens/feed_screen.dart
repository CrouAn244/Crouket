import 'dart:io';

import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/expense_service.dart';

class FeedScreen extends StatefulWidget {
  final VoidCallback? onOpenSnap;

  const FeedScreen({super.key, this.onOpenSnap});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _expenseService = ExpenseService();
  int _activeFilterIndex = 0; // 0: Tất cả, 1: Bạn bè, 2: Của tôi

  @override
  void initState() {
    super.initState();
    _expenseService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _expenseService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  List<TransactionModel> _getFilteredTransactions() {
    final all = _expenseService.transactions;
    if (_activeFilterIndex == 1) {
      return all
          .where((t) => t.userId != _expenseService.currentUserId)
          .toList();
    } else if (_activeFilterIndex == 2) {
      return all
          .where((t) => t.userId == _expenseService.currentUserId)
          .toList();
    }
    return all;
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes.clamp(1, 59)} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${diff.inDays} ngày trước';
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _getFilteredTransactions();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F11),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'C R O U K E T   F E E D',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        actions: [
          if (widget.onOpenSnap != null)
            IconButton(
              icon: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFFFFD233),
              ),
              onPressed: widget.onOpenSnap,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (Tất cả / Bạn bè / Của tôi)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E22),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildFilterTab(
                    0,
                    'Tất cả (${_expenseService.transactions.length})',
                  ),
                  _buildFilterTab(1, 'Bạn bè'),
                  _buildFilterTab(2, 'Của tôi'),
                ],
              ),
            ),
          ),

          // Stream list
          Expanded(
            child: transactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      return _buildFeedCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(int index, String title) {
    final isSelected = _activeFilterIndex == index;

    return Expanded(
      child: GestureDetector(
        key: ValueKey('filterTab_$index'),
        onTap: () => setState(() => _activeFilterIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2C2C32) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedCard(TransactionModel item) {
    final category = _expenseService.getCategory(item.categoryId);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF19191D),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Friend Avatar + Name + Time
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A2A30),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    item.userAvatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        item.userName.isNotEmpty ? item.userName[0] : 'C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatTimeAgo(item.createdAt),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge category
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: category.color.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category.icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        category.name,
                        style: TextStyle(
                          color: category.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Locket Photo with Rounded Corners & Amount Badge Overlay
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCardImage(item.photoPath),

                    // Top-Left Floating Expense Badge
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: item.type == TransactionType.expense
                                ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                                : const Color(0xFF10B981)
                                      .withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.type == TransactionType.expense
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 14,
                              color: item.type == TransactionType.expense
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.type == TransactionType.expense ? '-' : '+'}${ExpenseService.formatCurrency(item.amount)}',
                              style: TextStyle(
                                color: item.type == TransactionType.expense
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF10B981),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Gradient for caption readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Caption text pill at bottom of photo
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          item.caption,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Interactive Reaction Bar (Locket Style)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                _buildReactionChip(item, '💸'),
                const SizedBox(width: 8),
                _buildReactionChip(item, '🔥'),
                const SizedBox(width: 8),
                _buildReactionChip(item, '👏'),
                const SizedBox(width: 8),
                _buildReactionChip(item, '🤤'),
                const SizedBox(width: 8),
                _buildReactionChip(item, '😱'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionChip(TransactionModel item, String emoji) {
    final count = item.reactions[emoji] ?? 0;
    final isUserReacted = item.userReactedEmojis.contains(emoji);

    return InkWell(
      key: ValueKey('react_${item.id}_$emoji'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => _expenseService.toggleReaction(item.id, emoji),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isUserReacted
              ? const Color(0xFFFFD233).withValues(alpha: 0.2)
              : const Color(0xFF24242A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUserReacted
                ? const Color(0xFFFFD233)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  color: isUserReacted
                      ? const Color(0xFFFFD233)
                      : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(String? path) {
    if (path != null && path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildCardPlaceholder(),
      );
    } else if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return _buildCardPlaceholder();
  }

  Widget _buildCardPlaceholder() {
    return Container(
      color: const Color(0xFF282830),
      child: const Center(
        child: Icon(
          Icons.receipt_long_rounded,
          color: Colors.white30,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E22),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Color(0xFFFFD233),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có ảnh chi tiêu nào',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy chụp ly cà phê hoặc hoá đơn đầu tiên của bạn!',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (widget.onOpenSnap != null)
            ElevatedButton.icon(
              onPressed: widget.onOpenSnap,
              icon: const Icon(Icons.add_a_photo_rounded, size: 18),
              label: const Text('Chụp ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD233),
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
              ),
            ),
        ],
      ),
    );
  }
}
