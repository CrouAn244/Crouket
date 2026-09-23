import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/expense_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _expenseService = ExpenseService();
  TimeFrame _timeFrame = TimeFrame.month;

  @override
  void initState() {
    super.initState();
    _expenseService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _expenseService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final totalExpense = _expenseService.getTotalExpense(_timeFrame);
    final totalIncome = _expenseService.getTotalIncome(_timeFrame);
    final netBalance = totalIncome - totalExpense;
    final breakdown = _expenseService.getCategoryBreakdown(_timeFrame);
    final trend = _expenseService.getWeeklyTrend();
    final recentTxs = _expenseService.getFilteredTransactions(
      _timeFrame,
      onlyMine: true,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F11),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'THỐNG KÊ CHI TIÊU',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeframe Segmented Control
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E22),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTimeTab(TimeFrame.week, 'Tuần này'),
                  _buildTimeTab(TimeFrame.month, 'Tháng này'),
                  _buildTimeTab(TimeFrame.year, 'Năm nay'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Summary Overview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF19191D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TỔNG CHI TIÊU CỦA BẠN',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ExpenseService.formatCurrency(totalExpense),
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF2C2C32), height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thu nhập (Tiền vào)',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+${ExpenseService.formatCurrency(totalIncome)}',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Số dư ròng',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${netBalance >= 0 ? '+' : ''}${ExpenseService.formatCurrency(netBalance)}',
                              style: TextStyle(
                                color: netBalance >= 0
                                    ? Colors.white
                                    : const Color(0xFFEF4444),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Category Breakdown (Donut Chart)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF19191D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PHÂN BỔ THEO DANH MỤC',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (breakdown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Chưa có khoản chi nào trong khoảng thời gian này',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                    )
                  else ...[
                    // Custom Donut Chart Canvas
                    Center(
                      child: SizedBox(
                        width: 170,
                        height: 170,
                        child: CustomPaint(
                          painter: _DonutChartPainter(
                            breakdown: breakdown,
                            total: totalExpense,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Tổng cộng',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${breakdown.length} nhóm',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Legend list
                    for (final entry in breakdown.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: entry.key.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key.icon,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              totalExpense > 0
                                  ? '${((entry.value / totalExpense) * 100).toStringAsFixed(1)}%'
                                  : '0%',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              ExpenseService.formatCurrency(entry.value),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Weekly Trend Bar Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF19191D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'XU HƯỚNG CHI TIÊU 7 NGÀY GẦN NHẤT',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(height: 140, child: _buildBarChart(trend)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Photo Expense Timeline
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF19191D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LỊCH SỬ KHOẢNH KHẮC CHI TIÊU',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (recentTxs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Chưa có giao dịch cá nhân nào',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    for (final t in recentTxs) _buildTimelineItem(t),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTab(TimeFrame tf, String label) {
    final isSelected = _timeFrame == tf;

    return Expanded(
      child: GestureDetector(
        key: ValueKey('timeTab_${tf.name}'),
        onTap: () => setState(() => _timeFrame = tf),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2C2C32) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
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

  Widget _buildBarChart(List<DailyExpensePoint> points) {
    final maxAmount = points.map((p) => p.amount).fold(0.0, math.max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: points.map((p) {
        final heightRatio = maxAmount > 0 ? (p.amount / maxAmount) : 0.0;
        final barHeight = math.max(6.0, heightRatio * 90.0);
        final isToday = p.date.day == DateTime.now().day;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (p.amount > 0)
              Text(
                p.amount >= 1000
                    ? '${(p.amount / 1000).toStringAsFixed(0)}k'
                    : p.amount.toStringAsFixed(0),
                style: const TextStyle(color: Colors.white54, fontSize: 9),
              )
            else
              const SizedBox(height: 12),
            const SizedBox(height: 4),
            Container(
              width: 22,
              height: barHeight,
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFFFFD233)
                    : (p.amount > 0
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF2C2C32)),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              p.label,
              style: TextStyle(
                color: isToday ? const Color(0xFFFFD233) : Colors.white54,
                fontSize: 11,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTimelineItem(TransactionModel tx) {
    final cat = _expenseService.getCategory(tx.categoryId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Photo thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 52,
              height: 52,
              child: _buildThumbImage(tx.photoPath),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(cat.icon, style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      cat.name,
                      style: TextStyle(
                        color: cat.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${tx.createdAt.day}/${tx.createdAt.month}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${tx.type == TransactionType.expense ? '-' : '+'}${ExpenseService.formatCurrency(tx.amount)}',
            style: TextStyle(
              color: tx.type == TransactionType.expense
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbImage(String? path) {
    if (path != null && path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildThumbPlaceholder(),
      );
    } else if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return _buildThumbPlaceholder();
  }

  Widget _buildThumbPlaceholder() {
    return Container(
      color: const Color(0xFF2C2C32),
      child: const Center(
        child: Icon(Icons.receipt_rounded, color: Colors.white38, size: 20),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<CategoryModel, double> breakdown;
  final double total;

  const _DonutChartPainter({required this.breakdown, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;

    double startAngle = -math.pi / 2;

    for (final entry in breakdown.entries) {
      final cat = entry.key;
      final amt = entry.value;
      final sweepAngle = (amt / total) * 2 * math.pi;

      final paint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle + 0.04,
        math.max(0.01, sweepAngle - 0.08),
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.breakdown != breakdown;
  }
}
