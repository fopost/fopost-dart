import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/queue.dart';
import 'base.dart';

/// The posting queue: recurring slots a post lands in when it is created
/// with `schedule: 'queue'`.
///
/// Reach it as `client.queue`.
class QueueResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  QueueResource(this._http);

  final FoPostHttp _http;

  /// Returns a workspace's slots.
  Future<List<QueueSlot>> slots({required String workspaceId}) async {
    final rows = await _http
        .objects('GET', '/queue/slots', query: {'workspace_id': workspaceId});
    return rows.map(QueueSlot.fromJson).toList();
  }

  /// Adds a slot. [weekday] is 0 = Sunday through 6 = Saturday, [time] is
  /// `HH:MM` in [timezone]. Omit [accountId] for a slot every account shares.
  Future<QueueSlot> createSlot({
    required String workspaceId,
    required int weekday,
    required String time,
    required String timezone,
    String? accountId,
  }) async =>
      QueueSlot.fromJson(await _http.object(
        'POST',
        '/queue/slots',
        body: pruned({
          'workspace_id': workspaceId,
          'account_id': accountId,
          'weekday': weekday,
          'time': time,
          'timezone': timezone,
        }),
      ));

  /// Changes a slot. An unset field keeps its value; [clearAccountId] makes
  /// the slot apply to every account. Posts already in the slot move with it.
  Future<QueueSlotUpdate> updateSlot(
    String id, {
    String? accountId,
    bool clearAccountId = false,
    int? weekday,
    String? time,
    String? timezone,
  }) async =>
      QueueSlotUpdate.fromJson(await _http.object(
        'PUT',
        '/queue/slots/${segment(id)}',
        body: {
          if (accountId != null || clearAccountId) 'account_id': accountId,
          if (weekday != null) 'weekday': weekday,
          if (time != null) 'time': time,
          if (timezone != null) 'timezone': timezone,
        },
      ));

  /// Removes a slot. Posts queued in it move to the next free slot.
  Future<QueueSlotDeletion> deleteSlot(String id) async =>
      QueueSlotDeletion.fromJson(
          await _http.object('DELETE', '/queue/slots/${segment(id)}'));

  /// Returns when the next queued post would go out, or null when no slot
  /// applies.
  Future<DateTime?> next({
    required String workspaceId,
    String? accountId,
  }) async {
    final body = await _http.object('GET', '/queue/next',
        query: {'workspace_id': workspaceId, 'account_id': accountId});
    return asDate(body['next']);
  }

  /// Returns the next free times, [count] of them (1-20, default 5).
  Future<List<DateTime>> preview({
    required String workspaceId,
    String? accountId,
    int? count,
  }) async {
    final body = await _http.json('GET', '/queue/preview', query: {
      'workspace_id': workspaceId,
      'account_id': accountId,
      'count': count,
    });
    if (body is! List) return const [];
    return body.map(asDate).whereType<DateTime>().toList();
  }
}
