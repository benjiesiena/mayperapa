import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mayperapa/shared/data/database/database_helper.dart';
import 'package:mayperapa/features/settings/services/data_management_service.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  group('DataManagementService — Security & Sanitization Tests (AGENTS.md 5.2 & 5.3)', () {
    late MockDatabaseHelper mockDbHelper;
    late DataManagementService service;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      service = DataManagementService(mockDbHelper);
    });

    test('sanitizes CSV cells starting with dangerous formula operators (=, +, -, @)', () {
      // DDE Formula Injection test vectors
      expect(DataManagementService.sanitizeCsvCell('=SUM(A1:B10)'), equals('"\'=SUM(A1:B10)"'));
      expect(DataManagementService.sanitizeCsvCell('+cmd|/c calc'), equals('"\'+cmd|/c calc"'));
      expect(DataManagementService.sanitizeCsvCell('-123+456'), equals('"\'-123+456"'));
      expect(DataManagementService.sanitizeCsvCell('@IMPORTXML("url")'), equals('"\'@IMPORTXML(""url"")"'));
      expect(DataManagementService.sanitizeCsvCell('\tTabPrefixed'), equals('"\'\tTabPrefixed"'));
      expect(DataManagementService.sanitizeCsvCell('\rCarriageReturn'), equals('"\'\rCarriageReturn"'));
    });

    test('leaves safe normal text values un-prefixed in CSV output', () {
      expect(DataManagementService.sanitizeCsvCell('Groceries'), equals('"Groceries"'));
      expect(DataManagementService.sanitizeCsvCell('Coffee at Starbucks'), equals('"Coffee at Starbucks"'));
      expect(DataManagementService.sanitizeCsvCell('Salary - Monthly'), equals('"Salary - Monthly"'));
      expect(DataManagementService.sanitizeCsvCell(''), equals('""'));
    });

    test('enforces 5MB maximum file size bound on restore payload', () async {
      final hugePayload = 'A' * (5 * 1024 * 1024 + 1);

      expect(
        () => service.restoreBackup(hugePayload, 1),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('exceeds maximum allowable size'))),
      );
    });

    test('rejects payload with prototype pollution keys (__proto__, constructor, prototype)', () async {
      const maliciousPayload = '{"__proto__": {"isAdmin": true}, "transactions": []}';

      expect(
        () => service.restoreBackup(maliciousPayload, 1),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('restricted or dangerous property'))),
      );
    });

    test('enforces 5MB maximum file size bound on CSV import', () async {
      final hugeCsv = 'A' * (5 * 1024 * 1024 + 1);

      expect(
        () => service.importTransactionsCsv(hugeCsv, 1),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('exceeds maximum allowable size'))),
      );
    });
  });
}
