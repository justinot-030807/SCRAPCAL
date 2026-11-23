import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrapcal/main.dart';
import 'package:scrapcal/models/scrap_models.dart';
import 'package:scrapcal/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ScrapMath & Model Serialization', () {
    test('avoids floating-point artifacts and formats fractions/pesos', () {
      expect(ScrapMath.roundWeight(0.1 + 0.2), equals(0.3));
      expect(ScrapMath.roundPeso(1.25 * 15.0), equals(18.75));
      expect(ScrapMath.formatPeso(1250.5), equals('₱1,250.50'));
      expect(ScrapMath.fractionLabel(0.25), equals('¼'));
      expect(ScrapMath.fractionLabel(0.5), equals('½'));
      expect(ScrapMath.fractionLabel(0.75), equals('¾'));
      expect(ScrapMath.fractionLabel(1.25), equals('1¼'));
      expect(
        ScrapMath.formatQuantity(1.25, ScrapUnit.perKg),
        equals('1.25 kg (1¼)'),
      );
      expect(
        ScrapMath.formatQuantity(15, ScrapUnit.perPiece),
        equals('15 pcs'),
      );
    });

    test('serializes and deserializes ScrapTransaction cleanly', () {
      final line = TicketLine(
        id: 'l1',
        itemId: 'bakal',
        itemName: 'Bakal',
        unit: ScrapUnit.perKg,
        quantity: 1.25,
        unitPrice: 15.0,
      );
      final tx = ScrapTransaction(
        id: 't1',
        timestamp: DateTime(2026, 11, 23, 11, 20),
        lines: [line],
        grandTotal: 18.75,
      );

      final restored = ScrapTransaction.fromJson(tx.toJson());
      expect(restored.id, equals('t1'));
      expect(restored.grandTotal, equals(18.75));
      expect(
        restored.lines.first.formattedTapeSummary,
        equals('Bakal · 1.25 kg (1¼) × ₱15.00 = ₱18.75'),
      );
      expect(restored.formattedTimestamp, equals('Nov 23 · 11:20 AM'));
    });
  });

  group('SCRAPCAL Calculator Widget Flow', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init();
    });

    testWidgets(
      'computes kg fractions, switches to per-piraso increments, confirms Bagong Lista, and saves ticket to History',
      (WidgetTester tester) async {
        await tester.pumpWidget(ScrapCalApp(storage: storage));

        // Verify instant launch into calculator with 2-row seeded default chips & draft label
        expect(find.text('SCRAPCAL'), findsOneWidget);
        expect(find.text('Tinitimbang ngayon:'), findsOneWidget);
        expect(find.text('Bakal ₱15/kg'), findsOneWidget);
        expect(find.text('Plastic ₱10/kg'), findsOneWidget);
        expect(find.text('Tanso ₱350/kg'), findsOneWidget);
        expect(find.text('Bote ₱1/pc'), findsOneWidget);
        expect(find.text('ULITIN'), findsOneWidget);
        expect(find.text('Bagong Lista'), findsOneWidget);

        // Verify 3 kg quick-add fraction keys are visible for Bakal (no redundant +1.00 key)
        expect(find.byKey(const Key('quick_add_kg_025')), findsOneWidget);
        expect(find.byKey(const Key('quick_add_kg_050')), findsOneWidget);
        expect(find.byKey(const Key('quick_add_kg_075')), findsOneWidget);
        expect(find.byKey(const Key('quick_add_kg_100')), findsNothing);

        // Tap digit 1 on numpad and +1/4 quick-add -> 1.25 kg (1¼) of Bakal @ ₱15.00 = ₱18.75
        await tester.tap(find.byKey(const Key('key_1')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('quick_add_kg_025')));
        await tester.pump();

        expect(find.text('1.25 kg (1¼)'), findsOneWidget);
        expect(find.text('× ₱15.00/kg'), findsOneWidget);
        expect(find.text('₱18.75'), findsNWidgets(2)); // subtotal & grand total

        // Test ULITIN and long-press backspace clearing input
        await tester.tap(find.byKey(const Key('key_clear')));
        await tester.pump();
        expect(find.text('0 kg'), findsOneWidget);

        // Re-enter 1.25 kg and add to list
        await tester.tap(find.byKey(const Key('key_1')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('quick_add_kg_025')));
        await tester.pump();

        // Tap + DAGDAG to append Bakal to the running ticket tape
        await tester.tap(find.byKey(const Key('key_dagdag')));
        await tester.pump();

        expect(
          find.text('Bakal · 1.25 kg (1¼) × ₱15.00 = ₱18.75'),
          findsOneWidget,
        );

        // Verify Bagong Lista confirmation dialog protects against accidental clears
        await tester.tap(find.byKey(const Key('reset_ticket_btn')));
        await tester.pumpAndSettle();
        expect(find.text('Burahin lahat ng nakalista?'), findsOneWidget);
        await tester.tap(find.text('Hindi'));
        await tester.pumpAndSettle();
        expect(
          find.text('Bakal · 1.25 kg (1¼) × ₱15.00 = ₱18.75'),
          findsOneWidget,
        );

        // Select Bote (per piraso)
        await tester.tap(find.byKey(const Key('chip_bote')));
        await tester.pump();

        // Verify quick-add keys switch to 3 whole-number buttons: +1, +5, +10
        expect(find.byKey(const Key('quick_add_pc_1')), findsOneWidget);
        expect(find.byKey(const Key('quick_add_pc_5')), findsOneWidget);
        expect(find.byKey(const Key('quick_add_pc_10')), findsOneWidget);
        expect(find.byKey(const Key('quick_add_pc_20')), findsNothing);

        // Tap +10 and +5 -> 15 pcs of Bote @ ₱1.00 = ₱15.00
        await tester.tap(find.byKey(const Key('quick_add_pc_10')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('quick_add_pc_5')));
        await tester.pump();

        // Verify decimal key is disabled for per-piece item
        await tester.tap(find.byKey(const Key('key_dot')));
        await tester.pump();
        expect(find.text('15 pcs'), findsOneWidget);
        expect(find.text('× ₱1.00/pc'), findsOneWidget);

        // Grand total should now be ₱18.75 + ₱15.00 = ₱33.75
        expect(find.text('₱33.75'), findsOneWidget);

        // Tap SAVE (automatically includes active 15 pcs Bote + tape Bakal)
        await tester.tap(find.byKey(const Key('key_save')));
        await tester.pump();

        // Open History screen and verify saved transaction & Total Ngayon
        await tester.tap(find.byKey(const Key('nav_history_btn')));
        await tester.pumpAndSettle();

        expect(find.text('Total Ngayon'), findsOneWidget);
        expect(find.byKey(const Key('today_total_payout')), findsOneWidget);
        expect(find.text('₱33.75'), findsNWidgets(2));
        expect(find.text('Bakal · 1.25 kg (1¼) × ₱15.00'), findsOneWidget);
        expect(find.text('Bote · 15 pcs × ₱1.00'), findsOneWidget);
      },
    );

    testWidgets('adds custom scrap item in Presyo screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(ScrapCalApp(storage: storage));

      await tester.tap(find.byKey(const Key('nav_presyo_btn')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('new_scrap_name_field')),
        'Aluminum',
      );
      await tester.enterText(
        find.byKey(const Key('new_scrap_price_field')),
        '65',
      );
      await tester.tap(find.byKey(const Key('add_scrap_submit_btn')));
      await tester.pumpAndSettle();

      // Navigate back to Calculator
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Aluminum ₱65/kg'), findsOneWidget);
    });
  });
}
