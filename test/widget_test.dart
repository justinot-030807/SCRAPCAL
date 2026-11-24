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

    test(
      'serializes and deserializes ScrapTransaction with optional recipientName backwards-compatibly',
      () {
        final line = TicketLine(
          id: 'l1',
          itemId: 'bakal',
          itemName: 'Bakal',
          unit: ScrapUnit.perKg,
          quantity: 1.25,
          unitPrice: 15.0,
        );

        // Legacy JSON without recipientName
        final legacyJson = <String, dynamic>{
          'id': 't0',
          'timestamp': DateTime(2026, 11, 23, 11, 20).toIso8601String(),
          'lines': [line.toJson()],
          'grandTotal': 18.75,
        };
        final legacyTx = ScrapTransaction.fromJson(legacyJson);
        expect(legacyTx.recipientName, isNull);
        expect(legacyTx.grandTotal, equals(18.75));
        expect(
          legacyTx.lines.first.formattedTapeSummary,
          equals('Bakal · 1.25 kg (1¼) × ₱15.00 = ₱18.75'),
        );
        expect(legacyTx.formattedTimestamp, equals('Nov 23 · 11:20 AM'));

        // New JSON with recipientName
        final namedTx = legacyTx.copyWith(recipientName: 'Mang Juan');
        final restored = ScrapTransaction.fromJson(namedTx.toJson());
        expect(restored.recipientName, equals('Mang Juan'));
        expect(restored.normalizedRecipientName, equals('Mang Juan'));
      },
    );
  });

  group('SCRAPCAL Simplified UI, Drawer, Settings & Receipt Flow', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init();
    });

    testWidgets(
      'renders minimalist top bar, removes quick-add row, types decimals, saves to History, and updates PNG receipt recipient',
      (WidgetTester tester) async {
        // Test under large system font scale (2.0x) to verify clamped text scaling prevents overflow
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(ScrapCalApp(storage: storage));

        // Verify minimalist top bar (menu icon + SCRAPCAL only, no Presyo/History buttons on bar)
        expect(find.byKey(const Key('drawer_menu_btn')), findsOneWidget);
        expect(find.text('SCRAPCAL'), findsOneWidget);
        expect(find.text('Presyo'), findsNothing);
        expect(find.text('History'), findsNothing);

        // Verify quick-add row is completely removed
        expect(find.text('+1/4'), findsNothing);
        expect(find.text('+1/2'), findsNothing);
        expect(find.text('+3/4'), findsNothing);
        expect(find.text('+10'), findsNothing);

        // Verify single-language Tagalog labels (no double/bilingual labels)
        expect(find.text('Kabuuan'), findsOneWidget);
        expect(find.text('KABUUAN / TOTAL'), findsNothing);
        expect(find.text('Ulit'), findsOneWidget);
        expect(find.text('+ Dagdag'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('TAPOS NA'), findsNothing);

        // Verify single-row scrap chips
        expect(find.text('Bakal ₱15/kg'), findsOneWidget);
        expect(find.text('Plastic ₱10/kg'), findsOneWidget);
        expect(find.text('Tanso ₱350/kg'), findsOneWidget);
        expect(find.text('Bote ₱1/pc'), findsOneWidget);

        // Type 1.25 kg directly on numpad for Bakal @ ₱15.00 = ₱18.75
        await tester.tap(find.byKey(const Key('key_1')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('key_dot')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('key_2')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('key_5')));
        await tester.pump();

        expect(find.text('1.25 kg (1¼)'), findsOneWidget);
        expect(find.text('× ₱15.00/kg'), findsOneWidget);
        expect(find.text('₱18.75'), findsNWidgets(2));

        // Tap + Dagdag -> adds to tape and immediately resets active input to 0 kg
        await tester.tap(find.byKey(const Key('key_dagdag')));
        await tester.pump();

        expect(find.text('0 kg'), findsOneWidget);
        expect(
          find.text('Bakal · 1.25 kg (1¼) × ₱15.00 = ₱18.75'),
          findsOneWidget,
        );

        // Select Bote (per piraso) -> '.' must be disabled
        await tester.ensureVisible(find.byKey(const Key('chip_bote')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('chip_bote')));
        await tester.pump();

        await tester.tap(find.byKey(const Key('key_1')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('key_dot')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('key_5')));
        await tester.pump();

        expect(find.text('15 pcs'), findsOneWidget);
        expect(find.text('₱33.75'), findsOneWidget);

        // Tap Save -> saves transaction and resets ticket
        await tester.tap(find.byKey(const Key('key_save')));
        await tester.pump();

        // Open Hamburger Drawer and verify menu items + pinned developer credit
        await tester.tap(find.byKey(const Key('drawer_menu_btn')));
        await tester.pumpAndSettle();

        expect(find.text('Junkshop Calculator'), findsOneWidget);
        expect(find.text('Developed by Justine S. Lachica'), findsOneWidget);
        expect(find.byKey(const Key('drawer_presyo_item')), findsOneWidget);
        expect(find.byKey(const Key('drawer_history_item')), findsOneWidget);
        expect(find.byKey(const Key('drawer_settings_item')), findsOneWidget);

        // Navigate to History via Drawer
        await tester.tap(find.byKey(const Key('drawer_history_item')));
        await tester.pumpAndSettle();

        expect(find.text('Total Ngayon'), findsOneWidget);
        expect(find.text('₱33.75'), findsNWidgets(2));
        expect(find.text('Resibo'), findsOneWidget);

        // Open Receipt Preview modal and enter optional recipient name
        await tester.tap(find.text('Resibo'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('receipt_paper_card')), findsOneWidget);
        expect(find.text('RESIBO'), findsOneWidget);
        expect(find.text('Salamat!'), findsOneWidget);
        expect(find.byKey(const Key('receipt_save_png_btn')), findsOneWidget);
        expect(find.byKey(const Key('receipt_share_png_btn')), findsOneWidget);

        // Enter recipient name -> updates live preview and persists to History
        await tester.enterText(
          find.byKey(const Key('receipt_recipient_field')),
          'Mang Juan',
        );
        await tester.pump();

        expect(
          find.byKey(const Key('receipt_preview_recipient')),
          findsOneWidget,
        );
        expect(find.text('Pangalan: Mang Juan'), findsNWidgets(2));

        // Close Receipt modal and verify recipient persists on History card & storage
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.text('Pangalan: Mang Juan'), findsOneWidget);
        expect(
          storage.loadHistory().first.recipientName,
          equals('Mang Juan'),
        );
      },
    );

    testWidgets(
      'navigates to Settings via Drawer, switches to English and Dark Mode, and updates UI live',
      (WidgetTester tester) async {
        await tester.pumpWidget(ScrapCalApp(storage: storage));

        // Open Drawer -> Settings
        await tester.tap(find.byKey(const Key('drawer_menu_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('drawer_settings_item')));
        await tester.pumpAndSettle();

        expect(find.text('Wika'), findsOneWidget);
        expect(find.text('Tema'), findsOneWidget);
        expect(find.text('Developed by Justine S. Lachica'), findsOneWidget);

        // Switch Language to English and Theme to Dark Mode
        await tester.tap(find.byKey(const Key('lang_english_btn')));
        await tester.pumpAndSettle();
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Theme'), findsOneWidget);

        await tester.tap(find.byKey(const Key('theme_dark_btn')));
        await tester.pumpAndSettle();

        // Navigate back to Calculator
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Verify Calculator updated to English + Dark Mode (#121212 scaffold)
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('Clear'), findsOneWidget);
        expect(find.text('+ Add'), findsNWidgets(2)); // selector chip + keypad key
        expect(find.text('Current item:'), findsOneWidget);

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.backgroundColor, equals(const Color(0xFF121212)));
        expect(storage.loadDarkMode(), isTrue);
        expect(storage.loadLanguage().code, equals('en'));
      },
    );

    testWidgets('adds custom scrap item in Presyo via Drawer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(ScrapCalApp(storage: storage));

      await tester.tap(find.byKey(const Key('drawer_menu_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drawer_presyo_item')));
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

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Aluminum ₱65/kg'), findsOneWidget);
    });
  });
}
