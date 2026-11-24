import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../models/scrap_models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'history_sheet.dart';
import 'presyo_sheet.dart';
import 'settings_screen.dart';

class CalculatorScreen extends StatefulWidget {
  final StorageService storage;
  final AppLanguage language;
  final bool isDarkMode;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<bool> onDarkModeChanged;

  const CalculatorScreen({
    super.key,
    required this.storage,
    required this.language,
    required this.isDarkMode,
    required this.onLanguageChanged,
    required this.onDarkModeChanged,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _tapeScrollController = ScrollController();

  late List<ScrapItem> _items;
  late ScrapItem _selectedItem;
  late List<TicketLine> _ticketLines;
  late List<ScrapTransaction> _history;

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
    final p = AppPalette.of(context);
    final s = AppStrings(widget.language);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.border, width: 1.5),
        ),
        title: Text(
          s.resetDialogTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: p.ink,
          ),
        ),
        content: Text(
          s.resetDialogBody,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: p.inkSecondary,
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: p.ink,
              side: BorderSide(color: p.keyBorder),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              s.dialogCancel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          FilledButton(
            key: const Key('confirm_reset_yes_btn'),
            style: FilledButton.styleFrom(
              backgroundColor: p.danger,
              foregroundColor: const Color(0xFFFFFFFF),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              s.resetDialogConfirm,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _executeResetTicket();
    }
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
    final s = AppStrings(widget.language);
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
          SnackBar(
            content: Text(s.emptySaveWarning),
            duration: const Duration(seconds: 2),
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
            s.savedToast(ScrapMath.formatPeso(total), linesToSave.length),
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
          language: widget.language,
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
          language: widget.language,
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

  Future<void> _openSettings() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SettingsRouteHost(
          initialLanguage: widget.language,
          initialDarkMode: widget.isDarkMode,
          onLanguageChanged: widget.onLanguageChanged,
          onDarkModeChanged: widget.onDarkModeChanged,
        ),
      ),
    );
  }

  Widget _buildDrawer(AppPalette p, AppStrings s) {
    return Drawer(
      backgroundColor: p.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact Drawer Header
          Container(
            color: p.headerBg,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calculate_outlined,
                        color: p.headerFg,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.appTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: p.headerFg,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.appSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.headerFg.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Menu Items
          _DrawerMenuTile(
            key: const Key('drawer_presyo_item'),
            icon: Icons.sell_outlined,
            label: s.menuPresyo,
            onTap: () {
              Navigator.of(context).pop();
              _openPresyo();
            },
          ),
          _DrawerMenuTile(
            key: const Key('drawer_history_item'),
            icon: Icons.history,
            label: s.menuHistory,
            badgeCount: _history.length,
            onTap: () {
              Navigator.of(context).pop();
              _openHistory();
            },
          ),
          _DrawerMenuTile(
            key: const Key('drawer_settings_item'),
            icon: Icons.settings_outlined,
            label: s.menuSettings,
            onTap: () {
              Navigator.of(context).pop();
              _openSettings();
            },
          ),

          const Spacer(),

          // Pinned Footer
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Text(
                s.developerCredit,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: p.inkMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final s = AppStrings(widget.language);
    final isPiece = _selectedItem.unit == ScrapUnit.perPiece;
    final hasAnyInput = _ticketLines.isNotEmpty || _input != '0';

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: p.headerBg,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: p.scaffold,
      systemNavigationBarIconBrightness: p.isDark
          ? Brightness.light
          : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: p.scaffold,
        drawer: _buildDrawer(p, s),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Minimalist Top Bar (ONLY Hamburger Menu Icon + Clean SCRAPCAL Title)
            Container(
              decoration: BoxDecoration(
                color: p.headerBg,
                border: Border(
                  bottom: BorderSide(color: p.headerBorder, width: 1.5),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 54,
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('drawer_menu_btn'),
                        tooltip: 'Menu',
                        icon: Icon(Icons.menu, color: p.headerFg, size: 28),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          s.appTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                            color: p.headerFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Body Content
            Expanded(
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2. Spacious Calculator Tape & Live Display Panel
                    Expanded(
                      flex: 5,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: p.primarySoftBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Tape Header Bar
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: p.surfaceSubtle,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(10),
                                ),
                                border: Border(
                                  bottom: BorderSide(color: p.border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.playlist_add_check_rounded,
                                    size: 19,
                                    color: p.primarySoftText,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      s.listHeader(_ticketLines.length),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.tabularText(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: p.primarySoftText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    key: const Key('reset_ticket_btn'),
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: hasAnyInput
                                        ? _confirmResetTicket
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: hasAnyInput
                                            ? p.dangerBg
                                            : p.surface,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: hasAnyInput
                                              ? p.dangerBorder
                                              : p.border,
                                        ),
                                      ),
                                      child: Text(
                                        s.resetListButton,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: hasAnyInput
                                              ? p.danger
                                              : p.inkMuted,
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
                                          horizontal: 18,
                                        ),
                                        child: Text(
                                          s.emptyTapeHint,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            height: 1.35,
                                            color: p.inkMuted,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      controller: _tapeScrollController,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      itemCount: _ticketLines.length,
                                      separatorBuilder: (_, _) => Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: p.border,
                                      ),
                                      itemBuilder: (context, index) {
                                        final line = _ticketLines[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: p.primarySoftBg,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${index + 1}',
                                                  style: AppTheme.tabularText(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color: p.primarySoftText,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  line.formattedTapeSummary,
                                                  style: AppTheme.tabularText(
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: p.ink,
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
                                                        horizontal: 9,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: p.dangerBg,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: p.dangerBorder,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '×',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: p.danger,
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

                            // Active Draft Preview Bar
                            Container(
                              padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
                              decoration: BoxDecoration(
                                color: p.primarySoftBg,
                                border: Border(
                                  top: BorderSide(
                                    color: p.primarySoftBorder,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    s.currentDraftLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: p.primarySoftText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 100,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: p.primary,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              _selectedItem.name,
                                              key: const Key(
                                                'active_scrap_name',
                                              ),
                                              maxLines: 1,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFFFFFFF),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        flex: 3,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: p.surface,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: p.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              _formattedActiveQuantity,
                                              key: const Key(
                                                'active_quantity_pill',
                                              ),
                                              maxLines: 1,
                                              style: AppTheme.tabularText(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w900,
                                                color: p.ink,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        flex: 3,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '× ${ScrapMath.formatPeso(_selectedItem.price)}/${_selectedItem.unit.shortLabel}',
                                            key: const Key(
                                              'active_calculation_text',
                                            ),
                                            maxLines: 1,
                                            style: AppTheme.tabularText(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: p.primarySoftText,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        flex: 2,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            ScrapMath.formatPeso(
                                              _activeSubtotal,
                                            ),
                                            key: const Key(
                                              'active_subtotal_text',
                                            ),
                                            maxLines: 1,
                                            style: AppTheme.tabularText(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: p.primarySoftText,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Grand Total Banner (Single Active Language)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: p.totalBannerBg,
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    s.totalLabel,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      color: p.totalBannerLabel,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        ScrapMath.formatPeso(_grandTotal),
                                        key: const Key('grand_total_text'),
                                        maxLines: 1,
                                        style: AppTheme.tabularText(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: p.totalBannerValue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Single-Row Horizontal Scrap Selector (Clean, Unclipped, Spacious)
                    SizedBox(
                      height: 46,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            ..._items.map((item) {
                              final isSelected = item.id == _selectedItem.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _ScrapSelectorChip(
                                  key: Key('chip_${item.id}'),
                                  label: item.chipLabel,
                                  selected: isSelected,
                                  onTap: () => _selectScrapItem(item),
                                ),
                              );
                            }),
                            _ScrapSelectorChip(
                              key: const Key('chip_add_custom'),
                              label: s.addCustomChip,
                              selected: false,
                              isAction: true,
                              onTap: () => _openPresyo(openAddOnLaunch: true),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 4. Spacious Tactile Calculator Numpad (Quick-Add Row Removed)
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                                        const SizedBox(width: 8),
                                        _KeypadButton(
                                          key: const Key('key_8'),
                                          label: '8',
                                          onTap: () => _onDigitTap('8'),
                                        ),
                                        const SizedBox(width: 8),
                                        _KeypadButton(
                                          key: const Key('key_9'),
                                          label: '9',
                                          onTap: () => _onDigitTap('9'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _KeypadButton(
                                          key: const Key('key_4'),
                                          label: '4',
                                          onTap: () => _onDigitTap('4'),
                                        ),
                                        const SizedBox(width: 8),
                                        _KeypadButton(
                                          key: const Key('key_5'),
                                          label: '5',
                                          onTap: () => _onDigitTap('5'),
                                        ),
                                        const SizedBox(width: 8),
                                        _KeypadButton(
                                          key: const Key('key_6'),
                                          label: '6',
                                          onTap: () => _onDigitTap('6'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _KeypadButton(
                                          key: const Key('key_1'),
                                          label: '1',
                                          onTap: () => _onDigitTap('1'),
                                        ),
                                        const SizedBox(width: 8),
                                        _KeypadButton(
                                          key: const Key('key_2'),
                                          label: '2',
                                          onTap: () => _onDigitTap('2'),
                                        ),
                                        const SizedBox(width: 8),
                                        _KeypadButton(
                                          key: const Key('key_3'),
                                          label: '3',
                                          onTap: () => _onDigitTap('3'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _KeypadButton(
                                          key: const Key('key_dot'),
                                          label: '.',
                                          fontSize: 36,
                                          enabled: !isPiece,
                                          onTap: () => _onDigitTap('.'),
                                        ),
                                        const SizedBox(width: 8),
                                        _KeypadButton(
                                          key: const Key('key_0'),
                                          label: '0',
                                          onTap: () => _onDigitTap('0'),
                                        ),
                                        const SizedBox(width: 8),
                                        _KeypadButton(
                                          key: const Key('key_backspace'),
                                          label: '⌫',
                                          backgroundColor: p.surfaceSubtle,
                                          borderColor: p.primarySoftBorder,
                                          textColor: p.primarySoftText,
                                          onTap: _onBackspace,
                                          onLongPress: _onClearInput,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Column 4: Single-Word Action Controls (Ulit/Clear, + Dagdag/+ Add, Save)
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: _ActionKeyButton(
                                      key: const Key('key_clear'),
                                      label: s.keyClear,
                                      backgroundColor: p.dangerBg,
                                      borderColor: p.dangerBorder,
                                      textColor: p.danger,
                                      onTap: _onClearInput,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    flex: 2,
                                    child: _ActionKeyButton(
                                      key: const Key('key_dagdag'),
                                      label: s.keyAddLine,
                                      backgroundColor: p.primary,
                                      borderColor: p.primaryDark,
                                      textColor: const Color(0xFFFFFFFF),
                                      onTap: _onAddLineToTape,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    flex: 1,
                                    child: _ActionKeyButton(
                                      key: const Key('key_save'),
                                      label: s.keySave,
                                      backgroundColor: p.saveAmber,
                                      borderColor: p.saveAmberBorder,
                                      textColor: const Color(0xFFFFFFFF),
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

class _SettingsRouteHost extends StatefulWidget {
  final AppLanguage initialLanguage;
  final bool initialDarkMode;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<bool> onDarkModeChanged;

  const _SettingsRouteHost({
    required this.initialLanguage,
    required this.initialDarkMode,
    required this.onLanguageChanged,
    required this.onDarkModeChanged,
  });

  @override
  State<_SettingsRouteHost> createState() => _SettingsRouteHostState();
}

class _SettingsRouteHostState extends State<_SettingsRouteHost> {
  late AppLanguage _language;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
    _isDarkMode = widget.initialDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      language: _language,
      isDarkMode: _isDarkMode,
      onLanguageChanged: (lang) {
        setState(() => _language = lang);
        widget.onLanguageChanged(lang);
      },
      onDarkModeChanged: (dark) {
        setState(() => _isDarkMode = dark);
        widget.onDarkModeChanged(dark);
      },
    );
  }
}

class _DrawerMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;

  const _DrawerMenuTile({
    super.key,
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, size: 24, color: p.primary),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: p.ink,
        ),
      ),
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: p.primarySoftBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.primarySoftBorder),
              ),
              child: Text(
                badgeCount.toString(),
                style: AppTheme.tabularText(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: p.primarySoftText,
                ),
              ),
            )
          : Icon(Icons.chevron_right_rounded, color: p.inkMuted),
      onTap: onTap,
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
    final p = AppPalette.of(context);
    final bgColor = selected
        ? p.primary
        : (isAction ? p.primarySoftBg : p.surface);
    final fgColor = selected
        ? const Color(0xFFFFFFFF)
        : (isAction ? p.primarySoftText : p.ink);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? p.primaryDark : p.primarySoftBorder,
              width: selected ? 1.5 : 1.2,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFFFFFFFF),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  maxLines: 1,
                  style: AppTheme.tabularText(
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    color: fgColor,
                  ),
                ),
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
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final double fontSize;

  const _KeypadButton({
    super.key,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.fontSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final bg = enabled ? (backgroundColor ?? p.surface) : p.keyDisabledBg;
    final bd = enabled ? (borderColor ?? p.keyBorder) : p.border;
    final fg = enabled ? (textColor ?? p.ink) : p.keyDisabledFg;

    return Expanded(
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bd, width: 1.5),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: AppTheme.tabularText(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
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
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionKeyButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
