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
