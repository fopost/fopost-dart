import '../json.dart';

/// A connected social account.
class Account {
  /// Creates an account.
  const Account({
    required this.id,
    required this.platform,
    required this.username,
    this.workspaceId,
    this.name,
    this.platformName,
    this.avatar,
    this.isPrimary = false,
    this.active = true,
    this.healthStatus,
    this.lastHealthCheck,
  });

  /// Reads an account.
  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: asString(json['id']) ?? '',
        platform: asString(json['platform']) ?? '',
        username: asString(json['username']) ?? '',
        workspaceId: asString(json['workspaceId'] ?? json['workspace_id']),
        name: asString(json['name']),
        platformName: asString(json['platformName'] ?? json['platform_name']),
        avatar: asString(json['avatar']),
        isPrimary: asBool(json['isPrimary']) ?? false,
        active: asBool(json['active']) ?? true,
        healthStatus: asString(json['healthStatus']),
        lastHealthCheck: asDate(json['lastHealthCheck']),
      );

  /// The account's id.
  final String id;

  /// The account's network.
  final String platform;

  /// The account's handle.
  final String username;

  /// The workspace it belongs to.
  final String? workspaceId;

  /// The display name override when set, else [platformName].
  final String? name;

  /// The name the platform itself reports.
  final String? platformName;

  /// The account's avatar URL.
  final String? avatar;

  /// Whether this account leads its platform in the workspace.
  final bool isPrimary;

  /// Whether the account can be published to.
  final bool active;

  /// One of `AccountHealthStatus`.
  final String? healthStatus;

  /// When the health was last checked.
  final DateTime? lastHealthCheck;

  @override
  String toString() => 'Account($platform/$username)';
}

/// An account with the workspace that owns it.
class AccountDetail {
  /// Creates an account detail.
  const AccountDetail({
    required this.id,
    required this.platform,
    required this.username,
    this.workspaceId,
    this.name,
    this.platformName,
    this.avatar,
    this.workspaceName,
    this.workspaceSlug,
    this.createdAt,
    this.updatedAt,
  });

