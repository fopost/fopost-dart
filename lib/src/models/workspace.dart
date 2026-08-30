import '../json.dart';

/// A connected account as listed on a workspace.
class WorkspaceAccountRef {
  /// Creates an account reference.
  const WorkspaceAccountRef({
    required this.id,
    required this.platform,
    required this.username,
    this.workspaceId,
    this.name,
    this.avatar,
  });

  /// Reads an account reference.
  factory WorkspaceAccountRef.fromJson(Map<String, dynamic> json) => WorkspaceAccountRef(
        id: asString(json['id']) ?? '',
        platform: asString(json['platform']) ?? '',
        username: asString(json['username']) ?? '',
        workspaceId: asString(json['workspaceId']),
        name: asString(json['name']),
        avatar: asString(json['avatar']),
      );

  /// The account's id.
  final String id;

  /// The account's network.
  final String platform;

  /// The account's handle.
  final String username;

  /// The workspace it belongs to.
  final String? workspaceId;

  /// The account's display name.
  final String? name;

  /// The account's avatar URL.
  final String? avatar;

  @override
  String toString() => 'WorkspaceAccountRef($platform/$username)';
}

/// One tenant. Every other resource is scoped to a workspace.
class Workspace {
  /// Creates a workspace.
  const Workspace({
    required this.id,
    required this.name,
    required this.slug,
    this.type,
    this.logo,
    this.website,
    this.timezone,
    this.country,
    this.description,
    this.language,
    this.accounts = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Reads a workspace.
  factory Workspace.fromJson(Map<String, dynamic> json) => Workspace(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        slug: asString(json['slug']) ?? '',
        type: asString(json['type']),
        logo: asString(json['logo']),
        website: asString(json['website']),
        timezone: asString(json['timezone']),
        country: asString(json['country']),
        description: asString(json['description']),
        language: asString(json['language']),
        accounts: asModelList(json['accounts'], WorkspaceAccountRef.fromJson),
        createdAt: asDate(json['created_at'] ?? json['createdAt']),
        updatedAt: asDate(json['updated_at'] ?? json['updatedAt']),
      );

  /// The workspace's id.
  final String id;

  /// The workspace's name.
  final String name;

  /// The workspace's URL slug.
  final String slug;

  /// One of `WorkspaceType`.
  final String? type;

  /// The workspace's logo URL.
  final String? logo;

  /// The brand's website.
  final String? website;

  /// The IANA timezone scheduling is resolved in.
  final String? timezone;

  /// The workspace's country.
  final String? country;

  /// A short description.
  final String? description;

  /// The workspace's default content language.
  final String? language;

  /// The accounts connected to this workspace.
  final List<WorkspaceAccountRef> accounts;

  /// When the workspace was created.
  final DateTime? createdAt;

  /// When it last changed.
  final DateTime? updatedAt;

  @override
  String toString() => 'Workspace($name)';
}

/// One account's follower and post counts within a workspace roll-up.
class WorkspaceAccountAnalytics {
  /// Creates an account roll-up.
  const WorkspaceAccountAnalytics({
    required this.accountId,
    required this.platform,
    this.username,
    this.followers,
    this.following,
    this.totalPosts,
    this.fetchedAt,
  });

  /// Reads an account roll-up.
  factory WorkspaceAccountAnalytics.fromJson(Map<String, dynamic> json) =>
      WorkspaceAccountAnalytics(
        accountId: asString(json['accountId']) ?? '',
        platform: asString(json['platform']) ?? '',
        username: asString(json['username']),
        followers: asInt(json['followers']),
        following: asInt(json['following']),
        totalPosts: asInt(json['totalPosts']),
        fetchedAt: asDate(json['fetchedAt']),
      );

  /// The account's id.
  final String accountId;

  /// The account's network.
  final String platform;

  /// The account's handle.
  final String? username;

  /// Followers, where the platform reports them.
  final int? followers;

  /// Accounts followed.
  final int? following;

  /// Posts on the account.
  final int? totalPosts;

  /// When these numbers were pulled.
  final DateTime? fetchedAt;

  @override
  String toString() => 'WorkspaceAccountAnalytics($platform, $followers followers)';
}

/// The follower and post roll-up for one workspace.
class WorkspaceAnalytics {
  /// Creates a workspace roll-up.
  const WorkspaceAnalytics({
    required this.workspaceId,
    this.accounts = const [],
    this.totalFollowers = 0,
    this.totalPosts = 0,
  });

  /// Reads a workspace roll-up.
  factory WorkspaceAnalytics.fromJson(Map<String, dynamic> json) {
    final totals = asMap(json['totals']);
    return WorkspaceAnalytics(
      workspaceId: asString(json['workspaceId']) ?? '',
      accounts: asModelList(json['accounts'], WorkspaceAccountAnalytics.fromJson),
      totalFollowers: asInt(totals['followers']) ?? 0,
      totalPosts: asInt(totals['totalPosts']) ?? 0,
    );
  }

  /// The workspace these numbers belong to.
  final String workspaceId;

  /// One entry per connected account.
  final List<WorkspaceAccountAnalytics> accounts;

  /// Followers across every account.
  final int totalFollowers;

  /// Posts across every account.
  final int totalPosts;

  @override
  String toString() => 'WorkspaceAnalytics($totalFollowers followers)';
}
