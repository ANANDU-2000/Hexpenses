/// Composable query for `/reports/analytics` and expense lists.
class AnalyticsFilter {
  const AnalyticsFilter({
    this.year,
    this.month,
    this.fromYmd,
    this.toYmd,
    this.categoryId,
    this.subCategoryId,
    this.expenseTypeId,
    this.spendEntityId,
    this.paymentMode,
  });

  final int? year;
  final int? month;
  final String? fromYmd;
  final String? toYmd;
  final String? categoryId;
  final String? subCategoryId;
  final String? expenseTypeId;
  final String? spendEntityId;
  /// Backend enum: cash, card, upi, bank_transfer, wallet, other
  final String? paymentMode;

  /// Drill to category; clears deeper dimensions.
  AnalyticsFilter withCategoryDrill(String id) => AnalyticsFilter(
        year: year,
        month: month,
        fromYmd: fromYmd,
        toYmd: toYmd,
        categoryId: id,
        subCategoryId: null,
        expenseTypeId: null,
        spendEntityId: null,
        paymentMode: paymentMode,
      );

  AnalyticsFilter withSubCategoryDrill(String id) => AnalyticsFilter(
        year: year,
        month: month,
        fromYmd: fromYmd,
        toYmd: toYmd,
        categoryId: categoryId,
        subCategoryId: id,
        expenseTypeId: null,
        spendEntityId: null,
        paymentMode: paymentMode,
      );

  AnalyticsFilter withExpenseTypeDrill(String id) => AnalyticsFilter(
        year: year,
        month: month,
        fromYmd: fromYmd,
        toYmd: toYmd,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        expenseTypeId: id,
        spendEntityId: null,
        paymentMode: paymentMode,
      );

  AnalyticsFilter withSpendEntityDrill(String id) => AnalyticsFilter(
        year: year,
        month: month,
        fromYmd: fromYmd,
        toYmd: toYmd,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        expenseTypeId: expenseTypeId,
        spendEntityId: id,
        paymentMode: paymentMode,
      );

  Map<String, String> toQuery() {
    final m = <String, String>{};
    if (year != null) m['year'] = '$year';
    if (month != null) m['month'] = '$month';
    if (fromYmd != null && fromYmd!.isNotEmpty) m['from'] = fromYmd!;
    if (toYmd != null && toYmd!.isNotEmpty) m['to'] = toYmd!;
    if (categoryId != null && categoryId!.isNotEmpty) {
      m['categoryId'] = categoryId!;
    }
    if (subCategoryId != null && subCategoryId!.isNotEmpty) {
      m['subCategoryId'] = subCategoryId!;
    }
    if (expenseTypeId != null && expenseTypeId!.isNotEmpty) {
      m['expenseTypeId'] = expenseTypeId!;
    }
    if (spendEntityId != null && spendEntityId!.isNotEmpty) {
      m['spendEntityId'] = spendEntityId!;
    }
    if (paymentMode != null && paymentMode!.isNotEmpty) {
      m['paymentMode'] = paymentMode!;
    }
    return m;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsFilter &&
          year == other.year &&
          month == other.month &&
          fromYmd == other.fromYmd &&
          toYmd == other.toYmd &&
          categoryId == other.categoryId &&
          subCategoryId == other.subCategoryId &&
          expenseTypeId == other.expenseTypeId &&
          spendEntityId == other.spendEntityId &&
          paymentMode == other.paymentMode;

  @override
  int get hashCode => Object.hash(
        year,
        month,
        fromYmd,
        toYmd,
        categoryId,
        subCategoryId,
        expenseTypeId,
        spendEntityId,
        paymentMode,
      );
}
