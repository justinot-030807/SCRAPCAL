enum ScrapUnit {
  perKg,
  perPiece;

  String get shortLabel => this == ScrapUnit.perKg ? 'kg' : 'pc';
  String get pluralLabel => this == ScrapUnit.perKg ? 'kg' : 'pcs';
  String get displayLabel => this == ScrapUnit.perKg ? 'per kg' : 'per piraso';
  String get toggleLabel =>
      this == ScrapUnit.perKg ? 'Per Kilo (kg)' : 'Per Piraso (pcs)';

  static ScrapUnit fromJson(String? value) {
    return value == 'perPiece' ? ScrapUnit.perPiece : ScrapUnit.perKg;
  }

  String toJson() => name;
}

class ScrapMath {
  /// Rounds weight cleanly up to 3 decimal places to prevent floating-point drift.
  static double roundWeight(double value) {
    if (value.isNaN || value.isInfinite || value < 0) return 0.0;
    return (value * 1000).roundToDouble() / 1000.0;
  }

  /// Rounds peso amounts cleanly to 2 decimal places.
  static double roundPeso(double value) {
    if (value.isNaN || value.isInfinite || value < 0) return 0.0;
    return (value * 100).roundToDouble() / 100.0;
  }

  /// Formats a peso amount as `₱#,##0.00`.
  static String formatPeso(double value) {
    final clean = roundPeso(value);
    final fixed = clean.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }
    return '₱${buffer.toString()}.$decPart';
  }

  /// Formats a compact price for selector chips (e.g., `₱15` or `₱15.50`).
  static String formatCompactPeso(double value) {
    final clean = roundPeso(value);
    final cents = (clean * 100).round() % 100;
    if (cents == 0) {
      final intPart = clean.round().toString();
      final buffer = StringBuffer();
      for (int i = 0; i < intPart.length; i++) {
        if (i > 0 && (intPart.length - i) % 3 == 0) {
          buffer.write(',');
        }
        buffer.write(intPart[i]);
      }
      return '₱${buffer.toString()}';
    }
    return formatPeso(clean);
  }

  /// Formats a clean numeric string without unnecessary trailing zeros (up to 3 decimals).
  static String formatCleanNumber(double value) {
    final clean = roundWeight(value);
    if (clean == clean.roundToDouble()) {
      return clean.round().toString();
    }
    String s = clean.toStringAsFixed(3);
    while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// Returns a human-readable fraction label for common quarter-kilo increments
  /// (e.g. `¼`, `½`, `¾`, `1¼`, `2½`), or `null` if not a quarter fraction.
  static String? fractionLabel(double value) {
    final clean = roundWeight(value);
    if (clean <= 0) return null;
    final whole = clean.floor();
    final remMillis = ((clean - whole) * 1000).round();
    String? glyph;
    if (remMillis == 250) {
      glyph = '¼';
    } else if (remMillis == 500) {
      glyph = '½';
    } else if (remMillis == 750) {
      glyph = '¾';
    }
    if (glyph == null) return null;
    return whole > 0 ? '$whole$glyph' : glyph;
  }

  /// Formats quantity with unit and optional fraction label, e.g.:
  /// `0.25 kg (¼)`, `1.25 kg (1¼)`, `2 kg`, `15 pcs`.
  static String formatQuantity(double quantity, ScrapUnit unit) {
    if (unit == ScrapUnit.perPiece) {
      final count = quantity.round();
      return '$count pcs';
    }
    final clean = roundWeight(quantity);
    final numStr = formatCleanNumber(clean);
    final frac = fractionLabel(clean);
    if (frac != null) {
      return '$numStr kg ($frac)';
    }
    return '$numStr kg';
  }

  /// Formats a timestamp as `Nov 23 · 11:20 AM`.
  static String formatTimestamp(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[(dt.month - 1).clamp(0, 11)];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dt.day} · $hour12:$minute $period';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class ScrapItem {
  final String id;
  final String name;
  final ScrapUnit unit;
  final double price;

  const ScrapItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
  });

  static List<ScrapItem> get defaultItems => const [
    ScrapItem(
      id: 'bakal',
      name: 'Bakal',
      unit: ScrapUnit.perKg,
      price: 15.00,
    ),
    ScrapItem(
      id: 'plastic',
      name: 'Plastic',
      unit: ScrapUnit.perKg,
      price: 10.00,
    ),
    ScrapItem(
      id: 'tanso',
      name: 'Tanso',
      unit: ScrapUnit.perKg,
      price: 350.00,
    ),
    ScrapItem(
      id: 'bote',
      name: 'Bote',
      unit: ScrapUnit.perPiece,
      price: 1.00,
    ),
  ];

  String get chipLabel =>
      '$name ${ScrapMath.formatCompactPeso(price)}/${unit.shortLabel}';

  String get formattedUnitRate =>
      '${ScrapMath.formatPeso(price)} / ${unit.shortLabel}';

  ScrapItem copyWith({
    String? id,
    String? name,
    ScrapUnit? unit,
    double? price,
  }) {
    return ScrapItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      price: price != null ? ScrapMath.roundPeso(price) : this.price,
    );
  }

  factory ScrapItem.fromJson(Map<String, dynamic> json) {
    return ScrapItem(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      unit: ScrapUnit.fromJson(json['unit'] as String?),
      price: ScrapMath.roundPeso(((json['price'] as num?) ?? 0).toDouble()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'unit': unit.toJson(),
    'price': ScrapMath.roundPeso(price),
  };
}

class TicketLine {
  final String id;
  final String itemId;
  final String itemName;
  final ScrapUnit unit;
  final double quantity;
  final double unitPrice;

  const TicketLine({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => ScrapMath.roundPeso(quantity * unitPrice);

  String get formattedQuantity => ScrapMath.formatQuantity(quantity, unit);

  String get formattedCalculation =>
      '$formattedQuantity × ${ScrapMath.formatPeso(unitPrice)}';

  String get formattedTapeSummary =>
      '$itemName · $formattedQuantity × ${ScrapMath.formatPeso(unitPrice)} = ${ScrapMath.formatPeso(subtotal)}';

  factory TicketLine.fromJson(Map<String, dynamic> json) {
    final unit = ScrapUnit.fromJson(json['unit'] as String?);
    final rawQty = ((json['quantity'] as num?) ?? 0).toDouble();
    return TicketLine(
      id: (json['id'] as String?) ?? '',
      itemId: (json['itemId'] as String?) ?? '',
      itemName: (json['itemName'] as String?) ?? '',
      unit: unit,
      quantity: unit == ScrapUnit.perPiece
          ? rawQty.roundToDouble()
          : ScrapMath.roundWeight(rawQty),
      unitPrice: ScrapMath.roundPeso(
        ((json['unitPrice'] as num?) ?? 0).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'itemName': itemName,
    'unit': unit.toJson(),
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
}

class ScrapTransaction {
  final String id;
  final DateTime timestamp;
  final List<TicketLine> lines;
  final double grandTotal;
  final String? recipientName;

  const ScrapTransaction({
    required this.id,
    required this.timestamp,
    required this.lines,
    required this.grandTotal,
    this.recipientName,
  });

  String get formattedTimestamp => ScrapMath.formatTimestamp(timestamp);

  String? get normalizedRecipientName {
    final trimmed = recipientName?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  ScrapTransaction copyWith({
    String? id,
    DateTime? timestamp,
    List<TicketLine>? lines,
    double? grandTotal,
    String? recipientName,
    bool clearRecipientName = false,
  }) {
    final nextName = clearRecipientName
        ? null
        : (recipientName ?? this.recipientName);
    final trimmed = nextName?.trim();
    return ScrapTransaction(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      lines: lines ?? this.lines,
      grandTotal: grandTotal ?? this.grandTotal,
      recipientName: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
  }

  factory ScrapTransaction.fromJson(Map<String, dynamic> json) {
    final rawLines = (json['lines'] as List<dynamic>?) ?? const [];
    final parsedLines = rawLines
        .whereType<Map<String, dynamic>>()
        .map(TicketLine.fromJson)
        .toList();
    final computedTotal = parsedLines.fold<double>(
      0.0,
      (sum, item) => ScrapMath.roundPeso(sum + item.subtotal),
    );
    final rawName = json['recipientName'] as String?;
    final trimmedName = rawName?.trim();
    return ScrapTransaction(
      id: (json['id'] as String?) ?? '',
      timestamp:
          DateTime.tryParse((json['timestamp'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lines: parsedLines,
      grandTotal: ScrapMath.roundPeso(
        ((json['grandTotal'] as num?)?.toDouble()) ?? computedTotal,
      ),
      recipientName: (trimmedName == null || trimmedName.isEmpty)
          ? null
          : trimmedName,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'lines': lines.map((e) => e.toJson()).toList(),
      'grandTotal': ScrapMath.roundPeso(grandTotal),
    };
    final name = normalizedRecipientName;
    if (name != null) {
      map['recipientName'] = name;
    }
    return map;
  }
}
