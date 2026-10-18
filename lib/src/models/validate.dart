import '../json.dart';
import 'common.dart';

/// One file to check with `client.validate.post`.
class ValidateMedia {
  /// Creates a media reference.
  const ValidateMedia({required this.url, required this.mimeType, this.size});

  /// A public http(s) URL of the file.
  final String url;

  /// The file's MIME type, e.g. `image/png`.
  final String mimeType;

  /// The file's size in bytes, when known.
  final int? size;

  /// Renders the reference for a request body.
  Map<String, dynamic> toJson() =>
      pruned({'url': url, 'mime_type': mimeType, 'size': size});
}

/// One platform's verdict from `client.validate.post`.
class ValidatePostPlatform {
  /// Creates a platform verdict.
  const ValidatePostPlatform({
    required this.platform,
    required this.ready,
    this.issues = const [],
    this.score,
    this.signals = const [],
  });

  /// Reads a platform verdict.
  factory ValidatePostPlatform.fromJson(Map<String, dynamic> json) =>
      ValidatePostPlatform(
        platform: asString(json['platform']) ?? '',
        ready: asBool(json['ready']) ?? false,
        issues: asStringList(json['issues']),
        score: asDouble(json['score']),
        signals: asModelList(json['signals'], ContentSignal.fromJson),
      );

  /// The platform slug.
  final String platform;

  /// Whether the post could go out to this platform.
  final bool ready;

  /// Hard blockers that would prevent publishing.
  final List<String> issues;

  /// Advisory 0-100 score, when the API computed one.
  final double? score;

  /// Advisory signals; they never block.
  final List<ContentSignal> signals;

  @override
  String toString() => 'ValidatePostPlatform($platform, ready: $ready)';
}

/// The result of `client.validate.post`.
class ValidatePostResult {
  /// Creates a post validation result.
  const ValidatePostResult({required this.ready, this.platforms = const []});

  /// Reads a post validation result.
  factory ValidatePostResult.fromJson(Map<String, dynamic> json) =>
      ValidatePostResult(
        ready: asBool(json['ready']) ?? false,
        platforms:
            asModelList(json['platforms'], ValidatePostPlatform.fromJson),
      );

  /// Whether every platform is ready.
  final bool ready;

  /// One entry per requested platform.
  final List<ValidatePostPlatform> platforms;

  @override
  String toString() => 'ValidatePostResult(ready: $ready)';
}

/// One platform's count from `client.validate.length`.
class ValidateLengthPlatform {
  /// Creates a length verdict.
  const ValidateLengthPlatform({
    required this.platform,
    required this.length,
    required this.unit,
    required this.ok,
    this.limit,
    this.signals = const [],
  });

  /// Reads a length verdict.
  factory ValidateLengthPlatform.fromJson(Map<String, dynamic> json) =>
      ValidateLengthPlatform(
        platform: asString(json['platform']) ?? '',
        length: asInt(json['length']) ?? 0,
        limit: asInt(json['limit']),
        unit: asString(json['unit']) ?? 'chars',
        ok: asBool(json['ok']) ?? false,
        signals: asModelList(json['signals'], ContentSignal.fromJson),
      );

  /// The platform slug.
  final String platform;

  /// What the platform counts, in [unit].
  final int length;

  /// The platform's limit, or null when it has none.
  final int? limit;

  /// `chars` or `bytes`.
  final String unit;

  /// Whether the text fits.
  final bool ok;

  /// `over_length` or `near_length_limit`, when either applies.
  final List<ContentSignal> signals;

  @override
  String toString() => 'ValidateLengthPlatform($platform, $length $unit)';
}

/// The result of `client.validate.length`.
class ValidateLengthResult {
  /// Creates a length validation result.
  const ValidateLengthResult({required this.ok, this.platforms = const []});

  /// Reads a length validation result.
  factory ValidateLengthResult.fromJson(Map<String, dynamic> json) =>
      ValidateLengthResult(
        ok: asBool(json['ok']) ?? false,
        platforms:
            asModelList(json['platforms'], ValidateLengthPlatform.fromJson),
      );

  /// Whether the text fits every platform.
  final bool ok;

  /// One entry per requested platform.
  final List<ValidateLengthPlatform> platforms;

  @override
  String toString() => 'ValidateLengthResult(ok: $ok)';
}

/// The result of `client.validate.media`.
class ValidateMediaResult {
  /// Creates a media validation result.
  const ValidateMediaResult({
    required this.ok,
    required this.name,
    required this.size,
    this.issues = const [],
    this.mimeType,
    this.type,
  });

  /// Reads a media validation result.
  factory ValidateMediaResult.fromJson(Map<String, dynamic> json) =>
      ValidateMediaResult(
        ok: asBool(json['ok']) ?? false,
        issues: asStringList(json['issues']),
        name: asString(json['name']) ?? '',
        size: asInt(json['size']) ?? 0,
        mimeType: asString(json['mime_type']),
        type: asString(json['type']),
      );

  /// Whether the file passed every check.
  final bool ok;

  /// What failed, when [ok] is false.
  final List<String> issues;

  /// The file name.
  final String name;

  /// Bytes fetched.
  final int size;

  /// The detected MIME type, only when [ok].
  final String? mimeType;

  /// `image`, `video`, `audio` or `document`, only when [ok].
  final String? type;

  @override
  String toString() => 'ValidateMediaResult($name, ok: $ok)';
}

/// Whether a subreddit exists and takes a post from one account.
class ValidateSubredditResult {
  /// Creates a result.
  const ValidateSubredditResult({
    required this.subreddit,
    this.exists = false,
    this.canPost = false,
    this.over18 = false,
    this.flairEnabled = false,
    this.ok = false,
  });

  /// Reads a result.
  factory ValidateSubredditResult.fromJson(Map<String, dynamic> json) =>
      ValidateSubredditResult(
        subreddit: asString(json['subreddit']) ?? '',
        exists: asBool(json['exists']) ?? false,
        canPost: asBool(json['can_post']) ?? false,
        over18: asBool(json['over_18']) ?? false,
        flairEnabled: asBool(json['flair_enabled']) ?? false,
        ok: asBool(json['ok']) ?? false,
      );

  /// The subreddit that was checked, without the `r/` prefix.
  final String subreddit;

  /// Whether the subreddit exists and is visible to this account.
  final bool exists;

  /// Whether this account may submit there.
  final bool canPost;

  /// Whether the subreddit is marked over 18.
  final bool over18;

  /// Whether the subreddit offers post flairs.
  final bool flairEnabled;

  /// True when the subreddit exists and takes a post from this account.
  final bool ok;

  @override
  String toString() => 'ValidateSubredditResult(r/$subreddit, ok: $ok)';
}
