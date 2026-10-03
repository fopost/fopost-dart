import '../json.dart';

/// Activity kinds. [ActivityKind.security] is the audit log: its rows are
/// append-only and, unlike the rest, never expire.
abstract final class ActivityKind {
  /// A post finished publishing.
  static const publish = 'publish';

  /// An account was connected, disconnected, or changed health.
  static const connection = 'connection';

  /// A webhook delivery succeeded, or failed with no retries left.
  static const webhook = 'webhook';

  /// A reply was sent from the inbox.
  static const inbox = 'inbox';

  /// An automation run finished.
  static const automation = 'automation';

  /// A usage invoice was issued or charged.
  static const billing = 'billing';

  /// The audit log: membership, role, access and sign-in changes.
  static const security = 'security';
}

/// Who did something: `user`, `api_key`, `agent` or `system`.
class ActivityActor {
  /// Creates an actor.
  const ActivityActor({required this.type, this.name});

  /// Reads an actor.
  factory ActivityActor.fromJson(Map<String, dynamic> json) => ActivityActor(
        type: asString(json['type']) ?? 'system',
        name: asString(json['name']),
      );

  /// What kind of actor it was.
  final String type;

  /// Their name, where there is one. A system event has none.
  final String? name;

  @override
  String toString() => 'ActivityActor(${name ?? type})';
}

/// One thing that happened in a workspace.
class ActivityEvent {
  /// Creates an event.
  const ActivityEvent({
    required this.id,
    required this.kind,
    required this.summary,
    required this.actor,
    this.workspaceId,
    this.refType,
    this.refId,
    this.time,
  });

  /// Reads an event.
  factory ActivityEvent.fromJson(Map<String, dynamic> json) => ActivityEvent(
        id: asString(json['id']) ?? '',
        kind: asString(json['kind']) ?? '',
        summary: asString(json['summary']) ?? '',
        actor: ActivityActor.fromJson(asMap(json['actor'])),
        workspaceId: asString(json['workspace_id'] ?? json['workspaceId']),
        refType: asString(json['ref_type'] ?? json['refType']),
        refId: asString(json['ref_id'] ?? json['refId']),
        time: asDate(json['time']),
      );

  /// The event's id.
  final String id;

  /// One of [ActivityKind].
  final String kind;

  /// What happened, in a sentence.
  final String summary;

  /// Who did it.
  final ActivityActor actor;

  /// The workspace it happened in.
  final String? workspaceId;

  /// What the event is about, e.g. `post` or `member_removed`.
  final String? refType;

  /// The id of that thing, where there is one.
  final String? refId;

  /// When it happened.
  final DateTime? time;

  @override
  String toString() => 'ActivityEvent($kind: $summary)';
}

/// One page of activity, newest first.
class ActivityPage {
  /// Creates a page.
  const ActivityPage({required this.events, this.nextCursor});

  /// Reads a page from the whole response body.
  factory ActivityPage.fromJson(Map<String, dynamic> json) {
    final rows = json['data'];
    return ActivityPage(
      events: rows is List
          ? rows
              .whereType<Map<String, dynamic>>()
              .map(ActivityEvent.fromJson)
              .toList()
          : const [],
      nextCursor: asString(asMap(json['meta'])['next_cursor']),
    );
  }

  /// The events on this page.
  final List<ActivityEvent> events;

  /// Pass this back as `cursor` for the next page; null at the end.
  final String? nextCursor;

  @override
  String toString() => 'ActivityPage(${events.length} events)';
}
