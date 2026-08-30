import '../json.dart';

/// One campaign tag posts are grouped by.
class Label {
  /// Creates a label.
  const Label({
    required this.id,
    required this.name,
    required this.color,
    this.workspaceId,
    this.workspaceName,
    this.createdAt,
    this.updatedAt,
  });

  /// Reads a label.
  factory Label.fromJson(Map<String, dynamic> json) {
    final workspace = asMap(json['workspace']);
    return Label(
      id: asString(json['id']) ?? '',
      name: asString(json['name']) ?? '',
      color: asString(json['color']) ?? '',
      workspaceId: asString(
          json['workspace_id'] ?? json['workspaceId'] ?? workspace['id']),
      workspaceName: asString(workspace['name']),
      createdAt: asDate(json['created_at'] ?? json['createdAt']),
      updatedAt: asDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// The label's id.
  final String id;

  /// The label's name.
  final String name;

  /// The label's hex color, e.g. `#2563eb`.
  final String color;

  /// The workspace it belongs to.
  final String? workspaceId;

  /// That workspace's name, when the API expanded it.
  final String? workspaceName;

  /// When the label was created.
  final DateTime? createdAt;

  /// When it last changed.
  final DateTime? updatedAt;

  @override
  String toString() => 'Label($name)';
}
