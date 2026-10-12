import 'package:flutter_test/flutter_test.dart';
import 'package:mayperapa/shared/domain/entities/category.dart';
import 'package:mayperapa/shared/domain/entities/account.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';

void main() {
  group('Default Seeding Integrity', () {
    test('Category.defaults provides valid expense and income categories', () {
      final defaults = Category.defaults();
      expect(defaults.isNotEmpty, isTrue);

      for (final cat in defaults) {
        expect(cat['name'], isA<String>());
        expect((cat['name'] as String).isNotEmpty, isTrue);
        expect(cat['type'], isIn(['expense', 'income', 'transfer']));
        expect(cat['icon'], isA<String>());
        expect(cat['color'], isA<String>());
      }

      final expenseCats = defaults.where((c) => c['type'] == 'expense');
      final incomeCats = defaults.where((c) => c['type'] == 'income');
      expect(expenseCats.isNotEmpty, isTrue);
      expect(incomeCats.isNotEmpty, isTrue);
    });

    test('Account.defaults provides valid initial accounts with correct currency', () {
      final defaults = Account.defaults(currencyCode: 'PHP');
      expect(defaults.length, greaterThanOrEqualTo(2));

      for (final acc in defaults) {
        expect(acc['name'], isA<String>());
        expect((acc['name'] as String).isNotEmpty, isTrue);
        expect(acc['currency_code'], equals('PHP'));
        expect(acc['balance'], equals(0.0));
        // Verify type deserializes cleanly via AccountTypeX
        expect(() => AccountTypeX.fromDb(acc['type'] as String), returnsNormally);
      }

      final accountNames = defaults.map((a) => a['name']).toList();
      expect(accountNames, contains('Cash'));
      expect(accountNames, contains('Main Bank'));
    });
  });
}
