// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get balanceSheetTitle => 'uangsaku';

  @override
  String get navHome => 'Beranda';

  @override
  String get navAccounts => 'Akun';

  @override
  String get navRecord => 'Catat';

  @override
  String get navTransactions => 'Transaksi';

  @override
  String get navBudget => 'Anggaran';

  @override
  String get categoriesTooltip => 'Kategori';

  @override
  String get settingsTooltip => 'Pengaturan';

  @override
  String get helpTooltip => 'Bantuan';

  @override
  String get addAccountTooltip => 'Tambah akun';

  @override
  String get debtDetailsTooltip => 'Detail utang-piutang';

  @override
  String get figuresLoadError => 'Angka-angka gagal dimuat.';

  @override
  String get accountsSectionTitle => 'Akun';

  @override
  String get accountsLoading => 'Memuat akun…';

  @override
  String get accountsLoadError => 'Akun gagal dimuat.';

  @override
  String get figureSpendable => 'Yang bisa saya belanjakan sekarang';

  @override
  String get figureOwedToMe => 'Piutang saya';

  @override
  String get figureOwedByMe => 'Utang saya';

  @override
  String get figureNet => 'Bersih';

  @override
  String get figureSpendableTooltip =>
      'Yang bisa Anda belanjakan sekarang, dari seluruh akun HOLDING.';

  @override
  String get figureOwedToMeTooltip =>
      'Total yang menjadi piutang Anda, dari seluruh akun RECEIVABLE.';

  @override
  String get figureOwedByMeTooltip =>
      'Total yang menjadi utang Anda, dari seluruh akun PAYABLE.';

  @override
  String get figureNetTooltip =>
      'Yang bisa dibelanjakan ditambah piutang, dikurangi utang — posisi keuangan Anda secara keseluruhan.';

  @override
  String get noAccountsYetPeriod => 'Belum ada akun.';

  @override
  String debtDetailTitle(int accountId) {
    return 'Utang #$accountId';
  }

  @override
  String get markSettled => 'Tandai lunas';

  @override
  String get figurePaid => 'Sudah dibayar';

  @override
  String get figureRemaining => 'Sisa yang harus dibayar';

  @override
  String get settledBadge => 'Lunas';

  @override
  String get saveCorrectionTooltip => 'Simpan koreksi';

  @override
  String get saveChangesTooltip => 'Simpan perubahan';

  @override
  String get saveAccountTooltip => 'Simpan akun';

  @override
  String get saveButton => 'Simpan';

  @override
  String get titleCorrectAccount => 'Koreksi akun';

  @override
  String get titleEditAccount => 'Edit akun';

  @override
  String get titleNewAccount => 'Akun baru';

  @override
  String get nameLabel => 'Nama';

  @override
  String get nameHint => 'Dompet, kartu kredit, orang…';

  @override
  String get openingAmountLabel => 'Jumlah awal';

  @override
  String get openingAmountHint => 'Yang ada di dalamnya hari ini (boleh minus)';

  @override
  String get currentAmountUnknown => 'Jumlah saat ini: —';

  @override
  String currentAmountKnown(int amount) {
    return 'Jumlah saat ini: $amount';
  }

  @override
  String get targetAmountLabel => 'Yang seharusnya';

  @override
  String get targetAmountHint => 'Jumlah target (boleh minus)';

  @override
  String get deleteAccountButton => 'Hapus akun';

  @override
  String get accountGroupDescriptionHolding =>
      'Uang yang Anda pegang dan bisa langsung dibelanjakan — dompet, rekening bank, atau e-wallet.';

  @override
  String get accountGroupDescriptionReceivable =>
      'Uang yang menjadi piutang Anda kepada orang lain.';

  @override
  String get accountGroupDescriptionPayable =>
      'Uang yang menjadi utang Anda kepada orang lain.';

  @override
  String get duplicateAccountNameBlockedTitle => 'Nama sudah dipakai';

  @override
  String get duplicateAccountNameBlockedContent =>
      'Akun lain sudah memakai nama ini. Pilih nama lain untuk menyimpan.';

  @override
  String get budgetOverviewTitle => 'Anggaran bulan ini';

  @override
  String get setBudgetTooltip => 'Atur anggaran';

  @override
  String get noBudgetGroupsYet => 'Belum ada kelompok anggaran';

  @override
  String get othersLabel => 'Lainnya';

  @override
  String budgetSpentSubtitle(int amount, int spent) {
    return 'Anggaran: $amount   Terpakai: $spent';
  }

  @override
  String get setBudgetScreenTitle => 'Atur anggaran bulanan';

  @override
  String get addBudgetGroupTooltip => 'Tambah kelompok anggaran';

  @override
  String get amountHint => 'Jumlah';

  @override
  String get saveAmountTooltip => 'Simpan jumlah';

  @override
  String get amountSavedMessage => 'Jumlah tersimpan';

  @override
  String get deletePeriodTooltip => 'Hapus periode bulan ini';

  @override
  String get renameGroupTooltip => 'Ganti nama kelompok';

  @override
  String get deleteGroupTooltip => 'Hapus kelompok';

  @override
  String get categoryManagerTitle => 'Kategori dan subkategori';

  @override
  String get addCategoryTooltip => 'Tambah kategori';

  @override
  String get noCategoriesYet => 'Belum ada kategori';

  @override
  String get addSubcategoryTooltip => 'Tambah subkategori';

  @override
  String get renameCategoryTooltip => 'Ganti nama kategori';

  @override
  String get deleteCategoryTooltip => 'Hapus kategori';

  @override
  String get renameSubcategoryTooltip => 'Ganti nama subkategori';

  @override
  String get deleteSubcategoryTooltip => 'Hapus subkategori';

  @override
  String get recordTransactionTitle => 'Catat pergerakan uang';

  @override
  String get kindFieldLabel => 'Jenis transaksi';

  @override
  String get kindExpense => 'Pengeluaran';

  @override
  String get kindIncome => 'Pemasukan';

  @override
  String get kindTransfer => 'Transfer';

  @override
  String get kindLend => 'Pinjamkan';

  @override
  String get kindBorrow => 'Pinjam';

  @override
  String get kindRepay => 'Bayar utang';

  @override
  String get kindRepayment => 'Pembayaran';

  @override
  String get kindAdjustment => 'Penyesuaian';

  @override
  String get kindDescriptionExpense =>
      'Uang keluar dari salah satu akun Anda, dibelanjakan untuk sesuatu.';

  @override
  String get kindDescriptionIncome => 'Uang masuk ke salah satu akun Anda.';

  @override
  String get kindDescriptionTransfer =>
      'Uang berpindah antara dua akun milik Anda sendiri — bukan pengeluaran.';

  @override
  String get kindDescriptionLend =>
      'Uang keluar dari salah satu akun Anda menjadi piutang kepada orang lain.';

  @override
  String get kindDescriptionBorrow =>
      'Uang masuk ke salah satu akun Anda sebagai utang yang harus Anda bayar.';

  @override
  String get kindDescriptionRepay =>
      'Melunasi utang-piutang — uang berpindah antara akun seseorang dan akun Anda sendiri.';

  @override
  String get adjustmentDescription =>
      'Koreksi langsung terhadap saldo sebuah akun, bukan dengan mencatat transfer atau pengeluaran — dipakai untuk membetulkan kesalahan atau mengatur saldo awal.';

  @override
  String get amountLabel => 'Jumlah';

  @override
  String get amountHintMinor => 'Satuan terkecil, boleh minus';

  @override
  String get noteOptionalLabel => 'Catatan (opsional)';

  @override
  String get payingAccountLabel => 'Akun pembayar';

  @override
  String get receivingAccountLabel => 'Akun penerima';

  @override
  String get sourceAccountLabel => 'Akun asal';

  @override
  String get destinationAccountLabel => 'Akun tujuan';

  @override
  String get debtPersonLabel => 'Utang / orang';

  @override
  String get personDebtLabel => 'Orang / utang';

  @override
  String get ownAccountLabel => 'Akun sendiri';

  @override
  String get noneHint => '(tidak ada)';

  @override
  String get categoryOptionalLabel => 'Kategori (opsional)';

  @override
  String get subcategoryOptionalLabel => 'Subkategori (opsional)';

  @override
  String get budgetGroupOptionalLabel => 'Kelompok anggaran (opsional)';

  @override
  String get noAccountsYetHint => 'Belum ada akun';

  @override
  String createOptionLabel(String name) {
    return 'Buat \'$name\'';
  }

  @override
  String get recordedMessage => 'Tercatat';

  @override
  String get allTransactionsTitle => 'Semua transaksi';

  @override
  String get noTransactionsYet => 'Belum ada transaksi';

  @override
  String get amendTransactionTooltip => 'Ubah transaksi';

  @override
  String get deleteTransactionTooltip => 'Hapus transaksi';

  @override
  String get noAccountSet => 'tidak ada akun';

  @override
  String amendSheetTitle(String kind) {
    return 'Ubah $kind';
  }

  @override
  String get fromSideAccountLabel => 'Akun sisi asal';

  @override
  String get toSideAccountLabel => 'Akun sisi tujuan';

  @override
  String get categoryLabel => 'Kategori';

  @override
  String get subcategoryLabel => 'Subkategori';

  @override
  String get budgetGroupLabel => 'Kelompok anggaran';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get currencySectionTitle => 'Mata uang';

  @override
  String get languageSectionTitle => 'Bahasa';

  @override
  String get themeModeSectionTitle => 'Mode tema';

  @override
  String get themeColorSectionTitle => 'Warna tema';

  @override
  String get languageEnglish => 'Inggris';

  @override
  String get languageIndonesian => 'Indonesia';

  @override
  String get themeModeSystem => 'Sistem';

  @override
  String get themeModeLight => 'Terang';

  @override
  String get themeModeDark => 'Gelap';

  @override
  String get currencyRelabelDialogContent =>
      'Jumlah yang sudah tercatat hanya diberi label ulang, bukan dikonversi. Angka yang sama akan tampil dengan mata uang yang baru.';

  @override
  String get okButton => 'OK';

  @override
  String get balanceTrendChartTitle => 'Tren saldo (30 hari)';

  @override
  String get incomeExpenseChartTitle => 'Pemasukan vs pengeluaran bulan ini';

  @override
  String get categorySpendingChartTitle => 'Pengeluaran per kategori bulan ini';

  @override
  String get balanceTrendChartTooltip =>
      'Saldo bersih Anda selama 30 hari terakhir.';

  @override
  String get incomeExpenseChartTooltip =>
      'Total pemasukan dibanding total pengeluaran yang tercatat bulan kalender ini.';

  @override
  String get categorySpendingChartTooltip =>
      'Bagaimana pengeluaran bulan ini terbagi per kategori.';

  @override
  String get incomeLegendLabel => 'Pemasukan';

  @override
  String get expenseLegendLabel => 'Pengeluaran';

  @override
  String get uncategorizedLabel => 'Tanpa kategori';

  @override
  String get chartNoDataYet => 'Belum ada data.';

  @override
  String get helpScreenTitle => 'Bantuan';

  @override
  String get helpSectionAccounts => 'Apa itu akun';

  @override
  String get helpSectionRecording => 'Mencatat pergerakan uang';

  @override
  String get helpSectionBudgets => 'Anggaran';

  @override
  String get helpSectionDebts => 'Utang-piutang';

  @override
  String get helpBudgetsDescription =>
      'Kelompok anggaran adalah kategori pengeluaran dengan jumlah bulanan yang disisihkan untuknya. Pengeluaran yang dicatat tanpa kelompok masuk ke kelompok otomatis \"Lainnya\". Tidak ada yang terkunci di sini — anggaran bisa diubah di tengah bulan, dan kelebihan pengeluaran ditampilkan, bukan diblokir.';

  @override
  String get helpDebtsDescription =>
      'Akun receivable adalah uang yang menjadi piutang Anda kepada orang lain; akun payable adalah uang yang menjadi utang Anda kepada orang lain. \"Sudah dibayar\" adalah jumlah pembayaran yang tercatat untuknya, dan \"sisa yang harus dibayar\" adalah saldonya saat ini. Mencentang lunas menandai utang-piutang itu selesai tanpa menghapus riwayatnya.';
}
