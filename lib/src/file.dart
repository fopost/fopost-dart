import 'dart:convert';
import 'dart:typed_data';

/// One file for a multipart upload.
///
/// The bytes are held in memory so a retried request can replay them byte for
/// byte, and so the SDK stays pure Dart — read them however your platform
/// prefers:
///
/// ```dart
/// // Dart VM, Flutter iOS/Android/desktop
/// final file = FoPostFile(
///   filename: 'chart.png',
///   bytes: await File('chart.png').readAsBytes(),
/// );
/// ```
///
/// The API detects the media type from the bytes, so there is nothing to
/// declare here.
class FoPostFile {
  /// Creates a file from its bytes.
  FoPostFile({required this.filename, required List<int> bytes})
      : bytes = Uint8List.fromList(bytes);

  /// Creates a file from text, e.g. a CSV built in memory.
  factory FoPostFile.fromString(String filename, String contents) =>
      FoPostFile(filename: filename, bytes: utf8.encode(contents));

  /// The name the API stores the asset under.
  final String filename;

  /// The file's contents.
  final Uint8List bytes;
}
