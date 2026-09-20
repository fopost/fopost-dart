import '../json.dart';

/// One handle on one network.
///
/// [handle] is lower-cased with no leading `@`. [externalId] is the platform's
/// own id for that person when it gave one, and a merge prefers it: a handle
/// can be changed, an id cannot.
class ContactChannel {
  /// Creates a channel.
  const ContactChannel({
    required this.platform,
    required this.handle,
    this.externalId,
  });

  /// Reads a channel.
  factory ContactChannel.fromJson(Map<String, dynamic> json) => ContactChannel(
        platform: asString(json['platform']) ?? '',
        handle: asString(json['handle']) ?? '',
        externalId: asString(json['external_id'] ?? json['externalId']),
      );

  /// The network slug, such as `instagram`.
  final String platform;

  /// The handle, lower-cased and without a leading `@`.
  final String handle;

  /// The platform's own id for that person, when it gave one.
  final String? externalId;

  /// The shape a write sends.
  Map<String, dynamic> toJson() => pruned({
        'platform': platform,
        'handle': handle,
        'externalId': externalId,
      });

  @override
  String toString() => 'ContactChannel($platform:@$handle)';
}

/// A workspace label put on a contact.
class ContactLabel {
  /// Creates a label reference.
  const ContactLabel(
      {required this.id, required this.name, required this.color});

  /// Reads a label reference.
  factory ContactLabel.fromJson(Map<String, dynamic> json) => ContactLabel(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        color: asString(json['color']) ?? '',
      );

  /// The label's id.
  final String id;

  /// The label's name.
  final String name;

  /// The label's hex color.
  final String color;

  @override
  String toString() => 'ContactLabel($name)';
}

/// One person behind the inbox, however many handles they write from.
///
/// Built from what already reached the workspace: an inbound item files its
/// author, a reply files whoever you answered, an import files a row.
class Contact {
  /// Creates a contact.
  const Contact({
    required this.id,
    required this.channels,
    required this.source,
    this.displayName,
    this.note,
    this.firstSeenAt,
    this.lastSeenAt,
    this.fields = const {},
    this.labels = const [],
    this.workspaceId,
  });

  /// Reads a contact.
  factory Contact.fromJson(Map<String, dynamic> json) {
    final rawFields = asMap(json['fields']);
    return Contact(
      id: asString(json['id']) ?? '',
      displayName: asString(json['display_name'] ?? json['displayName']),
      channels: asModelList<ContactChannel>(
          json['channels'], ContactChannel.fromJson),
      source: asString(json['source']) ?? 'inbox',
      note: asString(json['note']),
      firstSeenAt: asDate(json['first_seen_at'] ?? json['firstSeenAt']),
      lastSeenAt: asDate(json['last_seen_at'] ?? json['lastSeenAt']),
      fields: {
        for (final entry in rawFields.entries)
          entry.key: asString(entry.value) ?? '',
      },
      labels: asModelList<ContactLabel>(json['labels'], ContactLabel.fromJson),
      workspaceId: asString(json['workspace_id'] ?? json['workspaceId']),
    );
  }

  /// The contact's id.
  final String id;

  /// The name a person typed in, or the one a platform gave.
  final String? displayName;

  /// Every handle this person writes from.
  final List<ContactChannel> channels;

  /// What first created the row: `inbox`, `radar` or `import`.
  final String source;

  /// A free note the workspace kept.
  final String? note;

  /// When the workspace first heard from them.
  final DateTime? firstSeenAt;

  /// When it last heard from them.
  final DateTime? lastSeenAt;

  /// Custom field answers, keyed by field key.
  final Map<String, String> fields;

  /// Workspace labels put on this contact.
  final List<ContactLabel> labels;

  /// Set only on a list that spans more than one workspace.
  final String? workspaceId;

  @override
  String toString() =>
      'Contact(${displayName ?? (channels.isEmpty ? id : '@${channels.first.handle}')})';
}

/// A column the workspace invented.
///
/// [key] is the machine name and also the CSV column header, fixed once
/// created; [name] is what people read.
class ContactField {
  /// Creates a field definition.
  const ContactField({
    required this.id,
    required this.key,
    required this.name,
    required this.type,
    this.options = const [],
    this.position,
  });

  /// Reads a field definition.
  factory ContactField.fromJson(Map<String, dynamic> json) => ContactField(
        id: asString(json['id']) ?? '',
        key: asString(json['key']) ?? '',
        name: asString(json['name']) ?? '',
        type: asString(json['type']) ?? 'text',
        options: asStringList(json['options']),
        position: asInt(json['position']),
      );

  /// The definition's id.
  final String id;

  /// The machine name, also the CSV column header.
  final String key;

  /// What people read.
  final String name;

  /// `text`, `number`, `date`, `select` or `boolean`.
  final String type;

  /// Allowed values when [type] is `select`.
  final List<String> options;

  /// Display order.
  final int? position;

  @override
  String toString() => 'ContactField($key)';
}

/// One inbox thread a contact appears in.
class ContactConversation {
  /// Creates a conversation row.
  const ContactConversation({
    required this.key,
    required this.accountId,
    required this.platform,
    required this.messages,
    required this.received,
    required this.sent,
    this.accountUsername,
    this.lastMessageAt,
    this.lastItemId,
  });

  /// Reads a conversation row.
  factory ContactConversation.fromJson(Map<String, dynamic> json) =>
      ContactConversation(
        key: asString(json['key']) ?? '',
        accountId: asString(json['account_id'] ?? json['accountId']) ?? '',
        accountUsername:
            asString(json['account_username'] ?? json['accountUsername']),
        platform: asString(json['platform']) ?? '',
        messages: asInt(json['messages']) ?? 0,
        received: asInt(json['received']) ?? 0,
        sent: asInt(json['sent']) ?? 0,
        lastMessageAt: asDate(json['last_message_at'] ?? json['lastMessageAt']),
        lastItemId: asString(json['last_item_id'] ?? json['lastItemId']),
      );

