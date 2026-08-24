// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get balanceSheetTitle => 'uangsaku';

  @override
  String get navHome => 'Home';

  @override
  String get navAccounts => 'Balance';

  @override
  String get navRecord => 'Record';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navBudget => 'Budget';

  @override
  String get categoriesTooltip => 'Categories';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get helpTooltip => 'Help';

  @override
  String get addAccountTooltip => 'Add account';

  @override
  String get debtDetailsTooltip => 'Debt details';

  @override
  String get figuresLoadError => 'The figures could not be loaded.';

  @override
  String get accountsSectionTitle => 'Accounts';

  @override
  String get accountsLoading => 'Loading accounts…';

  @override
  String get accountsLoadError => 'The accounts could not be loaded.';

  @override
  String get figureSpendable => 'What I can spend now';

  @override
  String get figureOwedToMe => 'Owed to me';

  @override
  String get figureOwedByMe => 'Owed by me';

  @override
  String get figureNet => 'Net';

  @override
  String get figureSpendableTooltip =>
      'What you can spend right now, across every HOLDING account.';

  @override
  String get figureOwedToMeTooltip =>
      'The total of what other people owe you, across every RECEIVABLE account.';

  @override
  String get figureOwedByMeTooltip =>
      'The total of what you owe other people, across every PAYABLE account.';

  @override
  String get figureNetTooltip =>
      'Spendable plus owed to you, minus what you owe — your overall position.';

  @override
  String get noAccountsYetPeriod => 'No accounts yet.';

  @override
  String debtDetailTitle(int accountId) {
    return 'Debt #$accountId';
  }

  @override
  String get writeOffDebtButton => 'Write it off';

  @override
  String get figurePaid => 'Paid off';

  @override
  String get figureRemaining => 'Left to pay';

  @override
  String get settledBadge => 'Settled';

  @override
  String get saveCorrectionTooltip => 'Save correction';

  @override
  String get saveChangesTooltip => 'Save changes';

  @override
  String get saveAccountTooltip => 'Save account';

  @override
  String get saveButton => 'Save';

  @override
  String get titleCorrectAccount => 'Correct account';

  @override
  String get titleEditAccount => 'Edit account';

  @override
  String get titleNewAccount => 'New account';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameHint => 'Wallet, credit card, person…';

  @override
  String get openingAmountLabel => 'Opening amount';

  @override
  String get openingAmountHint => 'What is in it today (minus allowed)';

  @override
  String get currentAmountUnknown => 'Current amount: —';

  @override
  String currentAmountKnown(int amount) {
    return 'Current amount: $amount';
  }

  @override
  String get targetAmountLabel => 'What it should actually be';

  @override
  String get targetAmountHint => 'Target amount (minus allowed)';

  @override
  String get deleteAccountButton => 'Delete account';

  @override
  String get adjustBalanceButton => 'Adjust balance';

  @override
  String get accountGroupDescriptionHolding =>
      'Money you hold and can spend directly — a wallet, bank account, or e-wallet.';

  @override
  String get accountGroupDescriptionReceivable =>
      'Money someone else owes you.';

  @override
  String get accountGroupDescriptionPayable => 'Money you owe someone else.';

  @override
  String get accountGroupDescriptionPerson =>
      'A person whose balance can go either way — you might owe them, or they might owe you, depending on what\'s happened.';

  @override
  String get accountGroupLabelHolding => 'Wallet';

  @override
  String get accountGroupLabelReceivable => 'Owed to me';

  @override
  String get accountGroupLabelPayable => 'Owed by me';

  @override
  String get accountGroupLabelPerson => 'Person';

  @override
  String get duplicateAccountNameBlockedTitle => 'Name already used';

  @override
  String get duplicateAccountNameBlockedContent =>
      'Another account already has this name. Choose a different name to save.';

  @override
  String get budgetOverviewTitle => 'Budget this month';

  @override
  String get setBudgetTooltip => 'Set budget';

  @override
  String get noBudgetGroupsYet => 'No budget groups yet';

  @override
  String get othersLabel => 'Others';

  @override
  String budgetSpentSubtitle(int amount, int spent) {
    return 'Budget: $amount   Spent: $spent';
  }

  @override
  String get setBudgetScreenTitle => 'Set the monthly budget';

  @override
  String get addBudgetGroupTooltip => 'Add budget group';

  @override
  String get amountHint => 'Amount';

  @override
  String get saveAmountTooltip => 'Save amount';

  @override
  String get amountSavedMessage => 'Amount saved';

  @override
  String get deletePeriodTooltip => 'Delete this month\'s period';

  @override
  String get renameGroupTooltip => 'Rename group';

  @override
  String get deleteGroupTooltip => 'Delete group';

  @override
  String get categoryManagerTitle => 'Categories and subcategories';

  @override
  String get addCategoryTooltip => 'Add category';

  @override
  String get noCategoriesYet => 'No categories yet';

  @override
  String get addSubcategoryTooltip => 'Add subcategory';

  @override
  String get renameCategoryTooltip => 'Rename category';

  @override
  String get deleteCategoryTooltip => 'Delete category';

  @override
  String get renameSubcategoryTooltip => 'Rename subcategory';

  @override
  String get deleteSubcategoryTooltip => 'Delete subcategory';

  @override
  String get recordTransactionTitle => 'Record money movement';

  @override
  String get kindFieldLabel => 'What kind';

  @override
  String get kindExpense => 'Expense';

  @override
  String get kindIncome => 'Income';

  @override
  String get kindTransfer => 'Transfer';

  @override
  String get kindLend => 'Lend';

  @override
  String get kindBorrow => 'Borrow';

  @override
  String get kindRepay => 'Repay';

  @override
  String get kindRepayment => 'Repayment';

  @override
  String get kindAdjustment => 'Adjustment';

  @override
  String get kindDescriptionExpense =>
      'Money leaving one of your accounts, spent on something.';

  @override
  String get kindDescriptionIncome => 'Money entering one of your accounts.';

  @override
  String get kindDescriptionTransfer =>
      'Money moving between two of your own accounts — not spending.';

  @override
  String get kindDescriptionLend =>
      'Money leaving one of your accounts to become money someone owes you.';

  @override
  String get kindDescriptionBorrow =>
      'Money entering one of your accounts as something you now owe.';

  @override
  String get kindDescriptionRepay =>
      'Settling a debt — money moving between a person\'s account and one of your own.';

  @override
  String get adjustmentDescription =>
      'A correction to an account\'s balance, made directly rather than by recording a transfer or expense — used to fix a mistake or set a starting balance.';

  @override
  String get amountLabel => 'Amount';

  @override
  String get amountHintMinor => 'Minor units, minus allowed';

  @override
  String get noteOptionalLabel => 'Note (optional)';

  @override
  String get payingAccountLabel => 'Paying account';

  @override
  String get receivingAccountLabel => 'Receiving account';

  @override
  String get sourceAccountLabel => 'Source account';

  @override
  String get destinationAccountLabel => 'Destination account';

  @override
  String get debtPersonLabel => 'Debt / person';

  @override
  String get personDebtLabel => 'Person / debt';

  @override
  String get ownAccountLabel => 'Own account';

  @override
  String get noneHint => '(none)';

  @override
  String get categoryOptionalLabel => 'Category (optional)';

  @override
  String get subcategoryOptionalLabel => 'Subcategory (optional)';

  @override
  String get budgetGroupOptionalLabel => 'Budget group (optional)';

  @override
  String get noAccountsYetHint => 'No accounts yet';

  @override
  String createOptionLabel(String name) {
    return 'Create \'$name\'';
  }

  @override
  String get createPersonCheckboxLabel =>
      'New person, balance can go either way';

  @override
  String get repayDirectionTheyPaidMe => 'They paid me';

  @override
  String get repayDirectionIPaidThem => 'I paid them';

  @override
  String get recordedMessage => 'Recorded';

  @override
  String get allTransactionsTitle => 'All transactions';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get amendTransactionTooltip => 'Amend transaction';

  @override
  String get deleteTransactionTooltip => 'Delete transaction';

  @override
  String get noAccountSet => 'no account set';

  @override
  String amendSheetTitle(String kind) {
    return 'Amend $kind';
  }

  @override
  String get fromSideAccountLabel => 'From-side account';

  @override
  String get toSideAccountLabel => 'To-side account';

  @override
  String get categoryLabel => 'Category';

  @override
  String get subcategoryLabel => 'Subcategory';

  @override
  String get budgetGroupLabel => 'Budget group';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get currencySectionTitle => 'Currency';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get themeModeSectionTitle => 'Theme mode';

  @override
  String get themeColorSectionTitle => 'Theme color';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Indonesian';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get currencyRelabelDialogContent =>
      'Existing amounts are re-labelled, not converted. The same recorded numbers will show with the new currency.';

  @override
  String get okButton => 'OK';

  @override
  String get budgetAllocationChartTitle => 'Budget allocation';

  @override
  String get balanceTrendChartTitle => 'Balance trend (30 days)';

  @override
  String get incomeExpenseChartTitle => 'Income vs expense this month';

  @override
  String get categorySpendingChartTitle => 'Spending by category this month';

  @override
  String get balanceTrendChartTooltip =>
      'Your net balance across the last 30 days.';

  @override
  String get incomeExpenseChartTooltip =>
      'Total income versus total expense recorded this calendar month.';

  @override
  String get categorySpendingChartTooltip =>
      'How this month\'s spending splits across categories.';

  @override
  String get incomeLegendLabel => 'Income';

  @override
  String get expenseLegendLabel => 'Expense';

  @override
  String get uncategorizedLabel => 'Uncategorized';

  @override
  String get chartNoDataYet => 'No data yet.';

  @override
  String get helpScreenTitle => 'Help';

  @override
  String get helpSectionAccounts => 'What is an account';

  @override
  String get helpSectionRecording => 'Recording money';

  @override
  String get helpSectionBudgets => 'Budgets';

  @override
  String get helpSectionDebts => 'Debts';

  @override
  String get helpBudgetsDescription =>
      'A budget group is a spending category with a monthly amount set aside for it. Spending recorded with no group falls into an automatic \"Others\" bucket. Nothing here is locked — a budget can be changed mid-month, and overspending is shown, never blocked.';

  @override
  String get helpDebtsDescription =>
      'A receivable account is money someone owes you; a payable account is money you owe someone else. \"Paid\" is the sum of repayments recorded against it, and \"remaining\" is its current balance. Ticking settle marks the debt closed without deleting its history.';
}
