import '../json.dart';

/// A named set of connected accounts in one workspace.
class AccountGroup {
  /// Creates an account group.
  const AccountGroup({
    required this.id,
    required this.name,
    this.accountIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Reads an account group.
  factory AccountGroup.fromJson(Map<String, dynamic> json) => AccountGroup(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        accountIds: asStringList(json['account_ids'] ?? json['accountIds']),
        createdAt: asDate(json['created_at'] ?? json['createdAt']),
        updatedAt: asDate(json['updated_at'] ?? json['updatedAt']),
      );

  /// The group's id.
  final String id;

  /// The group's name.
  final String name;

  /// The accounts in the group.
  final List<String> accountIds;

  /// When the group was created.
  final DateTime? createdAt;

  /// When it last changed.
  final DateTime? updatedAt;

  @override
  String toString() => 'AccountGroup($name)';
}
