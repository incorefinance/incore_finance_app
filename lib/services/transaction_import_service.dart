// lib/services/transaction_import_service.dart
//
// Parses CSV and Excel files into TransactionImportRow objects.
// Handles both friendly category/payment-method names and raw enum values.
// Validates every row before import; invalid rows are reported with a reason.

import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import 'package:incore_finance/models/payment_method.dart';

/// One row read from an import file.
///
/// If [validationError] is non-null the row is invalid and will be skipped.
class TransactionImportRow {
  final int rowNumber;
  final double? amount;
  final String? description;
  final String? category; // resolved enum value
  final String? type;
  final DateTime? date;
  final String? paymentMethod; // resolved db value
  final String? client;
  final String? validationError; // null = valid row

  const TransactionImportRow({
    required this.rowNumber,
    this.amount,
    this.description,
    this.category,
    this.type,
    this.date,
    this.paymentMethod,
    this.client,
    this.validationError,
  });

  bool get isValid => validationError == null;
}

class TransactionImportService {
  // ── Category mappings ───────────────────────────────────────────────────────

  static const Map<String, String> _categoryByFriendlyName = {
    'sales': 'rev_sales',
    'freelance': 'rev_freelance',
    'consulting': 'rev_consulting',
    'retainers': 'rev_retainers',
    'subscriptions': 'rev_subscriptions',
    'commissions': 'rev_commissions',
    'interest': 'rev_interest',
    'refunds': 'rev_refunds',
    'other income': 'rev_other',
    'advertising': 'mkt_ads',
    'software': 'mkt_software',
    'subscriptions (expense)': 'mkt_subs',
    'equipment': 'ops_equipment',
    'supplies': 'ops_supplies',
    'accounting': 'pro_accounting',
    'contractors': 'pro_contractors',
    'travel': 'travel_general',
    'meals': 'travel_meals',
    'rent': 'ops_rent',
    'insurance': 'ops_insurance',
    'taxes': 'ops_taxes',
    'fees': 'ops_fees',
    'salaries': 'people_salary',
    'training': 'people_training',
    'other expense': 'other_expense',
  };

  static const Set<String> _validCategoryEnums = {
    'rev_sales',
    'rev_freelance',
    'rev_consulting',
    'rev_retainers',
    'rev_subscriptions',
    'rev_commissions',
    'rev_interest',
    'rev_refunds',
    'rev_other',
    'mkt_ads',
    'mkt_software',
    'mkt_subs',
    'ops_equipment',
    'ops_supplies',
    'pro_accounting',
    'pro_contractors',
    'travel_general',
    'travel_meals',
    'ops_rent',
    'ops_insurance',
    'ops_taxes',
    'ops_fees',
    'people_salary',
    'people_training',
    'other_expense',
  };

  static const String _validIncomeCategories =
      'Sales, Freelance, Consulting, Retainers, Subscriptions, Commissions, '
      'Interest, Refunds, Other Income';

  static const String _validExpenseCategories =
      'Advertising, Software, Equipment, Supplies, Accounting, Contractors, '
      'Travel, Meals, Rent, Insurance, Taxes, Fees, Salaries, Training, Other Expense';

  static const Set<String> _incomeCategories = {
    'rev_sales',
    'rev_freelance',
    'rev_consulting',
    'rev_retainers',
    'rev_subscriptions',
    'rev_commissions',
    'rev_interest',
    'rev_refunds',
    'rev_other',
  };

  // ── Resolvers ───────────────────────────────────────────────────────────────

  /// Returns the canonical db value for a category, or null if unrecognised.
  static String? _resolveCategory(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final lower = raw.trim().toLowerCase();
    if (_validCategoryEnums.contains(lower)) return lower;
    return _categoryByFriendlyName[lower];
  }

  /// Returns the canonical db value for a payment method, or null if unrecognised.
  /// Stricter than PaymentMethodParser.fromAny() — does not fall back to "other".
  static String? _resolvePaymentMethod(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final lower = raw.trim().toLowerCase();

    for (final m in PaymentMethod.values) {
      if (m.dbValue == lower) return m.dbValue;
    }
    for (final m in PaymentMethod.values) {
      if (m.label.toLowerCase() == lower) return m.dbValue;
    }
    // Extra tolerance for common variants
    final normalized = lower.replaceAll(' ', '_').replaceAll('-', '_');
    switch (normalized) {
      case 'bank_transfer':
      case 'banktransfer':
        return 'bank_transfer';
      case 'mb_way':
      case 'mbway':
        return 'mbway';
      case 'direct_debit':
      case 'directdebit':
        return 'direct_debit';
    }
    return null; // unrecognised
  }

  // ── Row validation ──────────────────────────────────────────────────────────

