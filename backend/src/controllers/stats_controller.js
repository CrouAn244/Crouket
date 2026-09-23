import { db1 } from '../db/db1_users.js';

export class StatsController {
  static getStats(req, res, next) {
    try {
      const userId = req.user.id;
      const period = req.query.period || 'month'; // 'week' | 'month' | 'year'

      const now = new Date();
      let startDate;

      if (period === 'week') {
        const day = now.getDay() || 7;
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - day + 1);
      } else if (period === 'year') {
        startDate = new Date(now.getFullYear(), 0, 1);
      } else {
        // default: month
        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      }

      const isoStart = startDate.toISOString();

      // Total expense & income
      const totalsStmt = db1.prepare(`
        SELECT 
          type, 
          COALESCE(SUM(amount), 0) as total 
        FROM transactions 
        WHERE user_id = ? AND created_at >= ?
        GROUP BY type
      `);
      const totalsRows = totalsStmt.all(userId, isoStart);

      let totalExpense = 0;
      let totalIncome = 0;

      for (const r of totalsRows) {
        if (r.type === 'expense') totalExpense = r.total;
        if (r.type === 'income') totalIncome = r.total;
      }

      // Spending breakdown by category
      const catStmt = db1.prepare(`
        SELECT 
          c.id, c.name, c.emoji, c.color_value, c.monthly_budget,
          COALESCE(SUM(t.amount), 0) as spent
        FROM categories c
        LEFT JOIN transactions t ON c.id = t.category_id AND t.user_id = ? AND t.type = 'expense' AND t.created_at >= ?
        WHERE c.user_id = ? OR c.user_id IS NULL
        GROUP BY c.id
        HAVING spent > 0
        ORDER BY spent DESC
      `);
      const categoryBreakdown = catStmt.all(userId, isoStart, userId);

      const formattedCategories = categoryBreakdown.map((c) => ({
        id: c.id,
        name: c.name,
        emoji: c.emoji,
        colorValue: c.color_value,
        monthlyBudget: c.monthly_budget,
        spent: c.spent,
        percentage: totalExpense > 0 ? Number(((c.spent / totalExpense) * 100).toFixed(1)) : 0,
      }));

      // Last 7 days trend
      const sevenDaysAgo = new Date(Date.now() - 6 * 24 * 60 * 60 * 1000);
      sevenDaysAgo.setHours(0, 0, 0, 0);

      const dailyStmt = db1.prepare(`
        SELECT 
          substr(created_at, 1, 10) as day_date,
          COALESCE(SUM(amount), 0) as daily_total
        FROM transactions
        WHERE user_id = ? AND type = 'expense' AND created_at >= ?
        GROUP BY day_date
        ORDER BY day_date ASC
      `);
      const dailyRows = dailyStmt.all(userId, sevenDaysAgo.toISOString());
      const dailyMap = {};
      for (const d of dailyRows) {
        dailyMap[d.day_date] = d.daily_total;
      }

      const last7DaysTrend = [];
      for (let i = 6; i >= 0; i--) {
        const d = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
        const key = d.toISOString().slice(0, 10);
        const dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
        last7DaysTrend.push({
          date: key,
          label: i === 0 ? 'Hôm nay' : dayNames[d.getDay()],
          amount: dailyMap[key] || 0,
        });
      }

      res.json({
        success: true,
        data: {
          period,
          startDate: isoStart,
          summary: {
            totalExpense,
            totalIncome,
            netBalance: totalIncome - totalExpense,
          },
          categoryBreakdown: formattedCategories,
          last7DaysTrend,
        },
      });
    } catch (err) {
      next(err);
    }
  }
}

