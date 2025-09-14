// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get helloWorld => '你好，世界！';

  @override
  String get settingsPageBackButton => '返回';

  @override
  String get settingsPageTitle => '设置';

  @override
  String get settingsPageDarkMode => '深色';

  @override
  String get settingsPageLightMode => '浅色';

  @override
  String get settingsPageSystemMode => '跟随系统';

  @override
  String get settingsPageWarningMessage => '部分服务未配置，某些功能可能不可用';

  @override
  String get settingsPageGeneralSection => '通用设置';

  @override
  String get settingsPageColorMode => '颜色模式';

  @override
  String get settingsPageDisplay => '显示设置';

  @override
  String get settingsPageDisplaySubtitle => '界面主题与字号等外观设置';

  @override
  String get settingsPageAssistant => '助手';

  @override
  String get settingsPageAssistantSubtitle => '默认助手与对话风格';

  @override
  String get settingsPageModelsServicesSection => '模型与服务';

  @override
  String get settingsPageDefaultModel => '默认模型';

  @override
  String get settingsPageProviders => '供应商';

  @override
  String get settingsPageSearch => '搜索服务';

  @override
  String get settingsPageTts => '语音服务';

  @override
  String get settingsPageMcp => 'MCP';

  @override
  String get settingsPageDataSection => '数据设置';

  @override
  String get settingsPageBackup => '数据备份';

  @override
  String get settingsPageChatStorage => '聊天记录存储';

  @override
  String get settingsPageCalculating => '统计中…';

  @override
  String settingsPageFilesCount(int count, String size) {
    return '共 $count 个文件 · $size';
  }

  @override
  String get settingsPageAboutSection => '关于';

  @override
  String get settingsPageAbout => '关于';

  @override
  String get settingsPageDocs => '使用文档';

  @override
  String get settingsPageSponsor => '赞助';

  @override
  String get settingsPageShare => '分享';

  @override
  String get sponsorPageMethodsSectionTitle => '赞助方式';

  @override
  String get sponsorPageSponsorsSectionTitle => '赞助用户';

  @override
  String get sponsorPageEmpty => '暂无赞助者';

  @override
  String get sponsorPageAfdianTitle => '爱发电';

  @override
  String get sponsorPageAfdianSubtitle => 'afdian.com/a/kelivo';

  @override
  String get sponsorPageWeChatTitle => '微信赞助';

  @override
  String get sponsorPageWeChatSubtitle => '微信赞助码';

  @override
  String get languageDisplaySimplifiedChinese => '简体中文';

  @override
  String get languageDisplayEnglish => 'English';

  @override
  String get languageDisplayTraditionalChinese => '繁體中文';

  @override
  String get languageDisplayJapanese => '日本語';

  @override
  String get languageDisplayKorean => '한국어';

  @override
  String get languageDisplayFrench => 'Français';

  @override
  String get languageDisplayGerman => 'Deutsch';

  @override
  String get languageDisplayItalian => 'Italiano';

  @override
  String get languageSelectSheetTitle => '选择翻译语言';

  @override
  String get languageSelectSheetClearButton => '清空翻译';

  @override
  String get homePageClearContext => '清空上下文';

  @override
  String homePageClearContextWithCount(String actual, String configured) {
    return '清空上下文 ($actual/$configured)';
  }

  @override
  String get homePageDefaultAssistant => '默认助手';

  @override
  String get mermaidExportPng => '导出 PNG';

  @override
  String get mermaidExportFailed => '导出失败';

  @override
  String get mermaidPreviewOpen => '浏览器预览';

  @override
  String get mermaidPreviewOpenFailed => '无法打开预览';

  @override
  String get assistantProviderDefaultAssistantName => '默认助手';

  @override
  String get assistantProviderSampleAssistantName => '示例助手';

  @override
  String get assistantProviderNewAssistantName => '新助手';

  @override
  String assistantProviderSampleAssistantSystemPrompt(
    String model_name,
    String cur_datetime,
    String locale,
    String timezone,
    String device_info,
    String system_version,
  ) {
    return '你是$model_name, 一个人工智能助手，乐意为用户提供准确，有益的帮助。现在时间是$cur_datetime，用户设备语言为$locale，时区为$timezone，用户正在使用$device_info，版本$system_version。如果用户没有明确说明，请使用用户设备语言进行回复。';
  }

  @override
  String get displaySettingsPageLanguageTitle => '应用语言';

  @override
  String get displaySettingsPageLanguageSubtitle => '选择界面语言';

  @override
  String get displaySettingsPageLanguageChineseLabel => '简体中文';

  @override
  String get displaySettingsPageLanguageEnglishLabel => 'English';

  @override
  String get homePagePleaseSelectModel => '请先选择模型';

  @override
  String get homePagePleaseSetupTranslateModel => '请先设置翻译模型';

  @override
  String get homePageTranslating => '翻译中...';

  @override
  String homePageTranslateFailed(String error) {
    return '翻译失败: $error';
  }

  @override
  String get chatServiceDefaultConversationTitle => '新对话';

  @override
  String get userProviderDefaultUserName => '用户';

  @override
  String get homePageDeleteMessage => '删除消息';

  @override
  String get homePageDeleteMessageConfirm => '确定要删除这条消息吗？此操作不可撤销。';

  @override
  String get homePageCancel => '取消';

  @override
  String get homePageDelete => '删除';

  @override
  String get homePageSelectMessagesToShare => '请选择要分享的消息';

  @override
  String get homePageDone => '完成';

  @override
  String get assistantEditPageTitle => '助手';

  @override
  String get assistantEditPageNotFound => '助手不存在';

  @override
  String get assistantEditPageBasicTab => '基础设置';

  @override
  String get assistantEditPagePromptsTab => '提示词';

  @override
  String get assistantEditPageMcpTab => 'MCP';

  @override
  String get assistantEditPageCustomTab => '自定义请求';

  @override
  String get assistantEditCustomHeadersTitle => '自定义 Header';

  @override
  String get assistantEditCustomHeadersAdd => '添加 Header';

  @override
  String get assistantEditCustomHeadersEmpty => '未添加 Header';

  @override
  String get assistantEditCustomBodyTitle => '自定义 Body';

  @override
  String get assistantEditCustomBodyAdd => '添加 Body';

  @override
  String get assistantEditCustomBodyEmpty => '未添加 Body 项';

  @override
  String get assistantEditHeaderNameLabel => 'Header 名称';

  @override
  String get assistantEditHeaderValueLabel => 'Header 值';

  @override
  String get assistantEditBodyKeyLabel => 'Body Key';

  @override
  String get assistantEditBodyValueLabel => 'Body 值 (JSON)';

  @override
  String get assistantEditDeleteTooltip => '删除';

  @override
  String get assistantEditAssistantNameLabel => '助手名称';

  @override
  String get assistantEditUseAssistantAvatarTitle => '使用助手头像';

  @override
  String get assistantEditUseAssistantAvatarSubtitle =>
      '在聊天中使用助手头像和名字而不是模型头像和名字';

  @override
  String get assistantEditChatModelTitle => '聊天模型';

  @override
  String get assistantEditChatModelSubtitle => '为该助手设置默认聊天模型（未设置时使用全局默认）';

  @override
  String get assistantEditTemperatureDescription => '控制输出的随机性，范围 0–2';

  @override
  String get assistantEditTopPDescription => '请不要修改此值，除非你知道自己在做什么';

  @override
  String get assistantEditParameterDisabled => '已关闭（使用服务商默认）';

  @override
  String get assistantEditParameterDisabled2 => '已关闭（无限制）';

  @override
  String get assistantEditContextMessagesTitle => '上下文消息数量';

  @override
  String get assistantEditContextMessagesDescription =>
      '多少历史消息会被当作上下文发送给模型，超过数量会忽略，只保留最近 N 条';

  @override
  String get assistantEditStreamOutputTitle => '流式输出';

  @override
  String get assistantEditStreamOutputDescription => '是否启用消息的流式输出';

  @override
  String get assistantEditThinkingBudgetTitle => '思考预算';

  @override
  String get assistantEditConfigureButton => '配置';

  @override
  String get assistantEditMaxTokensTitle => '最大 Token 数';

  @override
  String get assistantEditMaxTokensDescription => '留空表示无限制';

  @override
  String get assistantEditMaxTokensHint => '无限制';

  @override
  String get assistantEditChatBackgroundTitle => '聊天背景';

  @override
  String get assistantEditChatBackgroundDescription => '设置助手聊天页面的背景图片';

  @override
  String get assistantEditChooseImageButton => '选择背景图片';

  @override
  String get assistantEditClearButton => '清除';

  @override
  String get assistantEditAvatarChooseImage => '选择图片';

  @override
  String get assistantEditAvatarChooseEmoji => '选择表情';

  @override
  String get assistantEditAvatarEnterLink => '输入链接';

  @override
  String get assistantEditAvatarImportQQ => 'QQ头像';

  @override
  String get assistantEditAvatarReset => '重置';

  @override
  String get assistantEditEmojiDialogTitle => '选择表情';

  @override
  String get assistantEditEmojiDialogHint => '输入或粘贴任意表情';

  @override
  String get assistantEditEmojiDialogCancel => '取消';

  @override
  String get assistantEditEmojiDialogSave => '保存';

  @override
  String get assistantEditImageUrlDialogTitle => '输入图片链接';

  @override
  String get assistantEditImageUrlDialogHint =>
      '例如: https://example.com/avatar.png';

  @override
  String get assistantEditImageUrlDialogCancel => '取消';

  @override
  String get assistantEditImageUrlDialogSave => '保存';

  @override
  String get assistantEditQQAvatarDialogTitle => '使用QQ头像';

  @override
  String get assistantEditQQAvatarDialogHint => '输入QQ号码（5-12位）';

  @override
  String get assistantEditQQAvatarRandomButton => '随机QQ';

  @override
  String get assistantEditQQAvatarFailedMessage => '获取随机QQ头像失败，请重试';

  @override
  String get assistantEditQQAvatarDialogCancel => '取消';

  @override
  String get assistantEditQQAvatarDialogSave => '保存';

  @override
  String get assistantEditGalleryErrorMessage => '无法打开相册，试试输入图片链接';

  @override
  String get assistantEditGeneralErrorMessage => '发生错误，试试输入图片链接';

  @override
  String get assistantEditSystemPromptTitle => '系统提示词';

  @override
  String get assistantEditSystemPromptHint => '输入系统提示词…';

  @override
  String get assistantEditAvailableVariables => '可用变量：';

  @override
  String get assistantEditVariableDate => '日期';

  @override
  String get assistantEditVariableTime => '时间';

  @override
  String get assistantEditVariableDatetime => '日期和时间';

  @override
  String get assistantEditVariableModelId => '模型ID';

  @override
  String get assistantEditVariableModelName => '模型名称';

  @override
  String get assistantEditVariableLocale => '语言环境';

  @override
  String get assistantEditVariableTimezone => '时区';

  @override
  String get assistantEditVariableSystemVersion => '系统版本';

  @override
  String get assistantEditVariableDeviceInfo => '设备信息';

  @override
  String get assistantEditVariableBatteryLevel => '电池电量';

  @override
  String get assistantEditVariableNickname => '用户昵称';

  @override
  String get assistantEditMessageTemplateTitle => '聊天内容模板';

  @override
  String get assistantEditVariableRole => '角色';

  @override
  String get assistantEditVariableMessage => '内容';

  @override
  String get assistantEditPreviewTitle => '预览';

  @override
  String get assistantEditSampleUser => '用户';

  @override
  String get assistantEditSampleMessage => '你好啊';

  @override
  String get assistantEditSampleReply => '你好，有什么我可以帮你的吗？';

  @override
  String get assistantEditMcpNoServersMessage => '暂无已启动的 MCP 服务器';

  @override
  String get assistantEditMcpConnectedTag => '已连接';

  @override
  String assistantEditMcpToolsCountTag(String enabled, String total) {
    return '工具: $enabled/$total';
  }

  @override
  String get assistantEditModelUseGlobalDefault => '使用全局默认';

  @override
  String get assistantSettingsPageTitle => '助手设置';

  @override
  String get assistantSettingsDefaultTag => '默认';

  @override
  String get assistantSettingsDeleteButton => '删除';

  @override
  String get assistantSettingsEditButton => '编辑';

  @override
  String get assistantSettingsAddSheetTitle => '助手名称';

  @override
  String get assistantSettingsAddSheetHint => '输入助手名称';

  @override
  String get assistantSettingsAddSheetCancel => '取消';

  @override
  String get assistantSettingsAddSheetSave => '保存';

  @override
  String get assistantSettingsDeleteDialogTitle => '删除助手';

  @override
  String get assistantSettingsDeleteDialogContent => '确定要删除该助手吗？此操作不可撤销。';

  @override
  String get assistantSettingsDeleteDialogCancel => '取消';

  @override
  String get assistantSettingsDeleteDialogConfirm => '删除';

  @override
  String get mcpAssistantSheetTitle => 'MCP服务器';

  @override
  String get mcpAssistantSheetSubtitle => '为该助手启用的服务';

  @override
  String get mcpAssistantSheetSelectAll => '全选';

  @override
  String get mcpAssistantSheetClearAll => '全不选';

  @override
  String get backupPageTitle => '备份与恢复';

  @override
  String get backupPageWebDavTab => 'WebDAV 备份';

  @override
  String get backupPageImportExportTab => '导入和导出';

  @override
  String get backupPageWebDavServerUrl => 'WebDAV 服务器地址';

  @override
  String get backupPageUsername => '用户名';

  @override
  String get backupPagePassword => '密码';

  @override
  String get backupPagePath => '路径';

  @override
  String get backupPageChatsLabel => '聊天记录';

  @override
  String get backupPageFilesLabel => '文件';

  @override
  String get backupPageTestDone => '测试完成';

  @override
  String get backupPageTestConnection => '测试连接';

  @override
  String get backupPageRestartRequired => '需要重启应用';

  @override
  String get backupPageRestartContent => '恢复完成，需要重启以完全生效。';

  @override
  String get backupPageOK => '好的';

  @override
  String get backupPageCancel => '取消';

  @override
  String get backupPageSelectImportMode => '选择导入模式';

  @override
  String get backupPageSelectImportModeDescription => '请选择如何导入备份数据：';

  @override
  String get backupPageOverwriteMode => '完全覆盖';

  @override
  String get backupPageOverwriteModeDescription => '清空本地所有数据后恢复';

  @override
  String get backupPageMergeMode => '智能合并';

  @override
  String get backupPageMergeModeDescription => '仅添加不存在的数据（智能去重）';

  @override
  String get backupPageRestore => '恢复';

  @override
  String get backupPageBackupUploaded => '已上传备份';

  @override
  String get backupPageBackup => '立即备份';

  @override
  String get backupPageExporting => '正在导出...';

  @override
  String get backupPageExportToFile => '导出为文件';

  @override
  String get backupPageExportToFileSubtitle => '导出APP数据为文件';

  @override
  String get backupPageImportBackupFile => '备份文件导入';

  @override
  String get backupPageImportBackupFileSubtitle => '导入本地备份文件';

  @override
  String get backupPageImportFromOtherApps => '从其他APP导入';

  @override
  String get backupPageImportFromRikkaHub => '从 RikkaHub 导入';

  @override
  String get backupPageNotSupportedYet => '暂不支持';

  @override
  String get backupPageRemoteBackups => '远端备份';

  @override
  String get backupPageNoBackups => '暂无备份';

  @override
  String get backupPageRestoreTooltip => '恢复';

  @override
  String get backupPageDeleteTooltip => '删除';

  @override
  String get chatHistoryPageTitle => '聊天历史';

  @override
  String get chatHistoryPageSearchTooltip => '搜索';

  @override
  String get chatHistoryPageDeleteAllTooltip => '删除全部';

  @override
  String get chatHistoryPageDeleteAllDialogTitle => '删除全部对话';

  @override
  String get chatHistoryPageDeleteAllDialogContent => '确定要删除全部对话吗？此操作不可撤销。';

  @override
  String get chatHistoryPageCancel => '取消';

  @override
  String get chatHistoryPageDelete => '删除';

  @override
  String get chatHistoryPageDeletedAllSnackbar => '已删除全部对话';

  @override
  String get chatHistoryPageSearchHint => '搜索对话';

  @override
  String get chatHistoryPageNoConversations => '暂无对话';

  @override
  String get chatHistoryPagePinnedSection => '置顶';

  @override
  String get chatHistoryPagePin => '置顶';

  @override
  String get chatHistoryPagePinned => '已置顶';

  @override
  String get messageEditPageTitle => '编辑消息';

  @override
  String get messageEditPageSave => '保存';

  @override
  String get messageEditPageHint => '输入消息内容…';

  @override
  String get selectCopyPageTitle => '选择复制';

  @override
  String get selectCopyPageCopyAll => '复制全部';

  @override
  String get selectCopyPageCopiedAll => '已复制全部';

  @override
  String get bottomToolsSheetCamera => '拍照';

  @override
  String get bottomToolsSheetPhotos => '照片';

  @override
  String get bottomToolsSheetUpload => '上传文件';

  @override
  String get bottomToolsSheetClearContext => '清空上下文';

  @override
  String get bottomToolsSheetLearningMode => '学习模式';

  @override
  String get bottomToolsSheetLearningModeDescription => '帮助你循序渐进地学习知识';

  @override
  String get bottomToolsSheetConfigurePrompt => '设置提示词';

  @override
  String get bottomToolsSheetPrompt => '提示词';

  @override
  String get bottomToolsSheetPromptHint => '输入用于学习模式的提示词';

  @override
  String get bottomToolsSheetResetDefault => '重置为默认';

  @override
  String get bottomToolsSheetSave => '保存';

  @override
  String get messageMoreSheetTitle => '更多操作';

  @override
  String get messageMoreSheetSelectCopy => '选择复制';

  @override
  String get messageMoreSheetRenderWebView => '网页视图渲染';

  @override
  String get messageMoreSheetNotImplemented => '暂未实现';

  @override
  String get messageMoreSheetEdit => '编辑';

  @override
  String get messageMoreSheetShare => '分享';

  @override
  String get messageMoreSheetCreateBranch => '创建分支';

  @override
  String get messageMoreSheetDelete => '删除';

  @override
  String get reasoningBudgetSheetOff => '关闭';

  @override
  String get reasoningBudgetSheetAuto => '自动';

  @override
  String get reasoningBudgetSheetLight => '轻度推理';

  @override
  String get reasoningBudgetSheetMedium => '中度推理';

  @override
  String get reasoningBudgetSheetHeavy => '重度推理';

  @override
  String get reasoningBudgetSheetTitle => '思维链强度';

  @override
  String reasoningBudgetSheetCurrentLevel(String level) {
    return '当前档位：$level';
  }

  @override
  String get reasoningBudgetSheetOffSubtitle => '关闭推理功能，直接回答';

  @override
  String get reasoningBudgetSheetAutoSubtitle => '由模型自动决定推理级别';

  @override
  String get reasoningBudgetSheetLightSubtitle => '使用少量推理来回答问题';

  @override
  String get reasoningBudgetSheetMediumSubtitle => '使用较多推理来回答问题';

  @override
  String get reasoningBudgetSheetHeavySubtitle => '使用大量推理来回答问题，适合复杂问题';

  @override
  String get reasoningBudgetSheetCustomLabel => '自定义推理预算 (tokens)';

  @override
  String get reasoningBudgetSheetCustomHint => '例如：2048 (-1 自动，0 关闭)';

  @override
  String chatMessageWidgetFileNotFound(String fileName) {
    return '文件不存在: $fileName';
  }

  @override
  String chatMessageWidgetCannotOpenFile(String message) {
    return '无法打开文件: $message';
  }

  @override
  String chatMessageWidgetOpenFileError(String error) {
    return '打开文件失败: $error';
  }

  @override
  String get chatMessageWidgetCopiedToClipboard => '已复制到剪贴板';

  @override
  String get chatMessageWidgetResendTooltip => '重新发送';

  @override
  String get chatMessageWidgetMoreTooltip => '更多';

  @override
  String get chatMessageWidgetThinking => '正在思考...';

  @override
  String get chatMessageWidgetTranslation => '翻译';

  @override
  String get chatMessageWidgetTranslating => '翻译中...';

  @override
  String get chatMessageWidgetCitationNotFound => '未找到引用来源';

  @override
  String chatMessageWidgetCannotOpenUrl(String url) {
    return '无法打开链接: $url';
  }

  @override
  String get chatMessageWidgetOpenLinkError => '打开链接失败';

  @override
  String chatMessageWidgetCitationsTitle(int count) {
    return '引用（共$count条）';
  }

  @override
  String get chatMessageWidgetRegenerateTooltip => '重新生成';

  @override
  String get chatMessageWidgetStopTooltip => '停止';

  @override
  String get chatMessageWidgetSpeakTooltip => '朗读';

  @override
  String get chatMessageWidgetTranslateTooltip => '翻译';

  @override
  String get chatMessageWidgetBuiltinSearchHideNote => '隐藏内置搜索工具卡片';

  @override
  String get chatMessageWidgetDeepThinking => '深度思考';

  @override
  String get chatMessageWidgetCreateMemory => '创建记忆';

  @override
  String get chatMessageWidgetEditMemory => '编辑记忆';

  @override
  String get chatMessageWidgetDeleteMemory => '删除记忆';

  @override
  String chatMessageWidgetWebSearch(String query) {
    return '联网检索: $query';
  }

  @override
  String get chatMessageWidgetBuiltinSearch => '模型内置搜索';

  @override
  String chatMessageWidgetToolCall(String name) {
    return '调用工具: $name';
  }

  @override
  String chatMessageWidgetToolResult(String name) {
    return '调用工具: $name';
  }

  @override
  String get chatMessageWidgetNoResultYet => '（暂无结果）';

  @override
  String get chatMessageWidgetArguments => '参数';

  @override
  String get chatMessageWidgetResult => '结果';

  @override
  String chatMessageWidgetCitationsCount(int count) {
    return '共$count条引用';
  }

  @override
  String get messageExportSheetAssistant => '助手';

  @override
  String get messageExportSheetDefaultTitle => '新对话';

  @override
  String get messageExportSheetExporting => '正在导出…';

  @override
  String messageExportSheetExportFailed(String error) {
    return '导出失败: $error';
  }

  @override
  String messageExportSheetExportedAs(String filename) {
    return '已导出为 $filename';
  }

  @override
  String get messageExportSheetFormatTitle => '导出格式';

  @override
  String get messageExportSheetMarkdown => 'Markdown';

  @override
  String get messageExportSheetSingleMarkdownSubtitle => '将该消息导出为 Markdown 文件';

  @override
  String get messageExportSheetBatchMarkdownSubtitle => '将选中的消息导出为 Markdown 文件';

  @override
  String get messageExportSheetExportImage => '导出为图片';

  @override
  String get messageExportSheetSingleExportImageSubtitle => '将该消息渲染为 PNG 图片';

  @override
  String get messageExportSheetBatchExportImageSubtitle => '将选中的消息渲染为 PNG 图片';

  @override
  String get messageExportSheetDateTimeWithSecondsPattern =>
      'yyyy年M月d日 HH:mm:ss';

  @override
  String get sideDrawerMenuRename => '重命名';

  @override
  String get sideDrawerMenuPin => '置顶';

  @override
  String get sideDrawerMenuUnpin => '取消置顶';

  @override
  String get sideDrawerMenuRegenerateTitle => '重新生成标题';

  @override
  String get sideDrawerMenuDelete => '删除';

  @override
  String sideDrawerDeleteSnackbar(String title) {
    return '已删除“$title”';
  }

  @override
  String get sideDrawerRenameHint => '输入新名称';

  @override
  String get sideDrawerCancel => '取消';

  @override
  String get sideDrawerOK => '确定';

  @override
  String get sideDrawerSave => '保存';

  @override
  String get sideDrawerGreetingMorning => '早上好 👋';

  @override
  String get sideDrawerGreetingNoon => '中午好 👋';

  @override
  String get sideDrawerGreetingAfternoon => '下午好 👋';

  @override
  String get sideDrawerGreetingEvening => '晚上好 👋';

  @override
  String get sideDrawerDateToday => '今天';

  @override
  String get sideDrawerDateYesterday => '昨天';

  @override
  String get sideDrawerDateShortPattern => 'M月d日';

  @override
  String get sideDrawerDateFullPattern => 'yyyy年M月d日';

  @override
  String get sideDrawerSearchHint => '搜索聊天记录';

  @override
  String sideDrawerUpdateTitle(String version) {
    return '发现新版本：$version';
  }

  @override
  String sideDrawerUpdateTitleWithBuild(String version, int build) {
    return '发现新版本：$version ($build)';
  }

  @override
  String get sideDrawerLinkCopied => '已复制下载链接';

  @override
  String get sideDrawerPinnedLabel => '置顶';

  @override
  String get sideDrawerHistory => '聊天历史';

  @override
  String get sideDrawerSettings => '设置';

  @override
  String get sideDrawerChooseAssistantTitle => '选择助手';

  @override
  String get sideDrawerChooseImage => '选择图片';

  @override
  String get sideDrawerChooseEmoji => '选择表情';

  @override
  String get sideDrawerEnterLink => '输入链接';

  @override
  String get sideDrawerImportFromQQ => 'QQ头像';

  @override
  String get sideDrawerReset => '重置';

  @override
  String get sideDrawerEmojiDialogTitle => '选择表情';

  @override
  String get sideDrawerEmojiDialogHint => '输入或粘贴任意表情';

  @override
  String get sideDrawerImageUrlDialogTitle => '输入图片链接';

  @override
  String get sideDrawerImageUrlDialogHint =>
      '例如: https://example.com/avatar.png';

  @override
  String get sideDrawerQQAvatarDialogTitle => '使用QQ头像';

  @override
  String get sideDrawerQQAvatarInputHint => '输入QQ号码（5-12位）';

  @override
  String get sideDrawerQQAvatarFetchFailed => '获取随机QQ头像失败，请重试';

  @override
  String get sideDrawerRandomQQ => '随机QQ';

  @override
  String get sideDrawerGalleryOpenError => '无法打开相册，试试输入图片链接';

  @override
  String get sideDrawerGeneralImageError => '发生错误，试试输入图片链接';

  @override
  String get sideDrawerSetNicknameTitle => '设置昵称';

  @override
  String get sideDrawerNicknameLabel => '昵称';

  @override
  String get sideDrawerNicknameHint => '输入新的昵称';

  @override
  String get sideDrawerRename => '重命名';

  @override
  String get chatInputBarHint => '输入消息与AI聊天';

  @override
  String get chatInputBarSelectModelTooltip => '选择模型';

  @override
  String get chatInputBarOnlineSearchTooltip => '联网搜索';

  @override
  String get chatInputBarReasoningStrengthTooltip => '思维链强度';

  @override
  String get chatInputBarMcpServersTooltip => 'MCP服务器';

  @override
  String get chatInputBarMoreTooltip => '更多';

  @override
  String get mcpPageBackTooltip => '返回';

  @override
  String get mcpPageAddMcpTooltip => '添加 MCP';

  @override
  String get mcpPageNoServers => '暂无 MCP 服务器';

  @override
  String get mcpPageErrorDialogTitle => '连接错误';

  @override
  String get mcpPageErrorNoDetails => '未提供错误详情';

  @override
  String get mcpPageClose => '关闭';

  @override
  String get mcpPageReconnect => '重新连接';

  @override
  String get mcpPageStatusConnected => '已连接';

  @override
  String get mcpPageStatusConnecting => '连接中…';

  @override
  String get mcpPageStatusDisconnected => '未连接';

  @override
  String get mcpPageStatusDisabled => '已禁用';

  @override
  String mcpPageToolsCount(int enabled, int total) {
    return '工具: $enabled/$total';
  }

  @override
  String get mcpPageConnectionFailed => '连接失败';

  @override
  String get mcpPageDetails => '详情';

  @override
  String get mcpPageDelete => '删除';

  @override
  String get mcpPageConfirmDeleteTitle => '确认删除';

  @override
  String get mcpPageConfirmDeleteContent => '删除后可通过撤销恢复。是否删除？';

  @override
  String get mcpPageServerDeleted => '已删除服务器';

  @override
  String get mcpPageUndo => '撤销';

  @override
  String get mcpPageCancel => '取消';

  @override
  String get mcpConversationSheetTitle => 'MCP服务器';

  @override
  String get mcpConversationSheetSubtitle => '选择在此助手中启用的服务';

  @override
  String get mcpConversationSheetSelectAll => '全选';

  @override
  String get mcpConversationSheetClearAll => '全不选';

  @override
  String get mcpConversationSheetNoRunning => '暂无已启动的 MCP 服务器';

  @override
  String get mcpConversationSheetConnected => '已连接';

  @override
  String mcpConversationSheetToolsCount(int enabled, int total) {
    return '工具: $enabled/$total';
  }

  @override
  String get mcpServerEditSheetEnabledLabel => '是否启用';

  @override
  String get mcpServerEditSheetNameLabel => '名称';

  @override
  String get mcpServerEditSheetTransportLabel => '传输类型';

  @override
  String get mcpServerEditSheetSseRetryHint => '如果SSE连接失败，请多试几次';

  @override
  String get mcpServerEditSheetUrlLabel => '服务器地址';

  @override
  String get mcpServerEditSheetCustomHeadersTitle => '自定义请求头';

  @override
  String get mcpServerEditSheetHeaderNameLabel => '请求头名称';

  @override
  String get mcpServerEditSheetHeaderNameHint => '如 Authorization';

  @override
  String get mcpServerEditSheetHeaderValueLabel => '请求头值';

  @override
  String get mcpServerEditSheetHeaderValueHint => '如 Bearer xxxxxx';

  @override
  String get mcpServerEditSheetRemoveHeaderTooltip => '删除';

  @override
  String get mcpServerEditSheetAddHeader => '添加请求头';

  @override
  String get mcpServerEditSheetTitleEdit => '编辑 MCP';

  @override
  String get mcpServerEditSheetTitleAdd => '添加 MCP';

  @override
  String get mcpServerEditSheetSyncToolsTooltip => '同步工具';

  @override
  String get mcpServerEditSheetTabBasic => '基础设置';

  @override
  String get mcpServerEditSheetTabTools => '工具';

  @override
  String get mcpServerEditSheetNoToolsHint => '暂无工具，点击上方同步';

  @override
  String get mcpServerEditSheetCancel => '取消';

  @override
  String get mcpServerEditSheetSave => '保存';

  @override
  String get mcpServerEditSheetUrlRequired => '请输入服务器地址';

  @override
  String get defaultModelPageBackTooltip => '返回';

  @override
  String get defaultModelPageTitle => '默认模型';

  @override
  String get defaultModelPageChatModelTitle => '聊天模型';

  @override
  String get defaultModelPageChatModelSubtitle => '全局默认的聊天模型';

  @override
  String get defaultModelPageTitleModelTitle => '标题总结模型';

  @override
  String get defaultModelPageTitleModelSubtitle => '用于总结对话标题的模型，推荐使用快速且便宜的模型';

  @override
  String get defaultModelPageTranslateModelTitle => '翻译模型';

  @override
  String get defaultModelPageTranslateModelSubtitle =>
      '用于翻译消息内容的模型，推荐使用快速且准确的模型';

  @override
  String get defaultModelPagePromptLabel => '提示词';

  @override
  String get defaultModelPageTitlePromptHint => '输入用于标题总结的提示词模板';

  @override
  String get defaultModelPageTranslatePromptHint => '输入用于翻译的提示词模板';

  @override
  String get defaultModelPageResetDefault => '重置为默认';

  @override
  String get defaultModelPageSave => '保存';

  @override
  String defaultModelPageTitleVars(String contentVar, String localeVar) {
    return '变量: 对话内容: $contentVar, 语言: $localeVar';
  }

  @override
  String defaultModelPageTranslateVars(String sourceVar, String targetVar) {
    return '变量：原始文本：$sourceVar，目标语言：$targetVar';
  }

  @override
  String get modelDetailSheetAddModel => '添加模型';

  @override
  String get modelDetailSheetEditModel => '编辑模型';

  @override
  String get modelDetailSheetBasicTab => '基本设置';

  @override
  String get modelDetailSheetAdvancedTab => '高级设置';

  @override
  String get modelDetailSheetModelIdLabel => '模型 ID';

  @override
  String get modelDetailSheetModelIdHint => '必填，建议小写字母、数字、连字符';

  @override
  String modelDetailSheetModelIdDisabledHint(String modelId) {
    return '$modelId';
  }

  @override
  String get modelDetailSheetModelNameLabel => '模型名称';

  @override
  String get modelDetailSheetModelTypeLabel => '模型类型';

  @override
  String get modelDetailSheetChatType => '聊天';

  @override
  String get modelDetailSheetEmbeddingType => '嵌入';

  @override
  String get modelDetailSheetInputModesLabel => '输入模式';

  @override
  String get modelDetailSheetOutputModesLabel => '输出模式';

  @override
  String get modelDetailSheetAbilitiesLabel => '能力';

  @override
  String get modelDetailSheetTextMode => '文本';

  @override
  String get modelDetailSheetImageMode => '图片';

  @override
  String get modelDetailSheetToolsAbility => '工具';

  @override
  String get modelDetailSheetReasoningAbility => '推理';

  @override
  String get modelDetailSheetProviderOverrideDescription =>
      '供应商重写：允许为特定模型自定义供应商设置。（暂未实现）';

  @override
  String get modelDetailSheetAddProviderOverride => '添加供应商重写';

  @override
  String get modelDetailSheetCustomHeadersTitle => '自定义 Headers';

  @override
  String get modelDetailSheetAddHeader => '添加 Header';

  @override
  String get modelDetailSheetCustomBodyTitle => '自定义 Body';

  @override
  String get modelDetailSheetAddBody => '添加 Body';

  @override
  String get modelDetailSheetBuiltinToolsDescription =>
      '内置工具仅支持部分 API（例如 Gemini 官方 API）（暂未实现）。';

  @override
  String get modelDetailSheetSearchTool => '搜索';

  @override
  String get modelDetailSheetSearchToolDescription => '启用 Google 搜索集成';

  @override
  String get modelDetailSheetUrlContextTool => 'URL 上下文';

  @override
  String get modelDetailSheetUrlContextToolDescription => '启用 URL 内容处理';

  @override
  String get modelDetailSheetCancelButton => '取消';

  @override
  String get modelDetailSheetAddButton => '添加';

  @override
  String get modelDetailSheetConfirmButton => '确认';

  @override
  String get modelDetailSheetInvalidIdError => '请输入有效的模型 ID（不少于2个字符且不含空格）';

  @override
  String get modelDetailSheetModelIdExistsError => '模型 ID 已存在';

  @override
  String get modelDetailSheetHeaderKeyHint => 'Header Key';

  @override
  String get modelDetailSheetHeaderValueHint => 'Header Value';

  @override
  String get modelDetailSheetBodyKeyHint => 'Body Key';

  @override
  String get modelDetailSheetBodyJsonHint => 'Body JSON';

  @override
  String get modelSelectSheetSearchHint => '搜索模型或服务商';

  @override
  String get modelSelectSheetFavoritesSection => '收藏';

  @override
  String get modelSelectSheetFavoriteTooltip => '收藏';

  @override
  String get modelSelectSheetChatType => '聊天';

  @override
  String get modelSelectSheetEmbeddingType => '嵌入';

  @override
  String get providerDetailPageShareTooltip => '分享';

  @override
  String get providerDetailPageDeleteProviderTooltip => '删除供应商';

  @override
  String get providerDetailPageDeleteProviderTitle => '删除供应商';

  @override
  String get providerDetailPageDeleteProviderContent => '确定要删除该供应商吗？此操作不可撤销。';

  @override
  String get providerDetailPageCancelButton => '取消';

  @override
  String get providerDetailPageDeleteButton => '删除';

  @override
  String get providerDetailPageProviderDeletedSnackbar => '已删除供应商';

  @override
  String get providerDetailPageConfigTab => '配置';

  @override
  String get providerDetailPageModelsTab => '模型';

  @override
  String get providerDetailPageNetworkTab => '网络代理';

  @override
  String get providerDetailPageEnabledTitle => '是否启用';

  @override
  String get providerDetailPageNameLabel => '名称';

  @override
  String get providerDetailPageApiKeyHint => '留空则使用上层默认';

  @override
  String get providerDetailPageHideTooltip => '隐藏';

  @override
  String get providerDetailPageShowTooltip => '显示';

  @override
  String get providerDetailPageApiPathLabel => 'API 路径';

  @override
  String get providerDetailPageResponseApiTitle => 'Response API (/responses)';

  @override
  String get providerDetailPageVertexAiTitle => 'Vertex AI';

  @override
  String get providerDetailPageLocationLabel => '区域 Location';

  @override
  String get providerDetailPageProjectIdLabel => '项目 ID';

  @override
  String get providerDetailPageServiceAccountJsonLabel => '服务账号 JSON（粘贴或导入）';

  @override
  String get providerDetailPageImportJsonButton => '导入 JSON';

  @override
  String get providerDetailPageTestButton => '测试';

  @override
  String get providerDetailPageSaveButton => '保存';

  @override
  String get providerDetailPageProviderRemovedMessage => '供应商已删除';

  @override
  String get providerDetailPageNoModelsTitle => '暂无模型';

  @override
  String get providerDetailPageNoModelsSubtitle => '点击下方按钮添加模型';

  @override
  String get providerDetailPageDeleteModelButton => '删除';

  @override
  String get providerDetailPageConfirmDeleteTitle => '确认删除';

  @override
  String get providerDetailPageConfirmDeleteContent => '删除后可通过撤销恢复。是否删除？';

  @override
  String get providerDetailPageModelDeletedSnackbar => '已删除模型';

  @override
  String get providerDetailPageUndoButton => '撤销';

  @override
  String get providerDetailPageAddNewModelButton => '添加新模型';

  @override
  String get providerDetailPageEnableProxyTitle => '是否启用代理';

  @override
  String get providerDetailPageHostLabel => '主机地址';

  @override
  String get providerDetailPagePortLabel => '端口';

  @override
  String get providerDetailPageUsernameOptionalLabel => '用户名（可选）';

  @override
  String get providerDetailPagePasswordOptionalLabel => '密码（可选）';

  @override
  String get providerDetailPageSavedSnackbar => '已保存';

  @override
  String get providerDetailPageEmbeddingsGroupTitle => '嵌入';

  @override
  String get providerDetailPageOtherModelsGroupTitle => '其他模型';

  @override
  String get providerDetailPageRemoveGroupTooltip => '移除本组';

  @override
  String get providerDetailPageAddGroupTooltip => '添加本组';

  @override
  String get providerDetailPageFilterHint => '输入模型名称筛选';

  @override
  String get providerDetailPageDeleteText => '删除';

  @override
  String get providerDetailPageEditTooltip => '编辑';

  @override
  String get providerDetailPageTestConnectionTitle => '测试连接';

  @override
  String get providerDetailPageSelectModelButton => '选择模型';

  @override
  String get providerDetailPageChangeButton => '更换';

  @override
  String get providerDetailPageTestingMessage => '正在测试…';

  @override
  String get providerDetailPageTestSuccessMessage => '测试成功';

  @override
  String get providersPageTitle => '供应商';

  @override
  String get providersPageImportTooltip => '导入';

  @override
  String get providersPageAddTooltip => '新增';

  @override
  String get providersPageProviderAddedSnackbar => '已添加供应商';

  @override
  String get providersPageSiliconFlowName => '硅基流动';

  @override
  String get providersPageAliyunName => '阿里云千问';

  @override
  String get providersPageZhipuName => '智谱';

  @override
  String get providersPageByteDanceName => '火山引擎';

  @override
  String get providersPageEnabledStatus => '启用';

  @override
  String get providersPageDisabledStatus => '禁用';

  @override
  String get providersPageModelsCountSuffix => ' models';

  @override
  String get providersPageModelsCountSingleSuffix => '个模型';

  @override
  String get addProviderSheetTitle => '添加供应商';

  @override
  String get addProviderSheetEnabledLabel => '是否启用';

  @override
  String get addProviderSheetNameLabel => '名称';

  @override
  String get addProviderSheetApiPathLabel => 'API 路径';

  @override
  String get addProviderSheetVertexAiLocationLabel => '位置';

  @override
  String get addProviderSheetVertexAiProjectIdLabel => '项目ID';

  @override
  String get addProviderSheetVertexAiServiceAccountJsonLabel =>
      '服务账号 JSON（粘贴或导入）';

  @override
  String get addProviderSheetImportJsonButton => '导入 JSON';

  @override
  String get addProviderSheetCancelButton => '取消';

  @override
  String get addProviderSheetAddButton => '添加';

  @override
  String get importProviderSheetTitle => '导入供应商';

  @override
  String get importProviderSheetScanQrTooltip => '扫码导入';

  @override
  String get importProviderSheetFromGalleryTooltip => '从相册导入';

  @override
  String importProviderSheetImportSuccessMessage(int count) {
    return '已导入$count个供应商';
  }

  @override
  String importProviderSheetImportFailedMessage(String error) {
    return '导入失败: $error';
  }

  @override
  String get importProviderSheetDescription =>
      '粘贴分享字符串（可多行，每行一个）或 ChatBox JSON';

  @override
  String get importProviderSheetInputHint => 'ai-provider:v1:...';

  @override
  String get importProviderSheetCancelButton => '取消';

  @override
  String get importProviderSheetImportButton => '导入';

  @override
  String get shareProviderSheetTitle => '分享供应商配置';

  @override
  String get shareProviderSheetDescription => '复制下面的分享字符串，或使用二维码分享。';

  @override
  String get shareProviderSheetCopiedMessage => '已复制';

  @override
  String get shareProviderSheetCopyButton => '复制';

  @override
  String get shareProviderSheetShareButton => '分享';

  @override
  String get qrScanPageTitle => '扫码导入';

  @override
  String get qrScanPageInstruction => '将二维码对准取景框';

  @override
  String get searchServicesPageBackTooltip => '返回';

  @override
  String get searchServicesPageTitle => '搜索服务';

  @override
  String get searchServicesPageDone => '完成';

  @override
  String get searchServicesPageEdit => '编辑';

  @override
  String get searchServicesPageAddProvider => '添加提供商';

  @override
  String get searchServicesPageSearchProviders => '搜索提供商';

  @override
  String get searchServicesPageGeneralOptions => '通用选项';

  @override
  String get searchServicesPageMaxResults => '最大结果数';

  @override
  String get searchServicesPageTimeoutSeconds => '超时时间（秒）';

  @override
  String get searchServicesPageAtLeastOneServiceRequired => '至少需要一个搜索服务';

  @override
  String get searchServicesPageTestingStatus => '测试中…';

  @override
  String get searchServicesPageConnectedStatus => '已连接';

  @override
  String get searchServicesPageFailedStatus => '连接失败';

  @override
  String get searchServicesPageNotTestedStatus => '未测试';

  @override
  String get searchServicesPageTestConnectionTooltip => '测试连接';

  @override
  String get searchServicesPageConfiguredStatus => '已配置';

  @override
  String get searchServicesPageApiKeyRequiredStatus => '需要 API Key';

  @override
  String get searchServicesPageUrlRequiredStatus => '需要 URL';

  @override
  String get searchServicesAddDialogTitle => '添加搜索服务';

  @override
  String get searchServicesAddDialogServiceType => '服务类型';

  @override
  String get searchServicesAddDialogBingLocal => '本地';

  @override
  String get searchServicesAddDialogCancel => '取消';

  @override
  String get searchServicesAddDialogAdd => '添加';

  @override
  String get searchServicesAddDialogApiKeyRequired => 'API Key 必填';

  @override
  String get searchServicesAddDialogInstanceUrl => '实例 URL';

  @override
  String get searchServicesAddDialogUrlRequired => 'URL 必填';

  @override
  String get searchServicesAddDialogEnginesOptional => '搜索引擎（可选）';

  @override
  String get searchServicesAddDialogLanguageOptional => '语言（可选）';

  @override
  String get searchServicesAddDialogUsernameOptional => '用户名（可选）';

  @override
  String get searchServicesAddDialogPasswordOptional => '密码（可选）';

  @override
  String get searchServicesEditDialogEdit => '编辑';

  @override
  String get searchServicesEditDialogCancel => '取消';

  @override
  String get searchServicesEditDialogSave => '保存';

  @override
  String get searchServicesEditDialogBingLocalNoConfig => 'Bing 本地搜索不需要配置。';

  @override
  String get searchServicesEditDialogApiKeyRequired => 'API Key 必填';

  @override
  String get searchServicesEditDialogInstanceUrl => '实例 URL';

  @override
  String get searchServicesEditDialogUrlRequired => 'URL 必填';

  @override
  String get searchServicesEditDialogEnginesOptional => '搜索引擎（可选）';

  @override
  String get searchServicesEditDialogLanguageOptional => '语言（可选）';

  @override
  String get searchServicesEditDialogUsernameOptional => '用户名（可选）';

  @override
  String get searchServicesEditDialogPasswordOptional => '密码（可选）';

  @override
  String get searchSettingsSheetTitle => '搜索设置';

  @override
  String get searchSettingsSheetBuiltinSearchTitle => '模型内置搜索';

  @override
  String get searchSettingsSheetBuiltinSearchDescription => '是否启用模型内置的搜索功能';

  @override
  String get searchSettingsSheetWebSearchTitle => '网络搜索';

  @override
  String get searchSettingsSheetWebSearchDescription => '是否启用网页搜索';

  @override
  String get searchSettingsSheetOpenSearchServicesTooltip => '打开搜索服务设置';

  @override
  String get searchSettingsSheetNoServicesMessage => '暂无可用服务，请先在\"搜索服务\"中添加';

  @override
  String get aboutPageEasterEggTitle => '彩蛋已解锁！';

  @override
  String get aboutPageEasterEggMessage => '\n（好吧现在还没彩蛋）';

  @override
  String get aboutPageEasterEggButton => '好的';

  @override
  String get aboutPageAppDescription => '开源移动端 AI 助手';

  @override
  String get aboutPageNoQQGroup => '暂无QQ群';

  @override
  String get aboutPageVersion => '版本';

  @override
  String get aboutPageSystem => '系统';

  @override
  String get aboutPageWebsite => '官网';

  @override
  String get aboutPageLicense => '许可证';

  @override
  String get displaySettingsPageShowUserAvatarTitle => '显示用户头像';

  @override
  String get displaySettingsPageShowUserAvatarSubtitle => '是否在聊天消息中显示用户头像';

  @override
  String get displaySettingsPageShowUserNameTimestampTitle => '显示用户名称和时间戳';

  @override
  String get displaySettingsPageShowUserNameTimestampSubtitle =>
      '是否在聊天消息中显示用户名称和时间戳';

  @override
  String get displaySettingsPageShowModelNameTimestampTitle => '显示模型名称和时间戳';

  @override
  String get displaySettingsPageShowModelNameTimestampSubtitle =>
      '是否在聊天消息中显示模型名称和时间戳';

  @override
  String get displaySettingsPageChatModelIconTitle => '聊天列表模型图标';

  @override
  String get displaySettingsPageChatModelIconSubtitle => '是否在聊天消息中显示模型图标';

  @override
  String get displaySettingsPageShowTokenStatsTitle => '显示Token和上下文统计';

  @override
  String get displaySettingsPageShowTokenStatsSubtitle => '显示 token 用量与消息数量';

  @override
  String get displaySettingsPageAutoCollapseThinkingTitle => '自动折叠思考';

  @override
  String get displaySettingsPageAutoCollapseThinkingSubtitle =>
      '思考完成后自动折叠，保持界面简洁';

  @override
  String get displaySettingsPageShowUpdatesTitle => '显示更新';

  @override
  String get displaySettingsPageShowUpdatesSubtitle => '显示应用更新通知';

  @override
  String get displaySettingsPageMessageNavButtonsTitle => '消息导航按钮';

  @override
  String get displaySettingsPageMessageNavButtonsSubtitle => '滚动时显示快速跳转按钮';

  @override
  String get displaySettingsPageHapticsOnSidebarTitle => '侧边栏触觉反馈';

  @override
  String get displaySettingsPageHapticsOnSidebarSubtitle => '打开/关闭侧边栏时启用触觉反馈';

  @override
  String get displaySettingsPageHapticsOnGenerateTitle => '消息生成触觉反馈';

  @override
  String get displaySettingsPageHapticsOnGenerateSubtitle => '生成消息时启用触觉反馈';

  @override
  String get displaySettingsPageNewChatOnLaunchTitle => '启动时新建对话';

  @override
  String get displaySettingsPageNewChatOnLaunchSubtitle => '应用启动时自动创建新对话';

  @override
  String get displaySettingsPageChatFontSizeTitle => '聊天字体大小';

  @override
  String get displaySettingsPageChatFontSampleText => '这是一个示例的聊天文本';

  @override
  String get displaySettingsPageThemeSettingsTitle => '主题设置';

  @override
  String get themeSettingsPageDynamicColorSection => '动态颜色';

  @override
  String get themeSettingsPageUseDynamicColorTitle => '使用动态颜色';

  @override
  String get themeSettingsPageUseDynamicColorSubtitle => '基于系统配色（Android 12+）';

  @override
  String get themeSettingsPageColorPalettesSection => '配色方案';

  @override
  String get ttsServicesPageBackButton => '返回';

  @override
  String get ttsServicesPageTitle => '语音服务';

  @override
  String get ttsServicesPageAddTooltip => '新增';

  @override
  String get ttsServicesPageAddNotImplemented => '新增 TTS 服务暂未实现';

  @override
  String get ttsServicesPageSystemTtsTitle => '系统TTS';

  @override
  String get ttsServicesPageSystemTtsAvailableSubtitle => '使用系统内置语音合成';

  @override
  String ttsServicesPageSystemTtsUnavailableSubtitle(String error) {
    return '不可用：$error';
  }

  @override
  String get ttsServicesPageSystemTtsUnavailableNotInitialized => '未初始化';

  @override
  String get ttsServicesPageTestSpeechText => '你好，这是一次测试语音。';

  @override
  String get ttsServicesPageConfigureTooltip => '配置';

  @override
  String get ttsServicesPageTestVoiceTooltip => '测试语音';

  @override
  String get ttsServicesPageStopTooltip => '停止';

  @override
  String get ttsServicesPageDeleteTooltip => '删除';

  @override
  String get ttsServicesPageSystemTtsSettingsTitle => '系统 TTS 设置';

  @override
  String get ttsServicesPageEngineLabel => '引擎';

  @override
  String get ttsServicesPageAutoLabel => '自动';

  @override
  String get ttsServicesPageLanguageLabel => '语言';

  @override
  String get ttsServicesPageSpeechRateLabel => '语速';

  @override
  String get ttsServicesPagePitchLabel => '音调';

  @override
  String get ttsServicesPageSettingsSavedMessage => '设置已保存。';

  @override
  String get ttsServicesPageDoneButton => '完成';

  @override
  String imageViewerPageShareFailedOpenFile(String message) {
    return '无法分享，已尝试打开文件: $message';
  }

  @override
  String imageViewerPageShareFailed(String error) {
    return '分享失败: $error';
  }

  @override
  String get imageViewerPageShareButton => '分享图片';

  @override
  String get settingsShare => 'Kelivo - 开源移动端AI助手';

  @override
  String get searchProviderBingLocalDescription =>
      '使用网络抓取工具获取必应搜索结果。无需 API 密钥，但可能不够稳定。';

  @override
  String get searchProviderBraveDescription => 'Brave 独立搜索引擎。注重隐私，无跟踪或画像。';

  @override
  String get searchProviderExaDescription => '具备语义理解的神经搜索引擎。适合研究与查找特定内容。';

  @override
  String get searchProviderLinkUpDescription =>
      '提供来源可追溯答案的搜索 API，同时提供搜索结果与 AI 摘要。';

  @override
  String get searchProviderMetasoDescription => '秘塔中文搜索引擎。面向中文内容优化并提供 AI 能力。';

  @override
  String get searchProviderSearXNGDescription => '注重隐私的元搜索引擎。需自建实例，无跟踪。';

  @override
  String get searchProviderTavilyDescription =>
      '为大型语言模型（LLMs）优化的 AI 搜索 API，提供高质量、相关的搜索结果。';

  @override
  String get searchProviderZhipuDescription =>
      '智谱 AI 旗下中文 AI 搜索服务，针对中文内容与查询进行了优化。';

  @override
  String get searchServiceNameBingLocal => 'Bing（Local）';

  @override
  String get searchServiceNameTavily => 'Tavily';

  @override
  String get searchServiceNameExa => 'Exa';

  @override
  String get searchServiceNameZhipu => '智谱';

  @override
  String get searchServiceNameSearXNG => 'SearXNG';

  @override
  String get searchServiceNameLinkUp => 'LinkUp';

  @override
  String get searchServiceNameBrave => 'Brave';

  @override
  String get searchServiceNameMetaso => '秘塔';

  @override
  String get generationInterrupted => '生成已中断';

  @override
  String get titleForLocale => '新对话';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get helloWorld => '你好，世界！';

  @override
  String get settingsPageBackButton => '返回';

  @override
  String get settingsPageTitle => '设置';

  @override
  String get settingsPageDarkMode => '深色';

  @override
  String get settingsPageLightMode => '浅色';

  @override
  String get settingsPageSystemMode => '跟随系统';

  @override
  String get settingsPageWarningMessage => '部分服务未配置，某些功能可能不可用';

  @override
  String get settingsPageGeneralSection => '通用设置';

  @override
  String get settingsPageColorMode => '颜色模式';

  @override
  String get settingsPageDisplay => '显示设置';

  @override
  String get settingsPageDisplaySubtitle => '界面主题与字号等外观设置';

  @override
  String get settingsPageAssistant => '助手';

  @override
  String get settingsPageAssistantSubtitle => '默认助手与对话风格';

  @override
  String get settingsPageModelsServicesSection => '模型与服务';

  @override
  String get settingsPageDefaultModel => '默认模型';

  @override
  String get settingsPageProviders => '供应商';

  @override
  String get settingsPageSearch => '搜索服务';

  @override
  String get settingsPageTts => '语音服务';

  @override
  String get settingsPageMcp => 'MCP';

  @override
  String get settingsPageDataSection => '数据设置';

  @override
  String get settingsPageBackup => '数据备份';

  @override
  String get settingsPageChatStorage => '聊天记录存储';

  @override
  String get settingsPageCalculating => '统计中…';

  @override
  String settingsPageFilesCount(int count, String size) {
    return '共 $count 个文件 · $size';
  }

  @override
  String get settingsPageAboutSection => '关于';

  @override
  String get settingsPageAbout => '关于';

  @override
  String get settingsPageDocs => '使用文档';

  @override
  String get settingsPageSponsor => '赞助';

  @override
  String get settingsPageShare => '分享';

  @override
  String get sponsorPageMethodsSectionTitle => '赞助方式';

  @override
  String get sponsorPageSponsorsSectionTitle => '赞助用户';

  @override
  String get sponsorPageEmpty => '暂无赞助者';

  @override
  String get sponsorPageAfdianTitle => '爱发电';

  @override
  String get sponsorPageAfdianSubtitle => 'afdian.com/a/kelivo';

  @override
  String get sponsorPageWeChatTitle => '微信赞助';

  @override
  String get sponsorPageWeChatSubtitle => '微信赞助码';

  @override
  String get languageDisplaySimplifiedChinese => '简体中文';

  @override
  String get languageDisplayEnglish => 'English';

  @override
  String get languageDisplayTraditionalChinese => '繁體中文';

  @override
  String get languageDisplayJapanese => '日本語';

  @override
  String get languageDisplayKorean => '한국어';

  @override
  String get languageDisplayFrench => 'Français';

  @override
  String get languageDisplayGerman => 'Deutsch';

  @override
  String get languageDisplayItalian => 'Italiano';

  @override
  String get languageSelectSheetTitle => '选择翻译语言';

  @override
  String get languageSelectSheetClearButton => '清空翻译';

  @override
  String get homePageClearContext => '清空上下文';

  @override
  String homePageClearContextWithCount(String actual, String configured) {
    return '清空上下文 ($actual/$configured)';
  }

  @override
  String get homePageDefaultAssistant => '默认助手';

  @override
  String get mermaidExportPng => '导出 PNG';

  @override
  String get mermaidExportFailed => '导出失败';

  @override
  String get mermaidPreviewOpen => '浏览器预览';

  @override
  String get mermaidPreviewOpenFailed => '无法打开预览';

  @override
  String get assistantProviderDefaultAssistantName => '默认助手';

  @override
  String get assistantProviderSampleAssistantName => '示例助手';

  @override
  String get assistantProviderNewAssistantName => '新助手';

  @override
  String assistantProviderSampleAssistantSystemPrompt(
    String model_name,
    String cur_datetime,
    String locale,
    String timezone,
    String device_info,
    String system_version,
  ) {
    return '你是$model_name, 一个人工智能助手，乐意为用户提供准确，有益的帮助。现在时间是$cur_datetime，用户设备语言为$locale，时区为$timezone，用户正在使用$device_info，版本$system_version。如果用户没有明确说明，请使用用户设备语言进行回复。';
  }

  @override
  String get displaySettingsPageLanguageTitle => '应用语言';

  @override
  String get displaySettingsPageLanguageSubtitle => '选择界面语言';

  @override
  String get displaySettingsPageLanguageChineseLabel => '简体中文';

  @override
  String get displaySettingsPageLanguageEnglishLabel => 'English';

  @override
  String get homePagePleaseSelectModel => '请先选择模型';

  @override
  String get homePagePleaseSetupTranslateModel => '请先设置翻译模型';

  @override
  String get homePageTranslating => '翻译中...';

  @override
  String homePageTranslateFailed(String error) {
    return '翻译失败: $error';
  }

  @override
  String get chatServiceDefaultConversationTitle => '新对话';

  @override
  String get userProviderDefaultUserName => '用户';

  @override
  String get homePageDeleteMessage => '删除消息';

  @override
  String get homePageDeleteMessageConfirm => '确定要删除这条消息吗？此操作不可撤销。';

  @override
  String get homePageCancel => '取消';

  @override
  String get homePageDelete => '删除';

  @override
  String get homePageSelectMessagesToShare => '请选择要分享的消息';

  @override
  String get homePageDone => '完成';

  @override
  String get assistantEditPageTitle => '助手';

  @override
  String get assistantEditPageNotFound => '助手不存在';

  @override
  String get assistantEditPageBasicTab => '基础设置';

  @override
  String get assistantEditPagePromptsTab => '提示词';

  @override
  String get assistantEditPageMcpTab => 'MCP';

  @override
  String get assistantEditPageCustomTab => '自定义请求';

  @override
  String get assistantEditCustomHeadersTitle => '自定义 Header';

  @override
  String get assistantEditCustomHeadersAdd => '添加 Header';

  @override
  String get assistantEditCustomHeadersEmpty => '未添加 Header';

  @override
  String get assistantEditCustomBodyTitle => '自定义 Body';

  @override
  String get assistantEditCustomBodyAdd => '添加 Body';

  @override
  String get assistantEditCustomBodyEmpty => '未添加 Body 项';

  @override
  String get assistantEditHeaderNameLabel => 'Header 名称';

  @override
  String get assistantEditHeaderValueLabel => 'Header 值';

  @override
  String get assistantEditBodyKeyLabel => 'Body Key';

  @override
  String get assistantEditBodyValueLabel => 'Body 值 (JSON)';

  @override
  String get assistantEditDeleteTooltip => '删除';

  @override
  String get assistantEditAssistantNameLabel => '助手名称';

  @override
  String get assistantEditUseAssistantAvatarTitle => '使用助手头像';

  @override
  String get assistantEditUseAssistantAvatarSubtitle =>
      '在聊天中使用助手头像和名字而不是模型头像和名字';

  @override
  String get assistantEditChatModelTitle => '聊天模型';

  @override
  String get assistantEditChatModelSubtitle => '为该助手设置默认聊天模型（未设置时使用全局默认）';

  @override
  String get assistantEditTemperatureDescription => '控制输出的随机性，范围 0–2';

  @override
  String get assistantEditTopPDescription => '请不要修改此值，除非你知道自己在做什么';

  @override
  String get assistantEditParameterDisabled => '已关闭（使用服务商默认）';

  @override
  String get assistantEditParameterDisabled2 => '已关闭（无限制）';

  @override
  String get assistantEditContextMessagesTitle => '上下文消息数量';

  @override
  String get assistantEditContextMessagesDescription =>
      '多少历史消息会被当作上下文发送给模型，超过数量会忽略，只保留最近 N 条';

  @override
  String get assistantEditStreamOutputTitle => '流式输出';

  @override
  String get assistantEditStreamOutputDescription => '是否启用消息的流式输出';

  @override
  String get assistantEditThinkingBudgetTitle => '思考预算';

  @override
  String get assistantEditConfigureButton => '配置';

  @override
  String get assistantEditMaxTokensTitle => '最大 Token 数';

  @override
  String get assistantEditMaxTokensDescription => '留空表示无限制';

  @override
  String get assistantEditMaxTokensHint => '无限制';

  @override
  String get assistantEditChatBackgroundTitle => '聊天背景';

  @override
  String get assistantEditChatBackgroundDescription => '设置助手聊天页面的背景图片';

  @override
  String get assistantEditChooseImageButton => '选择背景图片';

  @override
  String get assistantEditClearButton => '清除';

  @override
  String get assistantEditAvatarChooseImage => '选择图片';

  @override
  String get assistantEditAvatarChooseEmoji => '选择表情';

  @override
  String get assistantEditAvatarEnterLink => '输入链接';

  @override
  String get assistantEditAvatarImportQQ => 'QQ头像';

  @override
  String get assistantEditAvatarReset => '重置';

  @override
  String get assistantEditEmojiDialogTitle => '选择表情';

  @override
  String get assistantEditEmojiDialogHint => '输入或粘贴任意表情';

  @override
  String get assistantEditEmojiDialogCancel => '取消';

  @override
  String get assistantEditEmojiDialogSave => '保存';

  @override
  String get assistantEditImageUrlDialogTitle => '输入图片链接';

  @override
  String get assistantEditImageUrlDialogHint =>
      '例如: https://example.com/avatar.png';

  @override
  String get assistantEditImageUrlDialogCancel => '取消';

  @override
  String get assistantEditImageUrlDialogSave => '保存';

  @override
  String get assistantEditQQAvatarDialogTitle => '使用QQ头像';

  @override
  String get assistantEditQQAvatarDialogHint => '输入QQ号码（5-12位）';

  @override
  String get assistantEditQQAvatarRandomButton => '随机QQ';

  @override
  String get assistantEditQQAvatarFailedMessage => '获取随机QQ头像失败，请重试';

  @override
  String get assistantEditQQAvatarDialogCancel => '取消';

  @override
  String get assistantEditQQAvatarDialogSave => '保存';

  @override
  String get assistantEditGalleryErrorMessage => '无法打开相册，试试输入图片链接';

  @override
  String get assistantEditGeneralErrorMessage => '发生错误，试试输入图片链接';

  @override
  String get assistantEditSystemPromptTitle => '系统提示词';

  @override
  String get assistantEditSystemPromptHint => '输入系统提示词…';

  @override
  String get assistantEditAvailableVariables => '可用变量：';

  @override
  String get assistantEditVariableDate => '日期';

  @override
  String get assistantEditVariableTime => '时间';

  @override
  String get assistantEditVariableDatetime => '日期和时间';

  @override
  String get assistantEditVariableModelId => '模型ID';

  @override
  String get assistantEditVariableModelName => '模型名称';

  @override
  String get assistantEditVariableLocale => '语言环境';

  @override
  String get assistantEditVariableTimezone => '时区';

  @override
  String get assistantEditVariableSystemVersion => '系统版本';

  @override
  String get assistantEditVariableDeviceInfo => '设备信息';

  @override
  String get assistantEditVariableBatteryLevel => '电池电量';

  @override
  String get assistantEditVariableNickname => '用户昵称';

  @override
  String get assistantEditMessageTemplateTitle => '聊天内容模板';

  @override
  String get assistantEditVariableRole => '角色';

  @override
  String get assistantEditVariableMessage => '内容';

  @override
  String get assistantEditPreviewTitle => '预览';

  @override
  String get assistantEditSampleUser => '用户';

  @override
  String get assistantEditSampleMessage => '你好啊';

  @override
  String get assistantEditSampleReply => '你好，有什么我可以帮你的吗？';

  @override
  String get assistantEditMcpNoServersMessage => '暂无已启动的 MCP 服务器';

  @override
  String get assistantEditMcpConnectedTag => '已连接';

  @override
  String assistantEditMcpToolsCountTag(String enabled, String total) {
    return '工具: $enabled/$total';
  }

  @override
  String get assistantEditModelUseGlobalDefault => '使用全局默认';

  @override
  String get assistantSettingsPageTitle => '助手设置';

  @override
  String get assistantSettingsDefaultTag => '默认';

  @override
  String get assistantSettingsDeleteButton => '删除';

  @override
  String get assistantSettingsEditButton => '编辑';

  @override
  String get assistantSettingsAddSheetTitle => '助手名称';

  @override
  String get assistantSettingsAddSheetHint => '输入助手名称';

  @override
  String get assistantSettingsAddSheetCancel => '取消';

  @override
  String get assistantSettingsAddSheetSave => '保存';

  @override
  String get assistantSettingsDeleteDialogTitle => '删除助手';

  @override
  String get assistantSettingsDeleteDialogContent => '确定要删除该助手吗？此操作不可撤销。';

  @override
  String get assistantSettingsDeleteDialogCancel => '取消';

  @override
  String get assistantSettingsDeleteDialogConfirm => '删除';

  @override
  String get mcpAssistantSheetTitle => 'MCP服务器';

  @override
  String get mcpAssistantSheetSubtitle => '为该助手启用的服务';

  @override
  String get mcpAssistantSheetSelectAll => '全选';

  @override
  String get mcpAssistantSheetClearAll => '全不选';

  @override
  String get backupPageTitle => '备份与恢复';

  @override
  String get backupPageWebDavTab => 'WebDAV 备份';

  @override
  String get backupPageImportExportTab => '导入和导出';

  @override
  String get backupPageWebDavServerUrl => 'WebDAV 服务器地址';

  @override
  String get backupPageUsername => '用户名';

  @override
  String get backupPagePassword => '密码';

  @override
  String get backupPagePath => '路径';

  @override
  String get backupPageChatsLabel => '聊天记录';

  @override
  String get backupPageFilesLabel => '文件';

  @override
  String get backupPageTestDone => '测试完成';

  @override
  String get backupPageTestConnection => '测试连接';

  @override
  String get backupPageRestartRequired => '需要重启应用';

  @override
  String get backupPageRestartContent => '恢复完成，需要重启以完全生效。';

  @override
  String get backupPageOK => '好的';

  @override
  String get backupPageCancel => '取消';

  @override
  String get backupPageSelectImportMode => '选择导入模式';

  @override
  String get backupPageSelectImportModeDescription => '请选择如何导入备份数据：';

  @override
  String get backupPageOverwriteMode => '完全覆盖';

  @override
  String get backupPageOverwriteModeDescription => '清空本地所有数据后恢复';

  @override
  String get backupPageMergeMode => '智能合并';

  @override
  String get backupPageMergeModeDescription => '仅添加不存在的数据（智能去重）';

  @override
  String get backupPageRestore => '恢复';

  @override
  String get backupPageBackupUploaded => '已上传备份';

  @override
  String get backupPageBackup => '立即备份';

  @override
  String get backupPageExporting => '正在导出...';

  @override
  String get backupPageExportToFile => '导出为文件';

  @override
  String get backupPageExportToFileSubtitle => '导出APP数据为文件';

  @override
  String get backupPageImportBackupFile => '备份文件导入';

  @override
  String get backupPageImportBackupFileSubtitle => '导入本地备份文件';

  @override
  String get backupPageImportFromOtherApps => '从其他APP导入';

  @override
  String get backupPageImportFromRikkaHub => '从 RikkaHub 导入';

  @override
  String get backupPageNotSupportedYet => '暂不支持';

  @override
  String get backupPageRemoteBackups => '远端备份';

  @override
  String get backupPageNoBackups => '暂无备份';

  @override
  String get backupPageRestoreTooltip => '恢复';

  @override
  String get backupPageDeleteTooltip => '删除';

  @override
  String get chatHistoryPageTitle => '聊天历史';

  @override
  String get chatHistoryPageSearchTooltip => '搜索';

  @override
  String get chatHistoryPageDeleteAllTooltip => '删除全部';

  @override
  String get chatHistoryPageDeleteAllDialogTitle => '删除全部对话';

  @override
  String get chatHistoryPageDeleteAllDialogContent => '确定要删除全部对话吗？此操作不可撤销。';

  @override
  String get chatHistoryPageCancel => '取消';

  @override
  String get chatHistoryPageDelete => '删除';

  @override
  String get chatHistoryPageDeletedAllSnackbar => '已删除全部对话';

  @override
  String get chatHistoryPageSearchHint => '搜索对话';

  @override
  String get chatHistoryPageNoConversations => '暂无对话';

  @override
  String get chatHistoryPagePinnedSection => '置顶';

  @override
  String get chatHistoryPagePin => '置顶';

  @override
  String get chatHistoryPagePinned => '已置顶';

  @override
  String get messageEditPageTitle => '编辑消息';

  @override
  String get messageEditPageSave => '保存';

  @override
  String get messageEditPageHint => '输入消息内容…';

  @override
  String get selectCopyPageTitle => '选择复制';

  @override
  String get selectCopyPageCopyAll => '复制全部';

  @override
  String get selectCopyPageCopiedAll => '已复制全部';

  @override
  String get bottomToolsSheetCamera => '拍照';

  @override
  String get bottomToolsSheetPhotos => '照片';

  @override
  String get bottomToolsSheetUpload => '上传文件';

  @override
  String get bottomToolsSheetClearContext => '清空上下文';

  @override
  String get bottomToolsSheetLearningMode => '学习模式';

  @override
  String get bottomToolsSheetLearningModeDescription => '帮助你循序渐进地学习知识';

  @override
  String get bottomToolsSheetConfigurePrompt => '设置提示词';

  @override
  String get bottomToolsSheetPrompt => '提示词';

  @override
  String get bottomToolsSheetPromptHint => '输入用于学习模式的提示词';

  @override
  String get bottomToolsSheetResetDefault => '重置为默认';

  @override
  String get bottomToolsSheetSave => '保存';

  @override
  String get messageMoreSheetTitle => '更多操作';

  @override
  String get messageMoreSheetSelectCopy => '选择复制';

  @override
  String get messageMoreSheetRenderWebView => '网页视图渲染';

  @override
  String get messageMoreSheetNotImplemented => '暂未实现';

  @override
  String get messageMoreSheetEdit => '编辑';

  @override
  String get messageMoreSheetShare => '分享';

  @override
  String get messageMoreSheetCreateBranch => '创建分支';

  @override
  String get messageMoreSheetDelete => '删除';

  @override
  String get reasoningBudgetSheetOff => '关闭';

  @override
  String get reasoningBudgetSheetAuto => '自动';

  @override
  String get reasoningBudgetSheetLight => '轻度推理';

  @override
  String get reasoningBudgetSheetMedium => '中度推理';

  @override
  String get reasoningBudgetSheetHeavy => '重度推理';

  @override
  String get reasoningBudgetSheetTitle => '思维链强度';

  @override
  String reasoningBudgetSheetCurrentLevel(String level) {
    return '当前档位：$level';
  }

  @override
  String get reasoningBudgetSheetOffSubtitle => '关闭推理功能，直接回答';

  @override
  String get reasoningBudgetSheetAutoSubtitle => '由模型自动决定推理级别';

  @override
  String get reasoningBudgetSheetLightSubtitle => '使用少量推理来回答问题';

  @override
  String get reasoningBudgetSheetMediumSubtitle => '使用较多推理来回答问题';

  @override
  String get reasoningBudgetSheetHeavySubtitle => '使用大量推理来回答问题，适合复杂问题';

  @override
  String get reasoningBudgetSheetCustomLabel => '自定义推理预算 (tokens)';

  @override
  String get reasoningBudgetSheetCustomHint => '例如：2048 (-1 自动，0 关闭)';

  @override
  String chatMessageWidgetFileNotFound(String fileName) {
    return '文件不存在: $fileName';
  }

  @override
  String chatMessageWidgetCannotOpenFile(String message) {
    return '无法打开文件: $message';
  }

  @override
  String chatMessageWidgetOpenFileError(String error) {
    return '打开文件失败: $error';
  }

  @override
  String get chatMessageWidgetCopiedToClipboard => '已复制到剪贴板';

  @override
  String get chatMessageWidgetResendTooltip => '重新发送';

  @override
  String get chatMessageWidgetMoreTooltip => '更多';

  @override
  String get chatMessageWidgetThinking => '正在思考...';

  @override
  String get chatMessageWidgetTranslation => '翻译';

  @override
  String get chatMessageWidgetTranslating => '翻译中...';

  @override
  String get chatMessageWidgetCitationNotFound => '未找到引用来源';

  @override
  String chatMessageWidgetCannotOpenUrl(String url) {
    return '无法打开链接: $url';
  }

  @override
  String get chatMessageWidgetOpenLinkError => '打开链接失败';

  @override
  String chatMessageWidgetCitationsTitle(int count) {
    return '引用（共$count条）';
  }

  @override
  String get chatMessageWidgetRegenerateTooltip => '重新生成';

  @override
  String get chatMessageWidgetStopTooltip => '停止';

  @override
  String get chatMessageWidgetSpeakTooltip => '朗读';

  @override
  String get chatMessageWidgetTranslateTooltip => '翻译';

  @override
  String get chatMessageWidgetBuiltinSearchHideNote => '隐藏内置搜索工具卡片';

  @override
  String get chatMessageWidgetDeepThinking => '深度思考';

  @override
  String get chatMessageWidgetCreateMemory => '创建记忆';

  @override
  String get chatMessageWidgetEditMemory => '编辑记忆';

  @override
  String get chatMessageWidgetDeleteMemory => '删除记忆';

  @override
  String chatMessageWidgetWebSearch(String query) {
    return '联网检索: $query';
  }

  @override
  String get chatMessageWidgetBuiltinSearch => '模型内置搜索';

  @override
  String chatMessageWidgetToolCall(String name) {
    return '调用工具: $name';
  }

  @override
  String chatMessageWidgetToolResult(String name) {
    return '调用工具: $name';
  }

  @override
  String get chatMessageWidgetNoResultYet => '（暂无结果）';

  @override
  String get chatMessageWidgetArguments => '参数';

  @override
  String get chatMessageWidgetResult => '结果';

  @override
  String chatMessageWidgetCitationsCount(int count) {
    return '共$count条引用';
  }

  @override
  String get messageExportSheetAssistant => '助手';

  @override
  String get messageExportSheetDefaultTitle => '新对话';

  @override
  String get messageExportSheetExporting => '正在导出…';

  @override
  String messageExportSheetExportFailed(String error) {
    return '导出失败: $error';
  }

  @override
  String messageExportSheetExportedAs(String filename) {
    return '已导出为 $filename';
  }

  @override
  String get messageExportSheetFormatTitle => '导出格式';

  @override
  String get messageExportSheetMarkdown => 'Markdown';

  @override
  String get messageExportSheetSingleMarkdownSubtitle => '将该消息导出为 Markdown 文件';

  @override
  String get messageExportSheetBatchMarkdownSubtitle => '将选中的消息导出为 Markdown 文件';

  @override
  String get messageExportSheetExportImage => '导出为图片';

  @override
  String get messageExportSheetSingleExportImageSubtitle => '将该消息渲染为 PNG 图片';

  @override
  String get messageExportSheetBatchExportImageSubtitle => '将选中的消息渲染为 PNG 图片';

  @override
  String get messageExportSheetDateTimeWithSecondsPattern =>
      'yyyy年M月d日 HH:mm:ss';

  @override
  String get sideDrawerMenuRename => '重命名';

  @override
  String get sideDrawerMenuPin => '置顶';

  @override
  String get sideDrawerMenuUnpin => '取消置顶';

  @override
  String get sideDrawerMenuRegenerateTitle => '重新生成标题';

  @override
  String get sideDrawerMenuDelete => '删除';

  @override
  String sideDrawerDeleteSnackbar(String title) {
    return '已删除“$title”';
  }

  @override
  String get sideDrawerRenameHint => '输入新名称';

  @override
  String get sideDrawerCancel => '取消';

  @override
  String get sideDrawerOK => '确定';

  @override
  String get sideDrawerSave => '保存';

  @override
  String get sideDrawerGreetingMorning => '早上好 👋';

  @override
  String get sideDrawerGreetingNoon => '中午好 👋';

  @override
  String get sideDrawerGreetingAfternoon => '下午好 👋';

  @override
  String get sideDrawerGreetingEvening => '晚上好 👋';

  @override
  String get sideDrawerDateToday => '今天';

  @override
  String get sideDrawerDateYesterday => '昨天';

  @override
  String get sideDrawerDateShortPattern => 'M月d日';

  @override
  String get sideDrawerDateFullPattern => 'yyyy年M月d日';

  @override
  String get sideDrawerSearchHint => '搜索聊天记录';

  @override
  String sideDrawerUpdateTitle(String version) {
    return '发现新版本：$version';
  }

  @override
  String sideDrawerUpdateTitleWithBuild(String version, int build) {
    return '发现新版本：$version ($build)';
  }

  @override
  String get sideDrawerLinkCopied => '已复制下载链接';

  @override
  String get sideDrawerPinnedLabel => '置顶';

  @override
  String get sideDrawerHistory => '聊天历史';

  @override
  String get sideDrawerSettings => '设置';

  @override
  String get sideDrawerChooseAssistantTitle => '选择助手';

  @override
  String get sideDrawerChooseImage => '选择图片';

  @override
  String get sideDrawerChooseEmoji => '选择表情';

  @override
  String get sideDrawerEnterLink => '输入链接';

  @override
  String get sideDrawerImportFromQQ => 'QQ头像';

  @override
  String get sideDrawerReset => '重置';

  @override
  String get sideDrawerEmojiDialogTitle => '选择表情';

  @override
  String get sideDrawerEmojiDialogHint => '输入或粘贴任意表情';

  @override
  String get sideDrawerImageUrlDialogTitle => '输入图片链接';

  @override
  String get sideDrawerImageUrlDialogHint =>
      '例如: https://example.com/avatar.png';

  @override
  String get sideDrawerQQAvatarDialogTitle => '使用QQ头像';

  @override
  String get sideDrawerQQAvatarInputHint => '输入QQ号码（5-12位）';

  @override
  String get sideDrawerQQAvatarFetchFailed => '获取随机QQ头像失败，请重试';

  @override
  String get sideDrawerRandomQQ => '随机QQ';

  @override
  String get sideDrawerGalleryOpenError => '无法打开相册，试试输入图片链接';

  @override
  String get sideDrawerGeneralImageError => '发生错误，试试输入图片链接';

  @override
  String get sideDrawerSetNicknameTitle => '设置昵称';

  @override
  String get sideDrawerNicknameLabel => '昵称';

  @override
  String get sideDrawerNicknameHint => '输入新的昵称';

  @override
  String get sideDrawerRename => '重命名';

  @override
  String get chatInputBarHint => '输入消息与AI聊天';

  @override
  String get chatInputBarSelectModelTooltip => '选择模型';

  @override
  String get chatInputBarOnlineSearchTooltip => '联网搜索';

  @override
  String get chatInputBarReasoningStrengthTooltip => '思维链强度';

  @override
  String get chatInputBarMcpServersTooltip => 'MCP服务器';

  @override
  String get chatInputBarMoreTooltip => '更多';

  @override
  String get mcpPageBackTooltip => '返回';

  @override
  String get mcpPageAddMcpTooltip => '添加 MCP';

  @override
  String get mcpPageNoServers => '暂无 MCP 服务器';

  @override
  String get mcpPageErrorDialogTitle => '连接错误';

  @override
  String get mcpPageErrorNoDetails => '未提供错误详情';

  @override
  String get mcpPageClose => '关闭';

  @override
  String get mcpPageReconnect => '重新连接';

  @override
  String get mcpPageStatusConnected => '已连接';

  @override
  String get mcpPageStatusConnecting => '连接中…';

  @override
  String get mcpPageStatusDisconnected => '未连接';

  @override
  String get mcpPageStatusDisabled => '已禁用';

  @override
  String mcpPageToolsCount(int enabled, int total) {
    return '工具: $enabled/$total';
  }

  @override
  String get mcpPageConnectionFailed => '连接失败';

  @override
  String get mcpPageDetails => '详情';

  @override
  String get mcpPageDelete => '删除';

  @override
  String get mcpPageConfirmDeleteTitle => '确认删除';

  @override
  String get mcpPageConfirmDeleteContent => '删除后可通过撤销恢复。是否删除？';

  @override
  String get mcpPageServerDeleted => '已删除服务器';

  @override
  String get mcpPageUndo => '撤销';

  @override
  String get mcpPageCancel => '取消';

  @override
  String get mcpConversationSheetTitle => 'MCP服务器';

  @override
  String get mcpConversationSheetSubtitle => '选择在此助手中启用的服务';

  @override
  String get mcpConversationSheetSelectAll => '全选';

  @override
  String get mcpConversationSheetClearAll => '全不选';

  @override
  String get mcpConversationSheetNoRunning => '暂无已启动的 MCP 服务器';

  @override
  String get mcpConversationSheetConnected => '已连接';

  @override
  String mcpConversationSheetToolsCount(int enabled, int total) {
    return '工具: $enabled/$total';
  }

  @override
  String get mcpServerEditSheetEnabledLabel => '是否启用';

  @override
  String get mcpServerEditSheetNameLabel => '名称';

  @override
  String get mcpServerEditSheetTransportLabel => '传输类型';

  @override
  String get mcpServerEditSheetSseRetryHint => '如果SSE连接失败，请多试几次';

  @override
  String get mcpServerEditSheetUrlLabel => '服务器地址';

  @override
  String get mcpServerEditSheetCustomHeadersTitle => '自定义请求头';

  @override
  String get mcpServerEditSheetHeaderNameLabel => '请求头名称';

  @override
  String get mcpServerEditSheetHeaderNameHint => '如 Authorization';

  @override
  String get mcpServerEditSheetHeaderValueLabel => '请求头值';

  @override
  String get mcpServerEditSheetHeaderValueHint => '如 Bearer xxxxxx';

  @override
  String get mcpServerEditSheetRemoveHeaderTooltip => '删除';

  @override
  String get mcpServerEditSheetAddHeader => '添加请求头';

  @override
  String get mcpServerEditSheetTitleEdit => '编辑 MCP';

  @override
  String get mcpServerEditSheetTitleAdd => '添加 MCP';

  @override
  String get mcpServerEditSheetSyncToolsTooltip => '同步工具';

  @override
  String get mcpServerEditSheetTabBasic => '基础设置';

  @override
  String get mcpServerEditSheetTabTools => '工具';

  @override
  String get mcpServerEditSheetNoToolsHint => '暂无工具，点击上方同步';

  @override
  String get mcpServerEditSheetCancel => '取消';

  @override
  String get mcpServerEditSheetSave => '保存';

  @override
  String get mcpServerEditSheetUrlRequired => '请输入服务器地址';

  @override
  String get defaultModelPageBackTooltip => '返回';

  @override
  String get defaultModelPageTitle => '默认模型';

  @override
  String get defaultModelPageChatModelTitle => '聊天模型';

  @override
  String get defaultModelPageChatModelSubtitle => '全局默认的聊天模型';

  @override
  String get defaultModelPageTitleModelTitle => '标题总结模型';

  @override
  String get defaultModelPageTitleModelSubtitle => '用于总结对话标题的模型，推荐使用快速且便宜的模型';

  @override
  String get defaultModelPageTranslateModelTitle => '翻译模型';

  @override
  String get defaultModelPageTranslateModelSubtitle =>
      '用于翻译消息内容的模型，推荐使用快速且准确的模型';

  @override
  String get defaultModelPagePromptLabel => '提示词';

  @override
  String get defaultModelPageTitlePromptHint => '输入用于标题总结的提示词模板';

  @override
  String get defaultModelPageTranslatePromptHint => '输入用于翻译的提示词模板';

  @override
  String get defaultModelPageResetDefault => '重置为默认';

  @override
  String get defaultModelPageSave => '保存';

  @override
  String defaultModelPageTitleVars(String contentVar, String localeVar) {
    return '变量: 对话内容: $contentVar, 语言: $localeVar';
  }

  @override
  String defaultModelPageTranslateVars(String sourceVar, String targetVar) {
    return '变量：原始文本：$sourceVar，目标语言：$targetVar';
  }

  @override
  String get modelDetailSheetAddModel => '添加模型';

  @override
  String get modelDetailSheetEditModel => '编辑模型';

  @override
  String get modelDetailSheetBasicTab => '基本设置';

  @override
  String get modelDetailSheetAdvancedTab => '高级设置';

  @override
  String get modelDetailSheetModelIdLabel => '模型 ID';

  @override
  String get modelDetailSheetModelIdHint => '必填，建议小写字母、数字、连字符';

  @override
  String modelDetailSheetModelIdDisabledHint(String modelId) {
    return '$modelId';
  }

  @override
  String get modelDetailSheetModelNameLabel => '模型名称';

  @override
  String get modelDetailSheetModelTypeLabel => '模型类型';

  @override
  String get modelDetailSheetChatType => '聊天';

  @override
  String get modelDetailSheetEmbeddingType => '嵌入';

  @override
  String get modelDetailSheetInputModesLabel => '输入模式';

  @override
  String get modelDetailSheetOutputModesLabel => '输出模式';

  @override
  String get modelDetailSheetAbilitiesLabel => '能力';

  @override
  String get modelDetailSheetTextMode => '文本';

  @override
  String get modelDetailSheetImageMode => '图片';

  @override
  String get modelDetailSheetToolsAbility => '工具';

  @override
  String get modelDetailSheetReasoningAbility => '推理';

  @override
  String get modelDetailSheetProviderOverrideDescription =>
      '供应商重写：允许为特定模型自定义供应商设置。（暂未实现）';

  @override
  String get modelDetailSheetAddProviderOverride => '添加供应商重写';

  @override
  String get modelDetailSheetCustomHeadersTitle => '自定义 Headers';

  @override
  String get modelDetailSheetAddHeader => '添加 Header';

  @override
  String get modelDetailSheetCustomBodyTitle => '自定义 Body';

  @override
  String get modelDetailSheetAddBody => '添加 Body';

  @override
  String get modelDetailSheetBuiltinToolsDescription =>
      '内置工具仅支持部分 API（例如 Gemini 官方 API）（暂未实现）。';

  @override
  String get modelDetailSheetSearchTool => '搜索';

  @override
  String get modelDetailSheetSearchToolDescription => '启用 Google 搜索集成';

  @override
  String get modelDetailSheetUrlContextTool => 'URL 上下文';

  @override
  String get modelDetailSheetUrlContextToolDescription => '启用 URL 内容处理';

  @override
  String get modelDetailSheetCancelButton => '取消';

  @override
  String get modelDetailSheetAddButton => '添加';

  @override
  String get modelDetailSheetConfirmButton => '确认';

  @override
  String get modelDetailSheetInvalidIdError => '请输入有效的模型 ID（不少于2个字符且不含空格）';

  @override
  String get modelDetailSheetModelIdExistsError => '模型 ID 已存在';

  @override
  String get modelDetailSheetHeaderKeyHint => 'Header Key';

  @override
  String get modelDetailSheetHeaderValueHint => 'Header Value';

  @override
  String get modelDetailSheetBodyKeyHint => 'Body Key';

  @override
  String get modelDetailSheetBodyJsonHint => 'Body JSON';

  @override
  String get modelSelectSheetSearchHint => '搜索模型或服务商';

  @override
  String get modelSelectSheetFavoritesSection => '收藏';

  @override
  String get modelSelectSheetFavoriteTooltip => '收藏';

  @override
  String get modelSelectSheetChatType => '聊天';

  @override
  String get modelSelectSheetEmbeddingType => '嵌入';

  @override
  String get providerDetailPageShareTooltip => '分享';

  @override
  String get providerDetailPageDeleteProviderTooltip => '删除供应商';

  @override
  String get providerDetailPageDeleteProviderTitle => '删除供应商';

  @override
  String get providerDetailPageDeleteProviderContent => '确定要删除该供应商吗？此操作不可撤销。';

  @override
  String get providerDetailPageCancelButton => '取消';

  @override
  String get providerDetailPageDeleteButton => '删除';

  @override
  String get providerDetailPageProviderDeletedSnackbar => '已删除供应商';

  @override
  String get providerDetailPageConfigTab => '配置';

  @override
  String get providerDetailPageModelsTab => '模型';

  @override
  String get providerDetailPageNetworkTab => '网络代理';

  @override
  String get providerDetailPageEnabledTitle => '是否启用';

  @override
  String get providerDetailPageNameLabel => '名称';

  @override
  String get providerDetailPageApiKeyHint => '留空则使用上层默认';

  @override
  String get providerDetailPageHideTooltip => '隐藏';

  @override
  String get providerDetailPageShowTooltip => '显示';

  @override
  String get providerDetailPageApiPathLabel => 'API 路径';

  @override
  String get providerDetailPageResponseApiTitle => 'Response API (/responses)';

  @override
  String get providerDetailPageVertexAiTitle => 'Vertex AI';

  @override
  String get providerDetailPageLocationLabel => '区域 Location';

  @override
  String get providerDetailPageProjectIdLabel => '项目 ID';

  @override
  String get providerDetailPageServiceAccountJsonLabel => '服务账号 JSON（粘贴或导入）';

  @override
  String get providerDetailPageImportJsonButton => '导入 JSON';

  @override
  String get providerDetailPageTestButton => '测试';

  @override
  String get providerDetailPageSaveButton => '保存';

  @override
  String get providerDetailPageProviderRemovedMessage => '供应商已删除';

  @override
  String get providerDetailPageNoModelsTitle => '暂无模型';

  @override
  String get providerDetailPageNoModelsSubtitle => '点击下方按钮添加模型';

  @override
  String get providerDetailPageDeleteModelButton => '删除';

  @override
  String get providerDetailPageConfirmDeleteTitle => '确认删除';

  @override
  String get providerDetailPageConfirmDeleteContent => '删除后可通过撤销恢复。是否删除？';

  @override
  String get providerDetailPageModelDeletedSnackbar => '已删除模型';

  @override
  String get providerDetailPageUndoButton => '撤销';

  @override
  String get providerDetailPageAddNewModelButton => '添加新模型';

  @override
  String get providerDetailPageEnableProxyTitle => '是否启用代理';

  @override
  String get providerDetailPageHostLabel => '主机地址';

  @override
  String get providerDetailPagePortLabel => '端口';

  @override
  String get providerDetailPageUsernameOptionalLabel => '用户名（可选）';

  @override
  String get providerDetailPagePasswordOptionalLabel => '密码（可选）';

  @override
  String get providerDetailPageSavedSnackbar => '已保存';

  @override
  String get providerDetailPageEmbeddingsGroupTitle => '嵌入';

  @override
  String get providerDetailPageOtherModelsGroupTitle => '其他模型';

  @override
  String get providerDetailPageRemoveGroupTooltip => '移除本组';

  @override
  String get providerDetailPageAddGroupTooltip => '添加本组';

  @override
  String get providerDetailPageFilterHint => '输入模型名称筛选';

  @override
  String get providerDetailPageDeleteText => '删除';

  @override
  String get providerDetailPageEditTooltip => '编辑';

  @override
  String get providerDetailPageTestConnectionTitle => '测试连接';

  @override
  String get providerDetailPageSelectModelButton => '选择模型';

  @override
  String get providerDetailPageChangeButton => '更换';

  @override
  String get providerDetailPageTestingMessage => '正在测试…';

  @override
  String get providerDetailPageTestSuccessMessage => '测试成功';

  @override
  String get providersPageTitle => '供应商';

  @override
  String get providersPageImportTooltip => '导入';

  @override
  String get providersPageAddTooltip => '新增';

  @override
  String get providersPageProviderAddedSnackbar => '已添加供应商';

  @override
  String get providersPageSiliconFlowName => '硅基流动';

  @override
  String get providersPageAliyunName => '阿里云千问';

  @override
  String get providersPageZhipuName => '智谱';

  @override
  String get providersPageByteDanceName => '火山引擎';

  @override
  String get providersPageEnabledStatus => '启用';

  @override
  String get providersPageDisabledStatus => '禁用';

  @override
  String get providersPageModelsCountSuffix => ' models';

  @override
  String get providersPageModelsCountSingleSuffix => '个模型';

  @override
  String get addProviderSheetTitle => '添加供应商';

  @override
  String get addProviderSheetEnabledLabel => '是否启用';

  @override
  String get addProviderSheetNameLabel => '名称';

  @override
  String get addProviderSheetApiPathLabel => 'API 路径';

  @override
  String get addProviderSheetVertexAiLocationLabel => '位置';

  @override
  String get addProviderSheetVertexAiProjectIdLabel => '项目ID';

  @override
  String get addProviderSheetVertexAiServiceAccountJsonLabel =>
      '服务账号 JSON（粘贴或导入）';

  @override
  String get addProviderSheetImportJsonButton => '导入 JSON';

  @override
  String get addProviderSheetCancelButton => '取消';

  @override
  String get addProviderSheetAddButton => '添加';

  @override
  String get importProviderSheetTitle => '导入供应商';

  @override
  String get importProviderSheetScanQrTooltip => '扫码导入';

  @override
  String get importProviderSheetFromGalleryTooltip => '从相册导入';

  @override
  String importProviderSheetImportSuccessMessage(int count) {
    return '已导入$count个供应商';
  }

  @override
  String importProviderSheetImportFailedMessage(String error) {
    return '导入失败: $error';
  }

  @override
  String get importProviderSheetDescription =>
      '粘贴分享字符串（可多行，每行一个）或 ChatBox JSON';

  @override
  String get importProviderSheetInputHint => 'ai-provider:v1:...';

  @override
  String get importProviderSheetCancelButton => '取消';

  @override
  String get importProviderSheetImportButton => '导入';

  @override
  String get shareProviderSheetTitle => '分享供应商配置';

  @override
  String get shareProviderSheetDescription => '复制下面的分享字符串，或使用二维码分享。';

  @override
  String get shareProviderSheetCopiedMessage => '已复制';

  @override
  String get shareProviderSheetCopyButton => '复制';

  @override
  String get shareProviderSheetShareButton => '分享';

  @override
  String get qrScanPageTitle => '扫码导入';

  @override
  String get qrScanPageInstruction => '将二维码对准取景框';

  @override
  String get searchServicesPageBackTooltip => '返回';

  @override
  String get searchServicesPageTitle => '搜索服务';

  @override
  String get searchServicesPageDone => '完成';

  @override
  String get searchServicesPageEdit => '编辑';

  @override
  String get searchServicesPageAddProvider => '添加提供商';

  @override
  String get searchServicesPageSearchProviders => '搜索提供商';

  @override
  String get searchServicesPageGeneralOptions => '通用选项';

  @override
  String get searchServicesPageMaxResults => '最大结果数';

  @override
  String get searchServicesPageTimeoutSeconds => '超时时间（秒）';

  @override
  String get searchServicesPageAtLeastOneServiceRequired => '至少需要一个搜索服务';

  @override
  String get searchServicesPageTestingStatus => '测试中…';

  @override
  String get searchServicesPageConnectedStatus => '已连接';

  @override
  String get searchServicesPageFailedStatus => '连接失败';

  @override
  String get searchServicesPageNotTestedStatus => '未测试';

  @override
  String get searchServicesPageTestConnectionTooltip => '测试连接';

  @override
  String get searchServicesPageConfiguredStatus => '已配置';

  @override
  String get searchServicesPageApiKeyRequiredStatus => '需要 API Key';

  @override
  String get searchServicesPageUrlRequiredStatus => '需要 URL';

  @override
  String get searchServicesAddDialogTitle => '添加搜索服务';

  @override
  String get searchServicesAddDialogServiceType => '服务类型';

  @override
  String get searchServicesAddDialogBingLocal => '本地';

  @override
  String get searchServicesAddDialogCancel => '取消';

  @override
  String get searchServicesAddDialogAdd => '添加';

  @override
  String get searchServicesAddDialogApiKeyRequired => 'API Key 必填';

  @override
  String get searchServicesAddDialogInstanceUrl => '实例 URL';

  @override
  String get searchServicesAddDialogUrlRequired => 'URL 必填';

  @override
  String get searchServicesAddDialogEnginesOptional => '搜索引擎（可选）';

  @override
  String get searchServicesAddDialogLanguageOptional => '语言（可选）';

  @override
  String get searchServicesAddDialogUsernameOptional => '用户名（可选）';

  @override
  String get searchServicesAddDialogPasswordOptional => '密码（可选）';

  @override
  String get searchServicesEditDialogEdit => '编辑';

  @override
  String get searchServicesEditDialogCancel => '取消';

  @override
  String get searchServicesEditDialogSave => '保存';

  @override
  String get searchServicesEditDialogBingLocalNoConfig => 'Bing 本地搜索不需要配置。';

  @override
  String get searchServicesEditDialogApiKeyRequired => 'API Key 必填';

  @override
  String get searchServicesEditDialogInstanceUrl => '实例 URL';

  @override
  String get searchServicesEditDialogUrlRequired => 'URL 必填';

  @override
  String get searchServicesEditDialogEnginesOptional => '搜索引擎（可选）';

  @override
  String get searchServicesEditDialogLanguageOptional => '语言（可选）';

  @override
  String get searchServicesEditDialogUsernameOptional => '用户名（可选）';

  @override
  String get searchServicesEditDialogPasswordOptional => '密码（可选）';

  @override
  String get searchSettingsSheetTitle => '搜索设置';

  @override
  String get searchSettingsSheetBuiltinSearchTitle => '模型内置搜索';

  @override
  String get searchSettingsSheetBuiltinSearchDescription => '是否启用模型内置的搜索功能';

  @override
  String get searchSettingsSheetWebSearchTitle => '网络搜索';

  @override
  String get searchSettingsSheetWebSearchDescription => '是否启用网页搜索';

  @override
  String get searchSettingsSheetOpenSearchServicesTooltip => '打开搜索服务设置';

  @override
  String get searchSettingsSheetNoServicesMessage => '暂无可用服务，请先在\"搜索服务\"中添加';

  @override
  String get aboutPageEasterEggTitle => '彩蛋已解锁！';

  @override
  String get aboutPageEasterEggMessage => '\n（好吧现在还没彩蛋）';

  @override
  String get aboutPageEasterEggButton => '好的';

  @override
  String get aboutPageAppDescription => '开源移动端 AI 助手';

  @override
  String get aboutPageNoQQGroup => '暂无QQ群';

  @override
  String get aboutPageVersion => '版本';

  @override
  String get aboutPageSystem => '系统';

  @override
  String get aboutPageWebsite => '官网';

  @override
  String get aboutPageLicense => '许可证';

  @override
  String get displaySettingsPageShowUserAvatarTitle => '显示用户头像';

  @override
  String get displaySettingsPageShowUserAvatarSubtitle => '是否在聊天消息中显示用户头像';

  @override
  String get displaySettingsPageShowUserNameTimestampTitle => '显示用户名称和时间戳';

  @override
  String get displaySettingsPageShowUserNameTimestampSubtitle =>
      '是否在聊天消息中显示用户名称和时间戳';

  @override
  String get displaySettingsPageShowModelNameTimestampTitle => '显示模型名称和时间戳';

  @override
  String get displaySettingsPageShowModelNameTimestampSubtitle =>
      '是否在聊天消息中显示模型名称和时间戳';

  @override
  String get displaySettingsPageChatModelIconTitle => '聊天列表模型图标';

  @override
  String get displaySettingsPageChatModelIconSubtitle => '是否在聊天消息中显示模型图标';

  @override
  String get displaySettingsPageShowTokenStatsTitle => '显示Token和上下文统计';

  @override
  String get displaySettingsPageShowTokenStatsSubtitle => '显示 token 用量与消息数量';

  @override
  String get displaySettingsPageAutoCollapseThinkingTitle => '自动折叠思考';

  @override
  String get displaySettingsPageAutoCollapseThinkingSubtitle =>
      '思考完成后自动折叠，保持界面简洁';

  @override
  String get displaySettingsPageShowUpdatesTitle => '显示更新';

  @override
  String get displaySettingsPageShowUpdatesSubtitle => '显示应用更新通知';

  @override
  String get displaySettingsPageMessageNavButtonsTitle => '消息导航按钮';

  @override
  String get displaySettingsPageMessageNavButtonsSubtitle => '滚动时显示快速跳转按钮';

  @override
  String get displaySettingsPageHapticsOnSidebarTitle => '侧边栏触觉反馈';

  @override
  String get displaySettingsPageHapticsOnSidebarSubtitle => '打开/关闭侧边栏时启用触觉反馈';

  @override
  String get displaySettingsPageHapticsOnGenerateTitle => '消息生成触觉反馈';

  @override
  String get displaySettingsPageHapticsOnGenerateSubtitle => '生成消息时启用触觉反馈';

  @override
  String get displaySettingsPageNewChatOnLaunchTitle => '启动时新建对话';

  @override
  String get displaySettingsPageNewChatOnLaunchSubtitle => '应用启动时自动创建新对话';

  @override
  String get displaySettingsPageChatFontSizeTitle => '聊天字体大小';

  @override
  String get displaySettingsPageChatFontSampleText => '这是一个示例的聊天文本';

  @override
  String get displaySettingsPageThemeSettingsTitle => '主题设置';

  @override
  String get themeSettingsPageDynamicColorSection => '动态颜色';

  @override
  String get themeSettingsPageUseDynamicColorTitle => '使用动态颜色';

  @override
  String get themeSettingsPageUseDynamicColorSubtitle => '基于系统配色（Android 12+）';

  @override
  String get themeSettingsPageColorPalettesSection => '配色方案';

  @override
  String get ttsServicesPageBackButton => '返回';

  @override
  String get ttsServicesPageTitle => '语音服务';

  @override
  String get ttsServicesPageAddTooltip => '新增';

  @override
  String get ttsServicesPageAddNotImplemented => '新增 TTS 服务暂未实现';

  @override
  String get ttsServicesPageSystemTtsTitle => '系统TTS';

  @override
  String get ttsServicesPageSystemTtsAvailableSubtitle => '使用系统内置语音合成';

  @override
  String ttsServicesPageSystemTtsUnavailableSubtitle(String error) {
    return '不可用：$error';
  }

  @override
  String get ttsServicesPageSystemTtsUnavailableNotInitialized => '未初始化';

  @override
  String get ttsServicesPageTestSpeechText => '你好，这是一次测试语音。';

  @override
  String get ttsServicesPageConfigureTooltip => '配置';

  @override
  String get ttsServicesPageTestVoiceTooltip => '测试语音';

  @override
  String get ttsServicesPageStopTooltip => '停止';

  @override
  String get ttsServicesPageDeleteTooltip => '删除';

  @override
  String get ttsServicesPageSystemTtsSettingsTitle => '系统 TTS 设置';

  @override
  String get ttsServicesPageEngineLabel => '引擎';

  @override
  String get ttsServicesPageAutoLabel => '自动';

  @override
  String get ttsServicesPageLanguageLabel => '语言';

  @override
  String get ttsServicesPageSpeechRateLabel => '语速';

  @override
  String get ttsServicesPagePitchLabel => '音调';

  @override
  String get ttsServicesPageSettingsSavedMessage => '设置已保存。';

  @override
  String get ttsServicesPageDoneButton => '完成';

  @override
  String imageViewerPageShareFailedOpenFile(String message) {
    return '无法分享，已尝试打开文件: $message';
  }

  @override
  String imageViewerPageShareFailed(String error) {
    return '分享失败: $error';
  }

  @override
  String get imageViewerPageShareButton => '分享图片';

  @override
  String get settingsShare => 'Kelivo - 开源移动端AI助手';

  @override
  String get searchProviderBingLocalDescription =>
      '使用网络抓取工具获取必应搜索结果。无需 API 密钥，但可能不够稳定。';

  @override
  String get searchProviderBraveDescription => 'Brave 独立搜索引擎。注重隐私，无跟踪或画像。';

  @override
  String get searchProviderExaDescription => '具备语义理解的神经搜索引擎。适合研究与查找特定内容。';

  @override
  String get searchProviderLinkUpDescription =>
      '提供来源可追溯答案的搜索 API，同时提供搜索结果与 AI 摘要。';

  @override
  String get searchProviderMetasoDescription => '秘塔中文搜索引擎。面向中文内容优化并提供 AI 能力。';

  @override
  String get searchProviderSearXNGDescription => '注重隐私的元搜索引擎。需自建实例，无跟踪。';

  @override
  String get searchProviderTavilyDescription =>
      '为大型语言模型（LLMs）优化的 AI 搜索 API，提供高质量、相关的搜索结果。';

  @override
  String get searchProviderZhipuDescription =>
      '智谱 AI 旗下中文 AI 搜索服务，针对中文内容与查询进行了优化。';

  @override
  String get searchServiceNameBingLocal => 'Bing（Local）';

  @override
  String get searchServiceNameTavily => 'Tavily';

  @override
  String get searchServiceNameExa => 'Exa';

  @override
  String get searchServiceNameZhipu => '智谱';

  @override
  String get searchServiceNameSearXNG => 'SearXNG';

  @override
  String get searchServiceNameLinkUp => 'LinkUp';

  @override
  String get searchServiceNameBrave => 'Brave';

  @override
  String get searchServiceNameMetaso => '秘塔';

  @override
  String get generationInterrupted => '生成已中断';

  @override
  String get titleForLocale => '新对话';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get helloWorld => '你好，世界！';

  @override
  String get settingsPageBackButton => '返回';

  @override
  String get settingsPageTitle => '設定';

  @override
  String get settingsPageDarkMode => '深色';

  @override
  String get settingsPageLightMode => '淺色';

  @override
  String get settingsPageSystemMode => '跟隨系統';

  @override
  String get settingsPageWarningMessage => '部分服務未設定，某些功能可能不可用';

  @override
  String get settingsPageGeneralSection => '通用設定';

  @override
  String get settingsPageColorMode => '顏色模式';

  @override
  String get settingsPageDisplay => '顯示設定';

  @override
  String get settingsPageDisplaySubtitle => '介面主題與字號等外觀設定';

  @override
  String get settingsPageAssistant => '助理';

  @override
  String get settingsPageAssistantSubtitle => '預設助理與對話風格';

  @override
  String get settingsPageModelsServicesSection => '模型與服務';

  @override
  String get settingsPageDefaultModel => '預設模型';

  @override
  String get settingsPageProviders => '供應商';

  @override
  String get settingsPageSearch => '搜尋服務';

  @override
  String get settingsPageTts => '語音服務';

  @override
  String get settingsPageMcp => 'MCP';

  @override
  String get settingsPageDataSection => '資料設定';

  @override
  String get settingsPageBackup => '資料備份';

  @override
  String get settingsPageChatStorage => '聊天記錄儲存';

  @override
  String get settingsPageCalculating => '統計中…';

  @override
  String settingsPageFilesCount(int count, String size) {
    return '共 $count 個檔案 · $size';
  }

  @override
  String get settingsPageAboutSection => '關於';

  @override
  String get settingsPageAbout => '關於';

  @override
  String get settingsPageDocs => '使用文件';

  @override
  String get settingsPageSponsor => '贊助';

  @override
  String get settingsPageShare => '分享';

  @override
  String get sponsorPageMethodsSectionTitle => '贊助方式';

  @override
  String get sponsorPageSponsorsSectionTitle => '贊助用戶';

  @override
  String get sponsorPageEmpty => '暫無贊助者';

  @override
  String get sponsorPageAfdianTitle => '愛發電';

  @override
  String get sponsorPageAfdianSubtitle => 'afdian.com/a/kelivo';

  @override
  String get sponsorPageWeChatTitle => '微信贊助';

  @override
  String get sponsorPageWeChatSubtitle => '微信贊助碼';

  @override
  String get languageDisplaySimplifiedChinese => '简体中文';

  @override
  String get languageDisplayEnglish => 'English';

  @override
  String get languageDisplayTraditionalChinese => '繁體中文';

  @override
  String get languageDisplayJapanese => '日本語';

  @override
  String get languageDisplayKorean => '한국어';

  @override
  String get languageDisplayFrench => 'Français';

  @override
  String get languageDisplayGerman => 'Deutsch';

  @override
  String get languageDisplayItalian => 'Italiano';

  @override
  String get languageSelectSheetTitle => '選擇翻譯語言';

  @override
  String get languageSelectSheetClearButton => '清空翻譯';

  @override
  String get homePageClearContext => '清空上下文';

  @override
  String homePageClearContextWithCount(String actual, String configured) {
    return '清空上下文 ($actual/$configured)';
  }

  @override
  String get homePageDefaultAssistant => '預設助理';

  @override
  String get mermaidExportPng => '匯出 PNG';

  @override
  String get mermaidExportFailed => '匯出失敗';

  @override
  String get mermaidPreviewOpen => '瀏覽器預覽';

  @override
  String get mermaidPreviewOpenFailed => '無法打開預覽';

  @override
  String get assistantProviderDefaultAssistantName => '預設助理';

  @override
  String get assistantProviderSampleAssistantName => '範例助理';

  @override
  String get assistantProviderNewAssistantName => '新助理';

  @override
  String assistantProviderSampleAssistantSystemPrompt(
    String model_name,
    String cur_datetime,
    String locale,
    String timezone,
    String device_info,
    String system_version,
  ) {
    return '你是$model_name, 一個人工智慧助理，樂意為使用者提供準確，有益的幫助。現在時間是$cur_datetime，使用者裝置語言為$locale，時區為$timezone，使用者正在使用$device_info，版本$system_version。如果使用者沒有明確說明，請使用使用者裝置語言進行回覆。';
  }

  @override
  String get displaySettingsPageLanguageTitle => '應用程式語言';

  @override
  String get displaySettingsPageLanguageSubtitle => '選擇介面語言';

  @override
  String get displaySettingsPageLanguageChineseLabel => '简体中文';

  @override
  String get displaySettingsPageLanguageEnglishLabel => 'English';

  @override
  String get homePagePleaseSelectModel => '請先選擇模型';

  @override
  String get homePagePleaseSetupTranslateModel => '請先設定翻譯模型';

  @override
  String get homePageTranslating => '翻譯中...';

  @override
  String homePageTranslateFailed(String error) {
    return '翻譯失敗: $error';
  }

  @override
  String get chatServiceDefaultConversationTitle => '新對話';

  @override
  String get userProviderDefaultUserName => '使用者';

  @override
  String get homePageDeleteMessage => '刪除訊息';

  @override
  String get homePageDeleteMessageConfirm => '確定要刪除這條訊息嗎？此操作不可撤銷。';

  @override
  String get homePageCancel => '取消';

  @override
  String get homePageDelete => '刪除';

  @override
  String get homePageSelectMessagesToShare => '請選擇要分享的訊息';

  @override
  String get homePageDone => '完成';

  @override
  String get assistantEditPageTitle => '助理';

  @override
  String get assistantEditPageNotFound => '助理不存在';

  @override
  String get assistantEditPageBasicTab => '基礎設定';

  @override
  String get assistantEditPagePromptsTab => '提示詞';

  @override
  String get assistantEditPageMcpTab => 'MCP';

  @override
  String get assistantEditPageCustomTab => '自訂請求';

  @override
  String get assistantEditCustomHeadersTitle => '自訂 Header';

  @override
  String get assistantEditCustomHeadersAdd => '新增 Header';

  @override
  String get assistantEditCustomHeadersEmpty => '未新增 Header';

  @override
  String get assistantEditCustomBodyTitle => '自訂 Body';

  @override
  String get assistantEditCustomBodyAdd => '新增 Body';

  @override
  String get assistantEditCustomBodyEmpty => '未新增 Body 項';

  @override
  String get assistantEditHeaderNameLabel => 'Header 名稱';

  @override
  String get assistantEditHeaderValueLabel => 'Header 值';

  @override
  String get assistantEditBodyKeyLabel => 'Body Key';

  @override
  String get assistantEditBodyValueLabel => 'Body 值 (JSON)';

  @override
  String get assistantEditDeleteTooltip => '刪除';

  @override
  String get assistantEditAssistantNameLabel => '助理名稱';

  @override
  String get assistantEditUseAssistantAvatarTitle => '使用助理頭像';

  @override
  String get assistantEditUseAssistantAvatarSubtitle =>
      '在聊天中使用助理頭像和名字而不是模型頭像和名字';

  @override
  String get assistantEditChatModelTitle => '聊天模型';

  @override
  String get assistantEditChatModelSubtitle => '為該助理設定預設聊天模型（未設定時使用全域預設）';

  @override
  String get assistantEditTemperatureDescription => '控制輸出的隨機性，範圍 0–2';

  @override
  String get assistantEditTopPDescription => '請不要修改此值，除非你知道自己在做什麼';

  @override
  String get assistantEditParameterDisabled => '已關閉（使用服務商預設）';

  @override
  String get assistantEditParameterDisabled2 => '已關閉（無限制）';

  @override
  String get assistantEditContextMessagesTitle => '上下文訊息數量';

  @override
  String get assistantEditContextMessagesDescription =>
      '多少歷史訊息會被當作上下文傳送給模型，超過數量會忽略，只保留最近 N 條';

  @override
  String get assistantEditStreamOutputTitle => '串流輸出';

  @override
  String get assistantEditStreamOutputDescription => '是否啟用訊息的串流輸出';

  @override
  String get assistantEditThinkingBudgetTitle => '思考預算';

  @override
  String get assistantEditConfigureButton => '設定';

  @override
  String get assistantEditMaxTokensTitle => '最大 Token 數';

  @override
  String get assistantEditMaxTokensDescription => '留空表示無限制';

  @override
  String get assistantEditMaxTokensHint => '無限制';

  @override
  String get assistantEditChatBackgroundTitle => '聊天背景';

  @override
  String get assistantEditChatBackgroundDescription => '設定助理聊天頁面的背景圖片';

  @override
  String get assistantEditChooseImageButton => '選擇背景圖片';

  @override
  String get assistantEditClearButton => '清除';

  @override
  String get assistantEditAvatarChooseImage => '選擇圖片';

  @override
  String get assistantEditAvatarChooseEmoji => '選擇表情';

  @override
  String get assistantEditAvatarEnterLink => '輸入連結';

  @override
  String get assistantEditAvatarImportQQ => 'QQ頭像';

  @override
  String get assistantEditAvatarReset => '重設';

  @override
  String get assistantEditEmojiDialogTitle => '選擇表情';

  @override
  String get assistantEditEmojiDialogHint => '輸入或貼上任意表情';

  @override
  String get assistantEditEmojiDialogCancel => '取消';

  @override
  String get assistantEditEmojiDialogSave => '儲存';

  @override
  String get assistantEditImageUrlDialogTitle => '輸入圖片連結';

  @override
  String get assistantEditImageUrlDialogHint =>
      '例如: https://example.com/avatar.png';

  @override
  String get assistantEditImageUrlDialogCancel => '取消';

  @override
  String get assistantEditImageUrlDialogSave => '儲存';

  @override
  String get assistantEditQQAvatarDialogTitle => '使用QQ頭像';

  @override
  String get assistantEditQQAvatarDialogHint => '輸入QQ號碼（5-12位）';

  @override
  String get assistantEditQQAvatarRandomButton => '隨機QQ';

  @override
  String get assistantEditQQAvatarFailedMessage => '取得隨機QQ頭像失敗，請重試';

  @override
  String get assistantEditQQAvatarDialogCancel => '取消';

  @override
  String get assistantEditQQAvatarDialogSave => '儲存';

  @override
  String get assistantEditGalleryErrorMessage => '無法開啟相簿，試試輸入圖片連結';

  @override
  String get assistantEditGeneralErrorMessage => '發生錯誤，試試輸入圖片連結';

  @override
  String get assistantEditSystemPromptTitle => '系統提示詞';

  @override
  String get assistantEditSystemPromptHint => '輸入系統提示詞…';

  @override
  String get assistantEditAvailableVariables => '可用變數：';

  @override
  String get assistantEditVariableDate => '日期';

  @override
  String get assistantEditVariableTime => '時間';

  @override
  String get assistantEditVariableDatetime => '日期和時間';

  @override
  String get assistantEditVariableModelId => '模型ID';

  @override
  String get assistantEditVariableModelName => '模型名稱';

  @override
  String get assistantEditVariableLocale => '語言環境';

  @override
  String get assistantEditVariableTimezone => '時區';

  @override
  String get assistantEditVariableSystemVersion => '系統版本';

  @override
  String get assistantEditVariableDeviceInfo => '裝置資訊';

  @override
  String get assistantEditVariableBatteryLevel => '電池電量';

  @override
  String get assistantEditVariableNickname => '使用者暱稱';

  @override
  String get assistantEditMessageTemplateTitle => '聊天內容範本';

  @override
  String get assistantEditVariableRole => '角色';

  @override
  String get assistantEditVariableMessage => '內容';

  @override
  String get assistantEditPreviewTitle => '預覽';

  @override
  String get assistantEditSampleUser => '使用者';

  @override
  String get assistantEditSampleMessage => '你好啊';

  @override
  String get assistantEditSampleReply => '你好，有什麼我可以幫你的嗎？';

  @override
  String get assistantEditMcpNoServersMessage => '暫無已啟動的 MCP 伺服器';

  @override
  String get assistantEditMcpConnectedTag => '已連線';

  @override
  String assistantEditMcpToolsCountTag(String enabled, String total) {
    return '工具: $enabled/$total';
  }

  @override
  String get assistantEditModelUseGlobalDefault => '使用全域預設';

  @override
  String get assistantSettingsPageTitle => '助理設定';

  @override
  String get assistantSettingsDefaultTag => '預設';

  @override
  String get assistantSettingsDeleteButton => '刪除';

  @override
  String get assistantSettingsEditButton => '編輯';

  @override
  String get assistantSettingsAddSheetTitle => '助理名稱';

  @override
  String get assistantSettingsAddSheetHint => '輸入助理名稱';

  @override
  String get assistantSettingsAddSheetCancel => '取消';

  @override
  String get assistantSettingsAddSheetSave => '儲存';

  @override
  String get assistantSettingsDeleteDialogTitle => '刪除助理';

  @override
  String get assistantSettingsDeleteDialogContent => '確定要刪除該助理嗎？此操作不可撤銷。';

  @override
  String get assistantSettingsDeleteDialogCancel => '取消';

  @override
  String get assistantSettingsDeleteDialogConfirm => '刪除';

  @override
  String get mcpAssistantSheetTitle => 'MCP伺服器';

  @override
  String get mcpAssistantSheetSubtitle => '為該助理啟用的服務';

  @override
  String get mcpAssistantSheetSelectAll => '全選';

  @override
  String get mcpAssistantSheetClearAll => '全不選';

  @override
  String get backupPageTitle => '備份與還原';

  @override
  String get backupPageWebDavTab => 'WebDAV 備份';

  @override
  String get backupPageImportExportTab => '匯入和匯出';

  @override
  String get backupPageWebDavServerUrl => 'WebDAV 伺服器地址';

  @override
  String get backupPageUsername => '使用者名稱';

  @override
  String get backupPagePassword => '密碼';

  @override
  String get backupPagePath => '路徑';

  @override
  String get backupPageChatsLabel => '聊天記錄';

  @override
  String get backupPageFilesLabel => '檔案';

  @override
  String get backupPageTestDone => '測試完成';

  @override
  String get backupPageTestConnection => '測試連線';

  @override
  String get backupPageRestartRequired => '需要重啟應用程式';

  @override
  String get backupPageRestartContent => '還原完成，需要重啟以完全生效。';

  @override
  String get backupPageOK => '好的';

  @override
  String get backupPageCancel => '取消';

  @override
  String get backupPageSelectImportMode => '選擇匯入模式';

  @override
  String get backupPageSelectImportModeDescription => '請選擇如何匯入備份資料：';

  @override
  String get backupPageOverwriteMode => '完全覆蓋';

  @override
  String get backupPageOverwriteModeDescription => '清空本地所有資料後恢復';

  @override
  String get backupPageMergeMode => '智能合併';

  @override
  String get backupPageMergeModeDescription => '僅添加不存在的資料（智能去重）';

  @override
  String get backupPageRestore => '還原';

  @override
  String get backupPageBackupUploaded => '已上傳備份';

  @override
  String get backupPageBackup => '立即備份';

  @override
  String get backupPageExporting => '正在匯出...';

  @override
  String get backupPageExportToFile => '匯出為檔案';

  @override
  String get backupPageExportToFileSubtitle => '匯出APP資料為檔案';

  @override
  String get backupPageImportBackupFile => '備份檔案匯入';

  @override
  String get backupPageImportBackupFileSubtitle => '匯入本機備份檔案';

  @override
  String get backupPageImportFromOtherApps => '從其他APP匯入';

  @override
  String get backupPageImportFromRikkaHub => '從 RikkaHub 匯入';

  @override
  String get backupPageNotSupportedYet => '暫不支援';

  @override
  String get backupPageRemoteBackups => '遠端備份';

  @override
  String get backupPageNoBackups => '暫無備份';

  @override
  String get backupPageRestoreTooltip => '還原';

  @override
  String get backupPageDeleteTooltip => '刪除';

  @override
  String get chatHistoryPageTitle => '聊天歷史';

  @override
  String get chatHistoryPageSearchTooltip => '搜尋';

  @override
  String get chatHistoryPageDeleteAllTooltip => '刪除全部';

  @override
  String get chatHistoryPageDeleteAllDialogTitle => '刪除全部對話';

  @override
  String get chatHistoryPageDeleteAllDialogContent => '確定要刪除全部對話嗎？此操作不可撤銷。';

  @override
  String get chatHistoryPageCancel => '取消';

  @override
  String get chatHistoryPageDelete => '刪除';

  @override
  String get chatHistoryPageDeletedAllSnackbar => '已刪除全部對話';

  @override
  String get chatHistoryPageSearchHint => '搜尋對話';

  @override
  String get chatHistoryPageNoConversations => '暫無對話';

  @override
  String get chatHistoryPagePinnedSection => '置頂';

  @override
  String get chatHistoryPagePin => '置頂';

  @override
  String get chatHistoryPagePinned => '已置頂';

  @override
  String get messageEditPageTitle => '編輯訊息';

  @override
  String get messageEditPageSave => '儲存';

  @override
  String get messageEditPageHint => '輸入訊息內容…';

  @override
  String get selectCopyPageTitle => '選擇複製';

  @override
  String get selectCopyPageCopyAll => '複製全部';

  @override
  String get selectCopyPageCopiedAll => '已複製全部';

  @override
  String get bottomToolsSheetCamera => '拍照';

  @override
  String get bottomToolsSheetPhotos => '照片';

  @override
  String get bottomToolsSheetUpload => '上傳檔案';

  @override
  String get bottomToolsSheetClearContext => '清空上下文';

  @override
  String get bottomToolsSheetLearningMode => '學習模式';

  @override
  String get bottomToolsSheetLearningModeDescription => '幫助你循序漸進地學習知識';

  @override
  String get bottomToolsSheetConfigurePrompt => '設定提示詞';

  @override
  String get bottomToolsSheetPrompt => '提示詞';

  @override
  String get bottomToolsSheetPromptHint => '輸入用於學習模式的提示詞';

  @override
  String get bottomToolsSheetResetDefault => '重設為預設';

  @override
  String get bottomToolsSheetSave => '儲存';

  @override
  String get messageMoreSheetTitle => '更多操作';

  @override
  String get messageMoreSheetSelectCopy => '選擇複製';

  @override
  String get messageMoreSheetRenderWebView => '網頁視圖渲染';

  @override
  String get messageMoreSheetNotImplemented => '暫未實現';

  @override
  String get messageMoreSheetEdit => '編輯';

  @override
  String get messageMoreSheetShare => '分享';

  @override
  String get messageMoreSheetCreateBranch => '建立分支';

  @override
  String get messageMoreSheetDelete => '刪除';

  @override
  String get reasoningBudgetSheetOff => '關閉';

  @override
  String get reasoningBudgetSheetAuto => '自動';

  @override
  String get reasoningBudgetSheetLight => '輕度推理';

  @override
  String get reasoningBudgetSheetMedium => '中度推理';

  @override
  String get reasoningBudgetSheetHeavy => '重度推理';

  @override
  String get reasoningBudgetSheetTitle => '思維鏈強度';

  @override
  String reasoningBudgetSheetCurrentLevel(String level) {
    return '目前檔位：$level';
  }

  @override
  String get reasoningBudgetSheetOffSubtitle => '關閉推理功能，直接回答';

  @override
  String get reasoningBudgetSheetAutoSubtitle => '由模型自動決定推理級別';

  @override
  String get reasoningBudgetSheetLightSubtitle => '使用少量推理來回答問題';

  @override
  String get reasoningBudgetSheetMediumSubtitle => '使用較多推理來回答問題';

  @override
  String get reasoningBudgetSheetHeavySubtitle => '使用大量推理來回答問題，適合複雜問題';

  @override
  String get reasoningBudgetSheetCustomLabel => '自訂推理預算 (tokens)';

  @override
  String get reasoningBudgetSheetCustomHint => '例如：2048 (-1 自動，0 關閉)';

  @override
  String chatMessageWidgetFileNotFound(String fileName) {
    return '檔案不存在: $fileName';
  }

  @override
  String chatMessageWidgetCannotOpenFile(String message) {
    return '無法開啟檔案: $message';
  }

  @override
  String chatMessageWidgetOpenFileError(String error) {
    return '開啟檔案失敗: $error';
  }

  @override
  String get chatMessageWidgetCopiedToClipboard => '已複製到剪貼簿';

  @override
  String get chatMessageWidgetResendTooltip => '重新傳送';

  @override
  String get chatMessageWidgetMoreTooltip => '更多';

  @override
  String get chatMessageWidgetThinking => '正在思考...';

  @override
  String get chatMessageWidgetTranslation => '翻譯';

  @override
  String get chatMessageWidgetTranslating => '翻譯中...';

  @override
  String get chatMessageWidgetCitationNotFound => '未找到引用來源';

  @override
  String chatMessageWidgetCannotOpenUrl(String url) {
    return '無法開啟連結: $url';
  }

  @override
  String get chatMessageWidgetOpenLinkError => '開啟連結失敗';

  @override
  String chatMessageWidgetCitationsTitle(int count) {
    return '引用（共$count條）';
  }

  @override
  String get chatMessageWidgetRegenerateTooltip => '重新生成';

  @override
  String get chatMessageWidgetStopTooltip => '停止';

  @override
  String get chatMessageWidgetSpeakTooltip => '朗讀';

  @override
  String get chatMessageWidgetTranslateTooltip => '翻譯';

  @override
  String get chatMessageWidgetBuiltinSearchHideNote => '隱藏內建搜尋工具卡片';

  @override
  String get chatMessageWidgetDeepThinking => '深度思考';

  @override
  String get chatMessageWidgetCreateMemory => '建立記憶';

  @override
  String get chatMessageWidgetEditMemory => '編輯記憶';

  @override
  String get chatMessageWidgetDeleteMemory => '刪除記憶';

  @override
  String chatMessageWidgetWebSearch(String query) {
    return '聯網檢索: $query';
  }

  @override
  String get chatMessageWidgetBuiltinSearch => '模型內建搜尋';

  @override
  String chatMessageWidgetToolCall(String name) {
    return '呼叫工具: $name';
  }

  @override
  String chatMessageWidgetToolResult(String name) {
    return '呼叫工具: $name';
  }

  @override
  String get chatMessageWidgetNoResultYet => '（暫無結果）';

  @override
  String get chatMessageWidgetArguments => '參數';

  @override
  String get chatMessageWidgetResult => '結果';

  @override
  String chatMessageWidgetCitationsCount(int count) {
    return '共$count條引用';
  }

  @override
  String get messageExportSheetAssistant => '助理';

  @override
  String get messageExportSheetDefaultTitle => '新對話';

  @override
  String get messageExportSheetExporting => '正在匯出…';

  @override
  String messageExportSheetExportFailed(String error) {
    return '匯出失敗: $error';
  }

  @override
  String messageExportSheetExportedAs(String filename) {
    return '已匯出為 $filename';
  }

  @override
  String get messageExportSheetFormatTitle => '匯出格式';

  @override
  String get messageExportSheetMarkdown => 'Markdown';

  @override
  String get messageExportSheetSingleMarkdownSubtitle => '將該訊息匯出為 Markdown 檔案';

  @override
  String get messageExportSheetBatchMarkdownSubtitle => '將選中的訊息匯出為 Markdown 檔案';

  @override
  String get messageExportSheetExportImage => '匯出為圖片';

  @override
  String get messageExportSheetSingleExportImageSubtitle => '將該訊息渲染為 PNG 圖片';

  @override
  String get messageExportSheetBatchExportImageSubtitle => '將選中的訊息渲染為 PNG 圖片';

  @override
  String get messageExportSheetDateTimeWithSecondsPattern =>
      'yyyy年M月d日 HH:mm:ss';

  @override
  String get sideDrawerMenuRename => '重新命名';

  @override
  String get sideDrawerMenuPin => '置頂';

  @override
  String get sideDrawerMenuUnpin => '取消置頂';

  @override
  String get sideDrawerMenuRegenerateTitle => '重新生成標題';

  @override
  String get sideDrawerMenuDelete => '刪除';

  @override
  String sideDrawerDeleteSnackbar(String title) {
    return '已刪除「$title」';
  }

  @override
  String get sideDrawerRenameHint => '輸入新名稱';

  @override
  String get sideDrawerCancel => '取消';

  @override
  String get sideDrawerOK => '確定';

  @override
  String get sideDrawerSave => '儲存';

  @override
  String get sideDrawerGreetingMorning => '早安 👋';

  @override
  String get sideDrawerGreetingNoon => '午安 👋';

  @override
  String get sideDrawerGreetingAfternoon => '午安 👋';

  @override
  String get sideDrawerGreetingEvening => '晚安 👋';

  @override
  String get sideDrawerDateToday => '今天';

  @override
  String get sideDrawerDateYesterday => '昨天';

  @override
  String get sideDrawerDateShortPattern => 'M月d日';

  @override
  String get sideDrawerDateFullPattern => 'yyyy年M月d日';

  @override
  String get sideDrawerSearchHint => '搜尋聊天記錄';

  @override
  String sideDrawerUpdateTitle(String version) {
    return '發現新版本：$version';
  }

  @override
  String sideDrawerUpdateTitleWithBuild(String version, int build) {
    return '發現新版本：$version ($build)';
  }

  @override
  String get sideDrawerLinkCopied => '已複製下載連結';

  @override
  String get sideDrawerPinnedLabel => '置頂';

  @override
  String get sideDrawerHistory => '聊天歷史';

  @override
  String get sideDrawerSettings => '設定';

  @override
  String get sideDrawerChooseAssistantTitle => '選擇助理';

  @override
  String get sideDrawerChooseImage => '選擇圖片';

  @override
  String get sideDrawerChooseEmoji => '選擇表情';

  @override
  String get sideDrawerEnterLink => '輸入連結';

  @override
  String get sideDrawerImportFromQQ => 'QQ頭像';

  @override
  String get sideDrawerReset => '重設';

  @override
  String get sideDrawerEmojiDialogTitle => '選擇表情';

  @override
  String get sideDrawerEmojiDialogHint => '輸入或貼上任意表情';

  @override
  String get sideDrawerImageUrlDialogTitle => '輸入圖片連結';

  @override
  String get sideDrawerImageUrlDialogHint =>
      '例如: https://example.com/avatar.png';

  @override
  String get sideDrawerQQAvatarDialogTitle => '使用QQ頭像';

  @override
  String get sideDrawerQQAvatarInputHint => '輸入QQ號碼（5-12位）';

  @override
  String get sideDrawerQQAvatarFetchFailed => '取得隨機QQ頭像失敗，請重試';

  @override
  String get sideDrawerRandomQQ => '隨機QQ';

  @override
  String get sideDrawerGalleryOpenError => '無法開啟相簿，試試輸入圖片連結';

  @override
  String get sideDrawerGeneralImageError => '發生錯誤，試試輸入圖片連結';

  @override
  String get sideDrawerSetNicknameTitle => '設定暱稱';

  @override
  String get sideDrawerNicknameLabel => '暱稱';

  @override
  String get sideDrawerNicknameHint => '輸入新的暱稱';

  @override
  String get sideDrawerRename => '重新命名';

  @override
  String get chatInputBarHint => '輸入訊息與AI聊天';

  @override
  String get chatInputBarSelectModelTooltip => '選擇模型';

  @override
  String get chatInputBarOnlineSearchTooltip => '聯網搜尋';

  @override
  String get chatInputBarReasoningStrengthTooltip => '思維鏈強度';

  @override
  String get chatInputBarMcpServersTooltip => 'MCP伺服器';

  @override
  String get chatInputBarMoreTooltip => '更多';

  @override
  String get mcpPageBackTooltip => '返回';

  @override
  String get mcpPageAddMcpTooltip => '新增 MCP';

  @override
  String get mcpPageNoServers => '暫無 MCP 伺服器';

  @override
  String get mcpPageErrorDialogTitle => '連線錯誤';

  @override
  String get mcpPageErrorNoDetails => '未提供錯誤詳情';

  @override
  String get mcpPageClose => '關閉';

  @override
  String get mcpPageReconnect => '重新連線';

  @override
  String get mcpPageStatusConnected => '已連線';

  @override
  String get mcpPageStatusConnecting => '連線中…';

  @override
  String get mcpPageStatusDisconnected => '未連線';

  @override
  String get mcpPageStatusDisabled => '已停用';

  @override
  String mcpPageToolsCount(int enabled, int total) {
    return '工具: $enabled/$total';
  }

  @override
  String get mcpPageConnectionFailed => '連線失敗';

  @override
  String get mcpPageDetails => '詳情';

  @override
  String get mcpPageDelete => '刪除';

  @override
  String get mcpPageConfirmDeleteTitle => '確認刪除';

  @override
  String get mcpPageConfirmDeleteContent => '刪除後可透過撤銷還原。是否刪除？';

  @override
  String get mcpPageServerDeleted => '已刪除伺服器';

  @override
  String get mcpPageUndo => '撤銷';

  @override
  String get mcpPageCancel => '取消';

  @override
  String get mcpConversationSheetTitle => 'MCP伺服器';

  @override
  String get mcpConversationSheetSubtitle => '選擇在此助理中啟用的服務';

  @override
  String get mcpConversationSheetSelectAll => '全選';

  @override
  String get mcpConversationSheetClearAll => '全不選';

  @override
  String get mcpConversationSheetNoRunning => '暫無已啟動的 MCP 伺服器';

  @override
  String get mcpConversationSheetConnected => '已連線';

  @override
  String mcpConversationSheetToolsCount(int enabled, int total) {
    return '工具: $enabled/$total';
  }

  @override
  String get mcpServerEditSheetEnabledLabel => '是否啟用';

  @override
  String get mcpServerEditSheetNameLabel => '名稱';

  @override
  String get mcpServerEditSheetTransportLabel => '傳輸類型';

  @override
  String get mcpServerEditSheetSseRetryHint => '如果SSE連線失敗，請多試幾次';

  @override
  String get mcpServerEditSheetUrlLabel => '伺服器地址';

  @override
  String get mcpServerEditSheetCustomHeadersTitle => '自訂請求標頭';

  @override
  String get mcpServerEditSheetHeaderNameLabel => '請求標頭名稱';

  @override
  String get mcpServerEditSheetHeaderNameHint => '如 Authorization';

  @override
  String get mcpServerEditSheetHeaderValueLabel => '請求標頭值';

  @override
  String get mcpServerEditSheetHeaderValueHint => '如 Bearer xxxxxx';

  @override
  String get mcpServerEditSheetRemoveHeaderTooltip => '刪除';

  @override
  String get mcpServerEditSheetAddHeader => '新增請求標頭';

  @override
  String get mcpServerEditSheetTitleEdit => '編輯 MCP';

  @override
  String get mcpServerEditSheetTitleAdd => '新增 MCP';

  @override
  String get mcpServerEditSheetSyncToolsTooltip => '同步工具';

  @override
  String get mcpServerEditSheetTabBasic => '基礎設定';

  @override
  String get mcpServerEditSheetTabTools => '工具';

  @override
  String get mcpServerEditSheetNoToolsHint => '暫無工具，點擊上方同步';

  @override
  String get mcpServerEditSheetCancel => '取消';

  @override
  String get mcpServerEditSheetSave => '儲存';

  @override
  String get mcpServerEditSheetUrlRequired => '請輸入伺服器地址';

  @override
  String get defaultModelPageBackTooltip => '返回';

  @override
  String get defaultModelPageTitle => '預設模型';

  @override
  String get defaultModelPageChatModelTitle => '聊天模型';

  @override
  String get defaultModelPageChatModelSubtitle => '全域預設的聊天模型';

  @override
  String get defaultModelPageTitleModelTitle => '標題總結模型';

  @override
  String get defaultModelPageTitleModelSubtitle => '用於總結對話標題的模型，推薦使用快速且便宜的模型';

  @override
  String get defaultModelPageTranslateModelTitle => '翻譯模型';

  @override
  String get defaultModelPageTranslateModelSubtitle =>
      '用於翻譯訊息內容的模型，推薦使用快速且準確的模型';

  @override
  String get defaultModelPagePromptLabel => '提示詞';

  @override
  String get defaultModelPageTitlePromptHint => '輸入用於標題總結的提示詞範本';

  @override
  String get defaultModelPageTranslatePromptHint => '輸入用於翻譯的提示詞範本';

  @override
  String get defaultModelPageResetDefault => '重設為預設';

  @override
  String get defaultModelPageSave => '儲存';

  @override
  String defaultModelPageTitleVars(String contentVar, String localeVar) {
    return '變數: 對話內容: $contentVar, 語言: $localeVar';
  }

  @override
  String defaultModelPageTranslateVars(String sourceVar, String targetVar) {
    return '變數：原始文本：$sourceVar，目標語言：$targetVar';
  }

  @override
  String get modelDetailSheetAddModel => '新增模型';

  @override
  String get modelDetailSheetEditModel => '編輯模型';

  @override
  String get modelDetailSheetBasicTab => '基本設定';

  @override
  String get modelDetailSheetAdvancedTab => '進階設定';

  @override
  String get modelDetailSheetModelIdLabel => '模型 ID';

  @override
  String get modelDetailSheetModelIdHint => '必填，建議小寫字母、數字、連字號';

  @override
  String modelDetailSheetModelIdDisabledHint(String modelId) {
    return '$modelId';
  }

  @override
  String get modelDetailSheetModelNameLabel => '模型名稱';

  @override
  String get modelDetailSheetModelTypeLabel => '模型類型';

  @override
  String get modelDetailSheetChatType => '聊天';

  @override
  String get modelDetailSheetEmbeddingType => '嵌入';

  @override
  String get modelDetailSheetInputModesLabel => '輸入模式';

  @override
  String get modelDetailSheetOutputModesLabel => '輸出模式';

  @override
  String get modelDetailSheetAbilitiesLabel => '能力';

  @override
  String get modelDetailSheetTextMode => '文字';

  @override
  String get modelDetailSheetImageMode => '圖片';

  @override
  String get modelDetailSheetToolsAbility => '工具';

  @override
  String get modelDetailSheetReasoningAbility => '推理';

  @override
  String get modelDetailSheetProviderOverrideDescription =>
      '供應商覆寫：允許為特定模型自訂供應商設定。（暫未實現）';

  @override
  String get modelDetailSheetAddProviderOverride => '新增供應商覆寫';

  @override
  String get modelDetailSheetCustomHeadersTitle => '自訂 Headers';

  @override
  String get modelDetailSheetAddHeader => '新增 Header';

  @override
  String get modelDetailSheetCustomBodyTitle => '自訂 Body';

  @override
  String get modelDetailSheetAddBody => '新增 Body';

  @override
  String get modelDetailSheetBuiltinToolsDescription =>
      '內建工具僅支援部分 API（例如 Gemini 官方 API）（暫未實現）。';

  @override
  String get modelDetailSheetSearchTool => '搜尋';

  @override
  String get modelDetailSheetSearchToolDescription => '啟用 Google 搜尋整合';

  @override
  String get modelDetailSheetUrlContextTool => 'URL 上下文';

  @override
  String get modelDetailSheetUrlContextToolDescription => '啟用 URL 內容處理';

  @override
  String get modelDetailSheetCancelButton => '取消';

  @override
  String get modelDetailSheetAddButton => '新增';

  @override
  String get modelDetailSheetConfirmButton => '確認';

  @override
  String get modelDetailSheetInvalidIdError => '請輸入有效的模型 ID（不少於2個字元且不含空格）';

  @override
  String get modelDetailSheetModelIdExistsError => '模型 ID 已存在';

  @override
  String get modelDetailSheetHeaderKeyHint => 'Header Key';

  @override
  String get modelDetailSheetHeaderValueHint => 'Header Value';

  @override
  String get modelDetailSheetBodyKeyHint => 'Body Key';

  @override
  String get modelDetailSheetBodyJsonHint => 'Body JSON';

  @override
  String get modelSelectSheetSearchHint => '搜尋模型或供應商';

  @override
  String get modelSelectSheetFavoritesSection => '收藏';

  @override
  String get modelSelectSheetFavoriteTooltip => '收藏';

  @override
  String get modelSelectSheetChatType => '聊天';

  @override
  String get modelSelectSheetEmbeddingType => '嵌入';

  @override
  String get providerDetailPageShareTooltip => '分享';

  @override
  String get providerDetailPageDeleteProviderTooltip => '刪除供應商';

  @override
  String get providerDetailPageDeleteProviderTitle => '刪除供應商';

  @override
  String get providerDetailPageDeleteProviderContent => '確定要刪除該供應商嗎？此操作不可撤銷。';

  @override
  String get providerDetailPageCancelButton => '取消';

  @override
  String get providerDetailPageDeleteButton => '刪除';

  @override
  String get providerDetailPageProviderDeletedSnackbar => '已刪除供應商';

  @override
  String get providerDetailPageConfigTab => '設定';

  @override
  String get providerDetailPageModelsTab => '模型';

  @override
  String get providerDetailPageNetworkTab => '網路代理';

  @override
  String get providerDetailPageEnabledTitle => '是否啟用';

  @override
  String get providerDetailPageNameLabel => '名稱';

  @override
  String get providerDetailPageApiKeyHint => '留空則使用上層預設';

  @override
  String get providerDetailPageHideTooltip => '隱藏';

  @override
  String get providerDetailPageShowTooltip => '顯示';

  @override
  String get providerDetailPageApiPathLabel => 'API 路徑';

  @override
  String get providerDetailPageResponseApiTitle => 'Response API (/responses)';

  @override
  String get providerDetailPageVertexAiTitle => 'Vertex AI';

  @override
  String get providerDetailPageLocationLabel => '區域 Location';

  @override
  String get providerDetailPageProjectIdLabel => '專案 ID';

  @override
  String get providerDetailPageServiceAccountJsonLabel => '服務帳號 JSON（貼上或匯入）';

  @override
  String get providerDetailPageImportJsonButton => '匯入 JSON';

  @override
  String get providerDetailPageTestButton => '測試';

  @override
  String get providerDetailPageSaveButton => '儲存';

  @override
  String get providerDetailPageProviderRemovedMessage => '供應商已刪除';

  @override
  String get providerDetailPageNoModelsTitle => '暫無模型';

  @override
  String get providerDetailPageNoModelsSubtitle => '點擊下方按鈕新增模型';

  @override
  String get providerDetailPageDeleteModelButton => '刪除';

  @override
  String get providerDetailPageConfirmDeleteTitle => '確認刪除';

  @override
  String get providerDetailPageConfirmDeleteContent => '刪除後可透過撤銷還原。是否刪除？';

  @override
  String get providerDetailPageModelDeletedSnackbar => '已刪除模型';

  @override
  String get providerDetailPageUndoButton => '撤銷';

  @override
  String get providerDetailPageAddNewModelButton => '新增新模型';

  @override
  String get providerDetailPageEnableProxyTitle => '是否啟用代理';

  @override
  String get providerDetailPageHostLabel => '主機地址';

  @override
  String get providerDetailPagePortLabel => '連接埠';

  @override
  String get providerDetailPageUsernameOptionalLabel => '使用者名稱（可選）';

  @override
  String get providerDetailPagePasswordOptionalLabel => '密碼（可選）';

  @override
  String get providerDetailPageSavedSnackbar => '已儲存';

  @override
  String get providerDetailPageEmbeddingsGroupTitle => '嵌入';

  @override
  String get providerDetailPageOtherModelsGroupTitle => '其他模型';

  @override
  String get providerDetailPageRemoveGroupTooltip => '移除本組';

  @override
  String get providerDetailPageAddGroupTooltip => '新增本組';

  @override
  String get providerDetailPageFilterHint => '輸入模型名稱篩選';

  @override
  String get providerDetailPageDeleteText => '刪除';

  @override
  String get providerDetailPageEditTooltip => '編輯';

  @override
  String get providerDetailPageTestConnectionTitle => '測試連線';

  @override
  String get providerDetailPageSelectModelButton => '選擇模型';

  @override
  String get providerDetailPageChangeButton => '更換';

  @override
  String get providerDetailPageTestingMessage => '正在測試…';

  @override
  String get providerDetailPageTestSuccessMessage => '測試成功';

  @override
  String get providersPageTitle => '供應商';

  @override
  String get providersPageImportTooltip => '匯入';

  @override
  String get providersPageAddTooltip => '新增';

  @override
  String get providersPageProviderAddedSnackbar => '已新增供應商';

  @override
  String get providersPageSiliconFlowName => '矽基流動';

  @override
  String get providersPageAliyunName => '阿里雲千問';

  @override
  String get providersPageZhipuName => '智譜';

  @override
  String get providersPageByteDanceName => '火山引擎';

  @override
  String get providersPageEnabledStatus => '啟用';

  @override
  String get providersPageDisabledStatus => '停用';

  @override
  String get providersPageModelsCountSuffix => ' models';

  @override
  String get providersPageModelsCountSingleSuffix => '個模型';

  @override
  String get addProviderSheetTitle => '新增供應商';

  @override
  String get addProviderSheetEnabledLabel => '是否啟用';

  @override
  String get addProviderSheetNameLabel => '名稱';

  @override
  String get addProviderSheetApiPathLabel => 'API 路徑';

  @override
  String get addProviderSheetVertexAiLocationLabel => '位置';

  @override
  String get addProviderSheetVertexAiProjectIdLabel => '專案ID';

  @override
  String get addProviderSheetVertexAiServiceAccountJsonLabel =>
      '服務帳號 JSON（貼上或匯入）';

  @override
  String get addProviderSheetImportJsonButton => '匯入 JSON';

  @override
  String get addProviderSheetCancelButton => '取消';

  @override
  String get addProviderSheetAddButton => '新增';

  @override
  String get importProviderSheetTitle => '匯入供應商';

  @override
  String get importProviderSheetScanQrTooltip => '掃碼匯入';

  @override
  String get importProviderSheetFromGalleryTooltip => '從相簿匯入';

  @override
  String importProviderSheetImportSuccessMessage(int count) {
    return '已匯入$count個供應商';
  }

  @override
  String importProviderSheetImportFailedMessage(String error) {
    return '匯入失敗: $error';
  }

  @override
  String get importProviderSheetDescription => '貼上分享字串（可多行，每行一個）或 ChatBox JSON';

  @override
  String get importProviderSheetInputHint => 'ai-provider:v1:...';

  @override
  String get importProviderSheetCancelButton => '取消';

  @override
  String get importProviderSheetImportButton => '匯入';

  @override
  String get shareProviderSheetTitle => '分享供應商設定';

  @override
  String get shareProviderSheetDescription => '複製下面的分享字串，或使用QR Code分享。';

  @override
  String get shareProviderSheetCopiedMessage => '已複製';

  @override
  String get shareProviderSheetCopyButton => '複製';

  @override
  String get shareProviderSheetShareButton => '分享';

  @override
  String get qrScanPageTitle => '掃碼匯入';

  @override
  String get qrScanPageInstruction => '將QR Code對準取景框';

  @override
  String get searchServicesPageBackTooltip => '返回';

  @override
  String get searchServicesPageTitle => '搜尋服務';

  @override
  String get searchServicesPageDone => '完成';

  @override
  String get searchServicesPageEdit => '編輯';

  @override
  String get searchServicesPageAddProvider => '新增提供商';

  @override
  String get searchServicesPageSearchProviders => '搜尋提供商';

  @override
  String get searchServicesPageGeneralOptions => '通用選項';

  @override
  String get searchServicesPageMaxResults => '最大結果數';

  @override
  String get searchServicesPageTimeoutSeconds => '超時時間（秒）';

  @override
  String get searchServicesPageAtLeastOneServiceRequired => '至少需要一個搜尋服務';

  @override
  String get searchServicesPageTestingStatus => '測試中…';

  @override
  String get searchServicesPageConnectedStatus => '已連線';

  @override
  String get searchServicesPageFailedStatus => '連線失敗';

  @override
  String get searchServicesPageNotTestedStatus => '未測試';

  @override
  String get searchServicesPageTestConnectionTooltip => '測試連線';

  @override
  String get searchServicesPageConfiguredStatus => '已設定';

  @override
  String get searchServicesPageApiKeyRequiredStatus => '需要 API Key';

  @override
  String get searchServicesPageUrlRequiredStatus => '需要 URL';

  @override
  String get searchServicesAddDialogTitle => '新增搜尋服務';

  @override
  String get searchServicesAddDialogServiceType => '服務類型';

  @override
  String get searchServicesAddDialogBingLocal => '本機';

  @override
  String get searchServicesAddDialogCancel => '取消';

  @override
  String get searchServicesAddDialogAdd => '新增';

  @override
  String get searchServicesAddDialogApiKeyRequired => 'API Key 必填';

  @override
  String get searchServicesAddDialogInstanceUrl => '實例 URL';

  @override
  String get searchServicesAddDialogUrlRequired => 'URL 必填';

  @override
  String get searchServicesAddDialogEnginesOptional => '搜尋引擎（可選）';

  @override
  String get searchServicesAddDialogLanguageOptional => '語言（可選）';

  @override
  String get searchServicesAddDialogUsernameOptional => '使用者名稱（可選）';

  @override
  String get searchServicesAddDialogPasswordOptional => '密碼（可選）';

  @override
  String get searchServicesEditDialogEdit => '編輯';

  @override
  String get searchServicesEditDialogCancel => '取消';

  @override
  String get searchServicesEditDialogSave => '儲存';

  @override
  String get searchServicesEditDialogBingLocalNoConfig => 'Bing 本機搜尋不需要設定。';

  @override
  String get searchServicesEditDialogApiKeyRequired => 'API Key 必填';

  @override
  String get searchServicesEditDialogInstanceUrl => '實例 URL';

  @override
  String get searchServicesEditDialogUrlRequired => 'URL 必填';

  @override
  String get searchServicesEditDialogEnginesOptional => '搜尋引擎（可選）';

  @override
  String get searchServicesEditDialogLanguageOptional => '語言（可選）';

  @override
  String get searchServicesEditDialogUsernameOptional => '使用者名稱（可選）';

  @override
  String get searchServicesEditDialogPasswordOptional => '密碼（可選）';

  @override
  String get searchSettingsSheetTitle => '搜尋設定';

  @override
  String get searchSettingsSheetBuiltinSearchTitle => '模型內建搜尋';

  @override
  String get searchSettingsSheetBuiltinSearchDescription => '是否啟用模型內建的搜尋功能';

  @override
  String get searchSettingsSheetWebSearchTitle => '網路搜尋';

  @override
  String get searchSettingsSheetWebSearchDescription => '是否啟用網頁搜尋';

  @override
  String get searchSettingsSheetOpenSearchServicesTooltip => '開啟搜尋服務設定';

  @override
  String get searchSettingsSheetNoServicesMessage => '暫無可用服務，請先在\"搜尋服務\"中新增';

  @override
  String get aboutPageEasterEggTitle => '彩蛋已解鎖！';

  @override
  String get aboutPageEasterEggMessage => '\n（好吧現在還沒彩蛋）';

  @override
  String get aboutPageEasterEggButton => '好的';

  @override
  String get aboutPageAppDescription => '開源行動端 AI 助理';

  @override
  String get aboutPageNoQQGroup => '暫無QQ群';

  @override
  String get aboutPageVersion => '版本';

  @override
  String get aboutPageSystem => '系統';

  @override
  String get aboutPageWebsite => '官網';

  @override
  String get aboutPageLicense => '授權';

  @override
  String get displaySettingsPageShowUserAvatarTitle => '顯示使用者頭像';

  @override
  String get displaySettingsPageShowUserAvatarSubtitle => '是否在聊天訊息中顯示使用者頭像';

  @override
  String get displaySettingsPageShowUserNameTimestampTitle => '顯示使用者名稱與時間戳';

  @override
  String get displaySettingsPageShowUserNameTimestampSubtitle =>
      '是否在聊天訊息中顯示使用者名稱以時間戳';

  @override
  String get displaySettingsPageShowModelNameTimestampTitle => '顯示模型名稱與時間戳';

  @override
  String get displaySettingsPageShowModelNameTimestampSubtitle =>
      '是否在聊天訊息中顯示模型名稱及時間戳';

  @override
  String get displaySettingsPageChatModelIconTitle => '聊天列表模型圖示';

  @override
  String get displaySettingsPageChatModelIconSubtitle => '是否在聊天訊息中顯示模型圖示';

  @override
  String get displaySettingsPageShowTokenStatsTitle => '顯示Token和上下文統計';

  @override
  String get displaySettingsPageShowTokenStatsSubtitle => '顯示 token 用量與訊息數量';

  @override
  String get displaySettingsPageAutoCollapseThinkingTitle => '自動折疊思考';

  @override
  String get displaySettingsPageAutoCollapseThinkingSubtitle =>
      '思考完成後自動折疊，保持介面簡潔';

  @override
  String get displaySettingsPageShowUpdatesTitle => '顯示更新';

  @override
  String get displaySettingsPageShowUpdatesSubtitle => '顯示應用程式更新通知';

  @override
  String get displaySettingsPageMessageNavButtonsTitle => '訊息導航按鈕';

  @override
  String get displaySettingsPageMessageNavButtonsSubtitle => '滾動時顯示快速跳轉按鈕';

  @override
  String get displaySettingsPageHapticsOnSidebarTitle => '側邊欄觸覺回饋';

  @override
  String get displaySettingsPageHapticsOnSidebarSubtitle => '開啟/關閉側邊欄時啟用觸覺回饋';

  @override
  String get displaySettingsPageHapticsOnGenerateTitle => '訊息生成觸覺回饋';

  @override
  String get displaySettingsPageHapticsOnGenerateSubtitle => '生成訊息時啟用觸覺回饋';

  @override
  String get displaySettingsPageNewChatOnLaunchTitle => '啟動時新建對話';

  @override
  String get displaySettingsPageNewChatOnLaunchSubtitle => '應用程式啟動時自動建立新對話';

  @override
  String get displaySettingsPageChatFontSizeTitle => '聊天字體大小';

  @override
  String get displaySettingsPageChatFontSampleText => '這是一個範例的聊天文本';

  @override
  String get displaySettingsPageThemeSettingsTitle => '主題設定';

  @override
  String get themeSettingsPageDynamicColorSection => '動態顏色';

  @override
  String get themeSettingsPageUseDynamicColorTitle => '使用動態顏色';

  @override
  String get themeSettingsPageUseDynamicColorSubtitle => '基於系統配色（Android 12+）';

  @override
  String get themeSettingsPageColorPalettesSection => '配色方案';

  @override
  String get ttsServicesPageBackButton => '返回';

  @override
  String get ttsServicesPageTitle => '語音服務';

  @override
  String get ttsServicesPageAddTooltip => '新增';

  @override
  String get ttsServicesPageAddNotImplemented => '新增 TTS 服務暫未實現';

  @override
  String get ttsServicesPageSystemTtsTitle => '系統TTS';

  @override
  String get ttsServicesPageSystemTtsAvailableSubtitle => '使用系統內建語音合成';

  @override
  String ttsServicesPageSystemTtsUnavailableSubtitle(String error) {
    return '不可用：$error';
  }

  @override
  String get ttsServicesPageSystemTtsUnavailableNotInitialized => '未初始化';

  @override
  String get ttsServicesPageTestSpeechText => '你好，這是一次測試語音。';

  @override
  String get ttsServicesPageConfigureTooltip => '設定';

  @override
  String get ttsServicesPageTestVoiceTooltip => '測試語音';

  @override
  String get ttsServicesPageStopTooltip => '停止';

  @override
  String get ttsServicesPageDeleteTooltip => '刪除';

  @override
  String get ttsServicesPageSystemTtsSettingsTitle => '系統 TTS 設定';

  @override
  String get ttsServicesPageEngineLabel => '引擎';

  @override
  String get ttsServicesPageAutoLabel => '自動';

  @override
  String get ttsServicesPageLanguageLabel => '語言';

  @override
  String get ttsServicesPageSpeechRateLabel => '語速';

  @override
  String get ttsServicesPagePitchLabel => '音調';

  @override
  String get ttsServicesPageSettingsSavedMessage => '設定已儲存。';

  @override
  String get ttsServicesPageDoneButton => '完成';

  @override
  String imageViewerPageShareFailedOpenFile(String message) {
    return '無法分享，已嘗試開啟檔案: $message';
  }

  @override
  String imageViewerPageShareFailed(String error) {
    return '分享失敗: $error';
  }

  @override
  String get imageViewerPageShareButton => '分享圖片';

  @override
  String get settingsShare => 'Kelivo - 開源行動端AI助理';

  @override
  String get searchProviderBingLocalDescription =>
      '使用網路抓取工具取得 Bing 搜尋結果。無需 API 金鑰，但可能不夠穩定。';

  @override
  String get searchProviderBraveDescription => 'Brave 獨立搜尋引擎。注重隱私，無追蹤或建立個人檔案。';

  @override
  String get searchProviderExaDescription => '具備語義理解的神經搜尋引擎。適合研究與查找特定內容。';

  @override
  String get searchProviderLinkUpDescription =>
      '提供來源可追溯答案的搜尋 API，同時提供搜尋結果與 AI 摘要。';

  @override
  String get searchProviderMetasoDescription => '秘塔中文搜尋引擎。針對中文內容優化並提供 AI 能力。';

  @override
  String get searchProviderSearXNGDescription => '重視隱私的元搜尋引擎。需自建實例，無追蹤。';

  @override
  String get searchProviderTavilyDescription =>
      '為大型語言模型（LLM）優化的 AI 搜尋 API，提供高品質、相關的搜尋結果。';

  @override
  String get searchProviderZhipuDescription =>
      '智譜 AI 旗下中文 AI 搜尋服務，針對中文內容與查詢進行優化。';

  @override
  String get searchServiceNameBingLocal => 'Bing（本機）';

  @override
  String get searchServiceNameTavily => 'Tavily';

  @override
  String get searchServiceNameExa => 'Exa';

  @override
  String get searchServiceNameZhipu => 'Zhipu（智譜）';

  @override
  String get searchServiceNameSearXNG => 'SearXNG';

  @override
  String get searchServiceNameLinkUp => 'LinkUp';

  @override
  String get searchServiceNameBrave => 'Brave 搜尋';

  @override
  String get searchServiceNameMetaso => 'Metaso（秘塔）';

  @override
  String get generationInterrupted => '生成已中斷';

  @override
  String get titleForLocale => '新對話';
}
