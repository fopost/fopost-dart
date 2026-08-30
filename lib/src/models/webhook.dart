import '../json.dart';

/// One outbound webhook subscription.
class Webhook {
  /// Creates a subscription.
  const Webhook({
    required this.id,
    required this.url,
    required this.events,
    this.workspaceId,
    this.active = true,
    this.secret,
    this.lastTriggeredAt,
    this.failureCount,
    this.createdAt,
  });

  /// Reads a subscription.
  ///
  /// [secret] is only present on the response that created it.
  factory Webhook.fromJson(Map<String, dynamic> json) => Webhook(
        id: asString(json['id']) ?? '',
        url: asString(json['url']) ?? '',
        events: asStringList(json['events']),
        workspaceId: asString(json['workspaceId'] ?? json['workspace_id']),
        active: asBool(json['active']) ?? true,
        secret: asString(json['secret']),
        lastTriggeredAt: asDate(json['lastTriggeredAt']),
        failureCount: asInt(json['failureCount']),
        createdAt: asDate(json['createdAt']),
      );

  /// The subscription's id.
  final String id;

  /// Where events are delivered.
  final String url;

  /// The `WebhookEvent` values this subscription asked for.
  final List<String> events;

  /// The workspace it watches.
  final String? workspaceId;

  /// Whether events are being delivered.
  final bool active;

  /// The signing secret, shown once at creation — store it now.
  final String? secret;

  /// When an event was last delivered.
  final DateTime? lastTriggeredAt;

  /// Consecutive delivery failures.
  final int? failureCount;

  /// When the subscription was created.
  final DateTime? createdAt;

  @override
  String toString() => 'Webhook($url, ${events.length} events)';
}