  /// Reads an account detail.
  factory AccountDetail.fromJson(Map<String, dynamic> json) {
    final workspace = asMap(json['workspace']);
    return AccountDetail(
      id: asString(json['id']) ?? '',
      platform: asString(json['platform']) ?? '',
      username: asString(json['username']) ?? '',
      workspaceId: asString(
          json['workspace_id'] ?? json['workspaceId'] ?? workspace['id']),
      name: asString(json['name']),
      platformName: asString(json['platform_name'] ?? json['platformName']),
      avatar: asString(json['avatar']),
      workspaceName: asString(workspace['name']),
      workspaceSlug: asString(workspace['slug']),
      createdAt: asDate(json['created_at'] ?? json['createdAt']),
      updatedAt: asDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// The account's id.
  final String id;

  /// The account's network.
  final String platform;

  /// The account's handle.
  final String username;

  /// The workspace it belongs to.
  final String? workspaceId;

  /// The display name override when set, else [platformName].
  final String? name;

  /// The name the platform itself reports.
  final String? platformName;

  /// The account's avatar URL.
  final String? avatar;

  /// The owning workspace's name.
  final String? workspaceName;

  /// The owning workspace's slug.
  final String? workspaceSlug;

  /// When the account was connected.
  final DateTime? createdAt;

  /// When it last changed.
  final DateTime? updatedAt;

  @override
  String toString() => 'AccountDetail($platform/$username)';
}

/// An account's names after `AccountsResource.rename`.
class RenamedAccount {
  /// Creates a rename result.
  const RenamedAccount({required this.id, this.name, this.platformName});

  /// Reads a rename result.
  factory RenamedAccount.fromJson(Map<String, dynamic> json) => RenamedAccount(
        id: asString(json['id']) ?? '',
        name: asString(json['name']),
        platformName: asString(json['platform_name'] ?? json['platformName']),
      );

  /// The account's id.
  final String id;

  /// The name FoPost now shows.
  final String? name;

  /// The name the platform itself reports.
  final String? platformName;

  @override
  String toString() => 'RenamedAccount($id, $name)';
}

/// Where an account lives after `AccountsResource.move`.
class MovedAccount {
  /// Creates a move result.
  const MovedAccount({required this.id, this.workspaceId});

  /// Reads a move result.
  factory MovedAccount.fromJson(Map<String, dynamic> json) => MovedAccount(
        id: asString(json['id']) ?? '',
        workspaceId: asString(json['workspace_id'] ?? json['workspaceId']),
      );

  /// The account's id.
  final String id;

  /// The workspace it now belongs to.
  final String? workspaceId;

  @override
  String toString() => 'MovedAccount($id, $workspaceId)';
}

/// One account's connection health.
class AccountHealth {
  /// Creates a health record.
  const AccountHealth({
    required this.id,
    required this.platform,
    required this.healthStatus,
    this.workspaceId,
    this.username,
    this.active = true,
    this.lastHealthCheck,
  });

  /// Reads a health record.
  factory AccountHealth.fromJson(Map<String, dynamic> json) => AccountHealth(
        id: asString(json['id']) ?? '',
        platform: asString(json['platform']) ?? '',
        healthStatus: asString(json['healthStatus']) ?? 'unknown',
        workspaceId: asString(json['workspaceId']),
        username: asString(json['username']),
        active: asBool(json['active']) ?? true,
        lastHealthCheck: asDate(json['lastHealthCheck']),
      );

  /// The account's id.
  final String id;

  /// The account's network.
  final String platform;

  /// One of `AccountHealthStatus`.
  final String healthStatus;

  /// The workspace it belongs to.
  final String? workspaceId;

  /// The account's handle.
  final String? username;

  /// Whether the account can be published to.
  final bool active;

  /// When the health was last checked.
  final DateTime? lastHealthCheck;

  @override
  String toString() => 'AccountHealth($platform, $healthStatus)';
}

/// The health of every account the key can reach.
class AccountHealthSummary {
  /// Creates a health summary.
  const AccountHealthSummary({
    this.accounts = const [],
    this.total = 0,
    this.healthy = 0,
    this.degraded = 0,
    this.expired = 0,
    this.revoked = 0,
    this.unknown = 0,
  });

  /// Reads a health summary.
  factory AccountHealthSummary.fromJson(Map<String, dynamic> json) {
    final summary = asMap(json['summary']);
    return AccountHealthSummary(
      accounts: asModelList(json['accounts'], AccountHealth.fromJson),
      total: asInt(summary['total']) ?? 0,
      healthy: asInt(summary['healthy']) ?? 0,
      degraded: asInt(summary['degraded']) ?? 0,
      expired: asInt(summary['expired']) ?? 0,
      revoked: asInt(summary['revoked']) ?? 0,
      unknown: asInt(summary['unknown']) ?? 0,
    );
  }

  /// One entry per account.
  final List<AccountHealth> accounts;

  /// How many accounts were checked.
  final int total;

  /// How many are healthy.
  final int healthy;

  /// How many are degraded.
  final int degraded;

  /// How many have an expired token.
  final int expired;

  /// How many had access revoked.
  final int revoked;

  /// How many have never been checked.
  final int unknown;

  @override
  String toString() => 'AccountHealthSummary($healthy/$total healthy)';
}

/// Whether an account's stored credentials still work.
class AccountValidation {
  /// Creates a validation result.
  const AccountValidation({
    required this.accountId,
    required this.platform,
    required this.valid,
    this.healthStatus,
  });

  /// Reads a validation result.
  factory AccountValidation.fromJson(Map<String, dynamic> json) =>
      AccountValidation(
        accountId: asString(json['accountId']) ?? '',
        platform: asString(json['platform']) ?? '',
        valid: asBool(json['valid']) ?? false,
        healthStatus: asString(json['healthStatus']),
      );

  /// The account that was checked.
  final String accountId;

  /// The account's network.
  final String platform;

  /// Whether the credentials worked.
  final bool valid;

  /// One of `AccountHealthStatus`.
  final String? healthStatus;

  @override
  String toString() => 'AccountValidation($platform, valid: $valid)';
}

/// An account's primary flag after toggling.
class PrimaryAccount {
  /// Creates a primary-flag result.
  const PrimaryAccount({required this.id, required this.isPrimary});

  /// Reads a primary-flag result.
  factory PrimaryAccount.fromJson(Map<String, dynamic> json) => PrimaryAccount(
        id: asString(json['id']) ?? '',
        isPrimary: asBool(json['isPrimary']) ?? false,
      );

  /// The account's id.
  final String id;

  /// Whether it now leads its platform.
  final bool isPrimary;

  @override
  String toString() => 'PrimaryAccount($id, $isPrimary)';
}

/// When a refreshed credential now expires.
class RefreshedToken {
  /// Creates a refresh result.
  const RefreshedToken({required this.message, this.expiresAt});

  /// Reads a refresh result.
  factory RefreshedToken.fromJson(Map<String, dynamic> json) => RefreshedToken(
        message: asString(json['message']) ?? '',
        expiresAt: asDate(json['expiresAt']),
      );

  /// What the API said.
  final String message;

  /// When the new credential expires.
  final DateTime? expiresAt;

  @override
  String toString() => 'RefreshedToken(expires: $expiresAt)';
}

/// One point in an account's history.
class AccountSnapshot {
  /// Creates a snapshot.
  const AccountSnapshot({
    this.followers,
    this.following,
    this.totalPosts,
    this.reach,
    this.profileViews,
    this.fetchedAt,
  });

  /// Reads a snapshot.
  factory AccountSnapshot.fromJson(Map<String, dynamic> json) =>
      AccountSnapshot(
        followers: asInt(json['followers']),
        following: asInt(json['following']),
        totalPosts: asInt(json['totalPosts']),
        reach: asInt(json['reach']),
        profileViews: asInt(json['profileViews']),
        fetchedAt: asDate(json['fetchedAt']),
      );

  /// Followers at this point.
  final int? followers;

  /// Accounts followed at this point.
  final int? following;

  /// Posts on the account at this point.
  final int? totalPosts;

  /// Reach in the period.
  final int? reach;

  /// Profile views in the period.
  final int? profileViews;

  /// When the snapshot was taken.
  final DateTime? fetchedAt;

  @override
  String toString() => 'AccountSnapshot($followers followers)';
}

/// An account's stored snapshots, newest first.
class AccountAnalyticsHistory {
  /// Creates a history.
  const AccountAnalyticsHistory({
    required this.accountId,
    required this.platform,
    this.username,
    this.history = const [],
  });

  /// Reads a history.
  factory AccountAnalyticsHistory.fromJson(Map<String, dynamic> json) =>
      AccountAnalyticsHistory(
        accountId: asString(json['accountId']) ?? '',
        platform: asString(json['platform']) ?? '',
        username: asString(json['username']),
        history: asModelList(json['history'], AccountSnapshot.fromJson),
      );

  /// The account these snapshots belong to.
  final String accountId;

  /// The account's network.
  final String platform;

  /// The account's handle.
  final String? username;

  /// The snapshots, newest first.
  final List<AccountSnapshot> history;

  @override
  String toString() =>
      'AccountAnalyticsHistory($platform, ${history.length} points)';
}

/// A one-time code that connects a Telegram chat when sent to the bot.
class TelegramConnectCode {
  /// Creates a connect code.
  const TelegramConnectCode({
    required this.code,
    required this.command,
    this.botUsername,
    this.deepLink,
    this.groupLink,
    this.expiresAt,
  });

  /// Reads a connect code.
  factory TelegramConnectCode.fromJson(Map<String, dynamic> json) =>
      TelegramConnectCode(
        code: asString(json['code']) ?? '',
        command: asString(json['command']) ?? '',
        botUsername: asString(json['bot_username']),
        deepLink: asString(json['deep_link']),
        groupLink: asString(json['group_link']),
        expiresAt: asDate(json['expires_at']),
      );

  /// The one-time code, valid for 15 minutes.
  final String code;

  /// What to send in the chat: `/connect <code>`.
  final String command;

  /// The publishing bot, without the @.
  final String? botUsername;

  /// Opens a private chat with the bot, code included.
  final String? deepLink;

  /// Adds the bot to a group, code included.
  final String? groupLink;

  /// When the code lapses.
  final DateTime? expiresAt;

  @override
  String toString() => 'TelegramConnectCode($code)';
}

/// Where a Telegram connect code stands.
class TelegramConnectStatus {
  /// Creates a connect status.
  const TelegramConnectStatus({
    required this.status,
    this.accountId,
    this.reason,
  });

  /// Reads a connect status.
  factory TelegramConnectStatus.fromJson(Map<String, dynamic> json) =>
      TelegramConnectStatus(
        status: asString(json['status']) ?? 'pending',
        accountId: asString(json['account_id']),
        reason: asString(json['reason']),
      );

  /// `pending`, `connected`, `failed`, or `expired`.
  final String status;

  /// The connected account, once `connected`.
  final String? accountId;

  /// Why the connection failed, when `failed`: `card_required`, `slot_taken`,
  /// or `workspace_unavailable`.
  final String? reason;

  @override
  String toString() => 'TelegramConnectStatus($status)';
}

/// One entry in a Telegram bot's command menu.
class TelegramBotCommand {
  /// Creates a command.
  const TelegramBotCommand({required this.command, required this.description});

  /// Reads a command.
  factory TelegramBotCommand.fromJson(Map<String, dynamic> json) =>
      TelegramBotCommand(
        command: asString(json['command']) ?? '',
        description: asString(json['description']) ?? '',
      );

  /// 1-32 lowercase letters, digits or underscores, without the slash.
  final String command;

  /// 1-256 characters.
  final String description;

  /// The request body shape.
  Map<String, dynamic> toJson() =>
      {'command': command, 'description': description};

  @override
  String toString() => 'TelegramBotCommand(/$command)';
}

/// A Slack channel the app can post to.
class SlackChannel {
  /// Creates a channel.
  const SlackChannel({
    required this.id,
    required this.name,
    this.isPrivate = false,
    this.isMember = false,
    this.isCurrent = false,
  });

  /// Reads a channel.
  factory SlackChannel.fromJson(Map<String, dynamic> json) => SlackChannel(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        isPrivate: asBool(json['is_private']) ?? false,
        isMember: asBool(json['is_member']) ?? false,
        isCurrent: asBool(json['is_current']) ?? false,
      );

  /// The Slack channel id.
  final String id;

  /// The channel name.
  final String name;

  /// Whether the channel is private.
  final bool isPrivate;

  /// Whether the bot is in the channel.
  final bool isMember;

  /// Whether this account posts to the channel.
  final bool isCurrent;

  @override
  String toString() => 'SlackChannel($id, #$name)';
}

/// A person in the connected Slack workspace.
class SlackMember {
  /// Creates a member.
  const SlackMember({
    required this.id,
    required this.name,
    this.realName,
    this.displayName,
    this.avatar,
    this.isBot = false,
  });

  /// Reads a member.
  factory SlackMember.fromJson(Map<String, dynamic> json) => SlackMember(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        realName: asString(json['real_name']),
        displayName: asString(json['display_name']),
        avatar: asString(json['avatar']),
        isBot: asBool(json['is_bot']) ?? false,
      );

  /// The Slack user id; pass it as the handle to start a DM.
  final String id;

  /// The Slack username.
  final String name;

  /// The member's full name.
  final String? realName;

  /// The member's display name.
  final String? displayName;

  /// The member's avatar URL.
  final String? avatar;

  /// Whether the member is a bot.
  final bool isBot;

  @override
  String toString() => 'SlackMember($id, $name)';
}

/// The name and icon a Slack account posts under.
class SlackIdentity {
  /// Creates an identity.
  const SlackIdentity({this.username, this.iconUrl, this.iconEmoji});

  /// Reads an identity.
  factory SlackIdentity.fromJson(Map<String, dynamic> json) => SlackIdentity(
        username: asString(json['username']),
        iconUrl: asString(json['icon_url']),
        iconEmoji: asString(json['icon_emoji']),
      );

  /// The name posts appear under, or null for the app name.
  final String? username;

  /// The image posts appear with.
  final String? iconUrl;

  /// The emoji code posts appear with, e.g. `:rocket:`.
  final String? iconEmoji;

  @override
  String toString() => 'SlackIdentity($username)';
}

/// A tappable prompt Messenger or Instagram shows before the first message.
class MetaIceBreaker {
  /// Creates an ice breaker.
  const MetaIceBreaker({required this.question, required this.payload});

  /// Reads an ice breaker.
  factory MetaIceBreaker.fromJson(Map<String, dynamic> json) => MetaIceBreaker(
        question: asString(json['question']) ?? '',
        payload: asString(json['payload']) ?? '',
      );

  /// The prompt, up to 80 characters.
  final String question;

  /// What your webhook receives when the prompt is tapped.
  final String payload;

  /// The body the API takes.
  Map<String, dynamic> toJson() => {'question': question, 'payload': payload};

  @override
  String toString() => 'MetaIceBreaker($question)';
}

/// A persistent-menu item: a `postback` carrying [payload], or a `web_url`
/// carrying an http(s) [url]. The unused one stays null and is not sent.
class MetaMenuItem {
  /// Creates a menu item.
  const MetaMenuItem({
    required this.type,
    required this.title,
    this.payload,
    this.url,
  });

  /// An item that sends [payload] to your webhook when tapped.
  const MetaMenuItem.postback(
      {required this.title, required String this.payload})
      : type = 'postback',
        url = null;

  /// An item that opens [url].
  const MetaMenuItem.link({required this.title, required String this.url})
      : type = 'web_url',
        payload = null;

  /// Reads a menu item.
  factory MetaMenuItem.fromJson(Map<String, dynamic> json) => MetaMenuItem(
        type: asString(json['type']) ?? '',
        title: asString(json['title']) ?? '',
        payload: asString(json['payload']),
        url: asString(json['url']),
      );

  /// `postback` or `web_url`.
  final String type;

  /// The label, up to 30 characters.
  final String title;

  /// Set on a postback item.
  final String? payload;

  /// Set on a web_url item.
  final String? url;

  /// The body the API takes.
  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        if (payload != null) 'payload': payload,
        if (url != null) 'url': url,
      };

  @override
  String toString() => 'MetaMenuItem($type, $title)';
}

/// One locale's menu; `default` is the fallback every language uses.
class MetaPersistentMenuEntry {
  /// Creates a menu entry.
  const MetaPersistentMenuEntry({
    required this.callToActions,
    this.locale = 'default',
    this.composerInputDisabled,
  });

