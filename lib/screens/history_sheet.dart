import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../models/scrap_models.dart';
import '../services/receipt_export_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final List<ScrapTransaction> history;
  final AppLanguage language;
  final ValueChanged<List<ScrapTransaction>> onHistoryChanged;

  const HistoryScreen({
    super.key,
    required this.history,
    required this.language,
    required this.onHistoryChanged,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<ScrapTransaction> _history;

  @override
  void initState() {
    super.initState();
    _history = List<ScrapTransaction>.from(widget.history);
  }

  void _deleteTransaction(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      _history = _history.where((t) => t.id != id).toList();
    });
    widget.onHistoryChanged(_history);
  }

  void _updateTransaction(ScrapTransaction updated) {
    setState(() {
      _history = _history
          .map((t) => t.id == updated.id ? updated : t)
          .toList();
    });
    widget.onHistoryChanged(_history);
  }

  Future<void> _openReceiptModal(ScrapTransaction tx) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ReceiptPreviewSheet(
        transaction: tx,
        language: widget.language,
        onTransactionUpdated: _updateTransaction,
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    if (_history.isEmpty) return;
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
          s.clearAllDialogTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: p.ink,
          ),
        ),
        content: Text(
          s.clearAllDialogBody,
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
            child: Text(s.clearAllHistory),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _history = [];
      });
      widget.onHistoryChanged(_history);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final s = AppStrings(widget.language);

    final now = DateTime.now();
    final todayTx = _history
        .where((tx) => ScrapMath.isSameDay(tx.timestamp, now))
        .toList();
    final todayTotal = todayTx.fold<double>(
      0.0,
      (sum, tx) => ScrapMath.roundPeso(sum + tx.grandTotal),
    );

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
          s.historyTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: p.headerFg,
          ),
        ),
        actions: [
          if (_history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton(
                key: const Key('clear_all_history_btn'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.danger,
                  side: BorderSide(color: p.dangerBorder),
                  backgroundColor: p.dangerBg,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _confirmClearAll,
                child: Text(
                  s.clearAllHistory,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Summary Card: Total Ngayon / Today's Total
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: p.primarySoftBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.primarySoftBorder, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.todayTotalLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: p.primarySoftText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          s.todayTxCount(todayTx.length),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.tabularText(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: p.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        ScrapMath.formatPeso(todayTotal),
                        key: const Key('today_total_payout'),
                        maxLines: 1,
                        style: AppTheme.tabularText(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: p.primarySoftText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _history.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 44,
                              color: p.primary,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              s.emptyHistoryTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: p.primarySoftText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.emptyHistoryBody,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: p.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: _history.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = _history[index];
                        final recipient = tx.normalizedRecipientName;
                        return Container(
                          key: Key('history_tx_${tx.id}'),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: p.primarySoftBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 16,
                                      color: p.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        tx.formattedTimestamp,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.tabularText(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: p.primarySoftText,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      ScrapMath.formatPeso(tx.grandTotal),
                                      style: AppTheme.tabularText(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: p.primarySoftText,
                                      ),
                                    ),
                                  ],
                                ),
                                if (recipient != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.primarySoftBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${s.recipientPrefix}: $recipient',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: p.primarySoftText,
                                      ),
                                    ),
                                  ),
                                ],
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: p.border,
                                  ),
                                ),
                                ...tx.lines.map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${line.itemName} · ${line.formattedCalculation}',
                                            style: AppTheme.tabularText(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: p.ink,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          ScrapMath.formatPeso(line.subtotal),
                                          style: AppTheme.tabularText(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: p.primarySoftText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        key: Key('receipt_btn_${tx.id}'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: p.primarySoftText,
                                          backgroundColor: p.primarySoftBg,
                                          side: BorderSide(
                                            color: p.primarySoftBorder,
                                          ),
                                          minimumSize: const Size(0, 40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.receipt_long_outlined,
                                          size: 18,
                                        ),
                                        label: Text(
                                          s.receiptButtonLabel,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        onPressed: () => _openReceiptModal(tx),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      key: Key('delete_tx_${tx.id}'),
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => _deleteTransaction(tx.id),
                                      child: Container(
                                        height: 40,
                                        width: 44,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: p.dangerBg,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: p.dangerBorder,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: p.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

class _ReceiptPreviewSheet extends StatefulWidget {
  final ScrapTransaction transaction;
  final AppLanguage language;
  final ValueChanged<ScrapTransaction> onTransactionUpdated;

  const _ReceiptPreviewSheet({
    required this.transaction,
    required this.language,
    required this.onTransactionUpdated,
  });

  @override
  State<_ReceiptPreviewSheet> createState() => _ReceiptPreviewSheetState();
}

class _ReceiptPreviewSheetState extends State<_ReceiptPreviewSheet> {
  final GlobalKey _receiptBoundaryKey = GlobalKey();
  late TextEditingController _nameController;
  late ScrapTransaction _transaction;
  bool _isExporting = false;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    _nameController = TextEditingController(
      text: widget.transaction.normalizedRecipientName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onRecipientChanged(String raw) {
    final trimmed = raw.trim();
    final updated = _transaction.copyWith(
      recipientName: trimmed,
      clearRecipientName: trimmed.isEmpty,
    );
    setState(() {
      _transaction = updated;
    });
    widget.onTransactionUpdated(updated);
  }

  Future<void> _savePng() async {
    if (_isExporting) return;
    HapticFeedback.lightImpact();
    final s = AppStrings(widget.language);
    setState(() {
      _isExporting = true;
      _statusMessage = null;
    });

    try {
      await WidgetsBinding.instance.endOfFrame;
      final bytes = await ReceiptExportService.capturePng(
        _receiptBoundaryKey,
        pixelRatio: 3.0,
      );
      final fileName = ReceiptExportService.buildFileName(
        _transaction.timestamp,
      );
      await ReceiptExportService.savePngToGallery(
        pngBytes: bytes,
        fileName: fileName,
      );
      if (!mounted) return;
      setState(() {
        _statusMessage = s.receiptSavedSuccess;
        _statusIsError = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(s.receiptSavedSuccess),
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMessage = s.receiptSaveFailed;
        _statusIsError = true;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(s.receiptSaveFailed),
            duration: const Duration(seconds: 2),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _sharePng() async {
    if (_isExporting) return;
    HapticFeedback.lightImpact();
    final s = AppStrings(widget.language);
    setState(() {
      _isExporting = true;
      _statusMessage = null;
    });

    try {
      await WidgetsBinding.instance.endOfFrame;
      final bytes = await ReceiptExportService.capturePng(
        _receiptBoundaryKey,
        pixelRatio: 3.0,
      );
      final fileName = ReceiptExportService.buildFileName(
        _transaction.timestamp,
      );
      await ReceiptExportService.sharePng(
        pngBytes: bytes,
        fileName: fileName,
        text:
            'SCRAPCAL ${s.receiptPaperSubtitle} - ${ScrapMath.formatPeso(_transaction.grandTotal)}',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMessage = s.receiptShareFailed;
        _statusIsError = true;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(s.receiptShareFailed),
            duration: const Duration(seconds: 2),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final s = AppStrings(widget.language);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final recipient = _transaction.normalizedRecipientName;

    return Container(
      decoration: BoxDecoration(
        color: p.scaffold,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(top: BorderSide(color: p.border, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle & Title Row
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.receiptModalTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: p.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close, color: p.inkMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 1. Optional Recipient Name Field (Live auto-saves to History)
                TextField(
                  key: const Key('receipt_recipient_field'),
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  onChanged: _onRecipientChanged,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                  decoration: InputDecoration(
                    labelText: s.receiptNameFieldLabel,
                    hintText: s.receiptNameFieldHint,
                    filled: true,
                    fillColor: p.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: p.border),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 2. Crisp White Paper Receipt Card wrapped in RepaintBoundary
                // ALWAYS light paper (#FFFFFF) with sharp #111111 ink even in Dark Mode
                RepaintBoundary(
                  key: _receiptBoundaryKey,
                  child: Container(
                    key: const Key('receipt_paper_card'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFD4D4D8),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'SCRAPCAL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.receiptPaperSubtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: Color(0xFF52525B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _transaction.formattedTimestamp,
                          textAlign: TextAlign.center,
                          style: AppTheme.tabularText(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF52525B),
                          ),
                        ),
                        if (recipient != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${s.recipientPrefix}: $recipient',
                            key: const Key('receipt_preview_recipient'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: _DashedDivider(),
                        ),
                        // Itemized breakdown
                        ..._transaction.lines.map(
                          (line) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        line.itemName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF111111),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        line.formattedCalculation,
                                        style: AppTheme.tabularText(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF52525B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  ScrapMath.formatPeso(line.subtotal),
                                  style: AppTheme.tabularText(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF111111),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: _DashedDivider(),
                        ),
                        // Bold Grand Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.receiptPaperTotal,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: Color(0xFF111111),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  ScrapMath.formatPeso(
                                    _transaction.grandTotal,
                                  ),
                                  style: AppTheme.tabularText(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF111111),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s.receiptPaperFooter,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF52525B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_statusMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _statusIsError ? p.danger : p.primary,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // 3. Action Buttons: Save Image (PNG) & Share
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('receipt_save_png_btn'),
                        style: FilledButton.styleFrom(
                          backgroundColor: p.primary,
                          foregroundColor: const Color(0xFFFFFFFF),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isExporting ? null : _savePng,
                        icon: _isExporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFFFFFF),
                                ),
                              )
                            : const Icon(Icons.download_outlined, size: 20),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            s.savePngButton,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('receipt_share_png_btn'),
                        style: FilledButton.styleFrom(
                          backgroundColor: p.saveAmber,
                          foregroundColor: const Color(0xFFFFFFFF),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isExporting ? null : _sharePng,
                        icon: const Icon(Icons.share_outlined, size: 20),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            s.sharePngButton,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count.clamp(1, 100),
            (_) => const SizedBox(
              width: dashWidth,
              height: 1.2,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFA1A1AA)),
              ),
            ),
          ),
        );
      },
    );
  }
}
