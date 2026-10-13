import 'dart:convert';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../../../shared/data/database/database_helper.dart';
import '../../../../shared/data/repositories/account_repository_impl.dart';
import '../../../../shared/data/repositories/category_repository_impl.dart';

/// Service responsible for Data Export, Import, Backup, Restore, and Data Hygiene.
/// Implements AGENTS.md 5.2 (CSV DDE sanitization, 5MB file bound) and 5.3 (prototype pollution guards).
class DataManagementService {
  final DatabaseHelper _dbHelper;
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB ceiling per AGENTS.md 5.2

  DataManagementService(this._dbHelper);

  /// Sanitize cell values against CSV Formula Injection (DDE).
  /// If a string begins with dangerous operators (=, +, -, @, \t, \r), prepend a single quote (').
  static String sanitizeCsvCell(String value) {
    if (value.isEmpty) return '""';
    final trimmed = value.trim();
    if (value.startsWith('\t') ||
        value.startsWith('\r') ||
        trimmed.startsWith('=') ||
        trimmed.startsWith('+') ||
        trimmed.startsWith('-') ||
        trimmed.startsWith('@')) {
      return '"\'${value.replaceAll('"', '""')}"';
    }
    return '"${value.replaceAll('"', '""')}"';
  }

  /// Exports transactions to CSV format with formula injection mitigation.
  Future<String> exportTransactionsCsv(int userId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT t.id, t.date, t.type, t.amount, c.name as category, a.name as account, t.description, t.notes
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE t.user_id = ?
      ORDER BY t.date DESC
    ''', [userId]);

    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('ID,Date,Type,Amount,Category,Account,Description,Notes');

    for (final row in rows) {
      final date = DateTime.fromMillisecondsSinceEpoch((row['date'] as int?) ?? 0).toIso8601String();
      final type = (row['type'] as String?) ?? 'expense';
      final amount = ((row['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2);
      final category = (row['category'] as String?) ?? 'Uncategorized';
      final account = (row['account'] as String?) ?? 'Main Account';
      final desc = (row['description'] as String?) ?? '';
      final notes = (row['notes'] as String?) ?? '';

      buffer.writeln([
        row['id'].toString(),
        sanitizeCsvCell(date),
        sanitizeCsvCell(type),
        amount, // pure numeric
        sanitizeCsvCell(category),
        sanitizeCsvCell(account),
        sanitizeCsvCell(desc),
        sanitizeCsvCell(notes),
      ].join(','));
    }

    return buffer.toString();
  }

  /// Exports all financial entities (accounts, categories, transactions, budgets, goals) to JSON.
  Future<String> exportDataJson(int userId) async {
    final db = await _dbHelper.database;

    final accounts = await db.query('accounts', where: 'user_id = ?', whereArgs: [userId]);
    final categories = await db.query('categories', where: 'user_id = ?', whereArgs: [userId]);
    final transactions = await db.query('transactions', where: 'user_id = ?', whereArgs: [userId]);
    final budgets = await db.query('budgets', where: 'user_id = ?', whereArgs: [userId]);
    final goals = await db.query('financial_goals', where: 'user_id = ?', whereArgs: [userId]);

    final data = {
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'userId': userId,
      'accounts': accounts,
      'categories': categories,
      'transactions': transactions,
      'budgets': budgets,
      'financial_goals': goals,
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Creates a complete system backup snapshot with metadata.
  Future<String> createBackup(int userId) async {
    final jsonContent = await exportDataJson(userId);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Update last_backup_date in app_settings
    final db = await _dbHelper.database;
    await db.update(
      'app_settings',
      {'last_backup_date': now},
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return jsonContent;
  }

  /// Restores system state from a backup JSON payload defensively.
  Future<Map<String, int>> restoreBackup(String jsonContent, int userId) async {
    // 1. File size bound check (AGENTS.md 5.2)
    if (jsonContent.length > maxFileSizeBytes) {
      throw const FormatException('Import payload exceeds maximum allowable size (5MB).');
    }

    // 2. Prototype pollution check (AGENTS.md 5.3)
    if (jsonContent.contains('__proto__') ||
        jsonContent.contains('constructor') ||
        jsonContent.contains('prototype')) {
      throw const FormatException('Payload contains restricted or dangerous property names.');
    }

    final dynamic parsed = jsonDecode(jsonContent);
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup structure: root must be a JSON object.');
    }

    final schemaVersion = parsed['schemaVersion'] as int?;
    if (schemaVersion == null || schemaVersion > 1) {
      throw const FormatException('Unsupported backup schema version.');
    }

    final db = await _dbHelper.database;
    int importedTx = 0;
    int importedBudgets = 0;
    int importedGoals = 0;

    await db.transaction((txn) async {
      // Restore transactions if present
      if (parsed['transactions'] is List) {
        for (final item in parsed['transactions'] as List) {
          if (item is Map<String, dynamic>) {
            final txMap = Map<String, dynamic>.from(item);
            txMap.remove('id'); // Regenerate local autoincrement ID
            txMap['user_id'] = userId;
            await txn.insert('transactions', txMap, conflictAlgorithm: ConflictAlgorithm.replace);
            importedTx++;
          }
        }
      }

      // Restore budgets if present
      if (parsed['budgets'] is List) {
        for (final item in parsed['budgets'] as List) {
          if (item is Map<String, dynamic>) {
            final bMap = Map<String, dynamic>.from(item);
            bMap.remove('id');
            bMap['user_id'] = userId;
            await txn.insert('budgets', bMap, conflictAlgorithm: ConflictAlgorithm.replace);
            importedBudgets++;
          }
        }
      }

      // Restore goals if present
      if (parsed['financial_goals'] is List) {
        for (final item in parsed['financial_goals'] as List) {
          if (item is Map<String, dynamic>) {
            final gMap = Map<String, dynamic>.from(item);
            gMap.remove('id');
            gMap['user_id'] = userId;
            await txn.insert('financial_goals', gMap, conflictAlgorithm: ConflictAlgorithm.replace);
            importedGoals++;
          }
        }
      }
    });

    return {
      'transactions': importedTx,
      'budgets': importedBudgets,
      'goals': importedGoals,
    };
  }

  /// Defensive CSV import of transactions.
  Future<int> importTransactionsCsv(String csvContent, int userId) async {
    if (csvContent.length > maxFileSizeBytes) {
      throw const FormatException('CSV file exceeds maximum allowable size (5MB).');
    }

    final lines = const LineSplitter().convert(csvContent);
    if (lines.length <= 1) return 0; // Empty or header-only

    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    int count = 0;

    // Get default account & category
    final accRows = await db.query('accounts', where: 'user_id = ?', whereArgs: [userId], limit: 1);
    final defaultAccountId = accRows.isNotEmpty ? (accRows.first['id'] as int) : 1;

    final catRows = await db.query('categories', where: 'user_id = ?', whereArgs: [userId], limit: 1);
    final defaultCategoryId = catRows.isNotEmpty ? (catRows.first['id'] as int) : 1;

    await db.transaction((txn) async {
      // Skip header line (index 0)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = _parseCsvLine(line);
        if (parts.length >= 4) {
          final type = parts[2].toLowerCase().contains('income') ? 'income' : 'expense';
          final amount = double.tryParse(parts[3].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          if (amount <= 0) continue;

          final desc = parts.length > 6 ? parts[6] : (parts.length > 4 ? parts[4] : 'Imported');

          await txn.insert('transactions', {
            'user_id': userId,
            'account_id': defaultAccountId,
            'category_id': defaultCategoryId,
            'type': type,
            'amount': amount,
            'description': desc,
            'notes': 'Imported via CSV',
            'date': now,
            'created_at': now,
            'updated_at': now,
          });
          count++;
        }
      }
    });

    return count;
  }

  /// Completely wipes financial data and restores clean starter accounts & categories.
  Future<void> clearAllData(int userId) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Delete transactions & recurring
      await txn.delete('transactions', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('recurring_transactions', where: 'user_id = ?', whereArgs: [userId]);

      // 2. Delete budgets & budget items
      await txn.rawDelete('''
        DELETE FROM budget_items WHERE budget_id IN (SELECT id FROM budgets WHERE user_id = ?)
      ''', [userId]);
      await txn.delete('budgets', where: 'user_id = ?', whereArgs: [userId]);

      // 3. Delete financial goals
      await txn.delete('financial_goals', where: 'user_id = ?', whereArgs: [userId]);

      // 4. Delete AI conversation history & insights
      await txn.rawDelete('''
        DELETE FROM ai_messages WHERE conversation_id IN (SELECT id FROM ai_conversations WHERE user_id = ?)
      ''', [userId]);
      await txn.delete('ai_conversations', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('ai_insights', where: 'user_id = ?', whereArgs: [userId]);

      // 5. Delete accounts & categories to re-seed cleanly
      await txn.delete('accounts', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('categories', where: 'user_id = ?', whereArgs: [userId]);
    });

    // 6. Re-seed default categories and accounts
    final catRepo = CategoryRepositoryImpl(_dbHelper);
    await catRepo.seedDefaults(userId);

    final accRepo = AccountRepositoryImpl(_dbHelper);
    await accRepo.seedDefaults(userId, currencyCode: 'PHP');
  }

  /// Clears only AI messages and conversational history from SQLite.
  Future<void> clearAiMemory(int userId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.rawDelete('''
        DELETE FROM ai_messages WHERE conversation_id IN (SELECT id FROM ai_conversations WHERE user_id = ?)
      ''', [userId]);
      await txn.delete('ai_conversations', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('ai_insights', where: 'user_id = ?', whereArgs: [userId]);
    });
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++; // skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }
}
