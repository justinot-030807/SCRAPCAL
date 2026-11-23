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
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Clear All History?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: const Text(
          'Mabubura nang tuluyan ang lahat ng naka-save na transaksyon sa teleponong ito.',
          style: TextStyle(fontSize: 14, color: AppColors.inkSecondary),
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
        titleSpacing: 12,
        title: const Text(
          'TRANSACTION HISTORY',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: AppColors.ink,
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
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: _confirmClearAll,
                child: const Text(
                  'Clear All History',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Summary Card: Total Ngayon
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${todayTx.length} ${todayTx.length == 1 ? 'transaction' : 'transactions'} today',
                        style: AppTheme.tabularText(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    ScrapMath.formatPeso(todayTotal),
                    key: const Key('today_total_payout'),
                    style: AppTheme.tabularText(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
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
                            Text(
                              'Walang naka-save na transaksyon',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkSecondary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pindutin ang SAVE sa calculator pagkatapos magtimbang upang ma-record ang payout.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
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
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final tx = _history[index];
                        return Container(
                          key: Key('history_tx_${tx.id}'),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tx.formattedTimestamp,
                                        style: AppTheme.tabularText(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.inkSecondary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      ScrapMath.formatPeso(tx.grandTotal),
                                      style: AppTheme.tabularText(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      key: Key('delete_tx_${tx.id}'),
                                      borderRadius: BorderRadius.circular(4),
                                      onTap: () => _deleteTransaction(tx.id),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppColors.border,
                                  ),
                                ),
                                ...tx.lines.map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${line.itemName} · ${line.formattedCalculation}',
                                            style: AppTheme.tabularText(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          ScrapMath.formatPeso(line.subtotal),
                                          style: AppTheme.tabularText(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
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
