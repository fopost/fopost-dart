import 'dart:convert';
import 'dart:typed_data';

/// One file for an upload, held as bytes or opened as a stream.
///
/// Bytes keep the SDK pure Dart and let a retried request replay them byte
/// for byte. For a large file, [FoPostFile.stream] takes a function that
/// opens a fresh stream of a known length, so the file is never held in
/// memory and every retry can reopen it:
///
/// ```dart
/// // Dart VM, Flutter iOS/Android/desktop
/// final small = FoPostFile(
///   filename: 'chart.png',
///   mimeType: 'image/png',
///   bytes: await File('chart.png').readAsBytes(),
/// );
///
/// final clip = File('launch.mp4');
/// final large = FoPostFile.stream(
///   filename: 'launch.mp4',
///   mimeType: 'video/mp4',
///   length: await clip.length(),
///   open: clip.openRead,
/// );
/// ```
///
/// [mimeType] is optional for `media.upload`, which detects the type from the
/// bytes, and required for a direct upload and for files on a post.
class FoPostFile {
  /// Creates a file from its bytes.
  FoPostFile({required this.filename, required List<int> bytes, this.mimeType})
      : bytes = Uint8List.fromList(bytes),
        length = bytes.length,
        _open = null;

  /// Creates a file that is read from [open] each time it is sent.
  ///
  /// [length] must be the exact byte count the stream yields.
  FoPostFile.stream({
    required this.filename,
    required Stream<List<int>> Function() open,
    required this.length,
    this.mimeType,
  })  : bytes = null,
        _open = open;

  /// Creates a file from text, e.g. a CSV built in memory.
  factory FoPostFile.fromString(String filename, String contents,
          {String? mimeType}) =>
      FoPostFile(
          filename: filename, bytes: utf8.encode(contents), mimeType: mimeType);

  /// The name the API stores the asset under.
  final String filename;

  /// The file's MIME type, e.g. `image/png`.
  final String? mimeType;

  /// The file's contents, or null when the file is stream-backed.
  final Uint8List? bytes;

  /// The file's size in bytes.
  final int length;

  final Stream<List<int>> Function()? _open;

  /// Opens a fresh stream over the contents.
  Stream<List<int>> openRead() =>
      _open != null ? _open() : Stream.value(bytes!);
}