  /// Reads a menu entry.
  factory MetaPersistentMenuEntry.fromJson(Map<String, dynamic> json) =>
      MetaPersistentMenuEntry(
        locale: asString(json['locale']) ?? 'default',
        callToActions:
            asModelList(json['call_to_actions'], MetaMenuItem.fromJson),
        composerInputDisabled: asBool(json['composer_input_disabled']),
      );

  /// The locale this menu applies to.
  final String locale;

  /// Up to three items.
  final List<MetaMenuItem> callToActions;

  /// Whether typing is disabled while the menu is shown.
  final bool? composerInputDisabled;

  /// The body the API takes.
  Map<String, dynamic> toJson() => {
        'locale': locale,
        'call_to_actions': callToActions.map((i) => i.toJson()).toList(),
        if (composerInputDisabled != null)
          'composer_input_disabled': composerInputDisabled,
      };

  @override
  String toString() => 'MetaPersistentMenuEntry($locale)';
}

/// One locale's greeting, up to 160 characters.
class MetaGreetingText {
  /// Creates a greeting.
  const MetaGreetingText({required this.text, this.locale = 'default'});

  /// Reads a greeting.
  factory MetaGreetingText.fromJson(Map<String, dynamic> json) =>
      MetaGreetingText(
        locale: asString(json['locale']) ?? 'default',
        text: asString(json['text']) ?? '',
      );

