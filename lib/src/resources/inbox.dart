import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/common.dart';
import '../models/inbox.dart';
import 'base.dart';

/// The inbox: comments, mentions, reviews and direct messages on connected
/// accounts.
///
/// Every call needs the `inbox` scope. Reach it as `client.inbox`.
class InboxResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  InboxResource(this._http);

  final FoPostHttp _http;

  /// Returns one page of items, newest first unless [sort] says otherwise.
  ///
  /// [type] is one of [InboxItemType], [state] one of [InboxItemState],
  /// [sort] one of [InboxSort]. `meta.total` and `meta.perPage` are set.
  Future<Page<InboxItem>> list({
    String? workspaceId,
    String? type,
    String? state,
    String? platform,
    String? accountId,
    String? postId,
    String? postExternalId,
    String? conversationId,
    String? direction,
    String? q,
    String? sort,
    int? page,
    int? perPage,
  }) =>
      _page('/inbox', InboxItem.fromJson, {
        'workspace_id': workspaceId,
        'type': type,
        'state': state,
        'platform': platform,
        'account_id': accountId,
        'post_id': postId,
        'post_external_id': postExternalId,
        'conversation_id': conversationId,
        'direction': direction,
        'q': q,
        'sort': sort,
        'page': page,
        'per_page': perPage,
      });

  /// Returns one row per post with comments; pass `kind: 'mentions'` for the
  /// posts the account was tagged in, or `kind: 'reviews'` for one row per
  /// review left on the business.
  Future<Page<InboxThread>> threads({
    String? workspaceId,
    String? kind,
    String? platform,
    String? accountId,
    String? state,
    String? q,
    String? sort,
    int? page,
    int? perPage,
  }) =>
      _page('/inbox/posts', InboxThread.fromJson, {
        'workspace_id': workspaceId,
        'kind': kind,
        'platform': platform,
        'account_id': accountId,
        'state': state,
        'q': q,
        'sort': sort,
        'page': page,
        'per_page': perPage,
      });

  /// Returns one row per direct-message thread, latest first.
  Future<Page<InboxConversation>> conversations({
    String? workspaceId,
    String? platform,
    String? accountId,
    String? state,
    String? q,
    String? sort,
    int? page,
    int? perPage,
  }) =>
      _page('/inbox/conversations', InboxConversation.fromJson, {
        'workspace_id': workspaceId,
        'platform': platform,
        'account_id': accountId,
        'state': state,
        'q': q,
        'sort': sort,
        'page': page,
        'per_page': perPage,
      });

  /// How many items are unread.
  Future<int> unreadCount({String? workspaceId}) async {
    final body = await _http.raw('GET', '/inbox/unread-count',
        query: {'workspace_id': workspaceId});
    return asInt(asMap(body)['count']) ?? 0;
  }

  /// Every active account, flagged with whether comments and DMs can be read
  /// for it.
  Future<List<InboxAccount>> accounts({String? workspaceId}) async {
    final rows = await _http.objects('GET', '/inbox/accounts',
        query: {'workspace_id': workspaceId});
    return rows.map(InboxAccount.fromJson).toList();
  }

  /// What the inbox supports on each network.
  Future<List<InboxPlatform>> platforms() async {
    final rows = await _http.objects('GET', '/inbox/platforms');
    return rows.map(InboxPlatform.fromJson).toList();
  }

  /// Marks a whole comment thread ([postExternalId]) or DM thread
  /// ([conversationId]) read. Returns how many items changed.
  Future<int> markThreadRead({
    required String workspaceId,
    required String accountId,
    String? postExternalId,
    String? conversationId,
  }) async {
    final body = pruned({
      'workspace_id': workspaceId,
      'account_id': accountId,
      'post_external_id': postExternalId,
      'conversation_id': conversationId,
    });
    final result = await _http.object('POST', '/inbox/read', body: body);
    return asInt(result['updated']) ?? 0;
  }

  /// Polls every inbox-capable account in the workspace now.
  Future<InboxRefreshResult> refresh({required String workspaceId}) async =>
      InboxRefreshResult.fromJson(await _http.object('POST', '/inbox/refresh',
          body: {'workspace_id': workspaceId}));

  /// Lists the replies an automation or the agent drafted that a person still
  /// has to send.
  Future<List<InboxApproval>> listApprovals({String? workspaceId}) async {
    final rows = await _http.objects('GET', '/inbox/approvals',
        query: {'workspace_id': workspaceId});
    return rows.map(InboxApproval.fromJson).toList();
  }

  /// Sends a drafted reply, or [text] in its place.
  Future<InboxDecision> approveReply(int approvalId, {String? text}) async =>
      InboxDecision.fromJson(await _http.object(
        'POST',
        '/inbox/approvals/$approvalId/approve',
        body: pruned({'text': text}),
      ));

  /// Discards a drafted reply.
  Future<InboxDecision> rejectReply(int approvalId) async =>
      InboxDecision.fromJson(
          await _http.object('POST', '/inbox/approvals/$approvalId/reject'));

  /// Moves an item to [state], one of [InboxItemState]. A `snoozed` item
  /// resurfaces at [snoozedUntil].
  Future<InboxItem> update(
    String id, {
    required String state,
    DateTime? snoozedUntil,
  }) async {
    final body = pruned({
      'state': state,
      'snoozedUntil': snoozedUntil?.toUtc().toIso8601String(),
    });
    return InboxItem.fromJson(
        await _http.object('PATCH', '/inbox/${segment(id)}', body: body));
  }

  /// Edits our own comment on the platform to [text].
  ///
  /// Needs the `publish` scope; only where [InboxItem.canEdit] is true.
  Future<InboxItem> editComment(String id, String text) async =>
      InboxItem.fromJson(await _http
          .object('PATCH', '/inbox/${segment(id)}', body: {'text': text}));

  /// Sends [text] as a reply on the platform, as the connected account.
  ///
  /// [text] may be null when [mediaIds] (media library ids, at most 10) is
  /// given. [mediaIds] and [quickReplies] (at most 13, each up to 20
  /// characters) apply to DMs and need the `publish` scope.
  Future<InboxReplyResult> reply(
    String id,
    String? text, {
    List<String>? mediaIds,
    List<String>? quickReplies,
  }) async =>
      InboxReplyResult.fromJson(await _http.object(
        'POST',
        '/inbox/${segment(id)}/reply',
        body: pruned({
          'text': text,
          'media_ids': mediaIds,
          'quick_replies': quickReplies,
        }),
      ));

  /// Hides a comment on the platform.
  Future<InboxItem> hide(String id) async => InboxItem.fromJson(
      await _http.object('POST', '/inbox/${segment(id)}/hide'));

  /// Shows a hidden comment again.
  Future<InboxItem> unhide(String id) async => InboxItem.fromJson(
      await _http.object('POST', '/inbox/${segment(id)}/unhide'));

  /// Deletes a comment, or our own reply, on the platform as well as here.
  ///
  /// Deleting our own reply needs the `publish` scope.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/inbox/${segment(id)}');

  /// Likes an item on the platform. Needs the `publish` scope.
  Future<InboxItem> like(String id) async => InboxItem.fromJson(
      await _http.object('POST', '/inbox/${segment(id)}/like'));

  /// Removes the account's like. Needs the `publish` scope.
  Future<InboxItem> unlike(String id) async => InboxItem.fromJson(
      await _http.object('POST', '/inbox/${segment(id)}/unlike'));

  /// Pins our own comment on the platform. Needs the `publish` scope.
  Future<InboxItem> pin(String id) async => InboxItem.fromJson(
      await _http.object('POST', '/inbox/${segment(id)}/pin'));

  /// Unpins our own comment. Needs the `publish` scope.
  Future<InboxItem> unpin(String id) async => InboxItem.fromJson(
      await _http.object('POST', '/inbox/${segment(id)}/unpin'));

  /// Reacts to a DM with [reaction], an emoji of at most 32 characters, or
  /// removes ours when it is null. Needs the `publish` scope.
  Future<InboxItem> react(String id, String? reaction) async =>
      InboxItem.fromJson(await _http.object(
        'POST',
        '/inbox/${segment(id)}/react',
        // Not pruned: a null reaction means remove.
        body: {'reaction': reaction},
      ));

  /// Sends [text] as a new DM: to [handle] from [accountId], or as a private
  /// reply to the inbox comment [commentId]. [mediaIds] are media library ids,
  /// at most 10. Needs the `publish` scope.
  Future<InboxConversationStart> startConversation({
    required String text,
    String? accountId,
    String? handle,
    String? commentId,
    List<String>? mediaIds,
  }) async =>
      InboxConversationStart.fromJson(await _http.object(
        'POST',
        '/inbox/conversations',
        body: pruned({
          'account_id': accountId,
          'handle': handle,
          'comment_id': commentId,
          'text': text,
          'media_ids': mediaIds,
        }),
      ));

  /// Shows the typing indicator in the DM thread [conversationId], or clears
  /// it when [on] is false. Returns whether it is now on. Needs the `publish`
  /// scope.
  Future<bool> setTyping(
    String conversationId, {
    required String accountId,
    bool? on,
  }) async {
    final result = await _http.object(
      'POST',
      '/inbox/conversations/${segment(conversationId)}/typing',
      body: pruned({'account_id': accountId, 'on': on}),
    );
    return asBool(result['typing']) ?? false;
  }

  Future<Page<T>> _page<T>(
    String path,
    T Function(Map<String, dynamic>) parse,
    Map<String, dynamic> query,
  ) async {
    final body = await _http.raw('GET', path, query: query);
    return Page.fromJson(body is Map<String, dynamic> ? body : {}, parse);
  }
}
