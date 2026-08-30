import 'package:meta/meta.dart';

import '../file.dart';
import '../http.dart';
import '../json.dart';
import '../models/common.dart';
import '../models/post.dart';
import 'base.dart';

/// Posts, publishing, deliveries, and bulk operations.
///
/// Reach it as `client.posts`.
class PostsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  PostsResource(this._http);

  final FoPostHttp _http;

  /// Returns one page of posts.
  ///
  /// Unset filters are not sent, so the API applies its own defaults (page 1,
  /// 30 per page, newest first).
  Future<Page<Post>> list({
    int? page,
    int? perPage,
    String? workspaceId,
    String? status,
    String? search,
    String? platform,
    String? label,
    String? accountId,
    String? date,
    String? from,
    String? to,
    String? sort,
  }) async {
    final body = await _http.raw('GET', '/posts', query: {
      'page': page,
      'per_page': perPage,
      'workspace_id': workspaceId,
      'status': status,
      'search': search,
      'platform': platform,
      'label': label,
      'account_id': accountId,
      'date': date,
      'from': from,
      'to': to,
      'sort': sort,
    });
    return Page.fromJson(body is Map<String, dynamic> ? body : {}, Post.fromJson);
  }

  /// Walks every matching post, a page at a time.
  ///
  /// ```dart
  /// await for (final post in client.posts.stream(workspaceId: id)) {
  ///   print(post.id);
  /// }
  /// ```
  Stream<Post> stream({
    int? perPage,
    String? workspaceId,
    String? status,
    String? search,
    String? platform,
    String? label,
    String? accountId,
    String? date,
    String? from,
    String? to,
    String? sort,
  }) async* {
    final size = perPage ?? 30;
    var page = 1;
    while (true) {
      final result = await list(
        page: page,
        perPage: size,
        workspaceId: workspaceId,
        status: status,
        search: search,
        platform: platform,
        label: label,
        accountId: accountId,
        date: date,
        from: from,
        to: to,
        sort: sort,
      );
      for (final post in result.data) {
        yield post;
      }
      if (result.isEmpty) return;
      final lastPage = result.meta.lastPage;
      if (lastPage != null && lastPage > 0) {
        if (page >= lastPage) return;
      } else if (result.length < size) {
        return;
      }
      page++;
    }
  }

  /// Returns one post.
  Future<Post> get(String id) async =>
      Post.fromJson(await _http.object('GET', '/posts/${segment(id)}'));

  /// Composes a draft or a scheduled post.
  ///
  /// [content] takes a `String` for a single post, or a list for a thread —
  /// each entry a `String`, a [ContentBlock], or a raw map. [status] is
  /// `draft` or `scheduled`, and a scheduled post needs [scheduleAt]. To send
  /// something out now, create it and call [publish].
  Future<Post> create({
    required String workspaceId,
    required List<String> accounts,
    required Object content,
    String? contentType,
    String? artifactType,
    String? status,
    DateTime? scheduleAt,
    bool? repeatable,
    int? repeatableTimes,
    int? repeatableGap,
    String? repeatableGapUnit,
    List<String>? labels,
    String? title,
    String? internalTitle,
    String? summary,
    bool? autoPlug,
    String? autoPlugContent,
    Map<String, dynamic>? settings,
    List<String>? sourceIds,
    String? companionOf,
  }) async {
    final body = pruned({
      'workspace_id': workspaceId,
      'accounts': accounts,
      'content': encodeContent(content),
      'content_type': contentType,
      'artifact_type': artifactType,
      'status': status,
      'schedule_at': scheduleAt?.toUtc().toIso8601String(),
      'repeatable': repeatable,
      'repeatable_times': repeatableTimes,
      'repeatable_gap': repeatableGap,
      'repeatable_gap_unit': repeatableGapUnit,
      'labels': labels,
      'title': title,
      'internal_title': internalTitle,
      'summary': summary,
      'auto_plug': autoPlug,
      'auto_plug_content': autoPlugContent,
      'settings': settings,
      'source_ids': sourceIds,
      'companion_of': companionOf,
    });
    return Post.fromJson(await _http.object('POST', '/posts', body: body));
  }

  /// Edits a post that has not been published. Only the fields you pass are
  /// sent, so this is a partial update.
  Future<Post> update(
    String id, {
    List<String>? accounts,
    Object? content,
    String? contentType,
    String? artifactType,
    String? status,
    DateTime? scheduleAt,
    bool? repeatable,
    int? repeatableTimes,
    int? repeatableGap,
    String? repeatableGapUnit,
    List<String>? labels,
    String? title,
    String? internalTitle,
    String? summary,
    bool? autoPlug,
    String? autoPlugContent,
    Map<String, dynamic>? settings,
  }) async {
    final body = pruned({
      'accounts': accounts,
      'content': content == null ? null : encodeContent(content),
      'content_type': contentType,
      'artifact_type': artifactType,
      'status': status,
      'schedule_at': scheduleAt?.toUtc().toIso8601String(),
      'repeatable': repeatable,
      'repeatable_times': repeatableTimes,
      'repeatable_gap': repeatableGap,
      'repeatable_gap_unit': repeatableGapUnit,
      'labels': labels,
      'title': title,
      'internal_title': internalTitle,
      'summary': summary,
      'auto_plug': autoPlug,
      'auto_plug_content': autoPlugContent,
      'settings': settings,
    });
    return Post.fromJson(await _http.object('PUT', '/posts/${segment(id)}', body: body));
  }

  /// Removes a post.
  Future<void> delete(String id) => _http.discard('DELETE', '/posts/${segment(id)}');

  /// Copies a post into a new draft.
  Future<DuplicatedPost> duplicate(String id) async => DuplicatedPost.fromJson(
      await _http.object('POST', '/posts/${segment(id)}/duplicate'));

  /// Queues a post for immediate delivery to its accounts.
  ///
  /// Nothing reaches a platform without this call or a schedule the user set,
  /// and it returns when delivery is queued, not when it is live. Pass
  /// [dryRun] to validate the whole plan without sending anything.
  Future<PublishResult> publish(
    String id, {
    List<String>? accountIds,
    bool dryRun = false,
  }) async {
    final body = <String, dynamic>{
      if (accountIds != null && accountIds.isNotEmpty) 'accountIds': accountIds,
      if (dryRun) 'options': {'dryRun': true},
    };
    return PublishResult.fromJson(
        await _http.object('POST', '/posts/${segment(id)}/publish', body: body));
  }

  /// Re-sends the deliveries that failed, leaving successful ones alone.
  Future<RetryResult> retry(
    String id, {
    List<String>? accountIds,
    bool? includePublished,
  }) async {
    final body = pruned({
      'accountIds': accountIds,
      'includePublished': includePublished,
    });
    return RetryResult.fromJson(
        await _http.object('POST', '/posts/${segment(id)}/retry', body: body));
  }

  /// Stops the deliveries that have not gone out yet.
  Future<CancelResult> cancel(String id, {List<String>? accountIds}) async {
    final body = pruned({'accountIds': accountIds});
    return CancelResult.fromJson(
        await _http.object('POST', '/posts/${segment(id)}/cancel', body: body));
  }

  /// Checks a post against every target platform without publishing.
  Future<PreflightResult> preflight(String id) async => PreflightResult.fromJson(
      await _http.object('POST', '/posts/${segment(id)}/preflight'));

  /// Lists the current delivery record per account.
  Future<List<Delivery>> deliveries(String id) async {
    final rows = await _http.objects('GET', '/posts/${segment(id)}/deliveries');
    return rows.map(Delivery.fromJson).toList();
  }

  /// Lists every publish attempt made for a post, newest first.
  Future<List<PublishRun>> publishRuns(String id) async {
    final rows = await _http.objects('GET', '/posts/${segment(id)}/publish-runs');
    return rows.map(PublishRun.fromJson).toList();
  }

  /// Returns a post's performance across the platforms it reached.
  Future<PostAnalytics> analytics(String id) async => PostAnalytics.fromJson(
      await _http.object('GET', '/posts/${segment(id)}/analytics'));

  /// Moves a selection's schedule by [offsetMinutes], which may be negative
  /// but never zero.
  ///
  /// Only drafts and scheduled posts can be shifted, and one ineligible post
  /// in the selection changes nothing at all.
  Future<BulkResult> bulkShift({
    required String workspaceId,
    required List<String> postIds,
    required int offsetMinutes,
  }) =>
      _bulk({
        'action': 'shift',
        'workspace_id': workspaceId,
        'post_ids': postIds,
        'offset_minutes': offsetMinutes,
      });

  /// Relabels a selection.
  ///
  /// [mode] is `replace` (the default, where an empty [labelIds] clears them),
  /// `add`, or `remove`.
  Future<BulkResult> bulkLabel({
    required String workspaceId,
    required List<String> postIds,
    required List<String> labelIds,
    String? mode,
  }) =>
      _bulk(pruned({
        'action': 'label',
        'workspace_id': workspaceId,
        'post_ids': postIds,
        'label_ids': labelIds,
        'mode': mode,
      }));

  /// Removes a selection of posts in one transaction.
  Future<BulkResult> bulkDelete({
    required String workspaceId,
    required List<String> postIds,
  }) =>
      _bulk({
        'action': 'delete',
        'workspace_id': workspaceId,
        'post_ids': postIds,
      });

  Future<BulkResult> _bulk(Map<String, dynamic> body) async {
    final response = await _http.raw('POST', '/posts/bulk', body: body);
    return BulkResult.fromJson(response is Map<String, dynamic> ? response : {});
  }

  /// Checks a CSV without creating anything.
  Future<BulkImportValidation> validateBulkImport({
    required String workspaceId,
    required FoPostFile file,
  }) async {
    final body = await _http.multipart(
      '/posts/bulk-import/validate',
      fields: {'workspace_id': workspaceId},
      files: [file],
      fileField: 'file',
    );
    return BulkImportValidation.fromJson(
        body is Map<String, dynamic> ? body : <String, dynamic>{});
  }

  /// Creates the posts a CSV describes.
  Future<BulkImportResult> commitBulkImport({
    required String workspaceId,
    required FoPostFile file,
  }) async {
    final body = await _http.multipart(
      '/posts/bulk-import/commit',
      fields: {'workspace_id': workspaceId},
      files: [file],
      fileField: 'file',
    );
    return BulkImportResult.fromJson(
        body is Map<String, dynamic> ? body : <String, dynamic>{});
  }

  /// Deletes every post a committed batch created.
  Future<ApiMessage> rollbackBulkImport(String batchId) async {
    final body =
        await _http.raw('DELETE', '/posts/bulk-import/${segment(batchId)}');
    return ApiMessage.fromJson(body is Map<String, dynamic> ? body : {});
  }
}
