import 'dart:typed_data';

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
    final rows = await _http
        .objects('GET', '/media', query: {'workspaceId': workspaceId});
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
      throw ArgumentError.value(
          files, 'files', 'at least one file is required');
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

  /// Reserves a presigned slot for one file, to be filled with a direct `PUT`.
  ///
  /// [size] is the exact byte count that will be sent, at most 50 MB.
  Future<PresignedUpload> presign({
    required String workspaceId,
    required String filename,
    required String mimeType,
    required int size,
  }) async {
    final body = await _http.object('POST', '/media/presign', body: {
      'workspaceId': workspaceId,
      'filename': filename,
      'mimeType': mimeType,
      'size': size,
    });
    return PresignedUpload.fromJson(body);
  }

  /// Turns a filled presigned slot into a library asset.
  Future<UploadedMedia> complete(String uploadId) async {
    final body = await _http.object(
      'POST',
      '/media/presign/${Uri.encodeComponent(uploadId)}/complete',
    );
    return UploadedMedia.fromJson(body);
  }

  /// Stores one file through a presigned direct upload: presigns, `PUT`s the
  /// bytes straight to storage, then completes.
  ///
  /// ```dart
  /// final asset = await client.media.uploadDirect(
  ///   workspaceId,
  ///   'chart.png',
  ///   'image/png',
  ///   bytes,
  /// );
  /// ```
  Future<UploadedMedia> uploadDirect(
    String workspaceId,
    String filename,
    String mimeType,
    Uint8List data,
  ) async {
    final slot = await presign(
      workspaceId: workspaceId,
      filename: filename,
      mimeType: mimeType,
      size: data.length,
    );
    await _http.putBytes(
      Uri.parse(slot.uploadUrl),
      data,
      // http sets Content-Length from the body, matching the presigned size.
      headers: slot.headers,
    );
    return complete(slot.uploadId);
  }

  /// Removes an asset from the library.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/media/${Uri.encodeComponent(id)}');
}
