import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/analytics_filter.dart';

/// Bottom sheet: payment mode + clear drill filters.
Future<AnalyticsFilter?> showAnalyticsFilterSheet(
  BuildContext context, {
  required AnalyticsFilter current,
}) {
  return showModalBottomSheet<AnalyticsFilter>(
    context: context,
    backgroundColor: const Color(0xFF121A2B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModal) {
          String? pm = current.paymentMode;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: pm,
                  dropdownColor: const Color(0xFF1A2438),
                  decoration: const InputDecoration(
                    labelText: 'Payment mode',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    DropdownMenuItem(
                      value: 'bank_transfer',
                      child: Text('Bank transfer'),
                    ),
                    DropdownMenuItem(value: 'wallet', child: Text('Wallet')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setModal(() {
                    pm = v;
                  }),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          ctx,
                          AnalyticsFilter(
                            year: current.year,
                            month: current.month,
                            fromYmd: current.fromYmd,
                            toYmd: current.toYmd,
                            categoryId: current.categoryId,
                            subCategoryId: current.subCategoryId,
                            expenseTypeId: current.expenseTypeId,
                            spendEntityId: current.spendEntityId,
                            paymentMode: pm,
                          ),
                        );
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