  /// The locale this greeting applies to.
  final String locale;

  /// The greeting, up to 160 characters.
  final String text;

  /// The body the API takes.
  Map<String, dynamic> toJson() => {'locale': locale, 'text': text};

  @override
  String toString() => 'MetaGreetingText($locale)';
}

/// What the network delivers to the FoPost webhook for one account.
class WebhookSubscription {
  /// Creates a subscription report.
  const WebhookSubscription({
    required this.subscribed,
    required this.fields,
    required this.missingFields,
  });

  /// Reads a subscription report.
  factory WebhookSubscription.fromJson(Map<String, dynamic> json) =>
      WebhookSubscription(
        subscribed: asBool(json['subscribed']) ?? false,
        fields: asStringList(json['fields']),
        missingFields: asStringList(json['missing_fields']),
      );

  /// False when the subscription lapsed or a required field is missing.
  final bool subscribed;

  /// The fields the network reports as subscribed.
  final List<String> fields;

  /// Required fields the network is not delivering.
  final List<String> missingFields;

  @override
  String toString() => 'WebhookSubscription($subscribed)';
}

// ─── Discord (bot connections) ───────────────────────────────────────────

/// A Discord text channel the bot can post to.
class DiscordChannel {
  /// Creates a channel.
  const DiscordChannel({
    required this.id,
    required this.name,
    this.type = 0,
    this.parentId,
    this.nsfw = false,
    this.canPost = true,
    this.isCurrent = false,
  });

