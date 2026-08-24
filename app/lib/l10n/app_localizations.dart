import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// Balance sheet app-bar title (brand name, not translated in id either).
  ///
  /// In en, this message translates to:
  /// **'uangsaku'**
  String get balanceSheetTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// No description provided for @navRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get navRecord;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get navBudget;

  /// No description provided for @categoriesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @addAccountTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccountTooltip;

  /// No description provided for @debtDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Debt details'**
  String get debtDetailsTooltip;

  /// No description provided for @figuresLoadError.
  ///
  /// In en, this message translates to:
  /// **'The figures could not be loaded.'**
  String get figuresLoadError;

  /// No description provided for @accountsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsSectionTitle;

  /// No description provided for @accountsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading accounts…'**
  String get accountsLoading;

  /// No description provided for @accountsLoadError.
  ///
  /// In en, this message translates to:
  /// **'The accounts could not be loaded.'**
  String get accountsLoadError;

  /// No description provided for @figureSpendable.
  ///
  /// In en, this message translates to:
  /// **'What I can spend now'**
  String get figureSpendable;

  /// No description provided for @figureOwedToMe.
  ///
  /// In en, this message translates to:
  /// **'Owed to me'**
  String get figureOwedToMe;

  /// No description provided for @figureOwedByMe.
  ///
  /// In en, this message translates to:
  /// **'Owed by me'**
  String get figureOwedByMe;

  /// No description provided for @figureNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get figureNet;

  /// No description provided for @noAccountsYetPeriod.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet.'**
  String get noAccountsYetPeriod;

  /// No description provided for @debtDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt #{accountId}'**
  String debtDetailTitle(int accountId);

  /// No description provided for @markSettled.
  ///
  /// In en, this message translates to:
  /// **'Mark settled'**
  String get markSettled;

  /// No description provided for @figurePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid off'**
  String get figurePaid;

  /// No description provided for @figureRemaining.
  ///
  /// In en, this message translates to:
  /// **'Left to pay'**
  String get figureRemaining;

  /// No description provided for @settledBadge.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settledBadge;

  /// No description provided for @saveCorrectionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save correction'**
  String get saveCorrectionTooltip;

  /// No description provided for @saveChangesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesTooltip;

  /// No description provided for @saveAccountTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save account'**
  String get saveAccountTooltip;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @titleCorrectAccount.
  ///
  /// In en, this message translates to:
  /// **'Correct account'**
  String get titleCorrectAccount;

  /// No description provided for @titleEditAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get titleEditAccount;

  /// No description provided for @titleNewAccount.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get titleNewAccount;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Wallet, credit card, person…'**
  String get nameHint;

  /// No description provided for @openingAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening amount'**
  String get openingAmountLabel;

  /// No description provided for @openingAmountHint.
  ///
  /// In en, this message translates to:
  /// **'What is in it today (minus allowed)'**
  String get openingAmountHint;

  /// No description provided for @currentAmountUnknown.
  ///
  /// In en, this message translates to:
  /// **'Current amount: —'**
  String get currentAmountUnknown;

  /// No description provided for @currentAmountKnown.
  ///
  /// In en, this message translates to:
  /// **'Current amount: {amount}'**
  String currentAmountKnown(int amount);

  /// No description provided for @targetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'What it should actually be'**
  String get targetAmountLabel;

  /// No description provided for @targetAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Target amount (minus allowed)'**
  String get targetAmountHint;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountButton;

  /// No description provided for @duplicateAccountNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name already used'**
  String get duplicateAccountNameTitle;

  /// No description provided for @duplicateAccountNameDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Another account already has this name. It will still be saved.'**
  String get duplicateAccountNameDialogContent;

  /// No description provided for @budgetOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget this month'**
  String get budgetOverviewTitle;

  /// No description provided for @setBudgetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Set budget'**
  String get setBudgetTooltip;

  /// No description provided for @noBudgetGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No budget groups yet'**
  String get noBudgetGroupsYet;

  /// No description provided for @othersLabel.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get othersLabel;

  /// No description provided for @budgetSpentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Budget: {amount}   Spent: {spent}'**
  String budgetSpentSubtitle(int amount, int spent);

  /// No description provided for @setBudgetScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Set the monthly budget'**
  String get setBudgetScreenTitle;

  /// No description provided for @addBudgetGroupTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add budget group'**
  String get addBudgetGroupTooltip;

  /// No description provided for @amountHint.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountHint;

  /// No description provided for @saveAmountTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save amount'**
  String get saveAmountTooltip;

  /// No description provided for @amountSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Amount saved'**
  String get amountSavedMessage;

  /// No description provided for @deletePeriodTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete this month\'s period'**
  String get deletePeriodTooltip;

  /// No description provided for @renameGroupTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rename group'**
  String get renameGroupTooltip;

  /// No description provided for @deleteGroupTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroupTooltip;

  /// No description provided for @categoryManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories and subcategories'**
  String get categoryManagerTitle;

  /// No description provided for @addCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategoryTooltip;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategoriesYet;

  /// No description provided for @addSubcategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add subcategory'**
  String get addSubcategoryTooltip;

  /// No description provided for @renameCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rename category'**
  String get renameCategoryTooltip;

  /// No description provided for @deleteCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get deleteCategoryTooltip;

  /// No description provided for @renameSubcategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rename subcategory'**
  String get renameSubcategoryTooltip;

  /// No description provided for @deleteSubcategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete subcategory'**
  String get deleteSubcategoryTooltip;

  /// No description provided for @recordTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Record money movement'**
  String get recordTransactionTitle;

  /// No description provided for @kindFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'What kind'**
  String get kindFieldLabel;

  /// No description provided for @kindExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get kindExpense;

  /// No description provided for @kindIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get kindIncome;

  /// No description provided for @kindTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get kindTransfer;

  /// No description provided for @kindLend.
  ///
  /// In en, this message translates to:
  /// **'Lend'**
  String get kindLend;

  /// No description provided for @kindBorrow.
  ///
  /// In en, this message translates to:
  /// **'Borrow'**
  String get kindBorrow;

  /// No description provided for @kindRepay.
  ///
  /// In en, this message translates to:
  /// **'Repay'**
  String get kindRepay;

  /// No description provided for @kindRepayment.
  ///
  /// In en, this message translates to:
  /// **'Repayment'**
  String get kindRepayment;

  /// No description provided for @kindAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get kindAdjustment;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @amountHintMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor units, minus allowed'**
  String get amountHintMinor;

  /// No description provided for @noteOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptionalLabel;

  /// No description provided for @payingAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Paying account'**
  String get payingAccountLabel;

  /// No description provided for @receivingAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Receiving account'**
  String get receivingAccountLabel;

  /// No description provided for @sourceAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Source account'**
  String get sourceAccountLabel;

  /// No description provided for @destinationAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination account'**
  String get destinationAccountLabel;

  /// No description provided for @debtPersonLabel.
  ///
  /// In en, this message translates to:
  /// **'Debt / person'**
  String get debtPersonLabel;

  /// No description provided for @personDebtLabel.
  ///
  /// In en, this message translates to:
  /// **'Person / debt'**
  String get personDebtLabel;

  /// No description provided for @ownAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Own account'**
  String get ownAccountLabel;

  /// No description provided for @noneHint.
  ///
  /// In en, this message translates to:
  /// **'(none)'**
  String get noneHint;

  /// No description provided for @categoryOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get categoryOptionalLabel;

  /// No description provided for @subcategoryOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subcategory (optional)'**
  String get subcategoryOptionalLabel;

  /// No description provided for @budgetGroupOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget group (optional)'**
  String get budgetGroupOptionalLabel;

  /// No description provided for @noAccountsYetHint.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get noAccountsYetHint;

  /// No description provided for @createOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Create \'{name}\''**
  String createOptionLabel(String name);

  /// No description provided for @recordedMessage.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get recordedMessage;

  /// No description provided for @allTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'All transactions'**
  String get allTransactionsTitle;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @amendTransactionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Amend transaction'**
  String get amendTransactionTooltip;

  /// No description provided for @deleteTransactionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction'**
  String get deleteTransactionTooltip;

  /// No description provided for @noAccountSet.
  ///
  /// In en, this message translates to:
  /// **'no account set'**
  String get noAccountSet;

  /// No description provided for @amendSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Amend {kind}'**
  String amendSheetTitle(String kind);

  /// No description provided for @fromSideAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'From-side account'**
  String get fromSideAccountLabel;

  /// No description provided for @toSideAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'To-side account'**
  String get toSideAccountLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @subcategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Subcategory'**
  String get subcategoryLabel;

  /// No description provided for @budgetGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget group'**
  String get budgetGroupLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @currencySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencySectionTitle;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @themeModeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeModeSectionTitle;

  /// No description provided for @themeColorSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme color'**
  String get themeColorSectionTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get languageIndonesian;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @currencyRelabelDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Existing amounts are re-labelled, not converted. The same recorded numbers will show with the new currency.'**
  String get currencyRelabelDialogContent;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
