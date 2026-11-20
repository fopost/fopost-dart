import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/video_edit.dart';
import 'base.dart';

/// Video edits: trim, cut, subtitles, clips, voiceover and more, run as a
/// background job on a library video. Reachable with the `posts` scope; an
/// operation that uses AI also needs the `ai` scope.
///
/// Reach it as `client.videoEdits`.
class VideoEditsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  VideoEditsResource(this._http);

  final FoPostHttp _http;

  /// Returns every operation, whether it can run now, and whether it uses AI.
  Future<List<VideoEditOp>> ops() async {
    final rows = await _http.objects('GET', '/video-edits/ops');
    return rows.map(VideoEditOp.fromJson).toList();
  }

  /// Returns recent edit jobs in [workspaceId], or of the video [mediaId].
  /// Pass at least one of the two.
  Future<List<VideoEdit>> list({
    String? workspaceId,
    String? mediaId,
    int? limit,
  }) async {
    final rows = await _http.objects('GET', '/video-edits', query: {
      'workspace_id': workspaceId,
      'media_id': mediaId,
      'limit': limit,
    });
    return rows.map(VideoEdit.fromJson).toList();
  }

  /// Queues up to 10 [operations] on the video [mediaId]. The job comes back
  /// queued; poll [get] for the result.
  ///
  /// ```dart
  /// final job = await client.videoEdits.create(
  ///   mediaId: videoId,
  ///   operations: [
  ///     VideoEditOperation('trim', {'start': 2, 'end': 12}),
  ///     VideoEditOperation('denoise'),
  ///   ],
  /// );
  /// ```
  Future<VideoEdit> create({
    required String mediaId,
    required List<VideoEditOperation> operations,
    String? workspaceId,
  }) async =>
      VideoEdit.fromJson(await _http.object(
        'POST',
        '/video-edits',
        body: pruned({
          'workspace_id': workspaceId,
          'media_id': mediaId,
          'operations': operations.map((o) => o.toJson()).toList(),
        }),
      ));

  /// Returns one edit job.
  Future<VideoEdit> get(String id, {String? workspaceId}) async =>
      VideoEdit.fromJson(await _http.object(
        'GET',
        '/video-edits/${segment(id)}',
        query: {'workspace_id': workspaceId},
      ));
}
