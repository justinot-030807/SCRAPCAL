import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../models/scrap_models.dart';
import '../theme/app_theme.dart';

class PresyoScreen extends StatefulWidget {
  final List<ScrapItem> items;
  final AppLanguage language;
  final ValueChanged<List<ScrapItem>> onItemsChanged;
  final bool openAddOnLaunch;

  const PresyoScreen({
    super.key,
    required this.items,
    required this.language,
    required this.onItemsChanged,
    this.openAddOnLaunch = false,
  });

  @override
  State<PresyoScreen> createState() => _PresyoScreenState();
}

class _PresyoScreenState extends State<PresyoScreen> {
  late List<ScrapItem> _items;
  final Map<String, TextEditingController> _priceControllers = {};
  final TextEditingController _newNameController = TextEditingController();
  final TextEditingController _newPriceController = TextEditingController();
  final FocusNode _newNameFocus = FocusNode();
  ScrapUnit _newUnit = ScrapUnit.perKg;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _items = List<ScrapItem>.from(widget.items);
    _syncControllers();
    if (widget.openAddOnLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _newNameFocus.requestFocus();
        }
      });
    }
  }

  void _syncControllers() {
    final existingIds = _items.map((e) => e.id).toSet();
    final obsolete = _priceControllers.keys
        .where((k) => !existingIds.contains(k))
        .toList();
    for (final k in obsolete) {
      _priceControllers.remove(k)?.dispose();
    }
    for (final item in _items) {
      final formatted = ScrapMath.formatCleanNumber(item.price);
      if (!_priceControllers.containsKey(item.id)) {
        _priceControllers[item.id] = TextEditingController(text: formatted);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    _newNameController.dispose();
    _newPriceController.dispose();
    _newNameFocus.dispose();
    super.dispose();
  }

  void _commitChanges(List<ScrapItem> updated) {
    setState(() {
      _items = updated;
      _syncControllers();
    });
    widget.onItemsChanged(_items);
  }

  void _onPriceEdited(ScrapItem item, String rawValue) {
    final parsed = double.tryParse(rawValue.trim());
    if (parsed == null || parsed < 0) return;
    final cleanPrice = ScrapMath.roundPeso(parsed);
    final updated = _items
        .map((e) => e.id == item.id ? e.copyWith(price: cleanPrice) : e)
        .toList();
    _items = updated;
    widget.onItemsChanged(_items);
  }

  void _toggleItemUnit(ScrapItem item) {
    HapticFeedback.lightImpact();
    final nextUnit = item.unit == ScrapUnit.perKg
        ? ScrapUnit.perPiece
        : ScrapUnit.perKg;
    final updated = _items
        .map((e) => e.id == item.id ? e.copyWith(unit: nextUnit) : e)
        .toList();
    _commitChanges(updated);
  }

  Future<void> _editItemDialog(ScrapItem item) async {
    final p = AppPalette.of(context);
    final s = AppStrings(widget.language);
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(
      text: ScrapMath.formatCleanNumber(item.price),
    );
    ScrapUnit selectedUnit = item.unit;

    final result = await showDialog<ScrapItem>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: p.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: p.border, width: 1.5),
              ),
              title: Text(
                s.editItemTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                    decoration: InputDecoration(
                      labelText: s.itemNameLabel,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _UnitOptionButton(
                          label: s.unitPerKg,
                          selected: selectedUnit == ScrapUnit.perKg,
                          onTap: () => setDialogState(
                            () => selectedUnit = ScrapUnit.perKg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _UnitOptionButton(
                          label: s.unitPerPiece,
                          selected: selectedUnit == ScrapUnit.perPiece,
                          onTap: () => setDialogState(
                            () => selectedUnit = ScrapUnit.perPiece,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppTheme.tabularText(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                    decoration: InputDecoration(
                      labelText: s.priceLabel,
                      prefixText: '₱ ',
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(s.dialogCancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: const Color(0xFFFFFFFF),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text.trim());
                    if (name.isEmpty || price == null || price < 0) return;
                    Navigator.of(ctx).pop(
                      item.copyWith(
                        name: name,
                        unit: selectedUnit,
                        price: price,
                      ),
                    );
                  },
                  child: Text(s.keySave),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      _priceControllers[result.id]?.text = ScrapMath.formatCleanNumber(
        result.price,
      );
      final updated = _items
          .map((e) => e.id == result.id ? result : e)
          .toList();
      _commitChanges(updated);
    }
  }

  void _addNewScrap() {
    HapticFeedback.lightImpact();
    final s = AppStrings(widget.language);
    final name = _newNameController.text.trim();
    final priceRaw = _newPriceController.text.trim();
    final price = double.tryParse(priceRaw);

    if (name.isEmpty) {
      setState(() => _formError = s.nameError);
      return;
    }
    if (price == null || price <= 0) {
      setState(() => _formError = s.priceError);
      return;
    }

    final newItem = ScrapItem(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      unit: _newUnit,
      price: ScrapMath.roundPeso(price),
    );

    _newNameController.clear();
    _newPriceController.clear();
    setState(() {
      _formError = null;
      _newUnit = ScrapUnit.perKg;
    });
    FocusScope.of(context).unfocus();

    _commitChanges([..._items, newItem]);
  }

  void _deleteItem(ScrapItem item) {
    HapticFeedback.lightImpact();
    final s = AppStrings(widget.language);
    if (_items.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.keepOneItemWarning),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    final updated = _items.where((e) => e.id != item.id).toList();
    _commitChanges(updated);
  }

  Future<void> _confirmResetDefaults() async {
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
          s.resetDefaultsDialogTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: p.ink,
          ),
        ),
        content: Text(
          s.resetDefaultsDialogBody,
          style: TextStyle(fontSize: 15, color: p.inkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.dialogCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: p.danger,
              foregroundColor: const Color(0xFFFFFFFF),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.resetDefaultsConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final c in _priceControllers.values) {
        c.dispose();
      }
      _priceControllers.clear();
      _commitChanges(List<ScrapItem>.from(ScrapItem.defaultItems));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final s = AppStrings(widget.language);

    return Scaffold(
      backgroundColor: p.scaffold,
      appBar: AppBar(
        backgroundColor: p.headerBg,
        foregroundColor: p.headerFg,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: p.headerBg,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleSpacing: 8,
        title: Text(
          s.presyoTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: p.headerFg,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: p.danger,
                side: BorderSide(color: p.dangerBorder),
                backgroundColor: p.dangerBg,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _confirmResetDefaults,
              child: Text(
                s.resetDefaultsButton,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Add New Scrap Form
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.primarySoftBorder, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: p.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.addScrapSectionTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: p.primarySoftText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          key: const Key('new_scrap_name_field'),
                          controller: _newNameController,
                          focusNode: _newNameFocus,
                          textCapitalization: TextCapitalization.words,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                          ),
                          decoration: InputDecoration(
                            hintText: s.scrapNameHint,
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: p.inkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: p.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          key: const Key('new_scrap_price_field'),
                          controller: _newPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: AppTheme.tabularText(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: p.ink,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixText: '₱ ',
                            prefixStyle: AppTheme.tabularText(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: p.primarySoftText,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: p.border),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _UnitOptionButton(
                          key: const Key('unit_toggle_kg'),
                          label: s.unitPerKg,
                          selected: _newUnit == ScrapUnit.perKg,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _newUnit = ScrapUnit.perKg);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _UnitOptionButton(
                          key: const Key('unit_toggle_pcs'),
                          label: s.unitPerPiece,
                          selected: _newUnit == ScrapUnit.perPiece,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _newUnit = ScrapUnit.perPiece);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        key: const Key('add_scrap_submit_btn'),
                        style: FilledButton.styleFrom(
                          backgroundColor: p.primary,
                          foregroundColor: const Color(0xFFFFFFFF),
                          minimumSize: const Size(88, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _addNewScrap,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            s.addScrapSubmit,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_formError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formError!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                s.priceListHeader,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: p.primarySoftText,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.primarySoftBorder, width: 1.5),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: p.border,
                ),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final ctrl = _priceControllers[item.id]!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _editItemDialog(item),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: p.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => _toggleItemUnit(item),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.primarySoftBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: p.primarySoftBorder,
                                      ),
                                    ),
                                    child: Text(
                                      s.unitShortDisplay(
                                        item.unit == ScrapUnit.perPiece,
                                      ),
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: p.primarySoftText,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            key: Key('price_input_${item.id}'),
                            controller: ctrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            textAlign: TextAlign.right,
                            style: AppTheme.tabularText(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: p.primarySoftText,
                            ),
                            onChanged: (val) => _onPriceEdited(item, val),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: p.surfaceSubtle,
                              prefixText: '₱',
                              prefixStyle: AppTheme.tabularText(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: p.primarySoftText,
                              ),
                              suffixText: '/${item.unit.shortLabel}',
                              suffixStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: p.inkMuted,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: p.primarySoftBorder,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Edit ${item.name}',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: p.primary,
                          ),
                          onPressed: () => _editItemDialog(item),
                        ),
                        IconButton(
                          key: Key('delete_item_${item.id}'),
                          tooltip: 'Delete ${item.name}',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: p.danger,
                          ),
                          onPressed: () => _deleteItem(item),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitOptionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnitOptionButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Material(
      color: selected ? p.primary : p.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? p.primaryDark : p.primarySoftBorder,
              width: 1.5,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? const Color(0xFFFFFFFF) : p.primarySoftText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
