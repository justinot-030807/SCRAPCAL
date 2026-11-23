import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scrap_models.dart';

class StorageService {
  static const String _itemsKey = 'scrapcal_items_v1';
  static const String _ticketKey = 'scrapcal_active_ticket_v1';
  static const String _historyKey = 'scrapcal_history_v1';

  final SharedPreferences _prefs;

  const StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  List<ScrapItem> loadScrapItems() {
    final raw = _prefs.getString(_itemsKey);
    if (raw == null || raw.isEmpty) {
      final defaults = ScrapItem.defaultItems;
      saveScrapItems(defaults);
      return List<ScrapItem>.from(defaults);
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final items = decoded
          .whereType<Map<String, dynamic>>()
          .map(ScrapItem.fromJson)
          .where((item) => item.name.trim().isNotEmpty)
          .toList();
      if (items.isEmpty) {
        final defaults = ScrapItem.defaultItems;
        saveScrapItems(defaults);
        return List<ScrapItem>.from(defaults);
      }
      return items;
    } catch (_) {
      final defaults = ScrapItem.defaultItems;
      saveScrapItems(defaults);
      return List<ScrapItem>.from(defaults);
    }
  }

  Future<void> saveScrapItems(List<ScrapItem> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_itemsKey, encoded);
  }

  List<TicketLine> loadActiveTicket() {
    final raw = _prefs.getString(_ticketKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(TicketLine.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveActiveTicket(List<TicketLine> lines) async {
    final encoded = jsonEncode(lines.map((e) => e.toJson()).toList());
    await _prefs.setString(_ticketKey, encoded);
  }

  List<ScrapTransaction> loadHistory() {
    final raw = _prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ScrapTransaction.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<ScrapTransaction> history) async {
    final encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await _prefs.setString(_historyKey, encoded);
  }
}
