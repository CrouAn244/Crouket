import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/expense_service.dart';

class PreviewExpenseDialog extends StatefulWidget {
  final String photoPath;

  const PreviewExpenseDialog({super.key, required this.photoPath});

  @override
  State<PreviewExpenseDialog> createState() => _PreviewExpenseDialogState();
}

class _PreviewExpenseDialogState extends State<PreviewExpenseDialog> {
  final _captionController = TextEditingController();
  final _amountController = TextEditingController();
  final _expenseService = ExpenseService();

  TransactionType _type = TransactionType.expense;
  late String _selectedCategoryId;
  bool _isPrivate = false;

  final List<double> _quickAmounts = [20000, 50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = _expenseService.categories.first.id;
  }

  @override
  void dispose() {
    _captionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onQuickAmountTap(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  void _submit() {
    final amountText = _amountController.text.trim().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền chi tiêu hợp lệ'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final caption = _captionController.text.trim().isEmpty
        ? 'Khoảnh khắc chi tiêu mới'
        : _captionController.text.trim();

    _expenseService.addTransaction(
      photoPath: widget.photoPath,
      caption: caption,
      amount: amount,
      type: _type,
      categoryId: _selectedCategoryId,
      isPrivate: _isPrivate,
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Top action bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const Text(
                    'Đăng chi tiêu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: _submit,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD233),
                    ),
                    child: const Text(
                      'ĐĂNG',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo Preview with Locket Rounded Frame
                    Center(
                      child: Container(
                        width: math.min(size.width - 40, 260.0),
                        height: math.min(size.width - 40, 260.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E22),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildPhotoWidget(),

                            // Gradient shadow for caption readability
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 120,
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

                            // Caption Input Overlay (Locket Pill style)
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  key: const ValueKey('captionInput'),
                                  controller: _captionController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Thêm caption... (vd: Cà phê sáng ☕)',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Transaction Type Selector (Chi tiêu vs Thu nhập)
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _type = TransactionType.expense),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _type == TransactionType.expense
                                    ? const Color(0xFFEF4444)
                                          .withValues(alpha: 0.18)
                                    : const Color(0xFF1E1E22),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _type == TransactionType.expense
                                      ? const Color(0xFFEF4444)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    color: _type == TransactionType.expense
                                        ? const Color(0xFFEF4444)
                                        : Colors.white54,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Chi tiêu (Tiền ra)',
                                    style: TextStyle(
                                      color: _type == TransactionType.expense
                                          ? const Color(0xFFEF4444)
                                          : Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _type = TransactionType.income),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _type == TransactionType.income
                                    ? const Color(0xFF10B981)
                                          .withValues(alpha: 0.18)
                                    : const Color(0xFF1E1E22),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _type == TransactionType.income
                                      ? const Color(0xFF10B981)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    color: _type == TransactionType.income
                                        ? const Color(0xFF10B981)
                                        : Colors.white54,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Nhận tiền (Tiền vào)',
                                    style: TextStyle(
                                      color: _type == TransactionType.income
                                          ? const Color(0xFF10B981)
                                          : Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Amount Input Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SỐ TIỀN',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                _type == TransactionType.expense ? '- ' : '+ ',
                                style: TextStyle(
                                  color: _type == TransactionType.expense
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  key: const ValueKey('amountInput'),
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                    suffixText: '₫',
                                    suffixStyle: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Quick Amount Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _quickAmounts.map((amt) {
                                final label = amt >= 1000
                                    ? '${(amt / 1000).toStringAsFixed(0)}k'
                                    : amt.toStringAsFixed(0);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    label: Text(label),
                                    onPressed: () => _onQuickAmountTap(amt),
                                    backgroundColor: const Color(0xFF2C2C32),
                                    labelStyle: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    padding: EdgeInsets.zero,
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Category Selector Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DANH MỤC',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 50,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _expenseService.categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final cat = _expenseService.categories[index];
                              final isSelected = cat.id == _selectedCategoryId;

                              return ChoiceChip(
                                key: ValueKey('cat_${cat.id}'),
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      cat.icon,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(cat.name),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() => _selectedCategoryId = cat.id);
                                },
                                selectedColor: cat.color.withValues(
                                  alpha: 0.25,
                                ),
                                backgroundColor: const Color(0xFF1E1E22),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white60,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? cat.color
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Privacy Switch
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E22),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isPrivate
                                ? Icons.lock_rounded
                                : Icons.people_alt_rounded,
                            color: const Color(0xFFFFD233),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPrivate
                                      ? 'Chỉ mình tôi'
                                      : 'Chia sẻ với bạn bè',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _isPrivate
                                      ? 'Khoảnh khắc này sẽ không hiển thị trên feed bạn bè'
                                      : 'Bạn bè có thể thấy ảnh và reaction cổ vũ',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: !_isPrivate,
                            activeTrackColor: const Color(0xFFFFD233),
                            onChanged: (val) =>
                                setState(() => _isPrivate = !val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Big Submit Button
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        key: const ValueKey('submitExpenseButton'),
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD233),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Đăng lên Crouket',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoWidget() {
    if (widget.photoPath.startsWith('http')) {
      return Image.network(
        widget.photoPath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }

    final file = File(widget.photoPath);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF232328),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded, color: Colors.white54, size: 48),
            SizedBox(height: 8),
            Text(
              'Ảnh chi tiêu Crouket',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