  /// Reads a channel.
  factory DiscordChannel.fromJson(Map<String, dynamic> json) => DiscordChannel(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        type: asInt(json['type']) ?? 0,
        parentId: asString(json['parent_id']),
        nsfw: asBool(json['nsfw']) ?? false,
        canPost: asBool(json['can_post']) ?? true,
        isCurrent: asBool(json['is_current']) ?? false,
      );

  /// The Discord channel id.
  final String id;

  /// The channel name, without the leading `#`.
  final String name;

  /// Discord's channel type: 0 text, 5 announcement, 15 forum.
  final int type;

  /// The category the channel sits in.
  final String? parentId;

  /// Whether the channel is marked age-restricted.
  final bool nsfw;

  /// False when a channel permission in Discord shuts the bot out.
  final bool canPost;

  /// Whether this is the channel the account posts to.
  final bool isCurrent;

  @override
  String toString() => 'DiscordChannel($id, $name)';
}

/// The nickname and avatar the bot wears in the server.
class DiscordIdentity {
  /// Creates an identity.
  const DiscordIdentity({this.username, this.avatarUrl});

  /// Reads an identity.
  factory DiscordIdentity.fromJson(Map<String, dynamic> json) =>
      DiscordIdentity(
        username: asString(json['username']),
        avatarUrl: asString(json['avatar_url']),
      );

