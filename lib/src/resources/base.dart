import '../models/common.dart';

/// Escapes an id for use in a path segment.
String segment(String value) => Uri.encodeComponent(value);

/// Normalizes whatever a caller passed as `content` into the block list the
/// API expects.
///
/// Accepts a `String` (a single post), a [ContentBlock], a raw `Map`, or an
/// `Iterable` of any of those (a thread).
List<Map<String, dynamic>> encodeContent(Object content) {
  if (content is String) return [ContentBlock(text: content).toJson()];
  if (content is ContentBlock) return [content.toJson()];
  if (content is Map<String, dynamic>) return [content];
  if (content is Iterable) {
    return content.map(_encodeBlock).toList();
  }
  throw ArgumentError.value(
    content,
    'content',
    'expected a String, a ContentBlock, a Map, or an Iterable of those',
  );
}

Map<String, dynamic> _encodeBlock(Object? block) {
  if (block is String) return ContentBlock(text: block).toJson();
  if (block is ContentBlock) return block.toJson();
  if (block is Map) return Map<String, dynamic>.from(block);
  throw ArgumentError.value(
    block,
    'content',
    'expected a String, a ContentBlock, or a Map',
  );
}
