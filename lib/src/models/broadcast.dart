import '../json.dart';

/// Absent stays absent: `asStringList` answers an empty list, and an empty
/// clause would be sent as one rather than left off.
List<String>? _stringsOrNull(Object? value) =>
    value == null ? null : asStringList(value);

/// One custom-field clause in an audience filter.
///
/// [op] is `is`, `is_not`, `contains`, `is_set` or `is_not_set`; null means
/// `is`.
class AudienceField {
  /// Creates a clause.
  const AudienceField({required this.key, this.op, this.value});

  /// Reads a clause.
  factory AudienceField.fromJson(Map<String, dynamic> json) => AudienceField(
        key: asString(json['key']) ?? '',
        op: asString(json['op']),
        value: asString(json['value']),
      );

  /// The custom field's machine key.
  final String key;

  /// How the value is compared.
  final String? op;

  /// What it is compared against, where the operator takes one.
  final String? value;

  /// The shape a write sends.
  Map<String, dynamic> toJson() =>
      pruned({'key': key, 'op': op, 'value': value});

  @override
  String toString() => 'AudienceField($key)';
}

/// Who a broadcast or an enrollment resolves to, expressed over contacts.
///
/// Every clause narrows: a contact has to match all of them. An unset clause
/// is not sent, so an empty filter is everyone in the workspace.
class AudienceFilter {
  /// Creates a filter.
  const AudienceFilter({
    this.platforms,
    this.labelIds,
    this.source,
    this.fields,
  });

