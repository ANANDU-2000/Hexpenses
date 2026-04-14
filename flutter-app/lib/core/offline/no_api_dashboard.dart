import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'db/ledger_database.dart';
import '../../features/analytics/domain/analytics_filter.dart';

double _parseAmount(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '0') ?? 0;
}

bool _expenseInMonth(Map<String, dynamic> e, int year, int month) {
  final d = DateTime.tryParse(e['date']?.toString() ?? '');
  return d != null && d.year == year && d.month == month;
}

Future<List<Map<String, dynamic>>> _loadExpensePayloads(
  LedgerDatabase db,
) async {
  final rows =
      await (db.select(db.cachedExpenses)..where(
            (t) =>
                t.syncStatus.isNotValue(LedgerSyncStatus.pendingDelete.index),
          ))
          .get();
  return rows
      .map((r) => Map<String, dynamic>.from(jsonDecode(r.payloadJson) as Map))
      .toList();
}

Future<Map<String, dynamic>> buildOfflineMonthlySummary(
  LedgerDatabase db,
) async {
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

Future<Map<String, dynamic>> buildOfflineDashboardOverview(
  LedgerDatabase db,
) async {
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

Future<List<Map<String, dynamic>>> buildOfflineCategoryBreakdown(
  LedgerDatabase db,
) async {
  final expenses = await _loadExpensePayloads(db);
  final now = DateTime.now();
  final byCat = <String, double>{};
  for (final e in expenses) {
    if (!_expenseInMonth(e, now.year, now.month)) continue;
    final cat = e['category'];
    final cid =
        e['categoryId']?.toString() ??
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

/// Rough offline mirror of `/reports/expense-mvp` for charts when API is disabled.
Future<Map<String, dynamic>> buildOfflineExpenseMvp(
  LedgerDatabase db,
  int year,
  int month, {
  String? fromYmd,
  String? toYmd,
}) async {
  final expenses = await _loadExpensePayloads(db);
  double totalAll = 0;
  for (final e in expenses) {
    totalAll += _parseAmount(e['amount']);
  }

  DateTime? rangeStart;
  DateTime? rangeEndExcl;
  if (fromYmd != null &&
      toYmd != null &&
      fromYmd.isNotEmpty &&
      toYmd.isNotEmpty) {
    rangeStart = DateTime.tryParse('${fromYmd}T00:00:00');
    final toD = DateTime.tryParse('${toYmd}T00:00:00');
    if (toD != null) {
      rangeEndExcl = toD.add(const Duration(days: 1));
    }
  }

  bool inPeriod(DateTime d) {
    final rs = rangeStart;
    final re = rangeEndExcl;
    if (rs != null && re != null) {
      return !d.isBefore(rs) && d.isBefore(re);
    }
    return d.year == year && d.month == month;
  }

  final byCat = <String, double>{};
  final catNames = <String, String>{};
  double monthTotal = 0;
  for (final e in expenses) {
    final d = DateTime.tryParse(e['date']?.toString() ?? '');
    if (d == null || !inPeriod(d)) continue;
    monthTotal += _parseAmount(e['amount']);
    final cat = e['category'];
    String? cid;
    String name = 'Other';
    if (cat is Map) {
      cid = cat['id']?.toString();
      name = cat['name']?.toString() ?? name;
    }
    cid ??= 'unknown';
    catNames[cid] = name;
    byCat[cid] = (byCat[cid] ?? 0) + _parseAmount(e['amount']);
  }

  final breakdown = byCat.entries
      .map(
        (e) => {
          'categoryId': e.key,
          'name': catNames[e.key] ?? e.key,
          'total': e.value.toStringAsFixed(2),
        },
      )
      .toList();

  final now = DateTime(year, month);
  final monthlyExpenseTrend = <Map<String, dynamic>>[];
  final barLabels = <String>[];
  final barValues = <double>[];
  for (var i = 11; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i, 1);
    var v = 0.0;
    for (final e in expenses) {
      final ed = DateTime.tryParse(e['date']?.toString() ?? '');
      if (ed != null && ed.year == d.year && ed.month == d.month) {
        v += _parseAmount(e['amount']);
      }
    }
    final key = '${d.year}-${d.month}';
    monthlyExpenseTrend.add({
      'month': key,
      'label': DateFormat('MMM').format(d),
      'total': v.toStringAsFixed(2),
      'totalNum': v,
    });
    barLabels.add(DateFormat('MMM').format(d));
    barValues.add(v);
  }

  final periodLabel = rangeStart != null && toYmd != null
      ? '$fromYmd → $toYmd'
      : '$year-$month';

  return {
    'period': periodLabel,
    'totalSpentAllTime': totalAll.toStringAsFixed(2),
    'thisMonthExpenses': monthTotal.toStringAsFixed(2),
    'categoryBreakdownMonth': breakdown,
    'chart': {
      'pie': {
        'labels': breakdown.map((e) => e['name']).toList(),
        'values': breakdown
            .map((e) => double.tryParse(e['total']?.toString() ?? '0') ?? 0)
            .toList(),
        'categoryIds': breakdown.map((e) => e['categoryId']).toList(),
      },
      'monthlyExpenses': {
        'labels': barLabels,
        'values': barValues,
      },
    },
    'recurringMonthlyTotal': '0',
    'recurringNote': 'Offline — recurring total not available.',
    'vehicle': {
      'hasVehicles': false,
      'vehicleExpenseTotalAllTime': '0',
      'emptyHint': 'Offline mode',
    },
    'upcomingPayments': {'count': 0, 'note': 'Offline mode'},
  };
}

Future<Map<String, dynamic>> buildOfflineAnalytics(
  LedgerDatabase db,
  AnalyticsFilter f,
) async {
  final now = DateTime.now();
  var y = f.year ?? now.year;
  var mo = f.month ?? now.month;
  if (f.fromYmd != null && f.toYmd != null) {
    final d = DateTime.tryParse('${f.fromYmd}T00:00:00');
    if (d != null) {
      y = d.year;
      mo = d.month;
    }
  }
  final mvp = await buildOfflineExpenseMvp(
    db,
    y,
    mo,
    fromYmd: f.fromYmd,
    toYmd: f.toYmd,
  );
  final breakdown = (mvp['categoryBreakdownMonth'] as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  final total =
      double.tryParse(mvp['thisMonthExpenses']?.toString() ?? '0') ?? 0;
  final pie = {
    'labels': breakdown.map((e) => e['name']).toList(),
    'values': breakdown
        .map((e) => double.tryParse(e['total']?.toString() ?? '0') ?? 0)
        .toList(),
    'ids': breakdown.map((e) => e['categoryId']).toList(),
    'level': 'category',
  };
  final bar = mvp['chart'] is Map
      ? (mvp['chart'] as Map)['monthlyExpenses'] as Map?
      : null;
  final barLabels = (bar?['labels'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
      <String>[];
  final barVals = (bar?['values'] as List?)
          ?.map(
            (e) =>
                (e is num) ? e.toDouble() : double.tryParse(e.toString()) ?? 0,
          )
          .toList() ??
      <double>[];
  return {
    'period': mvp['period'],
    'total': total.toStringAsFixed(2),
    'count': breakdown.length,
    'average': breakdown.isEmpty
        ? '0'
        : (total / breakdown.length).toStringAsFixed(2),
    'pie': pie,
    'chart': {
      'monthlyBar': {'labels': barLabels, 'values': barVals},
      'lineTrend': {'labels': barLabels, 'values': barVals},
      'stackedCategoryMonth': {
        'months': barLabels,
        'monthLabels': barLabels,
        'series': <Map<String, dynamic>>[],
      },
    },
    'filters': {
      'categoryId': f.categoryId,
      'subCategoryId': f.subCategoryId,
      'expenseTypeId': f.expenseTypeId,
      'spendEntityId': f.spendEntityId,
      'paymentMode': f.paymentMode,
    },
  };
}

Map<String, dynamic> buildOfflineInsights() => {
      'thisMonthTotal': '0',
      'lastMonthTotal': '0',
      'monthOverMonthPct': null,
      'topCategoryThisMonth': null,
      'alerts': <Map<String, dynamic>>[],
    };

class OfflineModeBanner extends StatelessWidget {
  const OfflineModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MaterialBanner(
      backgroundColor: cs.tertiaryContainer,
      content: Text(
        'Offline mode — changes sync when you reconnect',
        style: TextStyle(color: cs.onTertiaryContainer),
      ),
      leading: Icon(Icons.cloud_off_outlined, color: cs.onTertiaryContainer),
      actions: [
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          },
          child: const Text('Got it'),
        ),
      ],
    );
  }
}
