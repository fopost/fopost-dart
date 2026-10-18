import '../json.dart';

/// One recurring posting slot: a weekday and a time in a zone.
class QueueSlot {
  /// Creates a slot.
  const QueueSlot({
    required this.id,
    required this.workspaceId,
    required this.weekday,
    required this.time,
    required this.timezone,
    this.accountId,
    this.createdAt,
  });

  /// Reads a slot.
  factory QueueSlot.fromJson(Map<String, dynamic> json) => QueueSlot(
        id: asString(json['id']) ?? '',
        workspaceId: asString(json['workspace_id']) ?? '',
        accountId: asString(json['account_id']),
        weekday: asInt(json['weekday']) ?? 0,
        time: asString(json['time']) ?? '',
        timezone: asString(json['timezone']) ?? '',
        createdAt: asDate(json['created_at']),
      );

  /// The slot's id.
  final String id;

  /// The workspace the slot belongs to.
  final String workspaceId;

  /// The account the slot is for, or null when it applies to every account.
  final String? accountId;

  /// 0 = Sunday through 6 = Saturday.
  final int weekday;

  /// `HH:MM`, 24-hour, in [timezone].
  final String time;

  /// The IANA zone [time] is read in.
  final String timezone;

  /// When the slot was created.
  final DateTime? createdAt;

  @override
  String toString() => 'QueueSlot($weekday $time $timezone)';
}

/// A queued post moved to a new time because a slot changed.
class QueueMove {
  /// Creates a move.
  const QueueMove({required this.id, this.from, this.to});

  /// Reads a move.
  factory QueueMove.fromJson(Map<String, dynamic> json) => QueueMove(
        id: asString(json['id']) ?? '',
        from: asDate(json['from']),
        to: asDate(json['to']),
      );

  /// The post that moved.
  final String id;

  /// When it was scheduled before.
  final DateTime? from;

  /// When it is scheduled now.
  final DateTime? to;

  @override
  String toString() => 'QueueMove($id)';
}

/// A slot after an edit, with the posts the edit moved.
class QueueSlotUpdate {
  /// Creates the result.
  const QueueSlotUpdate({required this.slot, required this.moved});

  /// Reads the result.
  factory QueueSlotUpdate.fromJson(Map<String, dynamic> json) =>
      QueueSlotUpdate(
        slot: QueueSlot.fromJson(json),
        moved: asModelList(json['moved'], QueueMove.fromJson),
      );

  /// The slot as it is now.
  final QueueSlot slot;

  /// Queued posts moved to a new slot because of the change.
  final List<QueueMove> moved;

  @override
  String toString() => 'QueueSlotUpdate(${moved.length} moved)';
}

/// What removing a slot did.
class QueueSlotDeletion {
  /// Creates the result.
  const QueueSlotDeletion({required this.deleted, required this.moved});

  /// Reads the result.
  factory QueueSlotDeletion.fromJson(Map<String, dynamic> json) =>
      QueueSlotDeletion(
        deleted: asBool(json['deleted']) ?? false,
        moved: asModelList(json['moved'], QueueMove.fromJson),
      );

  /// Whether the slot was removed.
  final bool deleted;

  /// Queued posts moved to another slot.
  final List<QueueMove> moved;

  @override
  String toString() => 'QueueSlotDeletion(${moved.length} moved)';
}
