import '../json.dart';

/// The statuses an article moves through.
abstract final class BlogArticleStatus {
  /// Waiting for a writer slot.
  static const String queued = 'queued';

  /// Being written right now.
  static const String writing = 'writing';

  /// Written and waiting for review.
  static const String draft = 'draft';

  /// On the calendar, waiting for its `publishAt`.
  static const String scheduled = 'scheduled';

  /// Being sent to the target.
  static const String publishing = 'publishing';

  /// Live on the target.
  static const String published = 'published';

  /// Writing or publishing failed; see `error`.
  static const String failed = 'failed';

  /// Turned down in review.
  static const String rejected = 'rejected';
}

/// The statuses a keyword moves through.
abstract final class BlogKeywordStatus {
  /// Proposed by planning, not yet acted on.
  static const String suggested = 'suggested';

  /// Picked for an article, optionally on a date.
  static const String planned = 'planned';

  /// An article was written for it.
  static const String written = 'written';

  /// Set aside.
  static const String dismissed = 'dismissed';
}

/// Where published articles go.
abstract final class BlogTargetKind {
  /// The blog FoPost hosts for the workspace.
  static const String productBlog = 'product_blog';

  /// A connected account that takes long-form articles.
  static const String account = 'account';

  /// Your own site, which receives a signed `article.published` webhook.
  static const String website = 'website';
}

/// The image quality tiers an article can be illustrated at.
abstract final class BlogImageTier {
  /// Fastest and cheapest.
  static const String draft = 'draft';

  /// The default.
  static const String standard = 'standard';

  /// Highest quality.
  static const String best = 'best';
}

/// A workspace's blog configuration.
class BlogSettings {
  /// Creates settings.
  const BlogSettings({
    required this.language,
    required this.cadencePerWeek,
    required this.reviewHoldDays,
    required this.autoPublish,
    required this.hasWebsiteSecret,
    this.siteUrl,
    this.topic,
    this.audience,
    this.locationCode,
    this.imageTier,
    this.inBodyImages,
    this.minWords,
    this.maxWords,
    this.brandVoiceId,
    this.targetKind,
    this.targetAccountId,
    this.targetPlatform,
    this.websiteUrl,
    this.keywordDataAvailable,
    this.updatedAt,
  });

  /// Reads settings.
  factory BlogSettings.fromJson(Map<String, dynamic> json) => BlogSettings(
        language: asString(json['language']) ?? 'en',
        cadencePerWeek: asInt(json['cadencePerWeek']) ?? 0,
        reviewHoldDays: asInt(json['reviewHoldDays']) ?? 0,
        autoPublish: asBool(json['autoPublish']) ?? false,
        hasWebsiteSecret: asBool(json['hasWebsiteSecret']) ?? false,
        siteUrl: asString(json['siteUrl']),
        topic: asString(json['topic']),
        audience: asString(json['audience']),
        locationCode: asInt(json['locationCode']),
        imageTier: asString(json['imageTier']),
        inBodyImages: asInt(json['inBodyImages']),
        minWords: asInt(json['minWords']),
        maxWords: asInt(json['maxWords']),
        brandVoiceId: asString(json['brandVoiceId']),
        targetKind: asString(json['targetKind']),
        targetAccountId: asString(json['targetAccountId']),
        targetPlatform: asString(json['targetPlatform']),
        websiteUrl: asString(json['websiteUrl']),
        keywordDataAvailable: asBool(json['keywordDataAvailable']),
        updatedAt: asDate(json['updatedAt']),
      );

  /// The site the blog is about.
  final String? siteUrl;

  /// What the blog covers.
  final String? topic;

  /// Who it is written for.
  final String? audience;

  /// The language articles are written in.
  final String language;

  /// The location keyword data is read for.
  final int? locationCode;

  /// Articles planned per week; 0 turns planning off.
  final int cadencePerWeek;

  /// Days a draft waits for review before it may auto-publish.
  final int reviewHoldDays;

  /// Whether a reviewed draft publishes on its own.
  final bool autoPublish;

  /// One of [BlogImageTier].
  final String? imageTier;

