import '../json.dart';

/// An X community linked to an account.
class Community {
  /// Creates a community link.
  const Community({
    required this.id,
    required this.communityId,
    required this.name,
    this.accountId,
    this.memberCount,
    this.description,
    this.imageUrl,
    this.lastSyncedAt,
    this.createdAt,
  });

  /// Reads a community link.
  factory Community.fromJson(Map<String, dynamic> json) => Community(
        id: asInt(json['id']) ?? 0,
        communityId: asString(json['communityId']) ?? '',
        name: asString(json['name']) ?? '',
        accountId: asString(json['accountId']),
        memberCount: asInt(json['memberCount']),
        description: asString(json['description']),
        imageUrl: asString(json['imageUrl']),
        lastSyncedAt: asDate(json['lastSyncedAt']),
        createdAt: asDate(json['createdAt']),
      );

  /// The link's own id, which `remove` takes.
  final int id;

  /// The platform's id for the community.
  final String communityId;

  /// The community's name.
  final String name;

  /// The account the community is linked to.
  final String? accountId;

  /// How many members it has.
  final int? memberCount;

  /// The community's description.
  final String? description;

  /// The community's image.
  final String? imageUrl;

  /// When it was last synced from the platform.
  final DateTime? lastSyncedAt;

  /// When the link was created.
  final DateTime? createdAt;

  @override
  String toString() => 'Community($name)';
}

/// A community as search returns it, before it is linked to an account.
class CommunitySearchResult {
  /// Creates a search result.
  const CommunitySearchResult({required this.id, required this.name, this.description, this.memberCount});

  /// Reads a search result.
  factory CommunitySearchResult.fromJson(Map<String, dynamic> json) => CommunitySearchResult(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        description: asString(json['description']),
        memberCount: asInt(json['member_count'] ?? json['memberCount']),
      );

  /// The platform's id for the community.
  final String id;

  /// The community's name.
  final String name;

  /// The community's description.
  final String? description;

  /// How many members it has.
  final int? memberCount;

  @override
  String toString() => 'CommunitySearchResult($name)';
}
