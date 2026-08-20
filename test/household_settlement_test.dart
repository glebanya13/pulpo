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
}
