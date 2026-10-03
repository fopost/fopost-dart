import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/broadcast.dart';
import '../models/common.dart';
import 'base.dart';

/// Broadcasts: one message into every conversation the workspace already has
/// with a segment of its contacts.
///
/// A broadcast is not a post and not a cold DM — every message lands in a
/// direct-message thread the contact already started.
///
/// Nothing is sent into a closed messaging window. Messenger and Instagram
/// take a business-initiated message only within 24 hours of the contact's
/// last one, so recipients outside it come back skipped with `window_closed`
/// and nothing is attempted — which is why the number sent is often lower than
/// the audience. Telegram, Slack, Bluesky and Reddit have no window.
///
/// Reading needs the `inbox` scope; [send] and [cancel] also need `publish`.
///
/// Reach it as `client.broadcasts`.
class BroadcastsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  BroadcastsResource(this._http);

  final FoPostHttp _http;

  /// Returns broadcasts, newest first.
  ///
  /// Omit [workspaceId] to span every workspace the key can reach; each
  /// broadcast then carries one.
  Future<Page<Broadcast>> list({
    String? workspaceId,
    String? status,
    int? page,
    int? perPage,
  }) async {
    final body = await _http.raw('GET', '/broadcasts', query: {
      'workspace_id': workspaceId,
      'status': status,
      'page': page,
      'per_page': perPage,
    });
    return _page(body, Broadcast.fromJson);
  }

  /// Returns one broadcast.
  ///
  /// A broadcast in a workspace the key cannot reach answers `404`, exactly as
  /// an id that never existed does.
  Future<Broadcast> get(String id) async => Broadcast.fromJson(
      await _http.object('GET', '/broadcasts/${segment(id)}'));

  /// Writes a broadcast without sending it.
  ///
  /// Give [scheduledAt] to have it go out on its own at that time; otherwise
  /// call [send]. An omitted [audience] means every contact in the workspace.
  Future<Broadcast> create({
    required String workspaceId,
    required String accountId,
    required String name,
    required String text,
    String? mediaId,
    AudienceFilter? audience,
    DateTime? scheduledAt,
  }) async {
    final body = pruned({
      'workspace_id': workspaceId,
      'account_id': accountId,
      'name': name,
      'text': text,
      'media_id': mediaId,
      'audience': audience?.toJson(),
      'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
    });
    return Broadcast.fromJson(
        await _http.object('POST', '/broadcasts', body: body));
  }

  /// Changes a broadcast. Only a draft or scheduled broadcast can be edited.
  Future<Broadcast> update(
    String id, {
    String? name,
    String? text,
    String? mediaId,
    AudienceFilter? audience,
    DateTime? scheduledAt,
  }) async {
    final body = pruned({
      'name': name,
      'text': text,
      'media_id': mediaId,
      'audience': audience?.toJson(),
      'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
    });
    return Broadcast.fromJson(
        await _http.object('PATCH', '/broadcasts/${segment(id)}', body: body));
  }

  /// Freezes the audience into a recipient list and starts sending.
  ///
  /// The returned `recipients` is how many contacts matched, not how many will
  /// be messaged — the messaging window decides that. Needs the `publish`
  /// scope as well as `inbox`.
  Future<BroadcastSent> send(String id) async =>
      BroadcastSent.fromJson(await _http
          .object('POST', '/broadcasts/${segment(id)}/send', body: const {}));

  /// Stops a broadcast where it stands.
  ///
  /// Anyone not yet written to stays unsent; messages already delivered are
  /// not recalled. Needs the `publish` scope.
  Future<Broadcast> cancel(String id) async => Broadcast.fromJson(await _http
      .object('POST', '/broadcasts/${segment(id)}/cancel', body: const {}));

  /// Returns one row per contact, with what became of their message.
  ///
  /// A skipped row carries its reason.
  Future<Page<BroadcastRecipient>> recipients(
    String id, {
    String? status,
    int? page,
    int? perPage,
  }) async {
    final body = await _http.raw('GET', '/broadcasts/${segment(id)}/recipients',
        query: {'status': status, 'page': page, 'per_page': perPage});
    return _page(body, BroadcastRecipient.fromJson);
  }

  /// Removes a broadcast and its recipient records.
  ///
  /// Messages already sent stay in the conversations they went to.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/broadcasts/${segment(id)}');
}