  /// Images placed inside the body, beyond the featured one.
  final int? inBodyImages;

  /// The shortest article the writer aims for.
  final int? minWords;

  /// The longest article the writer aims for.
  final int? maxWords;

  /// The brand the writer takes its voice from.
  final String? brandVoiceId;

  /// One of [BlogTargetKind], or null when no target is set.
  final String? targetKind;

  /// The account articles go to, for the `account` target.
  final String? targetAccountId;

  /// That account's network.
  final String? targetPlatform;

  /// Where articles are POSTed, for the `website` target.
  final String? websiteUrl;

  /// Whether a website secret has been issued.
  final bool hasWebsiteSecret;

  /// Whether search volume and difficulty can be fetched on this deployment.
  final bool? keywordDataAvailable;

  /// When the settings last changed.
  final DateTime? updatedAt;

  @override
  String toString() => 'BlogSettings(${targetKind ?? 'no target'})';
}

/// The answer to a settings update.
class BlogSettingsUpdate {
  /// Creates an update result.
  const BlogSettingsUpdate({required this.settings, this.websiteSecret});

  /// Reads the `{data, websiteSecret}` response.
  factory BlogSettingsUpdate.fromJson(Map<String, dynamic> json) =>
      BlogSettingsUpdate(
        settings: BlogSettings.fromJson(asMap(json['data'])),
        websiteSecret: asString(json['websiteSecret']),
      );

  /// The settings as they now stand.
  final BlogSettings settings;

  /// The website signing secret, present only on the update that first set
  /// `websiteUrl`. Store it now; it is never shown again.
  final String? websiteSecret;

  @override
  String toString() => 'BlogSettingsUpdate($settings)';
}

/// The outcome of a test delivery to the website target.
class BlogWebsiteTest {
  /// Creates a test result.
  const BlogWebsiteTest({required this.ok, this.status, this.error});

  /// Reads a test result.
  factory BlogWebsiteTest.fromJson(Map<String, dynamic> json) =>
      BlogWebsiteTest(
        ok: asBool(json['ok']) ?? false,
        status: asInt(json['status']),
        error: asString(json['error']),
      );

  /// Whether the site answered 2xx.
  final bool ok;

  /// The HTTP status the site answered with, when it answered.
  final int? status;

  /// Why the delivery failed, when it did.
  final String? error;

  @override
  String toString() => 'BlogWebsiteTest(ok: $ok, status: $status)';
}

/// A keyword in the plan.
class BlogKeyword {
  /// Creates a keyword.
  const BlogKeyword({
    required this.id,
    required this.keyword,
    required this.source,
    required this.status,
    this.searchVolume,
    this.difficulty,
    this.cpc,
    this.intent,
    this.plannedFor,
    this.createdAt,
  });

  /// Reads a keyword.
  factory BlogKeyword.fromJson(Map<String, dynamic> json) => BlogKeyword(
        id: asString(json['id']) ?? '',
        keyword: asString(json['keyword']) ?? '',
        source: asString(json['source']) ?? '',
        status: asString(json['status']) ?? '',
        searchVolume: asInt(json['searchVolume']),
        difficulty: asInt(json['difficulty']),
        cpc: asDouble(json['cpc']),
        intent: asString(json['intent']),
        plannedFor: asString(json['plannedFor']),
        createdAt: asDate(json['createdAt']),
      );

  /// The keyword's id.
  final String id;

  /// The search term.
  final String keyword;

  /// Monthly searches, when known.
  final int? searchVolume;

  /// Ranking difficulty from 0 to 100, when known.
  final int? difficulty;

  /// Cost per click, when known.
  final double? cpc;

  /// The search intent, when known.
  final String? intent;

  /// Where it came from: `provider`, `user` or `agent`.
  final String source;

  /// One of [BlogKeywordStatus].
  final String status;

  /// The day it is planned for, as `YYYY-MM-DD`.
  final String? plannedFor;

  /// When it was added.
  final DateTime? createdAt;

  @override
  String toString() => 'BlogKeyword($keyword, $status)';
}

/// An image attached to an article.
class BlogArticleImage {
  /// Creates an image reference.
  const BlogArticleImage({
    required this.mediaId,
    required this.url,
    required this.alt,
    this.position,
  });

