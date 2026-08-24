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
  String get navBalanceSheet => 'Balance Sheet';

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
  String get noAccountsYetPeriod => 'No accounts yet.';

  @override
  String debtDetailTitle(int accountId) {
    return 'Debt #$accountId';
  }

  @override
  String get markSettled => 'Mark settled';

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
}