  /// The nickname, or null for the application's own name.
  final String? username;

  /// The avatar the bot wears in this server.
  final String? avatarUrl;

  @override
  String toString() => 'DiscordIdentity($username)';
}

/// A message in the connected channel.
class DiscordMessage {
  /// Creates a message.
  const DiscordMessage({
    required this.id,
    required this.channelId,
    this.content = '',
    this.authorId = '',
    this.authorName = '',
    this.pinned = false,
    this.createdAt,
  });

  /// Reads a message.
  factory DiscordMessage.fromJson(Map<String, dynamic> json) => DiscordMessage(
        id: asString(json['id']) ?? '',
        channelId: asString(json['channel_id']) ?? '',
        content: asString(json['content']) ?? '',
        authorId: asString(json['author_id']) ?? '',
        authorName: asString(json['author_name']) ?? '',
        pinned: asBool(json['pinned']) ?? false,
        createdAt: asString(json['created_at']),
      );

  /// The Discord message id.
  final String id;

  /// The channel the message sits in.
  final String channelId;

  /// The message text.
  final String content;

  /// The author's Discord user id.
  final String authorId;

  /// The author's display name.
  final String authorName;

  /// Whether the message is pinned.
  final bool pinned;

  /// When Discord recorded the message.
  final String? createdAt;

  @override
  String toString() => 'DiscordMessage($id)';
}

/// A message the bot put somewhere.
class DiscordMessageRef {
  /// Creates a reference.
  const DiscordMessageRef({required this.id, required this.channelId});

  /// Reads a reference.
  factory DiscordMessageRef.fromJson(Map<String, dynamic> json) =>
      DiscordMessageRef(
        id: asString(json['id']) ?? '',
        channelId: asString(json['channel_id']) ?? '',
      );

  /// The Discord message id.
  final String id;

  /// The channel the message landed in.
  final String channelId;

  @override
  String toString() => 'DiscordMessageRef($id)';
}

/// A thread started on a message.
class DiscordThread {
  /// Creates a thread.
  const DiscordThread({required this.id, required this.name, this.parentId});

  /// Reads a thread.
  factory DiscordThread.fromJson(Map<String, dynamic> json) => DiscordThread(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        parentId: asString(json['parent_id']),
      );

  /// The Discord thread id.
  final String id;

  /// The thread name.
  final String name;

  /// The channel the thread hangs off.
  final String? parentId;

  @override
  String toString() => 'DiscordThread($id, $name)';
}

/// An event on the server's calendar.
///
/// [channelId] names a voice or stage channel; otherwise [location] says where
/// it happens.
class DiscordScheduledEvent {
  /// Creates an event.
  const DiscordScheduledEvent({
    required this.id,
    required this.name,
    required this.startTime,
    this.description,
    this.channelId,
    this.location,
    this.endTime,
    this.status = 'scheduled',
    this.userCount,
  });

