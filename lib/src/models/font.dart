import '../json.dart';

/// One file of a library font: a weight, style and character subset.
class FontFile {
  /// Creates a font file.
  const FontFile({
    required this.path,
    this.subset,
    this.weight,
    this.style,
    this.unicodeRange,
  });

  /// Reads a font file.
  factory FontFile.fromJson(Map<String, dynamic> json) => FontFile(
        path: asString(json['path']) ?? '',
        subset: asString(json['subset']),
        weight: asInt(json['weight']),
        style: asString(json['style']),
        unicodeRange: asString(json['unicode_range']),
      );

  /// Where the file is served from.
  final String path;

  /// The character subset, e.g. `latin`.
  final String? subset;

  /// The weight, 100 to 1000.
  final int? weight;

  /// `normal` or `italic`.
  final String? style;

  /// The CSS `unicode-range` the file covers.
  final String? unicodeRange;

  @override
  String toString() => 'FontFile($path)';
}

/// A font every workspace can use.
class LibraryFont {
  /// Creates a library font.
  const LibraryFont({
    required this.slug,
    required this.family,
    this.category,
    this.scripts = const [],
    this.weights = const [],
    this.files = const [],
  });

  /// Reads a library font.
  factory LibraryFont.fromJson(Map<String, dynamic> json) => LibraryFont(
        slug: asString(json['slug']) ?? '',
        family: asString(json['family']) ?? '',
        category: asString(json['category']),
        scripts: asStringList(json['scripts']),
        weights: json['weights'] is List
            ? (json['weights'] as List).map(asInt).whereType<int>().toList()
            : const [],
        files: asModelList(json['files'], FontFile.fromJson),
      );

  /// The font's stable id.
  final String slug;

  /// The family name a design's text layer refers to.
  final String family;

  /// The font's category, e.g. `sans-serif`.
  final String? category;

  /// The writing systems the font covers.
  final List<String> scripts;

  /// The weights available.
  final List<int> weights;

  /// The font's files.
  final List<FontFile> files;

  @override
  String toString() => 'LibraryFont($family)';
}

/// A font a workspace uploaded.
class UploadedFont {
  /// Creates an uploaded font.
  const UploadedFont({
    required this.id,
    required this.family,
    this.style,
    this.weight,
    this.format,
    this.fileUrl,
    this.createdAt,
  });

  /// Reads an uploaded font.
  factory UploadedFont.fromJson(Map<String, dynamic> json) => UploadedFont(
        id: asString(json['id']) ?? '',
        family: asString(json['family']) ?? '',
        style: asString(json['style']),
        weight: asInt(json['weight']),
        format: asString(json['format']),
        fileUrl: asString(json['file_url']),
        createdAt: asDate(json['created_at']),
      );

  /// The font's id.
  final String id;

  /// The family name a design's text layer refers to.
  final String family;

  /// `normal` or `italic`.
  final String? style;

  /// The weight, 100 to 1000.
  final int? weight;

  /// The file format, e.g. `woff2`.
  final String? format;

  /// A URL that serves the font file.
  final String? fileUrl;

  /// When the font was uploaded.
  final DateTime? createdAt;

  @override
  String toString() => 'UploadedFont($family)';
}

/// The fonts available to a workspace.
class FontList {
  /// Creates the list.
  const FontList({required this.library, required this.uploaded});

  /// Reads the list.
  factory FontList.fromJson(Map<String, dynamic> json) => FontList(
        library: asModelList(json['library'], LibraryFont.fromJson),
        uploaded: asModelList(json['uploaded'], UploadedFont.fromJson),
      );

  /// The shared font library.
  final List<LibraryFont> library;

  /// The workspace's own uploads; empty when no workspace was given.
  final List<UploadedFont> uploaded;

  @override
  String toString() =>
      'FontList(${library.length} library, ${uploaded.length} uploaded)';
}
