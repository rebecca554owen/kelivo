import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
    Locale('zh'),
  ];

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @settingsPageBackButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get settingsPageBackButton;

  /// No description provided for @settingsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPageTitle;

  /// No description provided for @settingsPageDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsPageDarkMode;

  /// No description provided for @settingsPageLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsPageLightMode;

  /// No description provided for @settingsPageSystemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsPageSystemMode;

  /// No description provided for @settingsPageWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Some services are not configured; features may be limited.'**
  String get settingsPageWarningMessage;

  /// No description provided for @settingsPageGeneralSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsPageGeneralSection;

  /// No description provided for @settingsPageColorMode.
  ///
  /// In en, this message translates to:
  /// **'Color Mode'**
  String get settingsPageColorMode;

  /// No description provided for @settingsPageDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsPageDisplay;

  /// No description provided for @settingsPageDisplaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance and text size'**
  String get settingsPageDisplaySubtitle;

  /// No description provided for @settingsPageAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get settingsPageAssistant;

  /// No description provided for @settingsPageAssistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Default assistant and style'**
  String get settingsPageAssistantSubtitle;

  /// No description provided for @settingsPageModelsServicesSection.
  ///
  /// In en, this message translates to:
  /// **'Models & Services'**
  String get settingsPageModelsServicesSection;

  /// No description provided for @settingsPageDefaultModel.
  ///
  /// In en, this message translates to:
  /// **'Default Model'**
  String get settingsPageDefaultModel;

  /// No description provided for @settingsPageProviders.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get settingsPageProviders;

  /// No description provided for @settingsPageSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get settingsPageSearch;

  /// No description provided for @settingsPageTts.
  ///
  /// In en, this message translates to:
  /// **'TTS'**
  String get settingsPageTts;

  /// No description provided for @settingsPageMcp.
  ///
  /// In en, this message translates to:
  /// **'MCP'**
  String get settingsPageMcp;

  /// No description provided for @settingsPageDataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsPageDataSection;

  /// No description provided for @settingsPageBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settingsPageBackup;

  /// No description provided for @settingsPageChatStorage.
  ///
  /// In en, this message translates to:
  /// **'Chat Storage'**
  String get settingsPageChatStorage;

  /// No description provided for @settingsPageCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get settingsPageCalculating;

  /// No description provided for @settingsPageFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files · {size}'**
  String settingsPageFilesCount(int count, String size);

  /// No description provided for @settingsPageAboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsPageAboutSection;

  /// No description provided for @settingsPageAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsPageAbout;

  /// No description provided for @settingsPageDocs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get settingsPageDocs;

  /// No description provided for @settingsPageSponsor.
  ///
  /// In en, this message translates to:
  /// **'Sponsor'**
  String get settingsPageSponsor;

  /// No description provided for @settingsPageShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get settingsPageShare;

  /// No description provided for @languageDisplaySimplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get languageDisplaySimplifiedChinese;

  /// No description provided for @languageDisplayEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageDisplayEnglish;

  /// No description provided for @languageDisplayTraditionalChinese.
  ///
  /// In en, this message translates to:
  /// **'Traditional Chinese'**
  String get languageDisplayTraditionalChinese;

  /// No description provided for @languageDisplayJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageDisplayJapanese;

  /// No description provided for @languageDisplayKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get languageDisplayKorean;

  /// No description provided for @languageDisplayFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageDisplayFrench;

  /// No description provided for @languageDisplayGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageDisplayGerman;

  /// No description provided for @languageDisplayItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get languageDisplayItalian;

  /// No description provided for @languageSelectSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Translation Language'**
  String get languageSelectSheetTitle;

  /// No description provided for @languageSelectSheetClearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear Translation'**
  String get languageSelectSheetClearButton;

  /// No description provided for @homePageClearContext.
  ///
  /// In en, this message translates to:
  /// **'Clear Context'**
  String get homePageClearContext;

  /// No description provided for @homePageClearContextWithCount.
  ///
  /// In en, this message translates to:
  /// **'Clear Context ({actual}/{configured})'**
  String homePageClearContextWithCount(String actual, String configured);

  /// No description provided for @homePageDefaultAssistant.
  ///
  /// In en, this message translates to:
  /// **'Default Assistant'**
  String get homePageDefaultAssistant;

  /// No description provided for @homePageDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get homePageDeleteMessage;

  /// No description provided for @homePageDeleteMessageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message? This cannot be undone.'**
  String get homePageDeleteMessageConfirm;

  /// No description provided for @homePageCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get homePageCancel;

  /// No description provided for @homePageDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get homePageDelete;

  /// No description provided for @homePageSelectMessagesToShare.
  ///
  /// In en, this message translates to:
  /// **'Please select messages to share'**
  String get homePageSelectMessagesToShare;

  /// No description provided for @homePageDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get homePageDone;
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