  static TransactionImportRow _validateRow(
    Map<String, String?> fields,
    int rowNumber,
  ) {
    // 1. type
    final rawType = fields['type']?.trim().toLowerCase();
    if (rawType != 'income' && rawType != 'expense') {
      return TransactionImportRow(
        rowNumber: rowNumber,
        validationError:
            '"type" must be "income" or "expense" (got "${fields['type'] ?? ''}")',
      );
    }
    final type = rawType!;

    // 2. amount
    final rawAmount =
        fields['amount']?.trim().replaceAll(',', '.').replaceAll(' ', '');
    final amount = double.tryParse(rawAmount ?? '');
    if (amount == null || amount <= 0) {
      return TransactionImportRow(
        rowNumber: rowNumber,
        type: type,
        validationError:
            '"amount" must be a positive number (got "${fields['amount'] ?? ''}")',
      );
    }

    // 3. description (optional)
    final description = fields['description']?.trim() ?? '';

    // 4. date
    final rawDate = fields['date']?.trim();
    DateTime? date;
    if (rawDate != null && rawDate.isNotEmpty) {
      // Normalise common separators (/ and .) to -
      final normalized = rawDate.replaceAll('/', '-').replaceAll('.', '-');
      date = DateTime.tryParse(normalized);
    }
    if (date == null) {
      return TransactionImportRow(
        rowNumber: rowNumber,
        type: type,
        amount: amount,
        description: description,
        validationError:
            '"date" must be in YYYY-MM-DD format (got "${fields['date'] ?? ''}")',
      );
    }

    // 5. category
    final category = _resolveCategory(fields['category']);
    if (category == null) {
      return TransactionImportRow(
        rowNumber: rowNumber,
        type: type,
        amount: amount,
        description: description,
        date: date,
        validationError:
            '"${fields['category'] ?? ''}" is not a valid category.\n'
            'Income: $_validIncomeCategories\n'
            'Expense: $_validExpenseCategories',
      );
    }

    // 6. type/category constraint
    final isIncomeCategory = _incomeCategories.contains(category);
    if (type == 'income' && !isIncomeCategory) {
      return TransactionImportRow(
        rowNumber: rowNumber,
        type: type,
        amount: amount,
        description: description,
        date: date,
        category: category,
        validationError:
            'Category "$category" cannot be used with type "income". '
            'Use an income category (e.g. "Consulting", "Sales").',
      );
    }
    if (type == 'expense' && isIncomeCategory) {
      return TransactionImportRow(
        rowNumber: rowNumber,
        type: type,
        amount: amount,
        description: description,
        date: date,
        category: category,
        validationError:
            'Category "$category" cannot be used with type "expense". '
            'Use an expense category (e.g. "Software", "Rent").',
      );
    }

    // 7. payment_method
    final paymentMethod = _resolvePaymentMethod(fields['payment_method']);
    if (paymentMethod == null) {
      return TransactionImportRow(
        rowNumber: rowNumber,
        type: type,
        amount: amount,
        description: description,
        date: date,
        category: category,
        validationError:
            '"${fields['payment_method'] ?? ''}" is not a valid payment method. '
            'Valid values: Cash, Card, Bank Transfer, MB Way, PayPal, Direct Debit, Other.',
      );
    }

    // All good
    final rawClient = fields['client']?.trim();
    return TransactionImportRow(
      rowNumber: rowNumber,
      amount: amount,
      description: description,
      category: category,
      type: type,
      date: date,
      paymentMethod: paymentMethod,
      client: (rawClient == null || rawClient.isEmpty) ? null : rawClient,
    );
  }

  // ── Header normalisation helper ─────────────────────────────────────────────

  static String _normalizeHeader(dynamic h) =>
      h.toString().trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');

  // ── CSV parsing ─────────────────────────────────────────────────────────────

