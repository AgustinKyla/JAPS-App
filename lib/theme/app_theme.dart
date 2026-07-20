import 'package:flutter/material.dart';

//Theme

class AppColors {
  static const Color primary = Color(0xFF1E4DB7);
  static const Color primaryDark = Color(0xFF15398C);
  static const Color primaryLight = Color(0xFF5C86E0);
  static const Color bg = Color(0xFFF3F5F9);
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF1F2430);
  static const Color textMuted = Color(0xFF7A8296);
  static const Color success = Color(0xFF20A860);
  static const Color warning = Color(0xFFE0A400);
  static const Color danger = Color(0xFFE5484D);
  static const Color border = Color(0xFFE3E7EF);
}

const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String fmtDate(DateTime d) => '${_kMonths[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';

String fmtDateTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ampm = d.hour >= 12 ? 'PM' : 'AM';
  final m = d.minute.toString().padLeft(2, '0');
  return '${fmtDate(d)}, $h:$m$ampm';
}

String fmtPeso(double v) {
  final neg = v < 0;
  final val = v.abs();
  final s = val.toStringAsFixed(2);
  final parts = s.split('.');
  String intPart = parts[0];
  final buf = StringBuffer();
  int count = 0;
  for (int i = intPart.length - 1; i >= 0; i--) {
    buf.write(intPart[i]);
    count++;
    if (count % 3 == 0 && i != 0) buf.write(',');
  }
  final grouped = buf.toString().split('').reversed.join();
  return '${neg ? '-' : ''}\u20B1$grouped.${parts[1]}';
}
