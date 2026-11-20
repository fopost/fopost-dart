import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/design.dart';
import 'base.dart';

/// Designs: stories, posts, carousels, thumbnails, cards and collages built
/// from pages of layers. Reachable with the `posts` scope.
///
/// The design document is passed through as a plain map, exactly as the
/// dashboard editor reads and writes it.
///
/// Reach it as `client.designs`.
class DesignsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  DesignsResource(this._http);

  final FoPostHttp _http;

  /// Returns a workspace's designs, newest first, without their documents.
  ///
  /// [kind] is one of `story`, `post`, `carousel`, `thumbnail`, `card`,
  /// `collage`.
  Future<List<Design>> list({
    required String workspaceId,
    String? kind,
    int? limit,
    int? offset,
  }) async {
    final rows = await _http.objects('GET', '/designs', query: {
      'workspace_id': workspaceId,
      'kind': kind,
      'limit': limit,
      'offset': offset,
    });
    return rows.map(Design.fromJson).toList();
  }

  /// Creates a design. Leaving [document] unset starts a blank one in the
  /// [kind]'s default size; [brandVoiceId] styles it with that brand.
  Future<Design> create({
    required String workspaceId,
    required String kind,
    String? name,
    Map<String, dynamic>? document,
    String? brandVoiceId,
  }) async =>
      Design.fromJson(await _http.object(
        'POST',
        '/designs',
        body: pruned({
          'workspace_id': workspaceId,
          'kind': kind,
          'name': name,
          'document': document,
          'brand_voice_id': brandVoiceId,
        }),
      ));

  /// Returns one design with its document.
  Future<Design> get(String id) async =>
      Design.fromJson(await _http.object('GET', '/designs/${segment(id)}'));

  /// Changes a design. An unset field keeps its value; [createVersion] saves
  /// the result as a new version.
  Future<DesignChange> update(
    String id, {
    String? name,
    String? kind,
    Map<String, dynamic>? document,
    bool? createVersion,
  }) async =>
      DesignChange.fromJson(asMap(await _http.raw(
        'PATCH',
        '/designs/${segment(id)}',
        body: pruned({
          'name': name,
          'kind': kind,
          'document': document,
          'create_version': createVersion,
        }),
      )));

  /// Deletes a design.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/designs/${segment(id)}');

  /// Returns a design's saved versions; [includeDocument] adds each one's
  /// document.
  Future<List<DesignVersion>> versions(
    String id, {
    bool includeDocument = false,
  }) async {
    final rows = await _http.objects('GET', '/designs/${segment(id)}/versions',
        query: {'include': includeDocument ? 'document' : null});
    return rows.map(DesignVersion.fromJson).toList();
  }

  /// Puts a saved version's document back on the design.
  Future<DesignChange> restoreVersion(String id, String versionId) async =>
      DesignChange.fromJson(asMap(await _http.raw(
        'POST',
        '/designs/${segment(id)}/versions/${segment(versionId)}/restore',
      )));

  /// Copies a design, optionally under a new [name].
  Future<Design> duplicate(String id, {String? name}) async =>
      Design.fromJson(await _http.object(
        'POST',
        '/designs/${segment(id)}/duplicate',
        body: pruned({'name': name}),
      ));

  /// Renders a design's pages into the media library.
  ///
  /// [format] is one of `png`, `jpg`, `pdf`, `mp4`, `gif`. [pageIndexes]
  /// picks pages (from 0, all by default); [durationSec] (5, 10 or 15) sets a
  /// video's length.
  Future<DesignExport> export(
    String id, {
    required String format,
    List<int>? pageIndexes,
    int? durationSec,
  }) async =>
      DesignExport.fromJson(await _http.object(
        'POST',
        '/designs/${segment(id)}/export',
        body: pruned({
          'format': format,
          'page_indexes': pageIndexes,
          'duration_sec': durationSec,
        }),
      ));

  /// Creates one copy of a design per row, each row's values filling the
  /// layers with the matching names. Up to 50 rows; [nameColumn] names each
  /// copy from that column.
  Future<List<Design>> bulk(
    String id, {
    required List<Map<String, String>> rows,
    String? nameColumn,
  }) async {
    final created = await _http.objects(
      'POST',
      '/designs/${segment(id)}/bulk',
      body: pruned({'rows': rows, 'name_column': nameColumn}),
    );
    return created.map(Design.fromJson).toList();
  }

  /// Returns the posts that used media exported from a design, with their
  /// metrics.
  Future<List<DesignPost>> posts(String id) async {
    final rows = await _http.objects('GET', '/designs/${segment(id)}/posts');
    return rows.map(DesignPost.fromJson).toList();
  }

  /// Splits long [text], or the text of the post [postId], into carousel
  /// slides. Pass one of the two.
  ///
  /// Uses AI credits; an API key needs the `ai` scope as well as `posts`.
  /// [maxSlides] is 2 to 18.
  Future<SlideOutline> textToSlides({
    required String workspaceId,
    String? text,
    String? postId,
    int? maxSlides,
    String? brandVoiceId,
  }) async =>
      SlideOutline.fromJson(await _http.object(
        'POST',
        '/designs/text-to-slides',
        body: pruned({
          'workspace_id': workspaceId,
          'text': text,
          'post_id': postId,
          'max_slides': maxSlides,
          'brand_voice_id': brandVoiceId,
        }),
      ));

  /// Creates a design from [text], or from the post [postId]. Pass one of
  /// the two.
  ///
  /// [style] is `quote` (the default), `post` or `plain`. [preset] picks a
  /// size, [accountId] shows that account's identity on a `post` style, and
  /// [carousel] splits long text across pages.
  Future<Design> fromPost({
    required String workspaceId,
    String? text,
    String? postId,
    String? style,
    String? preset,
    String? accountId,
    bool? carousel,
    String? name,
    String? brandVoiceId,
  }) async =>
      Design.fromJson(await _http.object(
        'POST',
        '/designs/from-post',
        body: pruned({
          'workspace_id': workspaceId,
          'text': text,
          'post_id': postId,
          'style': style,
          'preset': preset,
          'account_id': accountId,
          'carousel': carousel,
          'name': name,
          'brand_voice_id': brandVoiceId,
        }),
      ));
}
