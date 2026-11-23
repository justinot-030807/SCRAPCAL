import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/scrap_models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'history_sheet.dart';
import 'presyo_sheet.dart';

class CalculatorScreen extends StatefulWidget {
  final StorageService storage;

  const CalculatorScreen({super.key, required this.storage});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  static const SystemUiOverlayStyle _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: AppColors.primaryGreen,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.scaffold,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  late List<ScrapItem> _items;
  late ScrapItem _selectedItem;
  late List<TicketLine> _ticketLines;
  late List<ScrapTransaction> _history;
  final ScrollController _tapeScrollController = ScrollController();

  String _input = '0';

  @override
  void initState() {
    super.initState();
    _items = widget.storage.loadScrapItems();
    _selectedItem = _items.first;
    _ticketLines = widget.storage.loadActiveTicket();
    _history = widget.storage.loadHistory();
  }

  @override
  void dispose() {
    _tapeScrollController.dispose();
    super.dispose();
  }

  double get _currentQuantity {
    final parsed = double.tryParse(_input) ?? 0.0;
    if (_selectedItem.unit == ScrapUnit.perPiece) {
      return parsed.floorToDouble();
    }
    return ScrapMath.roundWeight(parsed);
  }

  double get _activeSubtotal {
    return ScrapMath.roundPeso(_currentQuantity * _selectedItem.price);
  }

  double get _tapeTotal {
    return _ticketLines.fold<double>(
      0.0,
      (sum, line) => ScrapMath.roundPeso(sum + line.subtotal),
    );
  }

  double get _grandTotal {
    return ScrapMath.roundPeso(_tapeTotal + _activeSubtotal);
  }

  String get _formattedActiveQuantity {
    if (_selectedItem.unit == ScrapUnit.perPiece) {
      final count = (double.tryParse(_input) ?? 0).floor();
      return '$count pcs';
    }
    final qty = _currentQuantity;
    final frac = ScrapMath.fractionLabel(qty);
    final rawDisplay = _input.endsWith('.') ? '${_input}0' : _input;
    final displayNum = _input.contains('.')
        ? rawDisplay
        : ScrapMath.formatCleanNumber(qty);
    if (frac != null) {
      return '$displayNum kg ($frac)';
    }
    return '$displayNum kg';
  }