/// Drip sequences: a series of messages, each a delay after the one before,
/// walked per enrolled contact.
///
/// The messaging window applies to every step. A step that comes due outside
/// it is skipped rather than sent, and the enrollment carries on — so someone
/// can complete a sequence having received only some of its messages.
///
/// Reading needs the `inbox` scope; [enroll] and [unenroll] also need
/// `publish`.
///
/// Reach it as `client.sequences`.
class SequencesResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  SequencesResource(this._http);

  final FoPostHttp _http;

  /// Returns sequences.
  Future<Page<Sequence>> list({
    String? workspaceId,
    int? page,
    int? perPage,
  }) async {
    final body = await _http.raw('GET', '/sequences', query: {
      'workspace_id': workspaceId,
      'page': page,
      'per_page': perPage,
    });
    return _page(body, Sequence.fromJson);
  }

  /// Returns one sequence.
  Future<Sequence> get(String id) async =>
      Sequence.fromJson(await _http.object('GET', '/sequences/${segment(id)}'));

  /// Writes a sequence. Creating one enrolls nobody.
  Future<Sequence> create({
    required String workspaceId,
    required String accountId,
    required String name,
    required List<SequenceStep> steps,
    String? status,
  }) async {
    final body = pruned({
      'workspace_id': workspaceId,
      'account_id': accountId,
      'name': name,
      'steps': steps.map((s) => s.toJson()).toList(),
      'status': status,
    });
    return Sequence.fromJson(
        await _http.object('POST', '/sequences', body: body));
  }

  /// Changes a sequence.
  ///
  /// Pausing stops every enrollment from firing without ending any of them;
  /// resuming picks them up where they stood.
  Future<Sequence> update(
    String id, {
    String? name,
    List<SequenceStep>? steps,
    String? status,
  }) async {
    final body = pruned({
      'name': name,
      'steps': steps?.map((s) => s.toJson()).toList(),
      'status': status,
    });
    return Sequence.fromJson(
        await _http.object('PATCH', '/sequences/${segment(id)}', body: body));
  }

  /// Puts contacts on the sequence, by id or by audience.
  ///
  /// Re-enrolling someone restarts their walk from the first step rather than
  /// running two in parallel. Needs `publish` as well as `inbox`.
  Future<Enrolled> enroll(
    String id, {
    List<String>? contactIds,
    AudienceFilter? audience,
  }) async {
    final body = pruned({
      'contact_ids': contactIds,
      'audience': audience?.toJson(),
    });
    return Enrolled.fromJson(await _http
        .object('POST', '/sequences/${segment(id)}/enroll', body: body));
  }

  /// Takes contacts off the sequence. Nothing further fires for them.
  ///
  /// Needs the `publish` scope.
  Future<Unenrolled> unenroll(String id, List<String> contactIds) async =>
      Unenrolled.fromJson(await _http.object(
        'POST',
        '/sequences/${segment(id)}/unenroll',
        body: {'contact_ids': contactIds},
      ));

  /// Returns who is on the sequence, what step they are at, and when the next
  /// one is due.
  Future<Page<Enrollment>> enrollments(
    String id, {
    int? page,
    int? perPage,
  }) async {
    final body = await _http.raw('GET', '/sequences/${segment(id)}/enrollments',
        query: {'page': page, 'per_page': perPage});
    return _page(body, Enrollment.fromJson);
  }

  /// Removes a sequence and every enrollment on it.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/sequences/${segment(id)}');
}

/// These lists name their counters `pagination` rather than `meta`, like
/// contacts, so the envelope is re-keyed before `Page` reads it.
Page<T> _page<T>(Object? body, T Function(Map<String, dynamic>) read) {
  final envelope = body is Map<String, dynamic> ? body : const {};
  return Page<T>.fromJson(
    {'data': envelope['data'], 'meta': asMap(envelope['pagination'])},
    read,
  );
}
