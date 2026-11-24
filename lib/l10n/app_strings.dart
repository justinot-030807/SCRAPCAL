enum AppLanguage {
  tagalog,
  english;

  String get code => this == AppLanguage.tagalog ? 'tl' : 'en';

  static AppLanguage fromCode(String? code) {
    return code == 'en' ? AppLanguage.english : AppLanguage.tagalog;
  }
}

class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  bool get isTagalog => language == AppLanguage.tagalog;

  // Brand & Drawer
  String get appTitle => 'SCRAPCAL';
  String get appSubtitle => 'Junkshop Calculator';
  String get developerCredit => 'Developed by Justine S. Lachica';
  String get menuPresyo => isTagalog ? 'Presyo' : 'Prices';
  String get menuHistory => 'History';
  String get menuSettings => 'Settings';

  // Main Calculator Screen
  String listHeader(int count) => isTagalog
      ? 'Listahan ($count)'
      : 'Items ($count)';
  String get resetListButton => isTagalog ? 'Bagong Lista' : 'New List';
  String get resetDialogTitle =>
      isTagalog ? 'Burahin lahat ng nakalista?' : 'Clear all listed items?';
  String get resetDialogBody => isTagalog
      ? 'Mabubura ang kasalukuyang listahan at tinitimbang.'
      : 'This will clear the current list and active input.';
  String get dialogCancel => isTagalog ? 'Hindi' : 'Cancel';
  String get resetDialogConfirm => isTagalog ? 'Oo, Burahin' : 'Clear';

  String get emptyTapeHint => isTagalog
      ? 'Pumili ng kalakal sa ibaba at ilagay ang timbang o bilang.'
      : 'Select a scrap item below and enter weight or count.';
  String get currentDraftLabel =>
      isTagalog ? 'Tinitimbang ngayon:' : 'Current item:';
  String get totalLabel => isTagalog ? 'Kabuuan' : 'Total';
  String get addCustomChip => '+ Add';

  // Keypad Action Buttons (single language, no double text)
  String get keyClear => isTagalog ? 'Ulit' : 'Clear';
  String get keyAddLine => isTagalog ? '+ Dagdag' : '+ Add';
  String get keySave => 'Save';

  // Calculator SnackBars
  String get emptySaveWarning => isTagalog
      ? 'Maglagay muna ng timbang o bilang.'
      : 'Enter weight or count first.';
  String savedToast(String formattedTotal, int itemCount) {
    final noun = itemCount == 1 ? 'item' : 'items';
    return isTagalog
        ? 'Na-save: $formattedTotal ($itemCount $noun)'
        : 'Saved: $formattedTotal ($itemCount $noun)';
  }

  // Presyo / Prices Screen
  String get presyoTitle => isTagalog ? 'Presyo' : 'Prices';
  String get resetDefaultsButton => 'Reset';
  String get addScrapSectionTitle =>
      isTagalog ? 'Bagong Kalakal' : 'New Scrap Item';
  String get scrapNameHint =>
      isTagalog ? 'Pangalan (hal. Aluminum)' : 'Name (e.g. Aluminum)';
  String get unitPerKg => 'Per Kilo (kg)';
  String get unitPerPiece => isTagalog ? 'Per Piraso (pcs)' : 'Per Piece (pcs)';
  String unitShortDisplay(bool isPiece) =>
      isPiece ? (isTagalog ? 'per piraso' : 'per piece') : 'per kg';
  String get addScrapSubmit => isTagalog ? '+ Dagdag' : '+ Add';
  String get priceListHeader => isTagalog ? 'Mga Presyo' : 'Price List';
  String get nameError => isTagalog
      ? 'Ilagay ang pangalan ng kalakal.'
      : 'Enter the scrap item name.';
  String get priceError => isTagalog
      ? 'Ilagay ang tamang presyo (₱).'
      : 'Enter a valid price (₱).';
  String get keepOneItemWarning => isTagalog
      ? 'Mag-iwan ng kahit isang item.'
      : 'Keep at least one item.';
  String get editItemTitle => isTagalog ? 'Baguhin' : 'Edit Item';
  String get itemNameLabel => isTagalog ? 'Pangalan' : 'Item Name';
  String get priceLabel => isTagalog ? 'Presyo (₱)' : 'Price (₱)';
  String get resetDefaultsDialogTitle =>
      isTagalog ? 'Ibalik sa default na presyo?' : 'Reset to default prices?';
  String get resetDefaultsDialogBody => isTagalog
      ? 'Ibabalik ang Bakal, Plastic, Tanso, at Bote sa orihinal na presyo.'
      : 'Restores Bakal, Plastic, Tanso, and Bote to default prices.';
  String get resetDefaultsConfirm => isTagalog ? 'Ibalik' : 'Reset';

  // History Screen
  String get historyTitle => 'History';
  String get clearAllHistory => isTagalog ? 'Burahin Lahat' : 'Clear All';
  String get clearAllDialogTitle =>
      isTagalog ? 'Burahin lahat ng history?' : 'Clear all history?';
  String get clearAllDialogBody => isTagalog
      ? 'Mabubura nang tuluyan ang lahat ng naka-save na transaksyon.'
      : 'This will permanently delete all saved transactions.';
  String get todayTotalLabel => isTagalog ? 'Total Ngayon' : "Today's Total";
  String todayTxCount(int count) {
    if (isTagalog) {
      return '$count transaksyon ngayon';
    }
    return '$count ${count == 1 ? 'transaction' : 'transactions'} today';
  }

  String get emptyHistoryTitle => isTagalog
      ? 'Walang naka-save na transaksyon'
      : 'No saved transactions';
  String get emptyHistoryBody => isTagalog
      ? 'Pindutin ang Save sa calculator upang maitala ang bayad.'
      : 'Tap Save on the calculator to record a payout.';
  String get recipientPrefix => isTagalog ? 'Pangalan' : 'Name';
  String get receiptButtonLabel => isTagalog ? 'Resibo' : 'Receipt';

  // Receipt Modal (Resibo)
  String get receiptModalTitle => isTagalog ? 'Resibo' : 'Receipt';
  String get receiptNameFieldLabel =>
      isTagalog ? 'Pangalan (Optional)' : 'Name (Optional)';
  String get receiptNameFieldHint =>
      isTagalog ? 'hal. Mang Juan' : 'e.g. Juan Dela Cruz';
  String get receiptPaperSubtitle => isTagalog ? 'RESIBO' : 'RECEIPT';
  String get receiptPaperTotal => isTagalog ? 'KABUUAN' : 'TOTAL';
  String get receiptPaperFooter => isTagalog ? 'Salamat!' : 'Thank you!';
  String get savePngButton => isTagalog ? 'I-save (PNG)' : 'Save Image';
  String get sharePngButton => isTagalog ? 'Ipasa' : 'Share';
  String get receiptSavedSuccess => isTagalog
      ? 'Na-save ang resibo sa Gallery.'
      : 'Receipt saved to Gallery.';
  String get receiptSaveFailed => isTagalog
      ? 'Hindi ma-save ang resibo.'
      : 'Could not save receipt image.';
  String get receiptShareFailed => isTagalog
      ? 'Hindi maipasa ang resibo.'
      : 'Could not share receipt image.';

  // Settings Screen
  String get settingsTitle => 'Settings';
  String get languageLabel => isTagalog ? 'Wika' : 'Language';
  String get themeLabel => isTagalog ? 'Tema' : 'Theme';
  String get lightModeLabel => 'Light Mode';
  String get darkModeLabel => 'Dark Mode';
}
