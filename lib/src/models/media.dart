import '../json.dart';
import 'common.dart';

/// One stored asset in the media library.
class MediaLibraryItem {
  /// Creates a library item.
  const MediaLibraryItem({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    this.workspaceId,
    this.mimeType,
    this.size,
    this.altText,
    this.createdAt,
  });

  /// Reads a library item.
  factory MediaLibraryItem.fromJson(Map<String, dynamic> json) =>
      MediaLibraryItem(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        url: asString(json['url']) ?? '',
        type: asString(json['type']) ?? '',
        workspaceId: asString(json['workspaceId']),
        mimeType: asString(json['mimeType']),
        size: asInt(json['size']),
        altText: asString(json['altText']),
        createdAt: asDate(json['createdAt']),
      );

  /// The asset's id.
  final String id;

  /// The asset's file name.
  final String name;

  /// Where the asset lives.
  final String url;

  /// `image`, `video`, `gif`, or `document`.
  final String type;

  /// The workspace the asset belongs to.
  final String? workspaceId;

  /// The asset's MIME type.
  final String? mimeType;

  /// The asset's size in bytes.
  final int? size;

  /// Alt text for accessibility.
  final String? altText;

  /// When it was stored.
  final DateTime? createdAt;

  /// Turns the asset into a content-block attachment.
  MediaItem toMediaItem() => MediaItem(
        type: type.isEmpty ? 'image' : type,
        name: name,
        url: url,
        size: size?.toDouble(),
        alt: altText,
      );

  @override
  String toString() => 'MediaLibraryItem($name)';
}

/// An asset as it comes back from an upload, shaped to drop straight into a
/// post's content block.
class UploadedMedia {
  /// Creates an uploaded asset.
  const UploadedMedia({
    required this.id,
    required this.type,
    required this.name,
    required this.url,
    this.size,
  });

  /// Reads an uploaded asset.
  factory UploadedMedia.fromJson(Map<String, dynamic> json) => UploadedMedia(
        id: asString(json['id']) ?? '',
        type: asString(json['type']) ?? 'image',
        name: asString(json['name']) ?? '',
        url: asString(json['url']) ?? '',
        size: asInt(json['size']),
      );

  /// The asset's id.
  final String id;

  /// `image`, `video`, or `gif`.
  final String type;

  /// The asset's file name.
  final String name;

  /// Where the asset lives.
  final String url;

  /// The asset's size in bytes.
  final int? size;

  /// Turns the asset into a content-block attachment.
  MediaItem toMediaItem() =>
      MediaItem(type: type, name: name, url: url, size: size?.toDouble());

  @override
  String toString() => 'UploadedMedia($name)';
}

/// A presigned direct-upload slot from `POST /media/presign`.
///
/// `PUT` the file's bytes to [uploadUrl] with exactly [headers] and a
/// `Content-Length` equal to the declared size, without an API key, then call
/// `client.media.complete(uploadId)` before [expiresAt].
class PresignedUpload {
  /// Creates a presigned upload.
  const PresignedUpload({
    required this.uploadId,
    required this.uploadUrl,
    required this.method,
    required this.headers,
    this.expiresAt,
  });

  /// Reads a presigned upload.
  factory PresignedUpload.fromJson(Map<String, dynamic> json) {
    final raw = json['headers'];
    final headers = <String, String>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is String) headers['$key'] = value;
      });
    }
    return PresignedUpload(
      uploadId: asString(json['uploadId']) ?? '',
      uploadUrl: asString(json['uploadUrl']) ?? '',
      method: asString(json['method']) ?? 'PUT',
      headers: headers,
      expiresAt: asDate(json['expiresAt']),
    );
  }

  /// The id to pass to `complete` once the bytes are stored.
  final String uploadId;

  /// Where to send the bytes.
  final String uploadUrl;

  /// The HTTP method to use, `PUT`.
  final String method;

  /// The headers the upload request must carry, e.g. `Content-Type`.
  final Map<String, String> headers;

  /// When the slot stops accepting bytes.
  final DateTime? expiresAt;

  @override
  String toString() => 'PresignedUpload($uploadId)';
}