  /// Reads an image reference.
  factory BlogArticleImage.fromJson(Map<String, dynamic> json) =>
      BlogArticleImage(
        mediaId: asString(json['mediaId']) ?? '',
        url: asString(json['url']) ?? '',
        alt: asString(json['alt']) ?? '',
        position: asInt(json['position']),
      );

  /// The media library row behind it.
  final String mediaId;

  /// Where to fetch it; valid for six hours in a webhook, so store a copy.
  final String url;

  /// Its alt text.
  final String alt;

  /// Index of the outline heading it sits under; absent on the featured image.
  final int? position;

  @override
  String toString() => 'BlogArticleImage($mediaId)';
}

/// An article as a list shows it, without its body.
class BlogArticle {
  /// Creates an article.
  const BlogArticle({
    required this.id,
    required this.title,
    required this.slug,
    required this.tags,
    required this.wordCount,
    required this.status,
    required this.origin,
    this.keyword,
    this.excerpt,
    this.metaTitle,
    this.metaDescription,
    this.featuredImage,
    this.reviewUntil,
    this.publishAt,
    this.publishedAt,
    this.publishedUrl,
    this.error,
    this.createdAt,
    this.updatedAt,
  });

  /// Reads an article.
  factory BlogArticle.fromJson(Map<String, dynamic> json) => BlogArticle(
        id: asString(json['id']) ?? '',
        title: asString(json['title']) ?? '',
        slug: asString(json['slug']) ?? '',
        tags: asStringList(json['tags']),
        wordCount: asInt(json['wordCount']) ?? 0,
        status: asString(json['status']) ?? '',
        origin: asString(json['origin']) ?? '',
        keyword: asString(json['keyword']),
        excerpt: asString(json['excerpt']),
        metaTitle: asString(json['metaTitle']),
        metaDescription: asString(json['metaDescription']),
        featuredImage: _image(json['featuredImage']),
        reviewUntil: asDate(json['reviewUntil']),
        publishAt: asDate(json['publishAt']),
        publishedAt: asDate(json['publishedAt']),
        publishedUrl: asString(json['publishedUrl']),
        error: asString(json['error']),
        createdAt: asDate(json['createdAt']),
        updatedAt: asDate(json['updatedAt']),
      );

  /// The article's id.
  final String id;

  /// Its headline.
  final String title;

  /// Its URL slug.
  final String slug;

  /// The keyword it targets.
  final String? keyword;

  /// A short summary.
  final String? excerpt;

  /// The `<title>` to publish with.
  final String? metaTitle;

  /// The meta description to publish with.
  final String? metaDescription;

  /// The hero image.
  final BlogArticleImage? featuredImage;

  /// Its tags.
  final List<String> tags;

  /// Words in the body.
  final int wordCount;

  /// One of [BlogArticleStatus].
  final String status;

  /// Where it came from: `plan`, `user` or `agent`.
  final String origin;

  /// When the review hold ends.
  final DateTime? reviewUntil;

  /// When it is set to publish.
  final DateTime? publishAt;

  /// When it went live.
  final DateTime? publishedAt;

  /// Where it is live.
  final String? publishedUrl;

  /// Why it failed, when it did.
  final String? error;

  /// When it was requested.
  final DateTime? createdAt;

  /// When it last changed.
  final DateTime? updatedAt;

  @override
  String toString() => 'BlogArticle($slug, $status)';
}

/// An article with its body, outline and images.
class BlogArticleFull extends BlogArticle {
  /// Creates a full article.
  const BlogArticleFull({
    required super.id,
    required super.title,
    required super.slug,
    required super.tags,
    required super.wordCount,
    required super.status,
    required super.origin,
    required this.bodyMarkdown,
    required this.bodyHtml,
    required this.outline,
    required this.images,
    this.instructions,
    this.brief,
    super.keyword,
    super.excerpt,
    super.metaTitle,
    super.metaDescription,
    super.featuredImage,
    super.reviewUntil,
    super.publishAt,
    super.publishedAt,
    super.publishedUrl,
    super.error,
    super.createdAt,
    super.updatedAt,
  });

