import 'dart:convert';

import 'db/ledger_database.dart';

double _parseAmount(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '0') ?? 0;
}

bool _expenseInMonth(Map<String, dynamic> e, int year, int month) {
  final d = DateTime.tryParse(e['date']?.toString() ?? '');
  return d != null && d.year == year && d.month == month;
}

Future<List<Map<String, dynamic>>> _loadExpensePayloads(LedgerDatabase db) async {
  final rows = await (db.select(db.cachedExpenses)
        ..where((t) => t.syncStatus.isNotValue(LedgerSyncStatus.pendingDelete.index)))
      .get();
  return rows
      .map((r) => Map<String, dynamic>.from(jsonDecode(r.payloadJson) as Map))
      .toList();
}

Future<Map<String, dynamic>> buildOfflineMonthlySummary(LedgerDatabase db) async {
  final expenses = await _loadExpensePayloads(db);
  final now = DateTime.now();
  final ym = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  var expenseTotal = 0.0;
  for (final e in expenses) {
    if (_expenseInMonth(e, now.year, now.month)) {
      expenseTotal += _parseAmount(e['amount']);
    }
  }
  final net = -expenseTotal;
  return {
    'totalIncome': '0',
    'totalExpenses': expenseTotal.toStringAsFixed(2),
    'netCashFlow': net.toStringAsFixed(2),
    'month': ym,
    'incomeBySource': <dynamic>[],
  };
}

Future<Map<String, dynamic>> buildOfflineDashboardOverview(LedgerDatabase db) async {
  final expenses = await _loadExpensePayloads(db);
  final now = DateTime.now();
  final month = await buildOfflineMonthlySummary(db);

  final trends = <Map<String, dynamic>>[];
  for (var i = 5; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i, 1);
    var exp = 0.0;
    for (final e in expenses) {
      if (_expenseInMonth(e, d.year, d.month)) {
        exp += _parseAmount(e['amount']);
      }
    }
    final monthKey = '${d.year}-${d.month.toString().padLeft(2, '0')}';
    trends.add({
      'month': monthKey,
      'income': 0,
      'expenses': exp,
      'netSavings': -exp,
    });
  }

  return {
    'netWorth': {
      'netWorth': '—',
      'bankAndCash': '—',
      'investments': '0',
      'creditCardDebt': '0',
      'otherLiabilities': '0',
    },
    'thisMonth': {
      'totalIncome': month['totalIncome'],
      'totalExpenses': month['totalExpenses'],
      'netSavings': month['netCashFlow'],
      'month': month['month'],
    },
    'savingsTrend': trends,
  };
}

Future<List<Map<String, dynamic>>> buildOfflineCategoryBreakdown(LedgerDatabase db) async {
  final expenses = await _loadExpensePayloads(db);
  final now = DateTime.now();
  final byCat = <String, double>{};
  for (final e in expenses) {
    if (!_expenseInMonth(e, now.year, now.month)) continue;
    final cat = e['category'];
    final cid = e['categoryId']?.toString() ??
        (cat is Map ? cat['id']?.toString() : null) ??
        'unknown';
    byCat[cid] = (byCat[cid] ?? 0) + _parseAmount(e['amount']);
  }
  return byCat.entries
      .map((e) => {'categoryId': e.key, 'total': e.value.toStringAsFixed(2)})
      .toList();
}

Map<String, dynamic> offlineTaxSummaryPlaceholder() => {
      'period': 'Offline demo',
      'totals': {
        'taxableExpenseCount': 0,
        'totalTaxableExpenseAmount': '0',
        'totalTaxAmount': '0',
      },
    };