  /// Reads an event.
  factory DiscordScheduledEvent.fromJson(Map<String, dynamic> json) =>
      DiscordScheduledEvent(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        startTime: asString(json['start_time']) ?? '',
        description: asString(json['description']),
        channelId: asString(json['channel_id']),
        location: asString(json['location']),
        endTime: asString(json['end_time']),
        status: asString(json['status']) ?? 'scheduled',
        userCount: asInt(json['user_count']),
      );

  /// The Discord event id.
  final String id;

  /// The event name.
  final String name;

  /// When it starts, as RFC 3339.
  final String startTime;

  /// The event description.
  final String? description;

  /// The voice or stage channel it happens in.
  final String? channelId;

  /// Where it happens, when it is not in a channel.
  final String? location;

  /// When it ends, as RFC 3339.
  final String? endTime;

  /// One of `scheduled`, `active`, `completed` or `canceled`.
  final String status;

  /// How many people marked themselves interested.
  final int? userCount;

  @override
  String toString() => 'DiscordScheduledEvent($id, $name)';
}

/// A person in the connected server.
class DiscordMember {
  /// Creates a member.
  const DiscordMember({
    required this.id,
    required this.username,
    this.displayName,
    this.nick,
    this.avatar,
    this.isBot = false,
    this.roles = const [],
    this.joinedAt,
  });

  /// Reads a member.
  factory DiscordMember.fromJson(Map<String, dynamic> json) => DiscordMember(
        id: asString(json['id']) ?? '',
        username: asString(json['username']) ?? '',
        displayName: asString(json['display_name']),
        nick: asString(json['nick']),
        avatar: asString(json['avatar']),
        isBot: asBool(json['is_bot']) ?? false,
        roles: asStringList(json['roles']),
        joinedAt: asString(json['joined_at']),
      );

  /// The Discord user id; pass it as the member id for a DM or a role.
  final String id;

  /// The Discord username.
  final String username;

  /// The member's global display name.
  final String? displayName;

  /// The member's nickname in this server.
  final String? nick;

  /// The member's avatar URL.
  final String? avatar;

  /// Whether the member is a bot.
  final bool isBot;

  /// The role ids the member holds.
  final List<String> roles;

  /// When the member joined the server.
  final String? joinedAt;

  @override
  String toString() => 'DiscordMember($id, $username)';
}

/// A role in the connected server.
class DiscordRole {
  /// Creates a role.
  const DiscordRole({
    required this.id,
    required this.name,
    this.color = 0,
    this.hoist = false,
    this.mentionable = false,
    this.managed = false,
    this.position = 0,
    this.permissions = '0',
  });

  /// Reads a role.
  factory DiscordRole.fromJson(Map<String, dynamic> json) => DiscordRole(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        color: asInt(json['color']) ?? 0,
        hoist: asBool(json['hoist']) ?? false,
        mentionable: asBool(json['mentionable']) ?? false,
        managed: asBool(json['managed']) ?? false,
        position: asInt(json['position']) ?? 0,
        permissions: asString(json['permissions']) ?? '0',
      );

  /// The Discord role id.
  final String id;

  /// The role name.
  final String name;

  /// An RGB integer; 0 is the default colour.
  final int color;

  /// Whether members with this role show separately in the member list.
  final bool hoist;

  /// Whether anyone can @mention the role.
  final bool mentionable;

  /// Whether an integration owns the role, which makes it read-only.
  final bool managed;

  /// Where the role sits in the hierarchy.
  final int position;

  /// Discord's permission bitfield as a decimal string.
  final String permissions;

  @override
  String toString() => 'DiscordRole($id, $name)';
}

/// What a Discord delete, pin or role assignment answers.
class DiscordAck {
  /// Creates an acknowledgement.
  const DiscordAck({this.deleted, this.pinned, this.assigned});

  /// Reads an acknowledgement.
  factory DiscordAck.fromJson(Map<String, dynamic> json) => DiscordAck(
        deleted: asBool(json['deleted']),
        pinned: asBool(json['pinned']),
        assigned: asBool(json['assigned']),
      );

  /// Whether the thing was deleted.
  final bool? deleted;

  /// Whether the message is now pinned.
  final bool? pinned;

  /// Whether the member now holds the role.
  final bool? assigned;

  @override
  String toString() => 'DiscordAck($deleted, $pinned, $assigned)';
}
