const List<String> _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const List<String> _monthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String formatRupiah(int amount) {
  final abs = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < abs.length; i++) {
    if (i > 0 && (abs.length - i) % 3 == 0) buffer.write('.');
    buffer.write(abs[i]);
  }
  final sign = amount < 0 ? '-' : '';
  return 'Rp$sign${buffer.toString()}';
}

/// Rounds a computed amount for display: whole rupiah for tiny values, tens up
/// to 100 thousand, hundreds above that (projections are estimates, so exact
/// rupiah would imply false precision).
String formatRupiahAuto(double value) {
  final abs = value.abs();
  final step = abs < 1000 ? 1 : (abs < 100000 ? 10 : 100);
  return formatRupiah((value / step).round() * step);
}

String _trimmedDecimal(double value, int digits) {
  var text = value.toStringAsFixed(digits);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  }
  return text.replaceAll('.', ',');
}

/// Short money for chart axes and tight spaces: Rp27,5 jt, Rp798 rb, Rp1,2 M.
String formatRupiahCompact(double value) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  if (abs >= 1e12) return 'Rp$sign${_trimmedDecimal(abs / 1e12, 1)} T';
  if (abs >= 1e9) return 'Rp$sign${_trimmedDecimal(abs / 1e9, 2)} M';
  if (abs >= 1e6) return 'Rp$sign${_trimmedDecimal(abs / 1e6, 1)} jt';
  if (abs >= 1e3) return 'Rp$sign${_trimmedDecimal(abs / 1e3, 0)} rb';
  return formatRupiah(value.round());
}

/// Indonesian percent with a decimal comma: 3,2%.
String formatPercent(double value, {int digits = 1}) {
  return '${value.toStringAsFixed(digits).replaceAll('.', ',')}%';
}

/// Months as "3 th 2 bln", "8 bln" or "2 th".
String formatDuration(int months) {
  final years = months ~/ 12;
  final rest = months % 12;
  if (years == 0) return '$rest bln';
  if (rest == 0) return '$years th';
  return '$years th $rest bln';
}

/// Time until a deadline for list/detail captions.
String formatTimeLeft(int days) {
  if (days < 0) return 'Tenggat terlewat';
  if (days == 0) return 'Tenggat hari ini';
  if (days < 45) return '$days hari lagi';
  return '${formatDuration((days / (365 / 12)).round())} lagi';
}

String formatMonthYear(DateTime date) {
  return '${_monthNames[date.month - 1]} ${date.year}';
}

String formatDateShort(DateTime date) {
  return '${date.day} ${_monthShort[date.month - 1]} ${date.year}';
}

DateTime startOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

DateTime endOfWeek(DateTime date) => startOfWeek(date).add(const Duration(days: 6));

String formatWeekRange(DateTime start, DateTime end) {
  if (start.year == end.year && start.month == end.month) {
    return '${start.day} – ${end.day} ${_monthShort[end.month - 1]} ${end.year}';
  }
  if (start.year == end.year) {
    return '${start.day} ${_monthShort[start.month - 1]} – '
        '${end.day} ${_monthShort[end.month - 1]} ${end.year}';
  }
  return '${formatDateShort(start)} – ${formatDateShort(end)}';
}

String _twoDigits(int n) => n.toString().padLeft(2, '0');

String formatRelativeTime(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;
  final time = '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  if (diff == 0) return 'Hari ini · $time';
  if (diff == 1) return 'Kemarin · $time';
  return '${formatDateShort(date)} · $time';
}
