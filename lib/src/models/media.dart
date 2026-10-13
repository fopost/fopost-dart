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
    this.maxFileBytes,
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
      maxFileBytes: asInt(json['maxFileBytes']),
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

  /// The largest file the account may upload.
  final int? maxFileBytes;

  @override
  String toString() => 'PresignedUpload($uploadId)';
}

/// The next upload tier an account can reach by connecting more accounts.
class UploadLimitTier {
  /// Creates a tier.
  const UploadLimitTier({this.upToAccounts, required this.maxFileBytes});

  /// Reads a tier.
  factory UploadLimitTier.fromJson(Map<String, dynamic> json) =>
      UploadLimitTier(
        upToAccounts: asInt(json['upToAccounts']),
        maxFileBytes: asInt(json['maxFileBytes']) ?? 0,
      );

  /// The connected-account count the tier runs up to; null for the top tier.
  final int? upToAccounts;

  /// The ceiling that tier grants.
  final int maxFileBytes;

  @override
  String toString() => 'UploadLimitTier($maxFileBytes)';
}

/// What an account may upload, from `GET /media/limits`.
class UploadLimits {
  /// Creates an upload-limits snapshot.
  const UploadLimits({
    required this.maxFileBytes,
    required this.source,
    required this.connectedAccounts,
    required this.largeUploadsEnabled,
    this.nextTier,
    required this.multipartMaxFileBytes,
    required this.maxFilesPerUpload,
    required this.directUploadAvailable,
    this.allowedTypes = const [],
  });

  /// Reads an upload-limits snapshot.
  factory UploadLimits.fromJson(Map<String, dynamic> json) => UploadLimits(
        maxFileBytes: asInt(json['maxFileBytes']) ?? 0,
        source: asString(json['source']) ?? '',
        connectedAccounts: asInt(json['connectedAccounts']) ?? 0,
        largeUploadsEnabled: asBool(json['largeUploadsEnabled']) ?? false,
        nextTier: json['nextTier'] is Map
            ? UploadLimitTier.fromJson(asMap(json['nextTier']))
            : null,
        multipartMaxFileBytes: asInt(json['multipartMaxFileBytes']) ?? 0,
        maxFilesPerUpload: asInt(json['maxFilesPerUpload']) ?? 0,
        directUploadAvailable: asBool(json['directUploadAvailable']) ?? false,
        allowedTypes: asStringList(json['allowedTypes']),
      );

  /// The largest file the account may upload by any route.
  final int maxFileBytes;

  /// Where the ceiling comes from: `accounts`, `add_on` or `bypass`.
  final String source;

  /// Connected accounts counted toward the tier.
  final int connectedAccounts;

  /// Whether the Large Uploads add-on is on.
  final bool largeUploadsEnabled;

  /// The next tier up, or null at the top.
  final UploadLimitTier? nextTier;

  /// The most a multipart request carries per file; larger files go direct.
  final int multipartMaxFileBytes;

  /// How many files one upload request takes.
  final int maxFilesPerUpload;

  /// Whether presigned direct uploads are available.
  final bool directUploadAvailable;

  /// The MIME types the library accepts.
  final List<String> allowedTypes;

  @override
  String toString() => 'UploadLimits($maxFileBytes, $source)';
}
