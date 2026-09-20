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
