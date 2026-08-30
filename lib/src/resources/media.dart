import 'package:meta/meta.dart';

import '../file.dart';
import '../http.dart';
import '../models/media.dart';

/// The media library. Uploads count against the plan's storage allowance and
/// are reachable with the `posts` scope.
///
/// Reach it as `client.media`.
class MediaResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  MediaResource(this._http);

  final FoPostHttp _http;

  /// Returns a workspace's media library.
  Future<List<MediaLibraryItem>> list(String workspaceId) async {
    final rows =
        await _http.objects('GET', '/media', query: {'workspaceId': workspaceId});
    return rows.map(MediaLibraryItem.fromJson).toList();
  }

  /// Stores files in the workspace's media library.
  ///
  /// ```dart
  /// final uploaded = await client.media.upload(workspaceId, [
  ///   FoPostFile(filename: 'chart.png', bytes: bytes),
  /// ]);
  /// final block = ContentBlock(
  ///   text: 'Numbers are in',
  ///   media: [uploaded.first.toMediaItem()],
  /// );
  /// ```
  Future<List<UploadedMedia>> upload(
    String workspaceId,
    List<FoPostFile> files,
  ) async {
    if (files.isEmpty) {
      throw ArgumentError.value(files, 'files', 'at least one file is required');
    }
    final body = await _http.multipart(
      '/media/upload',
      fields: {'workspaceId': workspaceId},
      files: files,
    );
    if (body is! List) return const [];
    return body
        .whereType<Map>()
        .map((e) => UploadedMedia.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Removes an asset from the library.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/media/${Uri.encodeComponent(id)}');
}
