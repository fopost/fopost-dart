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
  factory MediaLibraryItem.fromJson(Map<String, dynamic> json) => MediaLibraryItem(
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
