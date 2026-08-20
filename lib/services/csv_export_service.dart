import '../models/models.dart';

class CsvExportService {
  static String buildAllTimeTransactionsCsv(List<TxRecord> txs) {
    final rows = <List<String>>[];
    rows.add(const [
      'tanggal',
      'tipe',
      'nominal',
      'kategori',
      'catatan',
      'pembuat',
    ]);

    for (final tx in txs) {
      rows.add([
        _csvEscape(_formatDateTime(tx.createdAt)),
        _csvEscape(tx.isIncome ? 'Pemasukan' : 'Pengeluaran'),
        _csvEscape(tx.amount.toString()),
        _csvEscape(tx.categoryName),
        _csvEscape(tx.note),
        _csvEscape(tx.createdByName),
      ]);
    }

    return rows
        .map((r) => r.join(','))
        .join('\n')
        .replaceAll('\r\n', '\n');
  }

  static String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  static String _csvEscape(String value) {
    final v = value.replaceAll('"', '""');
    if (v.contains(',') || v.contains('"') || v.contains('\n') || v.contains('\r')) {
      return '"$v"';
    }
    return v;
  }
}