  /// Reads a full article.
  factory BlogArticleFull.fromJson(Map<String, dynamic> json) {
    final base = BlogArticle.fromJson(json);
    return BlogArticleFull(
      id: base.id,
      title: base.title,
      slug: base.slug,
      tags: base.tags,
      wordCount: base.wordCount,
      status: base.status,
      origin: base.origin,
      bodyMarkdown: asString(json['bodyMarkdown']) ?? '',
      bodyHtml: asString(json['bodyHtml']) ?? '',
      outline: asStringList(json['outline']),
      images: asModelList(json['images'], BlogArticleImage.fromJson),
      instructions: asString(json['instructions']),
      brief: asMapOrNull(json['brief']),
      keyword: base.keyword,
      excerpt: base.excerpt,
      metaTitle: base.metaTitle,
      metaDescription: base.metaDescription,
      featuredImage: base.featuredImage,
      reviewUntil: base.reviewUntil,
      publishAt: base.publishAt,
      publishedAt: base.publishedAt,
      publishedUrl: base.publishedUrl,
      error: base.error,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
    );
  }

  /// What the requester asked the writer for.
  final String? instructions;

  /// The headings the body follows.
  final List<String> outline;

  /// The research the writer worked from.
  final Map<String, dynamic>? brief;

  /// The body as Markdown.
  final String bodyMarkdown;

  /// The body as HTML.
  final String bodyHtml;

  /// The in-body images.
  final List<BlogArticleImage> images;
}

/// The `data` of an `article.published` webhook.
class BlogArticlePublished {
  /// Creates a payload.
  const BlogArticlePublished({
    required this.id,
    required this.title,
    required this.slug,
    required this.bodyMarkdown,
    required this.bodyHtml,
    required this.images,
    required this.tags,
    required this.wordCount,
    this.excerpt,
    this.metaTitle,
    this.metaDescription,
    this.featuredImage,
    this.keyword,
    this.publishedAt,
    this.publishedUrl,
  });

  /// Reads a payload.
  factory BlogArticlePublished.fromJson(Map<String, dynamic> json) =>
      BlogArticlePublished(
        id: asString(json['id']) ?? '',
        title: asString(json['title']) ?? '',
        slug: asString(json['slug']) ?? '',
        bodyMarkdown: asString(json['bodyMarkdown']) ?? '',
        bodyHtml: asString(json['bodyHtml']) ?? '',
        images: asModelList(json['images'], BlogArticleImage.fromJson),
        tags: asStringList(json['tags']),
        wordCount: asInt(json['wordCount']) ?? 0,
        excerpt: asString(json['excerpt']),
        metaTitle: asString(json['metaTitle']),
        metaDescription: asString(json['metaDescription']),
        featuredImage: _image(json['featuredImage']),
        keyword: asString(json['keyword']),
        publishedAt: asDate(json['publishedAt']),
        publishedUrl: asString(json['publishedUrl']),
      );

  /// The article's id.
  final String id;

  /// Its headline.
  final String title;

  /// Its URL slug.
  final String slug;

  /// A short summary.
  final String? excerpt;

  /// The `<title>` to publish with.
  final String? metaTitle;

  /// The meta description to publish with.
  final String? metaDescription;

  /// The body as Markdown.
  final String bodyMarkdown;

  /// The body as HTML.
  final String bodyHtml;

  /// The hero image. Its URL expires in six hours, so store a copy.
  final BlogArticleImage? featuredImage;

  /// The in-body images. Their URLs expire in six hours, so store copies.
  final List<BlogArticleImage> images;

  /// Its tags.
  final List<String> tags;

  /// The keyword it targets.
  final String? keyword;

  /// Words in the body.
  final int wordCount;

  /// When it went live.
  final DateTime? publishedAt;

  /// Where it is live, when the target reported one.
  final String? publishedUrl;

  @override
  String toString() => 'BlogArticlePublished($slug)';
}

BlogArticleImage? _image(Object? value) {
  final map = asMapOrNull(value);
  return map == null ? null : BlogArticleImage.fromJson(map);
}