  /// Reads a filter.
  factory AudienceFilter.fromJson(Map<String, dynamic> json) => AudienceFilter(
        platforms: _stringsOrNull(json['platforms']),
        labelIds: _stringsOrNull(json['label_ids'] ?? json['labelIds']),
        source: asString(json['source']),
        fields: (json['fields'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(AudienceField.fromJson)
            .toList(),
      );

  /// Contacts with a handle on at least one of these networks.
  final List<String>? platforms;

  /// Labels the contact carries.
  final List<String>? labelIds;

  /// `inbox`, `radar` or `import`.
  final String? source;

  /// Custom field clauses, by the field's machine key.
  final List<AudienceField>? fields;

  /// The shape a write sends.
  Map<String, dynamic> toJson() => pruned({
        'platforms': platforms,
        'label_ids': labelIds,
        'source': source,
        'fields': fields?.map((f) => f.toJson()).toList(),
      });

  @override
  String toString() => 'AudienceFilter(${platforms ?? const []})';
}

/// What became of a broadcast's recipients, by status.
///
/// [skipped] is usually the messaging window doing its job.
class BroadcastCounts {
  /// Creates a count block.
  const BroadcastCounts({
    this.total = 0,
    this.sent = 0,
    this.skipped = 0,
    this.failed = 0,
    this.pending = 0,
  });

  /// Reads a count block.
  factory BroadcastCounts.fromJson(Map<String, dynamic> json) =>
      BroadcastCounts(
        total: asInt(json['total']) ?? 0,
        sent: asInt(json['sent']) ?? 0,
        skipped: asInt(json['skipped']) ?? 0,
        failed: asInt(json['failed']) ?? 0,
        pending: asInt(json['pending']) ?? 0,
      );

  /// Every recipient the audience resolved to.
  final int total;

  /// Messages that reached a platform.
  final int sent;

  /// Recipients nothing was attempted for.
  final int skipped;

  /// Recipients the platform refused.
  final int failed;

  /// Recipients not yet worked.
  final int pending;

  @override
  String toString() => 'BroadcastCounts(sent: $sent, skipped: $skipped)';
}

/// One message, sent into conversations the workspace already has.
class Broadcast {
  /// Creates a broadcast.
  const Broadcast({
    required this.id,
    required this.name,
    required this.text,
    required this.status,
    this.accountId,
    this.audience,
    this.scheduledAt,
    this.sentAt,
    this.createdAt,
    this.counts,
    this.workspaceId,
  });

  /// Reads a broadcast.
  factory Broadcast.fromJson(Map<String, dynamic> json) => Broadcast(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        text: asString(json['text']) ?? '',
        status: asString(json['status']) ?? 'draft',
        accountId: asString(json['account_id'] ?? json['accountId']),
        audience: json['audience'] is Map<String, dynamic>
            ? AudienceFilter.fromJson(json['audience'] as Map<String, dynamic>)
            : null,
        scheduledAt: asDate(json['scheduled_at'] ?? json['scheduledAt']),
        sentAt: asDate(json['sent_at'] ?? json['sentAt']),
        createdAt: asDate(json['created_at'] ?? json['createdAt']),
        counts: json['counts'] is Map<String, dynamic>
            ? BroadcastCounts.fromJson(json['counts'] as Map<String, dynamic>)
            : null,
        workspaceId: asString(json['workspace_id'] ?? json['workspaceId']),
      );

  /// The broadcast's id.
  final String id;

  /// What you call it. Internal only; never sent to anyone.
  final String name;

  /// The message itself.
  final String text;

  /// `draft`, `scheduled`, `sending`, `sent` or `cancelled`.
  final String status;

  /// The connected account the messages go out from.
  final String? accountId;

  /// Who it goes to.
  final AudienceFilter? audience;

  /// When it goes out on its own, when it is scheduled.
  final DateTime? scheduledAt;

  /// When it finished sending.
  final DateTime? sentAt;

  /// When it was written.
  final DateTime? createdAt;

  /// What became of its recipients.
  final BroadcastCounts? counts;

  /// Set only on a list that spans more than one workspace.
  final String? workspaceId;

  @override
  String toString() => 'Broadcast($name, $status)';
}

/// One contact on one broadcast, and what became of their message.
class BroadcastRecipient {
  /// Creates a recipient row.
  const BroadcastRecipient({
    required this.contactId,
    required this.status,
    this.displayName,
    this.skipReason,
    this.sentAt,
    this.error,
  });

  /// Reads a recipient row.
  factory BroadcastRecipient.fromJson(Map<String, dynamic> json) =>
      BroadcastRecipient(
        contactId: asString(json['contact_id'] ?? json['contactId']) ?? '',
        status: asString(json['status']) ?? 'pending',
        displayName: asString(json['display_name'] ?? json['displayName']),
        skipReason: asString(json['skip_reason'] ?? json['skipReason']),
        sentAt: asDate(json['sent_at'] ?? json['sentAt']),
        error: asString(json['error']),
      );

  /// The contact this row is about.
  final String contactId;

  /// `pending`, `sent`, `skipped` or `failed`.
  final String status;

  /// The contact's name, where the workspace knows one.
  final String? displayName;

  /// Why nothing was sent: `window_closed`, `no_conversation` or
  /// `unsupported_platform`. `window_closed` means the network's messaging
  /// window had shut, so nothing was attempted.
  final String? skipReason;

  /// When the message reached the platform.
  final DateTime? sentAt;

  /// What the platform said, when it refused.
  final String? error;

  @override
  String toString() => 'BroadcastRecipient($contactId, $status)';
}

/// What a send started.
class BroadcastSent {
  /// Creates a send result.
  const BroadcastSent({
    required this.id,
    required this.status,
    required this.recipients,
  });

  /// Reads a send result.
  factory BroadcastSent.fromJson(Map<String, dynamic> json) => BroadcastSent(
        id: asString(json['id']) ?? '',
        status: asString(json['status']) ?? '',
        recipients: asInt(json['recipients']) ?? 0,
      );

  /// The broadcast's id.
  final String id;

  /// Its new status.
  final String status;

  /// How many contacts matched, not how many will be messaged — the messaging
  /// window decides that.
  final int recipients;

  @override
  String toString() => 'BroadcastSent($id, $recipients)';
}

/// One message and how long after the previous step it goes out.
///
/// [delayHours] on the first step is measured from the enrollment, so 0 means
/// straight away.
class SequenceStep {
  /// Creates a step.
  const SequenceStep({
    required this.delayHours,
    required this.text,
    this.mediaId,
  });

  /// Reads a step.
  factory SequenceStep.fromJson(Map<String, dynamic> json) => SequenceStep(
        delayHours: asDouble(json['delay_hours'] ?? json['delayHours']) ?? 0,
        text: asString(json['text']) ?? '',
        mediaId: asString(json['media_id'] ?? json['mediaId']),
      );

  /// Hours to wait after the previous step.
  final double delayHours;

  /// The message itself.
  final String text;

  /// An asset from the media library to attach.
  final String? mediaId;

  /// The shape a write sends.
  Map<String, dynamic> toJson() => pruned({
        'delay_hours': delayHours,
        'text': text,
        'media_id': mediaId,
      });

  @override
  String toString() => 'SequenceStep(+${delayHours}h)';
}

/// Where a sequence's enrollments stand, by status.
class EnrollmentCounts {
  /// Creates a count block.
  const EnrollmentCounts({
    this.total = 0,
    this.active = 0,
    this.completed = 0,
    this.stopped = 0,
    this.failed = 0,
  });

  /// Reads a count block.
  factory EnrollmentCounts.fromJson(Map<String, dynamic> json) =>
      EnrollmentCounts(
        total: asInt(json['total']) ?? 0,
        active: asInt(json['active']) ?? 0,
        completed: asInt(json['completed']) ?? 0,
        stopped: asInt(json['stopped']) ?? 0,
        failed: asInt(json['failed']) ?? 0,
      );

  /// Every enrollment the sequence has ever had.
  final int total;

  /// Still walking it.
  final int active;

  /// Reached the end.
  final int completed;

  /// Unenrolled.
  final int stopped;

  /// Stopped because the account went away.
  final int failed;

  @override
  String toString() => 'EnrollmentCounts(active: $active)';
}

/// A series of messages, each a delay after the one before.
class Sequence {
  /// Creates a sequence.
  const Sequence({
    required this.id,
    required this.name,
    required this.steps,
    required this.status,
    this.accountId,
    this.createdAt,
    this.enrollments,
    this.workspaceId,
  });

  /// Reads a sequence.
  factory Sequence.fromJson(Map<String, dynamic> json) => Sequence(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        steps: (json['steps'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(SequenceStep.fromJson)
                .toList() ??
            const [],
        status: asString(json['status']) ?? 'active',
        accountId: asString(json['account_id'] ?? json['accountId']),
        createdAt: asDate(json['created_at'] ?? json['createdAt']),
        enrollments: json['enrollments'] is Map<String, dynamic>
            ? EnrollmentCounts.fromJson(
                json['enrollments'] as Map<String, dynamic>)
            : null,
        workspaceId: asString(json['workspace_id'] ?? json['workspaceId']),
      );

  /// The sequence's id.
  final String id;

  /// What you call it. Internal only.
  final String name;

  /// The steps it walks, in order.
  final List<SequenceStep> steps;

  /// `active` or `paused`. A paused sequence fires nothing.
  final String status;

  /// The connected account every step is sent from.
  final String? accountId;

  /// When it was written.
  final DateTime? createdAt;

  /// Where its enrollments stand.
  final EnrollmentCounts? enrollments;

  /// Set only on a list that spans more than one workspace.
  final String? workspaceId;

  @override
  String toString() => 'Sequence($name, ${steps.length} steps)';
}

/// One contact walking one sequence.
class Enrollment {
  /// Creates an enrollment.
  const Enrollment({
    required this.id,
    required this.contactId,
    required this.step,
    required this.status,
    this.displayName,
    this.nextAt,
    this.lastSentAt,
    this.error,
  });

  /// Reads an enrollment.
  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
        id: asString(json['id']) ?? '',
        contactId: asString(json['contact_id'] ?? json['contactId']) ?? '',
        step: asInt(json['step']) ?? 0,
        status: asString(json['status']) ?? 'active',
        displayName: asString(json['display_name'] ?? json['displayName']),
        nextAt: asDate(json['next_at'] ?? json['nextAt']),
        lastSentAt: asDate(json['last_sent_at'] ?? json['lastSentAt']),
        error: asString(json['error']),
      );

  /// The enrollment's id.
  final String id;

  /// The contact walking the sequence.
  final String contactId;

  /// Steps already sent, so also the index of the next one.
  final int step;

  /// `active`, `completed`, `stopped` or `failed`.
  final String status;

  /// The contact's name, where the workspace knows one.
  final String? displayName;

  /// When the next step is due.
  final DateTime? nextAt;

  /// When the last step went out.
  final DateTime? lastSentAt;

  /// On a skipped step, the reason it was skipped.
  final String? error;

  @override
  String toString() => 'Enrollment($contactId, step $step)';
}

/// How many contacts a call put on the sequence.
class Enrolled {
  /// Creates an enroll result.
  const Enrolled({required this.id, required this.enrolled});

  /// Reads an enroll result.
  factory Enrolled.fromJson(Map<String, dynamic> json) => Enrolled(
        id: asString(json['id']) ?? '',
        enrolled: asInt(json['enrolled']) ?? 0,
      );

  /// The sequence's id.
  final String id;

  /// How many contacts were put on it.
  final int enrolled;

  @override
  String toString() => 'Enrolled($enrolled)';
}

/// How many enrollments a call stopped.
class Unenrolled {
  /// Creates an unenroll result.
  const Unenrolled({required this.id, required this.stopped});

  /// Reads an unenroll result.
  factory Unenrolled.fromJson(Map<String, dynamic> json) => Unenrolled(
        id: asString(json['id']) ?? '',
        stopped: asInt(json['stopped']) ?? 0,
      );

  /// The sequence's id.
  final String id;

  /// How many enrollments were stopped.
  final int stopped;

  @override
  String toString() => 'Unenrolled($stopped)';
}
