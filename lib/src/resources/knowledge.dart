import 'package:meta/meta.dart';

import '../http.dart';
import '../models/knowledge.dart';
import 'base.dart';

/// The workspace knowledge base: what the workspace has told FoPost about
/// itself.
///
/// A source is an FAQ, a note, a page on your own site, or a plain-text/CSV
/// item from the media library. Retrieval over these is what grounds a drafted
/// inbox reply in your own answers instead of an invented one. Needs the
/// `inbox` scope.
///
/// Reach it as `client.knowledge`.
class KnowledgeResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  KnowledgeResource(this._http);

  final FoPostHttp _http;

  /// Returns the workspace's sources. Only a `ready` one is searched.
  Future<List<KnowledgeSource>> list({String? workspaceId}) async {
    final rows = await _http.objects('GET', '/knowledge/sources',
        query: {'workspace_id': workspaceId});
    return rows.map(KnowledgeSource.fromJson).toList();
  }

  /// Adds a source and queues it for indexing, so it comes back `pending`.
  ///
  /// [kind] is `faq`, `text`, `url` or `file`. An `faq` or `text` source needs
  /// [content], a `url` source needs [url], and a `file` source needs
  /// [mediaId] pointing at a plain-text or CSV item in the same workspace.
  Future<KnowledgeSource> create({
    required String kind,
    required String title,
    String? content,
    String? url,
    String? mediaId,
    String? brandVoiceId,
    String? workspaceId,
  }) async {
    final body = <String, dynamic>{'kind': kind, 'title': title};
    if (content != null) body['content'] = content;
    if (url != null) body['url'] = url;
    if (mediaId != null) body['media_id'] = mediaId;
    if (brandVoiceId != null) body['brand_voice_id'] = brandVoiceId;
    if (workspaceId != null) body['workspace_id'] = workspaceId;
    return KnowledgeSource.fromJson(
        await _http.object('POST', '/knowledge/sources', body: body));
  }

  /// Edits a source. Only what you pass is sent; changing the content or the
  /// URL returns the source to `pending` and re-indexes it.
  Future<KnowledgeSource> update(
    String id, {
    String? title,
    String? content,
    String? url,
    String? brandVoiceId,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (url != null) body['url'] = url;
    if (brandVoiceId != null) body['brand_voice_id'] = brandVoiceId;
    return KnowledgeSource.fromJson(await _http
        .object('PATCH', '/knowledge/sources/${segment(id)}', body: body));
  }

  /// Removes a source and every passage indexed from it.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/knowledge/sources/${segment(id)}');

  /// Reads the source again — a `url` source is re-fetched. Returns once the
  /// re-index is queued, not once it has finished.
  Future<KnowledgeSyncResult> sync(String id) async =>
      KnowledgeSyncResult.fromJson(await _http.object(
          'POST', '/knowledge/sources/${segment(id)}/sync',
          body: <String, dynamic>{}));

  /// Returns the passages closest to a question, best first. An empty list is
  /// the honest answer when nothing stored answers it. [topK] defaults to 5
  /// and caps at 20.
  Future<List<KnowledgeMatch>> search(
    String q, {
    int? topK,
    String? brandVoiceId,
    String? workspaceId,
  }) async {
    final rows = await _http.objects('GET', '/knowledge/search', query: {
      'q': q,
      'top_k': topK,
      'brand_voice_id': brandVoiceId,
      'workspace_id': workspaceId,
    });
    return rows.map(KnowledgeMatch.fromJson).toList();
  }
}
