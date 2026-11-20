import '../json.dart';

/// A design: pages of layers in one size, editable in the dashboard's Create
/// section.
class Design {
  /// Creates a design.
  const Design({
    required this.id,
    required this.name,
    required this.kind,
    this.width,
    this.height,
    this.document,
    this.thumbnailMediaId,
    this.thumbnailUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Reads a design.
  factory Design.fromJson(Map<String, dynamic> json) => Design(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        kind: asString(json['kind']) ?? '',
        width: asInt(json['width']),
        height: asInt(json['height']),
        document: asMapOrNull(json['document']),
        thumbnailMediaId: asString(json['thumbnail_media_id']),
        thumbnailUrl: asString(json['thumbnail_url']),
        createdAt: asDate(json['created_at']),
        updatedAt: asDate(json['updated_at']),
      );

  /// The design's id.
  final String id;

  /// The design's name.
  final String name;

  /// One of `story`, `post`, `carousel`, `thumbnail`, `card`, `collage`.
  final String kind;

  /// Canvas width in pixels.
  final int? width;

  /// Canvas height in pixels.
  final int? height;

  /// The design document (pages and layers), passed through as it came.
  /// Null on `designs.list`, which leaves documents out.
  final Map<String, dynamic>? document;

  /// The library asset holding the latest thumbnail, if one was rendered.
  final String? thumbnailMediaId;

  /// A URL that serves the thumbnail.
  final String? thumbnailUrl;

  /// When the design was created.
  final DateTime? createdAt;

  /// When the design last changed.
  final DateTime? updatedAt;

  @override
  String toString() => 'Design($id $kind)';
}

/// A saved version of a design.
class DesignVersion {
  /// Creates a version.
  const DesignVersion({
    required this.id,
    required this.version,
    this.document,
    this.createdAt,
  });

  /// Reads a version.
  factory DesignVersion.fromJson(Map<String, dynamic> json) => DesignVersion(
        id: asString(json['id']) ?? '',
        version: asInt(json['version']) ?? 0,
        document: asMapOrNull(json['document']),
        createdAt: asDate(json['created_at']),
      );

  /// The version's id.
  final String id;

  /// The version number, counting up from 1.
  final int version;

  /// The document at this version, present when asked for.
  final Map<String, dynamic>? document;

  /// When the version was saved.
  final DateTime? createdAt;

  @override
  String toString() => 'DesignVersion($id v$version)';
}

/// A design after an edit or a restore, with the version it saved.
class DesignChange {
  /// Creates the result.
  const DesignChange({required this.design, this.version});

  /// Reads the result from the full response body.
  factory DesignChange.fromJson(Map<String, dynamic> json) => DesignChange(
        design: Design.fromJson(asMap(json['data'])),
        version: json['version'] is Map
            ? DesignVersion.fromJson(asMap(json['version']))
            : null,
      );

  /// The design as it is now.
  final Design design;

  /// The version this change saved, or null when none was saved.
  final DesignVersion? version;

  @override
  String toString() => 'DesignChange(${design.id})';
}

/// One rendered page of a design export.
class DesignExportFile {
  /// Creates a file.
  const DesignExportFile({
    required this.mediaId,
    this.pageIndex,
    this.mimeType,
    this.previewUrl,
  });

  /// Reads a file.
  factory DesignExportFile.fromJson(Map<String, dynamic> json) =>
      DesignExportFile(
        mediaId: asString(json['media_id']) ?? '',
        pageIndex: asInt(json['page_index']),
        mimeType: asString(json['mime_type']),
        previewUrl: asString(json['preview_url']),
      );

  /// The library asset the page was rendered into.
  final String mediaId;

  /// The page it came from, counting from 0.
  final int? pageIndex;

  /// The rendered file's MIME type.
  final String? mimeType;

  /// A URL that serves the file.
  final String? previewUrl;

  @override
  String toString() => 'DesignExportFile($mediaId)';
}

/// What a design export stored in the media library.
class DesignExport {
  /// Creates the result.
  const DesignExport({required this.format, required this.files});

  /// Reads the result.
  factory DesignExport.fromJson(Map<String, dynamic> json) => DesignExport(
        format: asString(json['format']) ?? '',
        files: asModelList(json['files'], DesignExportFile.fromJson),
      );

  /// One of `png`, `jpg`, `pdf`, `mp4`, `gif`.
  final String format;

  /// The stored files, one per rendered page (one for a PDF or a video).
  final List<DesignExportFile> files;

  @override
  String toString() => 'DesignExport($format, ${files.length} files)';
}

/// A post that used media exported from a design, with its metrics.
class DesignPost {
  /// Creates a post summary.
  const DesignPost({
    required this.id,
    required this.status,
    this.title,
    this.text,
    this.scheduleAt,
    this.publishedAt,
    this.platforms = const [],
    this.engagement,
    this.views,
  });

  /// Reads a post summary.
  factory DesignPost.fromJson(Map<String, dynamic> json) => DesignPost(
        id: asString(json['id']) ?? '',
        status: asString(json['status']) ?? '',
        title: asString(json['title']),
        text: asString(json['text']),
        scheduleAt: asDate(json['schedule_at']),
        publishedAt: asDate(json['published_at']),
        platforms: asStringList(json['platforms']),
        engagement: asInt(json['engagement']),
        views: asInt(json['views']),
      );

  /// The post's id.
  final String id;

  /// The post's status, e.g. `scheduled` or `published`.
  final String status;

  /// The post's title, if it has one.
  final String? title;

  /// The post's first text.
  final String? text;

  /// When the post is scheduled for.
  final DateTime? scheduleAt;

  /// When the post went out.
  final DateTime? publishedAt;

  /// The networks the post targets.
  final List<String> platforms;

  /// Total engagement, when measured.
  final int? engagement;

  /// Total views, when measured.
  final int? views;

  @override
  String toString() => 'DesignPost($id $status)';
}

/// A heading and a body, one slide's worth of text.
class SlideText {
  /// Creates the text.
  const SlideText({required this.heading, required this.body});

  /// Reads the text.
  factory SlideText.fromJson(Map<String, dynamic> json) => SlideText(
        heading: asString(json['heading']) ?? '',
        body: asString(json['body']) ?? '',
      );

  /// The slide's heading.
  final String heading;

  /// The slide's body text.
  final String body;

  @override
  String toString() => 'SlideText($heading)';
}

/// Long text split into carousel slides, plus the brand to style them with.
class SlideOutline {
  /// Creates the outline.
  const SlideOutline({
    required this.coverTitle,
    required this.coverSubtitle,
    required this.slides,
    required this.cta,
    this.brandColors = const [],
    this.headingFont,
    this.bodyFont,
    this.logoMediaId,
  });

  /// Reads the outline.
  factory SlideOutline.fromJson(Map<String, dynamic> json) {
    final cover = asMap(json['cover']);
    final brand = asMap(json['brand']);
    final fonts = asMap(brand['fonts']);
    return SlideOutline(
      coverTitle: asString(cover['title']) ?? '',
      coverSubtitle: asString(cover['subtitle']) ?? '',
      slides: asModelList(json['slides'], SlideText.fromJson),
      cta: SlideText.fromJson(asMap(json['cta'])),
      brandColors: asStringList(brand['colors']),
      headingFont: asString(fonts['heading']),
      bodyFont: asString(fonts['body']),
      logoMediaId: asString(brand['logo_media_id']),
    );
  }

  /// The cover slide's title.
  final String coverTitle;

  /// The cover slide's subtitle.
  final String coverSubtitle;

  /// The content slides, in order.
  final List<SlideText> slides;

  /// The closing call-to-action slide.
  final SlideText cta;

  /// The brand's colors, as hex strings.
  final List<String> brandColors;

  /// The brand's heading font family.
  final String? headingFont;

  /// The brand's body font family.
  final String? bodyFont;

  /// The brand's logo asset.
  final String? logoMediaId;

  @override
  String toString() => 'SlideOutline(${slides.length} slides)';
}
