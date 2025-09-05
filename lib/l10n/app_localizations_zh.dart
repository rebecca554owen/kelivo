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
  String get backupPageRestore => '恢复';

  @override
  String get backupPageBackupUploaded => '已上传备份';

  @override
  String get backupPageBackup => '立即备份';

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
  String get modelSelectSheetSearchHint => '输入模型名称搜索';

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
}
