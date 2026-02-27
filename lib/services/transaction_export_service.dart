// lib/services/transaction_export_service.dart
//
// Converts List<TransactionRecord> into CSV or Excel (.xlsx) files and
// writes them to the device temporary directory for sharing via share_plus.
//
// Column layout matches the import template (round-trip compatible):
//   date, type, amount, description, category, payment_method, client
//
// Category and payment method are exported using their friendly English labels
// (e.g. "Consulting", "Bank Transfer") so the file is human-readable and
// can be re-imported without modification.

import 'dart:convert';
import 'dart:io';

import '../utils/date_format_util.dart';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'package:incore_finance/models/payment_method.dart';
import 'package:incore_finance/models/transaction_category.dart';
import 'package:incore_finance/models/transaction_record.dart';

class TransactionExportService {
  static const List<String> _headers = [
    'date',
    'type',
    'amount',
    'description',
    'category',
    'payment_method',
    'client',
  ];

  // ── CSV ─────────────────────────────────────────────────────────────────────

  /// Generates a CSV string from [transactions].
  String generateCSV(List<TransactionRecord> transactions) {
    final rows = <List<dynamic>>[_headers];
    for (final t in transactions) {
      rows.add([
        _formatDate(t.date),
        t.type,
        t.amount.toStringAsFixed(2),
        t.description,
        _categoryLabel(t.category),
        _paymentLabel(t.paymentMethod),
        t.client ?? '',
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  // ── Excel ────────────────────────────────────────────────────────────────────

  /// Generates Excel (.xlsx) bytes from [transactions].
  List<int> generateExcel(List<TransactionRecord> transactions) {
    final workbook = Excel.createExcel();
    workbook.rename('Sheet1', 'Transactions');
    final sheet = workbook['Transactions'];

    // Header row
    for (var c = 0; c < _headers.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .value = TextCellValue(_headers[c]);
    }

    // Data rows
    for (var r = 0; r < transactions.length; r++) {
      final t = transactions[r];
      final values = [
        _formatDate(t.date),
        t.type,
        t.amount.toStringAsFixed(2),
        t.description,
        _categoryLabel(t.category),
        _paymentLabel(t.paymentMethod),
        t.client ?? '',
      ];
      for (var c = 0; c < values.length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(values[c]);
      }
    }

    final bytes = workbook.encode();
    if (bytes == null) throw Exception('Failed to encode Excel export');
    return bytes;
  }

  // ── Disk write ───────────────────────────────────────────────────────────────

  /// Writes the export file to the device temp directory.
  ///
  /// [format] must be `'csv'` or `'excel'`.
  /// Returns the file path for sharing via share_plus.
  Future<String> writeExportToDisk(
    List<TransactionRecord> transactions,
    String format,
  ) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (format == 'csv') {
      final content = generateCSV(transactions);
      final file = File('${dir.path}/incore_export_$stamp.csv');
      await file.writeAsString(content, encoding: utf8);
      return file.path;
    } else {
      final bytes = generateExcel(transactions);
      final file = File('${dir.path}/incore_export_$stamp.xlsx');
      await file.writeAsBytes(bytes);
      return file.path;
    }
  }

  // ── Label helpers ────────────────────────────────────────────────────────────

  static String _categoryLabel(String dbValue) =>
      TransactionCategory.fromDbValue(dbValue)?.label ?? dbValue;

  static String _paymentLabel(String? dbValue) =>
      PaymentMethodParser.fromAny(dbValue)?.label ?? dbValue ?? '';

  static String _formatDate(DateTime d) => toIsoDateString(d);
}
