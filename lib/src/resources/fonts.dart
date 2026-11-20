import 'package:meta/meta.dart';

import '../file.dart';
import '../http.dart';
import '../models/font.dart';
import 'base.dart';

/// Fonts for designs: the shared library plus a workspace's own uploads.
/// Reachable with the `posts` scope.
///
/// Reach it as `client.fonts`.
class FontsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  FontsResource(this._http);

  final FoPostHttp _http;

  /// Returns the font library and, with [workspaceId], that workspace's
  /// uploaded fonts.
  Future<FontList> list({String? workspaceId}) async =>
      FontList.fromJson(await _http
          .object('GET', '/fonts', query: {'workspace_id': workspaceId}));

  /// Uploads a font file (TTF, OTF, WOFF or WOFF2, up to 5 MB) to a
  /// workspace.
  ///
  /// [family] defaults to the file name, [weight] (100-1000) to 400 and
  /// [style] (`normal` or `italic`) to `normal`.
  ///
  /// ```dart
  /// final font = await client.fonts.upload(
  ///   workspaceId,
  ///   FoPostFile(filename: 'Brand.woff2', bytes: bytes),
  ///   family: 'Brand Sans',
  /// );
  /// ```
  Future<UploadedFont> upload(
    String workspaceId,
    FoPostFile file, {
    String? family,
    int? weight,
    String? style,
  }) async {
    final body = await _http.multipart(
      '/fonts',
      fields: {
        'workspace_id': workspaceId,
        'family': family ?? '',
        'weight': weight?.toString() ?? '',
        'style': style ?? '',
      },
      files: [file],
      fileField: 'file',
    );
    return UploadedFont.fromJson(
        body is Map ? Map<String, dynamic>.from(body) : const {});
  }

  /// Deletes an uploaded font.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/fonts/${segment(id)}');
}
