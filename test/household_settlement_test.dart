import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/features/shared_budget/household_service.dart';

void main() {
  test('settlement even when totals match', () {
    final entries = [
      SharedEntry(
        id: '1',
        uid: 'a',
        amount: 100,
        currency: 'EUR',
        categoryName: 'food',
        categoryIcon: 'utensils',
        categoryColor: 0,
        date: DateTime(2026, 8, 5),
      ),
      SharedEntry(
        id: '2',
        uid: 'b',
        amount: 100,
        currency: 'EUR',
        categoryName: 'food',
        categoryIcon: 'utensils',
        categoryColor: 0,
        date: DateTime(2026, 8, 6),
      ),
    ];
    final s = HouseholdService.settlement(
      entries: entries,
      myUid: 'a',
      partnerUid: 'b',
      currency: 'EUR',
    );
    expect(s.even, isTrue);
  });

  test('settlement partner owes when you spent more', () {
    final entries = [
      SharedEntry(
        id: '1',
        uid: 'a',
        amount: 150,
        currency: 'EUR',
        categoryName: 'rent',
        categoryIcon: 'home',
        categoryColor: 0,
        date: DateTime(2026, 8, 1),
      ),
      SharedEntry(
        id: '2',
        uid: 'b',
        amount: 50,
        currency: 'EUR',
        categoryName: 'food',
        categoryIcon: 'utensils',
        categoryColor: 0,
        date: DateTime(2026, 8, 2),
      ),
    ];
    final s = HouseholdService.settlement(
      entries: entries,
      myUid: 'a',
      partnerUid: 'b',
      currency: 'EUR',
    );
    expect(s.even, isFalse);
    expect(s.partnerOwesYou, 100);
    expect(s.youOwe, 0);
  });

  test('settlement converts foreign currency via rates', () {
    final entries = [
      SharedEntry(
        id: '1',
        uid: 'a',
        amount: 100, // USD
        currency: 'USD',
        categoryName: 'food',
        categoryIcon: 'utensils',
        categoryColor: 0,
        date: DateTime(2026, 8, 5),
      ),
      SharedEntry(
        id: '2',
        uid: 'b',
        amount: 50, // EUR
        currency: 'EUR',
        categoryName: 'food',
        categoryIcon: 'utensils',
        categoryColor: 0,
        date: DateTime(2026, 8, 6),
      ),
    ];
    final s = HouseholdService.settlement(
      entries: entries,
      myUid: 'a',
      partnerUid: 'b',
      currency: 'EUR',
      ratesToBase: const {'USD': 0.9, 'EUR': 1.0},
    );
    // a: 90 EUR, b: 50 EUR → partner owes 40
    expect(s.partnerOwesYou, closeTo(40, 0.01));
  });

  test('settlement skips unknown FX instead of mixing units', () {
    final entries = [
      SharedEntry(
        id: '1',
        uid: 'a',
        amount: 100,
        currency: 'JPY',
        categoryName: 'food',
        categoryIcon: 'utensils',
        categoryColor: 0,
        date: DateTime(2026, 8, 5),
      ),
      SharedEntry(
        id: '2',
        uid: 'b',
        amount: 40,
        currency: 'EUR',
        categoryName: 'food',
        categoryIcon: 'utensils',
        categoryColor: 0,
        date: DateTime(2026, 8, 6),
      ),
    ];
    final s = HouseholdService.settlement(
      entries: entries,
      myUid: 'a',
      partnerUid: 'b',
      currency: 'EUR',
    );
    expect(s.youOwe, 40);
    expect(s.yourTotal, 0);
  });
}
