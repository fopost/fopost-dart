import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../file.dart';
import '../http.dart';
import '../json.dart';
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

  /// Returns what the account may upload: the per-file ceiling, the multipart
  /// ceiling, and the accepted types.
  Future<UploadLimits> limits({String? workspaceId}) async {
    final body = await _http
        .object('GET', '/media/limits', query: {'workspaceId': workspaceId});
    return UploadLimits.fromJson(body);
  }

  /// Reserves a presigned slot for one file, to be filled with a direct `PUT`.
  ///
  /// [size] is the exact byte count that will be sent, up to the account's
  /// `maxFileBytes` from [limits]. A `brandRole` of `person` needs
  /// [personConsent] with `subject` and `statement`.
  Future<PresignedUpload> presign({
    required String workspaceId,
    required String filename,
    required String mimeType,
    required int size,
    String? folderId,
    String? origin,
    String? brandRole,
    String? brandVoiceId,
    Map<String, String>? personConsent,
  }) async {
    final body = await _http.object('POST', '/media/presign',
        body: pruned({
          'workspaceId': workspaceId,
          'filename': filename,
          'mimeType': mimeType,
          'size': size,
          'folderId': folderId,
          'origin': origin,
          'brandRole': brandRole,
          'brandVoiceId': brandVoiceId,
          'personConsent': personConsent,
        }));
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
    Uint8List data, {
    String? folderId,
    String? origin,
    String? brandRole,
    String? brandVoiceId,
    Map<String, String>? personConsent,
  }) =>
      uploadDirectFile(
        workspaceId,
        FoPostFile(filename: filename, bytes: data, mimeType: mimeType),
        folderId: folderId,
        origin: origin,
        brandRole: brandRole,
        brandVoiceId: brandVoiceId,
        personConsent: personConsent,
      );

  /// Stores one [FoPostFile] through a presigned direct upload. A
  /// [FoPostFile.stream] file is streamed to storage, never buffered, so this
  /// is the route for anything over the multipart ceiling.
  ///
  /// ```dart
  /// final clip = File('launch.mp4');
  /// final asset = await client.media.uploadDirectFile(
  ///   workspaceId,
  ///   FoPostFile.stream(
  ///     filename: 'launch.mp4',
  ///     mimeType: 'video/mp4',
  ///     length: await clip.length(),
  ///     open: clip.openRead,
  ///   ),
  /// );
  /// ```
  Future<UploadedMedia> uploadDirectFile(
    String workspaceId,
    FoPostFile file, {
    String? folderId,
    String? origin,
    String? brandRole,
    String? brandVoiceId,
    Map<String, String>? personConsent,
  }) async {
    final mimeType = file.mimeType;
    if (mimeType == null || mimeType.isEmpty) {
      throw ArgumentError.value(
          file, 'file', 'a direct upload needs the file\'s mimeType');
    }
    final slot = await presign(
      workspaceId: workspaceId,
      filename: file.filename,
      mimeType: mimeType,
      size: file.length,
      folderId: folderId,
      origin: origin,
      brandRole: brandRole,
      brandVoiceId: brandVoiceId,
      personConsent: personConsent,
    );
    // Content-Length comes from the file's length, matching the presigned size.
    await _http.putFile(Uri.parse(slot.uploadUrl), file, headers: slot.headers);
    return complete(slot.uploadId);
  }

  /// Removes an asset from the library.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/media/${Uri.encodeComponent(id)}');
}