  List<TransactionImportRow> parseCSV(String content) {
    // Normalise line endings so the converter always sees \n
    final normalised = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    const converter = CsvToListConverter(eol: '\n');
    final rows = converter.convert(normalised);

    if (rows.isEmpty) {
      return [
        const TransactionImportRow(
          rowNumber: 0,
          validationError: 'File is empty.',
        ),
      ];
    }

    final headers = rows.first.map(_normalizeHeader).toList();
    final missing = _checkRequiredHeaders(headers);
    if (missing != null) return [missing];

    final results = <TransactionImportRow>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      // Skip fully blank rows
      if (row.every((cell) => cell?.toString().trim().isEmpty ?? true)) continue;

      final fields = <String, String?>{};
      for (var j = 0; j < headers.length; j++) {
        fields[headers[j]] = j < row.length ? row[j]?.toString() : null;
      }
      results.add(_validateRow(fields, i + 1)); // row 1 = header, so data starts at 2
    }
    return results;
  }

  // ── Excel parsing ───────────────────────────────────────────────────────────

  List<TransactionImportRow> parseExcel(Uint8List bytes) {
    final workbook = Excel.decodeBytes(bytes);

    // Use first non-Reference sheet
    final sheetName = workbook.tables.keys.firstWhere(
      (s) => s.trim().toLowerCase() != 'reference',
      orElse: () => workbook.tables.keys.first,
    );
    final sheet = workbook.tables[sheetName];

    if (sheet == null || sheet.rows.isEmpty) {
      return [
        const TransactionImportRow(
          rowNumber: 0,
          validationError: 'The file appears to be empty.',
        ),
      ];
    }

    final headers = sheet.rows.first.map((cell) {
      return _normalizeHeader(cell?.value ?? '');
    }).toList();

    final missing = _checkRequiredHeaders(headers);
    if (missing != null) return [missing];

    final results = <TransactionImportRow>[];
    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.every((cell) {
        final v = cell?.value;
        return v == null || v.toString().trim().isEmpty;
      })) continue;

      final fields = <String, String?>{};
      for (var j = 0; j < headers.length; j++) {
        if (j >= row.length) {
          fields[headers[j]] = null;
          continue;
        }
        final cellValue = row[j]?.value;
        String? value;
        if (cellValue is DateTime) {
          final dt = cellValue as DateTime;
          value =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        } else if (cellValue != null) {
          value = cellValue.toString();
        }
        fields[headers[j]] = value;
      }
      results.add(_validateRow(fields, i + 1));
    }
    return results;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<TransactionImportRow> validRows(List<TransactionImportRow> rows) =>
      rows.where((r) => r.isValid).toList();

  List<TransactionImportRow> invalidRows(List<TransactionImportRow> rows) =>
      rows.where((r) => !r.isValid).toList();

  /// Detects the date range covered by valid rows.
  /// Returns null if there are no valid rows with dates.
  ({DateTime min, DateTime max})? detectDateRange(
    List<TransactionImportRow> rows,
  ) {
    final dates =
        rows.where((r) => r.isValid && r.date != null).map((r) => r.date!);
    if (dates.isEmpty) return null;
    return (min: dates.reduce((a, b) => a.isBefore(b) ? a : b), max: dates.reduce((a, b) => a.isAfter(b) ? a : b));
  }

  static TransactionImportRow? _checkRequiredHeaders(List<String> headers) {
    const required = [
      'date',
      'type',
      'amount',
      'description',
      'category',
      'payment_method',
    ];
    for (final r in required) {
      if (!headers.contains(r)) {
        return TransactionImportRow(
          rowNumber: 0,
          validationError:
              'Missing required column: "$r". '
              'Expected columns: date, type, amount, description, category, payment_method, client',
        );
      }
    }
    return null;
  }

  // ── Template generation ─────────────────────────────────────────────────────

  /// Writes a ready-to-use Excel template (.xlsx) to the device temp directory.
  /// Sheet 1 "Import": header + sample rows. Sheet 2 "Reference": valid values.
  /// Returns the file path for sharing via share_plus.
  Future<String> writeTemplateToDisk() async {
    final workbook = Excel.createExcel();

    // ── Sheet 1: Import ──────────────────────────────────────────────────────
    workbook.rename('Sheet1', 'Import');
    final importSheet = workbook['Import'];

    final headers = [
      'date', 'type', 'amount', 'description', 'category', 'payment_method', 'client',
    ];
    for (var c = 0; c < headers.length; c++) {
      importSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .value = TextCellValue(headers[c]);
    }

    final samples = [
      ['2025-01-15', 'income',  '5000.00', 'Client project payment', 'Consulting',   'Bank Transfer', 'Acme Corp'],
      ['2025-01-20', 'expense', '120.00',  'Monthly hosting',        'Software',     'Card',          ''],
      ['2025-02-01', 'income',  '3000.00', 'Retainer fee',           'Retainers',    'Bank Transfer', 'Beta Ltd'],
      ['2025-02-10', 'expense', '800.00',  'Office rent',            'Rent',         'Direct Debit',  ''],
    ];
    for (var r = 0; r < samples.length; r++) {
      for (var c = 0; c < samples[r].length; c++) {
        importSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(samples[r][c]);
      }
    }

    // ── Sheet 2: Reference ───────────────────────────────────────────────────
    final refSheet = workbook['Reference'];

    refSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = TextCellValue('Category');
    const categoryLabels = [
      'Sales', 'Freelance', 'Consulting', 'Retainers', 'Subscriptions',
      'Commissions', 'Interest', 'Refunds', 'Other Income',
      'Advertising', 'Software', 'Subscriptions (expense)', 'Equipment',
      'Supplies', 'Accounting', 'Contractors', 'Travel', 'Meals',
      'Rent', 'Insurance', 'Taxes', 'Fees', 'Salaries', 'Training', 'Other Expense',
    ];
    for (var r = 0; r < categoryLabels.length; r++) {
      refSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r + 1))
          .value = TextCellValue(categoryLabels[r]);
    }

    refSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
        .value = TextCellValue('Payment Method');
    const pmLabels = [
      'Cash', 'Card', 'Bank Transfer', 'MB Way', 'PayPal', 'Direct Debit', 'Other',
    ];
    for (var r = 0; r < pmLabels.length; r++) {
      refSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r + 1))
          .value = TextCellValue(pmLabels[r]);
    }

    final bytes = workbook.encode();
    if (bytes == null) throw Exception('Failed to encode Excel template');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/incore_import_template.xlsx');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