  void _selectScrapItem(ScrapItem item) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedItem = item;
      if (item.unit == ScrapUnit.perPiece && _input.contains('.')) {
        final whole = (double.tryParse(_input) ?? 0).floor();
        _input = whole.toString();
      }
    });
  }

  void _onDigitTap(String digit) {
    HapticFeedback.lightImpact();
    setState(() {
      if (digit == '.') {
        if (_selectedItem.unit == ScrapUnit.perPiece) return;
        if (_input.contains('.')) return;
        _input = '$_input.';
        return;
      }

      if (_input == '0') {
        _input = digit;
        return;
      }

      // Limit decimals to 3 places for kg
      if (_input.contains('.')) {
        final parts = _input.split('.');
        if (parts.length > 1 && parts[1].length >= 3) {
          return;
        }
      } else if (_input.length >= 6) {
        return;
      }

      _input = '$_input$digit';
    });
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_input.length <= 1) {
        _input = '0';
      } else {
        _input = _input.substring(0, _input.length - 1);
        if (_input.isEmpty || _input == '-') {
          _input = '0';
        }
      }
    });
  }

  void _onClearInput() {
    HapticFeedback.lightImpact();
    setState(() {
      _input = '0';
    });
  }

  void _executeResetTicket() {
    HapticFeedback.lightImpact();
    setState(() {
      _input = '0';
      _ticketLines = [];
    });
    widget.storage.saveActiveTicket(_ticketLines);
  }

  Future<void> _confirmResetTicket() async {
    if (_ticketLines.isEmpty && _input == '0') return;
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightGreenBorder, width: 1.5),
        ),
        title: const Text(
          'Burahin lahat ng nakalista?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        content: const Text(
          'Mabubura ang kasalukuyang listahan at tinitimbang para makapagsimula ng bagong customer.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.inkSecondary,
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.keyBorder),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Hindi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          FilledButton(
            key: const Key('confirm_reset_yes_btn'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Oo, Burahin',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _executeResetTicket();
    }
  }

  void _onQuickAdd(double increment) {
    HapticFeedback.lightImpact();
    setState(() {
      final current = double.tryParse(_input) ?? 0.0;
      if (_selectedItem.unit == ScrapUnit.perPiece) {
        final next = (current.floor() + increment.round()).clamp(0, 999999);
        _input = next.toString();
      } else {
        final next = ScrapMath.roundWeight(
          (current + increment).clamp(0.0, 999999.0),
        );
        _input = ScrapMath.formatCleanNumber(next);
      }
    });
  }

  void _onAddLineToTape() {
    HapticFeedback.lightImpact();
    final qty = _currentQuantity;
    if (qty <= 0) return;

    final newLine = TicketLine(
      id: 'line_${DateTime.now().microsecondsSinceEpoch}',
      itemId: _selectedItem.id,
      itemName: _selectedItem.name,
      unit: _selectedItem.unit,
      quantity: qty,
      unitPrice: _selectedItem.price,
    );

    setState(() {
      _ticketLines = [..._ticketLines, newLine];
      _input = '0';
    });
    widget.storage.saveActiveTicket(_ticketLines);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tapeScrollController.hasClients) {
        _tapeScrollController.animateTo(
          _tapeScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeTicketLine(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      _ticketLines = _ticketLines.where((e) => e.id != id).toList();
    });
    widget.storage.saveActiveTicket(_ticketLines);
  }

  void _onSaveTransaction() {
    HapticFeedback.lightImpact();
    final activeQty = _currentQuantity;
    final linesToSave = List<TicketLine>.from(_ticketLines);

    if (activeQty > 0) {
      linesToSave.add(
        TicketLine(
          id: 'line_${DateTime.now().microsecondsSinceEpoch}',
          itemId: _selectedItem.id,
          itemName: _selectedItem.name,
          unit: _selectedItem.unit,
          quantity: activeQty,
          unitPrice: _selectedItem.price,
        ),
      );
    }

    if (linesToSave.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Maglagay muna ng timbang o bilang bago mag-SAVE.'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    final total = linesToSave.fold<double>(
      0.0,
      (sum, item) => ScrapMath.roundPeso(sum + item.subtotal),
    );

    final transaction = ScrapTransaction(
      id: 'tx_${DateTime.now().microsecondsSinceEpoch}',
      timestamp: DateTime.now(),
      lines: linesToSave,
      grandTotal: total,
    );

    setState(() {
      _history = [transaction, ..._history];
      _ticketLines = [];
      _input = '0';
    });

    widget.storage.saveActiveTicket(_ticketLines);
    widget.storage.saveHistory(_history);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Na-save ang transaksyon: ${ScrapMath.formatPeso(total)} (${linesToSave.length} ${linesToSave.length == 1 ? 'item' : 'items'})',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _openPresyo({bool openAddOnLaunch = false}) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PresyoScreen(
          items: _items,
          openAddOnLaunch: openAddOnLaunch,
          onItemsChanged: (updated) {
            setState(() {
              _items = updated;
              final match = _items.where((e) => e.id == _selectedItem.id);
              if (match.isNotEmpty) {
                _selectedItem = match.first;
              } else {
                _selectedItem = _items.first;
              }
              if (_selectedItem.unit == ScrapUnit.perPiece &&
                  _input.contains('.')) {
                _input = (double.tryParse(_input) ?? 0).floor().toString();
              }
            });
            widget.storage.saveScrapItems(updated);
          },
        ),
      ),
    );
  }

  Future<void> _openHistory() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryScreen(
          history: _history,
          onHistoryChanged: (updated) {
            setState(() {
              _history = updated;
            });
            widget.storage.saveHistory(updated);
          },
        ),
      ),
    );
  }

  Widget _buildTwoRowCategorySelector() {
    final allChips = <Widget>[
      ..._items.map((item) {
        final isSelected = item.id == _selectedItem.id;
        return _ScrapSelectorChip(
          key: Key('chip_${item.id}'),
          label: item.chipLabel,
          selected: isSelected,
          onTap: () => _selectScrapItem(item),
        );
      }),
      _ScrapSelectorChip(
        key: const Key('chip_add_custom'),
        label: '+ Add',
        selected: false,
        isAction: true,
        onTap: () => _openPresyo(openAddOnLaunch: true),
      ),
    ];

    final row1 = <Widget>[];
    final row2 = <Widget>[];
    for (int i = 0; i < allChips.length; i++) {
      if (i.isEven) {
        row1.add(allChips[i]);
      } else {
        row2.add(allChips[i]);
      }
    }

    return SizedBox(
      height: 76,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 35,
              child: Row(
                children: [
                  for (int i = 0; i < row1.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    row1[i],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 35,
              child: Row(
                children: [
                  for (int i = 0; i < row2.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    row2[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPiece = _selectedItem.unit == ScrapUnit.perPiece;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Senior-Friendly Green Header Bar (extends behind top status bar so status icons are always crisp light-on-dark-green)
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primaryGreenDark,
                    width: 1.5,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.calculate_outlined,
                          color: AppColors.surface,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SCRAPCAL',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: AppColors.surface,
                        ),
                      ),
                      const Spacer(),
                      _HeaderNavButton(
                        key: const Key('nav_presyo_btn'),
                        icon: Icons.sell_outlined,
                        label: 'Presyo',
                        onTap: () => _openPresyo(),
                      ),
                      const SizedBox(width: 8),
                      _HeaderNavButton(
                        key: const Key('nav_history_btn'),
                        icon: Icons.receipt_long_outlined,
                        label: 'History',
                        badgeCount: _history.length,
                        onTap: _openHistory,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Remaining body inside SafeArea(top: false)
            Expanded(
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2. Calculator Tape & Live Display Panel
                    Expanded(
                      flex: 4,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.lightGreenBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Tape Header Bar with Bagong Lista confirmation action
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.lightGreenSurface,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                border: Border(
                                  bottom: BorderSide(color: AppColors.border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.playlist_add_check_rounded,
                                    size: 18,
                                    color: AppColors.primaryGreenDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'LISTAHAN (${_ticketLines.length} ${_ticketLines.length == 1 ? 'ITEM' : 'ITEMS'})',
                                    style: AppTheme.tabularText(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryGreenDark,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    key: const Key('reset_ticket_btn'),
                                    borderRadius: BorderRadius.circular(6),
                                    onTap:
                                        (_ticketLines.isNotEmpty ||
                                            _input != '0')
                                        ? _confirmResetTicket
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (_ticketLines.isNotEmpty ||
                                                _input != '0')
                                            ? AppColors.dangerBg
                                            : AppColors.surface,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color:
                                              (_ticketLines.isNotEmpty ||
                                                  _input != '0')
                                              ? AppColors.dangerBorder
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        'Bagong Lista',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color:
                                              (_ticketLines.isNotEmpty ||
                                                  _input != '0')
                                              ? AppColors.danger
                                              : AppColors.inkMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Running Ticket Tape (Expanded scrollable area)
                            Expanded(
                              child: _ticketLines.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        child: Text(
                                          '1. Pumili ng kalakal sa ibaba (Bakal, Plastic, Bote...)\n2. Pindutin ang timbang o bilang, tapos + DAGDAG o SAVE.',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            height: 1.3,
                                            color: AppColors.inkMuted,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      controller: _tapeScrollController,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      itemCount: _ticketLines.length,
                                      separatorBuilder: (_, _) => const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: AppColors.border,
                                      ),
                                      itemBuilder: (context, index) {
                                        final line = _ticketLines[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 22,
                                                height: 22,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: AppColors.lightGreenBg,
                                                  borderRadius:
                                                      BorderRadius.circular(11),
                                                ),
                                                child: Text(
                                                  '${index + 1}',
                                                  style: AppTheme.tabularText(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors
                                                        .primaryGreenDark,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  line.formattedTapeSummary,
                                                  style: AppTheme.tabularText(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.ink,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              InkWell(
                                                key: Key(
                                                  'remove_line_${line.id}',
                                                ),
                                                onTap: () =>
                                                    _removeTicketLine(line.id),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.dangerBg,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: AppColors
                                                          .dangerBorder,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    '×',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: AppColors.danger,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),

                            // Active Calculation Bar (Draft Preview with "Tinitimbang ngayon:" & White Input Pill)
                            Container(
                              padding: const EdgeInsets.fromLTRB(10, 5, 10, 6),
                              decoration: const BoxDecoration(
                                color: AppColors.lightGreenBg,
                                border: Border(
                                  top: BorderSide(
                                    color: AppColors.lightGreenBorder,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Tinitimbang ngayon:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryGreenDark,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          _selectedItem.name,
                                          key: const Key('active_scrap_name'),
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.surface,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Prominent white rounded container/pill for typed quantity
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primaryGreen,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          _formattedActiveQuantity,
                                          key: const Key(
                                            'active_quantity_pill',
                                          ),
                                          style: AppTheme.tabularText(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '× ${ScrapMath.formatPeso(_selectedItem.price)}/${_selectedItem.unit.shortLabel}',
                                          key: const Key(
                                            'active_calculation_text',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTheme.tabularText(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryGreenDark,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        ScrapMath.formatPeso(_activeSubtotal),
                                        key: const Key('active_subtotal_text'),
                                        style: AppTheme.tabularText(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primaryGreenDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Grand Total Row (High-Contrast Deep Forest Green Banner)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryGreenDark,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'KABUUAN / TOTAL',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: AppColors.lightGreenBg,
                                    ),
                                  ),
                                  Text(
                                    ScrapMath.formatPeso(_grandTotal),
                                    key: const Key('grand_total_text'),
                                    style: AppTheme.tabularText(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.surface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Scrap Category Selector (2-row horizontally scrollable grid with 12px horizontal padding)
                    _buildTwoRowCategorySelector(),

                    const SizedBox(height: 6),

                    // 4. Context-Aware Quick-Add Row (3 wider buttons: +1/4, +1/2, +3/4 for /kg; +1, +5, +10 for /pc)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        height: 40,
                        child: Row(
                          children: isPiece
                              ? [
                                  _QuickAddKey(
                                    key: const Key('quick_add_pc_1'),
                                    label: '+1',
                                    onTap: () => _onQuickAdd(1),
                                  ),
                                  const SizedBox(width: 8),
                                  _QuickAddKey(
                                    key: const Key('quick_add_pc_5'),
                                    label: '+5',
                                    onTap: () => _onQuickAdd(5),
                                  ),
                                  const SizedBox(width: 8),
                                  _QuickAddKey(
                                    key: const Key('quick_add_pc_10'),
                                    label: '+10',
                                    onTap: () => _onQuickAdd(10),
                                  ),
                                ]
                              : [
                                  _QuickAddKey(
                                    key: const Key('quick_add_kg_025'),
                                    label: '+1/4',
                                    subLabel: '+0.25',
                                    onTap: () => _onQuickAdd(0.25),
                                  ),
                                  const SizedBox(width: 8),
                                  _QuickAddKey(
                                    key: const Key('quick_add_kg_050'),
                                    label: '+1/2',
                                    subLabel: '+0.50',
                                    onTap: () => _onQuickAdd(0.50),
                                  ),
                                  const SizedBox(width: 8),
                                  _QuickAddKey(
                                    key: const Key('quick_add_kg_075'),
                                    label: '+3/4',
                                    subLabel: '+0.75',
                                    onTap: () => _onQuickAdd(0.75),
                                  ),
                                ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 5. Tactile Calculator Numpad (4-column grid, non-scrolling)
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Columns 1-3: Digits 7-9, 4-6, 1-3, . 0 ⌫
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _KeypadButton(
                                          key: const Key('key_7'),
                                          label: '7',
                                          onTap: () => _onDigitTap('7'),
                                        ),
                                        const SizedBox(width: 6),
                                        _KeypadButton(
                                          key: const Key('key_8'),
                                          label: '8',
                                          onTap: () => _onDigitTap('8'),
                                        ),
                                        const SizedBox(width: 6),
                                        _KeypadButton(
                                          key: const Key('key_9'),
                                          label: '9',
                                          onTap: () => _onDigitTap('9'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _KeypadButton(
                                          key: const Key('key_4'),
                                          label: '4',
                                          onTap: () => _onDigitTap('4'),
                                        ),
                                        const SizedBox(width: 6),
                                        _KeypadButton(
                                          key: const Key('key_5'),
                                          label: '5',
                                          onTap: () => _onDigitTap('5'),
                                        ),
                                        const SizedBox(width: 6),
                                        _KeypadButton(
                                          key: const Key('key_6'),
                                          label: '6',
                                          onTap: () => _onDigitTap('6'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _KeypadButton(
                                          key: const Key('key_1'),
                                          label: '1',
                                          onTap: () => _onDigitTap('1'),
                                        ),
                                        const SizedBox(width: 6),
                                        _KeypadButton(
                                          key: const Key('key_2'),
                                          label: '2',
                                          onTap: () => _onDigitTap('2'),
                                        ),
                                        const SizedBox(width: 6),
                                        _KeypadButton(
                                          key: const Key('key_3'),
                                          label: '3',
                                          onTap: () => _onDigitTap('3'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _KeypadButton(
                                          key: const Key('key_dot'),
                                          label: '.',
                                          fontSize: 34,
                                          enabled: !isPiece,
                                          onTap: () => _onDigitTap('.'),
                                        ),
                                        const SizedBox(width: 6),
                                        _KeypadButton(
                                          key: const Key('key_0'),
                                          label: '0',
                                          onTap: () => _onDigitTap('0'),
                                        ),
                                        const SizedBox(width: 6),
                                        _KeypadButton(
                                          key: const Key('key_backspace'),
                                          label: '⌫',
                                          backgroundColor:
                                              AppColors.lightGreenSurface,
                                          borderColor:
                                              AppColors.lightGreenBorder,
                                          textColor: AppColors.primaryGreenDark,
                                          onTap: _onBackspace,
                                          onLongPress: _onClearInput,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Column 4: Action Controls (ULITIN, + DAGDAG SA LISTA, SAVE / TAPOS NA)
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: _ActionKeyButton(
                                      key: const Key('key_clear'),
                                      label: 'ULITIN',
                                      backgroundColor: AppColors.dangerBg,
                                      borderColor: AppColors.dangerBorder,
                                      textColor: AppColors.danger,
                                      onTap: _onClearInput,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    flex: 2,
                                    child: _ActionKeyButton(
                                      key: const Key('key_dagdag'),
                                      label: '+ DAGDAG',
                                      subLabel: 'SA LISTA',
                                      backgroundColor: AppColors.primaryGreen,
                                      borderColor: AppColors.primaryGreenDark,
                                      textColor: AppColors.surface,
                                      onTap: _onAddLineToTape,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    flex: 1,
                                    child: _ActionKeyButton(
                                      key: const Key('key_save'),
                                      label: 'SAVE',
                                      subLabel: 'TAPOS NA',
                                      backgroundColor: AppColors.saveAmber,
                                      borderColor: AppColors.saveAmberDark,
                                      textColor: AppColors.surface,
                                      onTap: _onSaveTransaction,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;

  const _HeaderNavButton({
    super.key,
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.lightGreenBorder, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primaryGreenDark),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreenDark,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreenBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.lightGreenBorder),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: AppTheme.tabularText(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryGreenDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScrapSelectorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isAction;
  final VoidCallback onTap;

  const _ScrapSelectorChip({
    super.key,
    required this.label,
    required this.selected,
    this.isAction = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? AppColors.primaryGreen
        : (isAction ? AppColors.lightGreenBg : AppColors.surface);
    final fgColor = selected ? AppColors.surface : AppColors.primaryGreenDark;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primaryGreenDark
                  : AppColors.lightGreenBorder,
              width: selected ? 1.5 : 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_circle,
                  size: 15,
                  color: AppColors.surface,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: AppTheme.tabularText(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAddKey extends StatelessWidget {
  final String label;
  final String? subLabel;
  final VoidCallback onTap;

  const _QuickAddKey({
    super.key,
    required this.label,
    this.subLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.lightGreenBg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.lightGreenBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTheme.tabularText(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryGreenDark,
                  ),
                ),
                if (subLabel != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '($subLabel)',
                    style: AppTheme.tabularText(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final double fontSize;

  const _KeypadButton({
    super.key,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.keyBorder,
    this.textColor = AppColors.ink,
    this.fontSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: enabled ? backgroundColor : AppColors.scaffold,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: enabled ? borderColor : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: AppTheme.tabularText(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: enabled ? textColor : AppColors.keyBorder,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionKeyButton extends StatelessWidget {
  final String label;
  final String? subLabel;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionKeyButton({
    super.key,
    required this.label,
    this.subLabel,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: textColor,
                  ),
                ),
              ),
              if (subLabel != null) ...[
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subLabel!,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: textColor.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
