import 'package:flutter/material.dart';

/// Layout rhythm (DESIGN.md).
abstract final class LedgerGap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

/// Motion tokens.
abstract final class LedgerMotion {
  static const Duration medium = Duration(milliseconds: 320);
  static const Curve curve = Curves.easeOutCubic;
}
