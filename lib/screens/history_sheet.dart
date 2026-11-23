import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/scrap_models.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final List<ScrapTransaction> history;
  final ValueChanged<List<ScrapTransaction>> onHistoryChanged;

  const HistoryScreen({
    super.key,
    required this.history,
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

  Future<void> _confirmClearAll() async {
    if (_history.isEmpty) return;
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.lightGreenBorder),
        ),
        title: const Text(
          'Burahin Lahat ng History?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        content: const Text(
          'Mabubura nang tuluyan ang lahat ng naka-save na transaksyon sa teleponong ito.',
          style: TextStyle(fontSize: 15, color: AppColors.inkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All History'),
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
    final now = DateTime.now();
    final todayTx = _history
        .where((tx) => ScrapMath.isSameDay(tx.timestamp, now))
        .toList();
    final todayTotal = todayTx.fold<double>(
      0.0,
      (sum, tx) => ScrapMath.roundPeso(sum + tx.grandTotal),
    );

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        titleSpacing: 8,
        title: const Text(
          'LISTAHAN NG BENTA / HISTORY',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            color: AppColors.surface,
          ),
        ),
        actions: [
          if (_history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton(
                key: const Key('clear_all_history_btn'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.dangerBorder),
                  backgroundColor: AppColors.dangerBg,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _confirmClearAll,
                child: const Text(
                  'Clear All History',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Summary Card: Total Ngayon (Rich Green Banner)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.lightGreenBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.lightGreenBorder,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Ngayon',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryGreenDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${todayTx.length} ${todayTx.length == 1 ? 'transaction' : 'transactions'} today',
                        style: AppTheme.tabularText(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    ScrapMath.formatPeso(todayTotal),
                    key: const Key('today_total_payout'),
                    style: AppTheme.tabularText(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryGreenDark,
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
                          children: const [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 44,
                              color: AppColors.primaryGreen,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Wala pang naka-save na transaksyon',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryGreenDark,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Pindutin ang SAVE sa calculator pagkatapos magtimbang upang ma-record ang payout.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkMuted,
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
                        return Container(
                          key: Key('history_tx_${tx.id}'),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.lightGreenBorder,
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
                                    const Icon(
                                      Icons.schedule,
                                      size: 16,
                                      color: AppColors.primaryGreen,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        tx.formattedTimestamp,
                                        style: AppTheme.tabularText(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryGreenDark,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      ScrapMath.formatPeso(tx.grandTotal),
                                      style: AppTheme.tabularText(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryGreenDark,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      key: Key('delete_tx_${tx.id}'),
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () => _deleteTransaction(tx.id),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.dangerBg,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: AppColors.dangerBorder,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppColors.border,
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
                                              color: AppColors.ink,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          ScrapMath.formatPeso(line.subtotal),
                                          style: AppTheme.tabularText(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryGreenDark,
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
