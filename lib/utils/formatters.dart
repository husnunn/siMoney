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
