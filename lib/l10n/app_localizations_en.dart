// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World!';

  @override
  String get settingsPageBackButton => 'Back';

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get settingsPageDarkMode => 'Dark';

  @override
  String get settingsPageLightMode => 'Light';

  @override
  String get settingsPageSystemMode => 'System';

  @override
  String get settingsPageWarningMessage =>
      'Some services are not configured; features may be limited.';

  @override
  String get settingsPageGeneralSection => 'General';

  @override
  String get settingsPageColorMode => 'Color Mode';

  @override
  String get settingsPageDisplay => 'Display';

  @override
  String get settingsPageDisplaySubtitle => 'Appearance and text size';

  @override
  String get settingsPageAssistant => 'Assistant';

  @override
  String get settingsPageAssistantSubtitle => 'Default assistant and style';

  @override
  String get settingsPageModelsServicesSection => 'Models & Services';

  @override
  String get settingsPageDefaultModel => 'Default Model';

  @override
  String get settingsPageProviders => 'Providers';

  @override
  String get settingsPageSearch => 'Search';

  @override
  String get settingsPageTts => 'TTS';

  @override
  String get settingsPageMcp => 'MCP';

  @override
  String get settingsPageDataSection => 'Data';

  @override
  String get settingsPageBackup => 'Backup';

  @override
  String get settingsPageChatStorage => 'Chat Storage';

  @override
  String get settingsPageCalculating => 'Calculating…';

  @override
  String settingsPageFilesCount(int count, String size) {
    return '$count files · $size';
  }

  @override
  String get settingsPageAboutSection => 'About';

  @override
  String get settingsPageAbout => 'About';

  @override
  String get settingsPageDocs => 'Docs';

  @override
  String get settingsPageSponsor => 'Sponsor';

  @override
  String get settingsPageShare => 'Share';

  @override
  String get languageDisplaySimplifiedChinese => 'Simplified Chinese';

  @override
  String get languageDisplayEnglish => 'English';

  @override
  String get languageDisplayTraditionalChinese => 'Traditional Chinese';

  @override
  String get languageDisplayJapanese => 'Japanese';

  @override
  String get languageDisplayKorean => 'Korean';

  @override
  String get languageDisplayFrench => 'French';

  @override
  String get languageDisplayGerman => 'German';

  @override
  String get languageDisplayItalian => 'Italian';

  @override
  String get languageSelectSheetTitle => 'Select Translation Language';

  @override
  String get languageSelectSheetClearButton => 'Clear Translation';

  @override
  String get homePageClearContext => 'Clear Context';

  @override
  String homePageClearContextWithCount(String actual, String configured) {
    return 'Clear Context ($actual/$configured)';
  }

  @override
  String get homePageDefaultAssistant => 'Default Assistant';

  @override
  String get homePageDeleteMessage => 'Delete Message';

  @override
  String get homePageDeleteMessageConfirm =>
      'Are you sure you want to delete this message? This cannot be undone.';

  @override
  String get homePageCancel => 'Cancel';

  @override
  String get homePageDelete => 'Delete';

  @override
  String get homePageSelectMessagesToShare => 'Please select messages to share';

  @override
  String get homePageDone => 'Done';

  @override
  String get assistantEditPageTitle => 'Assistant';

  @override
  String get assistantEditPageNotFound => 'Assistant not found';

  @override
  String get assistantEditPageBasicTab => 'Basic';

  @override
  String get assistantEditPagePromptsTab => 'Prompts';

  @override
  String get assistantEditPageMcpTab => 'MCP';

  @override
  String get assistantEditPageCustomTab => 'Custom';

  @override
  String get assistantEditCustomHeadersTitle => 'Custom Headers';

  @override
  String get assistantEditCustomHeadersAdd => 'Add Header';

  @override
  String get assistantEditCustomHeadersEmpty => 'No headers added';

  @override
  String get assistantEditCustomBodyTitle => 'Custom Body';

  @override
  String get assistantEditCustomBodyAdd => 'Add Body';

  @override
  String get assistantEditCustomBodyEmpty => 'No body items added';

  @override
  String get assistantEditHeaderNameLabel => 'Header Name';

  @override
  String get assistantEditHeaderValueLabel => 'Header Value';

  @override
  String get assistantEditBodyKeyLabel => 'Body Key';

  @override
  String get assistantEditBodyValueLabel => 'Body Value (JSON)';

  @override
  String get assistantEditDeleteTooltip => 'Delete';

  @override
  String get assistantEditAssistantNameLabel => 'Assistant Name';

  @override
  String get assistantEditUseAssistantAvatarTitle => 'Use Assistant Avatar';

  @override
  String get assistantEditUseAssistantAvatarSubtitle =>
      'Use assistant avatar/name instead of model';

  @override
  String get assistantEditChatModelTitle => 'Chat Model';

  @override
  String get assistantEditChatModelSubtitle =>
      'Default chat model for this assistant (fallback to global)';

  @override
  String get assistantEditTemperatureDescription =>
      'Controls randomness, range 0–2';

  @override
  String get assistantEditTopPDescription =>
      'Do not change unless you know what you are doing';

  @override
  String get assistantEditParameterDisabled =>
      'Disabled (uses provider default)';

  @override
  String get assistantEditContextMessagesTitle => 'Context Messages';

  @override
  String get assistantEditContextMessagesDescription =>
      'How many recent messages to keep in context';

  @override
  String get assistantEditStreamOutputTitle => 'Stream Output';

  @override
  String get assistantEditStreamOutputDescription =>
      'Enable streaming responses';

  @override
  String get assistantEditThinkingBudgetTitle => 'Thinking Budget';

  @override
  String get assistantEditConfigureButton => 'Configure';

  @override
  String get assistantEditMaxTokensTitle => 'Max Tokens';

  @override
  String get assistantEditMaxTokensDescription => 'Leave empty for unlimited';

  @override
  String get assistantEditMaxTokensHint => 'Unlimited';

  @override
  String get assistantEditChatBackgroundTitle => 'Chat Background';

  @override
  String get assistantEditChatBackgroundDescription =>
      'Set a background image for this assistant';

  @override
  String get assistantEditChooseImageButton => 'Choose Image';

  @override
  String get assistantEditClearButton => 'Clear';

  @override
  String get assistantEditAvatarChooseImage => 'Choose Image';

  @override
  String get assistantEditAvatarChooseEmoji => 'Choose Emoji';

  @override
  String get assistantEditAvatarEnterLink => 'Enter Link';

  @override
  String get assistantEditAvatarImportQQ => 'Import from QQ';

  @override
  String get assistantEditAvatarReset => 'Reset';

  @override
  String get assistantEditEmojiDialogTitle => 'Choose Emoji';

  @override
  String get assistantEditEmojiDialogHint => 'Type or paste any emoji';

  @override
  String get assistantEditEmojiDialogCancel => 'Cancel';

  @override
  String get assistantEditEmojiDialogSave => 'Save';

  @override
  String get assistantEditImageUrlDialogTitle => 'Enter Image URL';

  @override
  String get assistantEditImageUrlDialogHint =>
      'e.g. https://example.com/avatar.png';

  @override
  String get assistantEditImageUrlDialogCancel => 'Cancel';

  @override
  String get assistantEditImageUrlDialogSave => 'Save';

  @override
  String get assistantEditQQAvatarDialogTitle => 'Import from QQ';

  @override
  String get assistantEditQQAvatarDialogHint => 'Enter QQ number (5-12 digits)';

  @override
  String get assistantEditQQAvatarRandomButton => 'Random One';

  @override
  String get assistantEditQQAvatarFailedMessage =>
      'Failed to fetch random QQ avatar. Please try again.';

  @override
  String get assistantEditQQAvatarDialogCancel => 'Cancel';

  @override
  String get assistantEditQQAvatarDialogSave => 'Save';

  @override
  String get assistantEditGalleryErrorMessage =>
      'Unable to open gallery. Try entering an image URL.';

  @override
  String get assistantEditGeneralErrorMessage =>
      'Something went wrong. Try entering an image URL.';

  @override
  String get assistantEditSystemPromptTitle => 'System Prompt';

  @override
  String get assistantEditSystemPromptHint => 'Enter system prompt…';

  @override
  String get assistantEditAvailableVariables => 'Available variables:';

  @override
  String get assistantEditVariableDate => 'Date';

  @override
  String get assistantEditVariableTime => 'Time';

  @override
  String get assistantEditVariableDatetime => 'Datetime';

  @override
  String get assistantEditVariableModelId => 'Model ID';

  @override
  String get assistantEditVariableModelName => 'Model Name';

  @override
  String get assistantEditVariableLocale => 'Locale';

  @override
  String get assistantEditVariableTimezone => 'Timezone';

  @override
  String get assistantEditVariableSystemVersion => 'System Version';

  @override
  String get assistantEditVariableDeviceInfo => 'Device Info';

  @override
  String get assistantEditVariableBatteryLevel => 'Battery Level';

  @override
  String get assistantEditVariableNickname => 'Nickname';

  @override
  String get assistantEditMessageTemplateTitle => 'Message Template';

  @override
  String get assistantEditVariableRole => 'Role';

  @override
  String get assistantEditVariableMessage => 'Message';

  @override
  String get assistantEditPreviewTitle => 'Preview';

  @override
  String get assistantEditSampleUser => 'User';

  @override
  String get assistantEditSampleMessage => 'Hello there';

  @override
  String get assistantEditSampleReply => 'Hello, how can I help you?';

  @override
  String get assistantEditMcpNoServersMessage => 'No running MCP servers';

  @override
  String get assistantEditMcpConnectedTag => 'Connected';

  @override
  String assistantEditMcpToolsCountTag(String enabled, String total) {
    return 'Tools: $enabled/$total';
  }

  @override
  String get assistantEditModelUseGlobalDefault => 'Use global default';

  @override
  String get assistantSettingsPageTitle => 'Assistant Settings';

  @override
  String get assistantSettingsDefaultTag => 'Default';

  @override
  String get assistantSettingsDeleteButton => 'Delete';

  @override
  String get assistantSettingsEditButton => 'Edit';

  @override
  String get assistantSettingsAddSheetTitle => 'Assistant Name';

  @override
  String get assistantSettingsAddSheetHint => 'Enter a name';

  @override
  String get assistantSettingsAddSheetCancel => 'Cancel';

  @override
  String get assistantSettingsAddSheetSave => 'Save';

  @override
  String get assistantSettingsDeleteDialogTitle => 'Delete Assistant';

  @override
  String get assistantSettingsDeleteDialogContent =>
      'Are you sure you want to delete this assistant? This action cannot be undone.';

  @override
  String get assistantSettingsDeleteDialogCancel => 'Cancel';

  @override
  String get assistantSettingsDeleteDialogConfirm => 'Delete';

  @override
  String get mcpAssistantSheetTitle => 'MCP Servers';

  @override
  String get mcpAssistantSheetSubtitle => 'Servers enabled for this assistant';

  @override
  String get mcpAssistantSheetSelectAll => 'Select All';

  @override
  String get mcpAssistantSheetClearAll => 'Clear';

  @override
  String get backupPageTitle => 'Backup & Restore';

  @override
  String get backupPageWebDavTab => 'WebDAV';

  @override
  String get backupPageImportExportTab => 'Import/Export';

  @override
  String get backupPageWebDavServerUrl => 'WebDAV Server URL';

  @override
  String get backupPageUsername => 'Username';

  @override
  String get backupPagePassword => 'Password';

  @override
  String get backupPagePath => 'Path';

  @override
  String get backupPageChatsLabel => 'Chats';

  @override
  String get backupPageFilesLabel => 'Files';

  @override
  String get backupPageTestDone => 'Test done';

  @override
  String get backupPageTestConnection => 'Test';

  @override
  String get backupPageRestartRequired => 'Restart Required';

  @override
  String get backupPageRestartContent =>
      'Restore completed. Please restart the app.';

  @override
  String get backupPageOK => 'OK';

  @override
  String get backupPageRestore => 'Restore';

  @override
  String get backupPageBackupUploaded => 'Backup uploaded';

  @override
  String get backupPageBackup => 'Backup';

  @override
  String get backupPageExportToFile => 'Export to File';

  @override
  String get backupPageExportToFileSubtitle => 'Export app data to a file';

  @override
  String get backupPageImportBackupFile => 'Import Backup File';

  @override
  String get backupPageImportBackupFileSubtitle => 'Import a local backup file';

  @override
  String get backupPageImportFromOtherApps => 'Import from Other Apps';

  @override
  String get backupPageImportFromRikkaHub => 'Import from RikkaHub';

  @override
  String get backupPageNotSupportedYet => 'Not supported yet';

  @override
  String get backupPageRemoteBackups => 'Remote Backups';

  @override
  String get backupPageNoBackups => 'No backups';

  @override
  String get backupPageRestoreTooltip => 'Restore';

  @override
  String get backupPageDeleteTooltip => 'Delete';

  @override
  String get chatHistoryPageTitle => 'Chat History';

  @override
  String get chatHistoryPageSearchTooltip => 'Search';

  @override
  String get chatHistoryPageDeleteAllTooltip => 'Delete All';

  @override
  String get chatHistoryPageDeleteAllDialogTitle => 'Delete All Conversations';

  @override
  String get chatHistoryPageDeleteAllDialogContent =>
      'Are you sure you want to delete all conversations? This cannot be undone.';

  @override
  String get chatHistoryPageCancel => 'Cancel';

  @override
  String get chatHistoryPageDelete => 'Delete';

  @override
  String get chatHistoryPageDeletedAllSnackbar => 'All conversations deleted';

  @override
  String get chatHistoryPageSearchHint => 'Search conversations';

  @override
  String get chatHistoryPageNoConversations => 'No conversations';

  @override
  String get chatHistoryPagePinnedSection => 'Pinned';

  @override
  String get chatHistoryPagePin => 'Pin';

  @override
  String get chatHistoryPagePinned => 'Pinned';

  @override
  String get messageEditPageTitle => 'Edit Message';

  @override
  String get messageEditPageSave => 'Save';

  @override
  String get messageEditPageHint => 'Enter message…';

  @override
  String get selectCopyPageTitle => 'Select & Copy';

  @override
  String get selectCopyPageCopyAll => 'Copy All';

  @override
  String get selectCopyPageCopiedAll => 'Copied all';

  @override
  String get bottomToolsSheetCamera => 'Camera';

  @override
  String get bottomToolsSheetPhotos => 'Photos';

  @override
  String get bottomToolsSheetUpload => 'Upload';

  @override
  String get bottomToolsSheetClearContext => 'Clear Context';

  @override
  String get bottomToolsSheetLearningMode => 'Learning Mode';

  @override
  String get bottomToolsSheetLearningModeDescription =>
      'Help you learn step by step';

  @override
  String get bottomToolsSheetConfigurePrompt => 'Configure prompt';

  @override
  String get bottomToolsSheetPrompt => 'Prompt';

  @override
  String get bottomToolsSheetPromptHint => 'Enter prompt for learning mode';

  @override
  String get bottomToolsSheetResetDefault => 'Reset to default';

  @override
  String get bottomToolsSheetSave => 'Save';

  @override
  String get messageMoreSheetTitle => 'More Actions';

  @override
  String get messageMoreSheetSelectCopy => 'Select & Copy';

  @override
  String get messageMoreSheetRenderWebView => 'Render Web View';

  @override
  String get messageMoreSheetNotImplemented => 'Not yet implemented';

  @override
  String get messageMoreSheetEdit => 'Edit';

  @override
  String get messageMoreSheetShare => 'Share';

  @override
  String get messageMoreSheetCreateBranch => 'Create Branch';

  @override
  String get messageMoreSheetDelete => 'Delete';
}