  /// How the inbox groups the thread: the DM thread id, else the post the
  /// comments hang off, else the handle.
  final String key;

  /// The connected account the thread arrived on.
  final String accountId;

  /// That account's username, when the API expanded it.
  final String? accountUsername;

  /// The network the thread is on.
  final String platform;

  /// How many messages the thread carried.
  final int messages;

  /// How many of them came in.
  final int received;

  /// How many went out.
  final int sent;

  /// When the last message landed.
  final DateTime? lastMessageAt;

  /// An inbox item id, so the thread can be read through the inbox.
  final String? lastItemId;

  @override
  String toString() => 'ContactConversation($platform, $messages messages)';
}

/// One CSV row that was not stored, and why.
class ContactImportSkip {
  /// Creates a skip.
  const ContactImportSkip({required this.row, required this.reason});

  /// Reads a skip.
  factory ContactImportSkip.fromJson(Map<String, dynamic> json) =>
      ContactImportSkip(
        row: asInt(json['row']) ?? 0,
        reason: asString(json['reason']) ?? '',
      );

  /// The 1-based row number in the file, counting the header.
  final int row;

  /// Why it was not stored.
  final String reason;

  @override
  String toString() => 'ContactImportSkip(row $row: $reason)';
}

/// What an import did.
class ContactImportResult {
  /// Creates an import result.
  const ContactImportResult({
    required this.created,
    required this.merged,
    this.skipped = const [],
    this.unknownColumns = const [],
  });

  /// Reads an import result.
  factory ContactImportResult.fromJson(Map<String, dynamic> json) =>
      ContactImportResult(
        created: asInt(json['created']) ?? 0,
        merged: asInt(json['merged']) ?? 0,
        skipped: asModelList<ContactImportSkip>(
            json['skipped'], ContactImportSkip.fromJson),
        unknownColumns:
            asStringList(json['unknownColumns'] ?? json['unknown_columns']),
      );

  /// How many rows became a new contact.
  final int created;

  /// How many folded into a contact already on file.
  final int merged;

  /// Rows that were not stored, and why.
  final List<ContactImportSkip> skipped;

  /// Headers matching no custom field. Reported rather than stored, so a typo
  /// in a column name is visible.
  final List<String> unknownColumns;

  @override
  String toString() =>
      'ContactImportResult(created: $created, merged: $merged)';
}

/// How one thread performed over the period.
class ConversationAnalyticsRow {
  /// Creates a row.
  const ConversationAnalyticsRow({
    required this.key,
    required this.accountId,
    required this.platform,
    required this.received,
    required this.sent,
    required this.answered,
    required this.open,
    this.medianResponseMinutes,
    this.firstMessageAt,
    this.lastMessageAt,
  });

  /// Reads a row.
  factory ConversationAnalyticsRow.fromJson(Map<String, dynamic> json) =>
      ConversationAnalyticsRow(
        key: asString(json['key']) ?? '',
        accountId: asString(json['accountId'] ?? json['account_id']) ?? '',
        platform: asString(json['platform']) ?? '',
        received: asInt(json['received']) ?? 0,
        sent: asInt(json['sent']) ?? 0,
        answered: asInt(json['answered']) ?? 0,
        open: asInt(json['open']) ?? 0,
        medianResponseMinutes: asInt(
            json['medianResponseMinutes'] ?? json['median_response_minutes']),
        firstMessageAt:
            asDate(json['firstMessageAt'] ?? json['first_message_at']),
        lastMessageAt: asDate(json['lastMessageAt'] ?? json['last_message_at']),
      );

  /// An opaque, stable handle for the thread, not the id or handle the inbox
  /// groups on: that would be a person, and this reads under the `analytics`
  /// scope. Use it to line the same thread up between two calls.
  final String key;

  /// The connected account the thread arrived on.
  final String accountId;

  /// The network the thread is on.
  final String platform;

  /// How many messages came in.
  final int received;

  /// How many went out.
  final int sent;

  /// How many inbound messages were answered.
  final int answered;

  /// How many are still open.
  final int open;

  /// Median minutes to the first reply; null when nothing was answered.
  final int? medianResponseMinutes;

  /// When the thread started, inside the period.
  final DateTime? firstMessageAt;

  /// When it last moved.
  final DateTime? lastMessageAt;

  @override
  String toString() => 'ConversationAnalyticsRow($platform, $received in)';
}

/// One page of per-thread inbox numbers.
class ConversationAnalytics {
  /// Creates a page.
  const ConversationAnalytics({
    required this.conversations,
    required this.total,
    required this.page,
    required this.perPage,
  });

  /// Reads a page.
  factory ConversationAnalytics.fromJson(Map<String, dynamic> json) =>
      ConversationAnalytics(
        conversations: asModelList<ConversationAnalyticsRow>(
            json['conversations'], ConversationAnalyticsRow.fromJson),
        total: asInt(json['total']) ?? 0,
        page: asInt(json['page']) ?? 1,
        perPage: asInt(json['perPage'] ?? json['per_page']) ?? 25,
      );

  /// The threads on this page.
  final List<ConversationAnalyticsRow> conversations;

  /// How many threads match in total.
  final int total;

  /// The page this response is.
  final int page;

  /// How many rows a full page holds.
  final int perPage;

  @override
  String toString() => 'ConversationAnalytics($total threads)';
}
