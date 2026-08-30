import '../json.dart';

/// One page of a paginated list.
class PageMeta {
  /// Creates page metadata.
  const PageMeta({
    this.currentPage,
    this.perPage,
    this.total,
    this.lastPage,
    this.from,
    this.to,
  });

  /// Reads the `meta` block the API sends alongside a paginated `data` list.
  factory PageMeta.fromJson(Map<String, dynamic> json) => PageMeta(
        currentPage: asInt(json['current_page']),
        perPage: asInt(json['per_page']),
        total: asInt(json['total']),
        lastPage: asInt(json['last_page']),
        from: asInt(json['from']),
        to: asInt(json['to']),
      );

  /// The page this response is.
  final int? currentPage;

  /// How many rows a full page holds.
  final int? perPage;

  /// How many rows match in total.
  final int? total;

  /// The last page number, so `currentPage == lastPage` is the end.
  final int? lastPage;

  /// The 1-based index of the first row on this page.
  final int? from;

  /// The 1-based index of the last row on this page.
  final int? to;

  /// Whether another page follows this one.
  bool get hasMore {
    final current = currentPage;
    final last = lastPage;
    if (current == null || last == null) return false;
    return current < last;
  }

  @override
  String toString() => 'PageMeta(page: $currentPage/$lastPage, total: $total)';
}

/// A page of results and the metadata describing where it sits.
class Page<T> {
  /// Creates a page.
  const Page({required this.data, required this.meta});

  /// Reads a `{"data": [...], "meta": {...}}` response.
  factory Page.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    return Page<T>(
      data: asModelList<T>(json['data'], parse),
      meta: PageMeta.fromJson(asMap(json['meta'])),
    );
  }

  /// The rows on this page.
  final List<T> data;

  /// Where this page sits in the whole result set.
  final PageMeta meta;

  /// How many rows this page holds.
  int get length => data.length;

  /// Whether this page is empty.
  bool get isEmpty => data.isEmpty;

  /// Whether this page holds anything.
  bool get isNotEmpty => data.isNotEmpty;

  @override
  String toString() => 'Page(${data.length} of ${meta.total})';
}

/// One attachment on a content block.
class MediaItem {
  /// Creates an attachment.
  const MediaItem({
    required this.type,
    required this.name,
    required this.url,
    this.size,
    this.alt,
    this.thumbnail,
  });

  /// Reads an attachment off a post's content block.
  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        type: asString(json['type']) ?? 'image',
        name: asString(json['name']) ?? '',
        url: asString(json['url']) ?? '',
        size: asDouble(json['size']),
        alt: asString(json['alt']),
        thumbnail: asString(json['thumbnail']),
      );

  /// `image`, `video`, or `gif`.
  final String type;

  /// The file name shown in the composer.
  final String name;

  /// Where the asset lives.
  final String url;

  /// The asset's size in bytes, when the API reported one.
  final double? size;

  /// Alt text for accessibility.
  final String? alt;

  /// A poster frame for a video.
  final String? thumbnail;

  /// Renders the attachment for a request body.
  Map<String, dynamic> toJson() => pruned({
        'type': type,
        'name': name,
        'url': url,
        'size': size,
        'alt': alt,
        'thumbnail': thumbnail,
      });

  @override
  String toString() => 'MediaItem($type, $name)';
}

/// One text-plus-media unit. A single post has one block; a thread has one per
/// entry, in order.
class ContentBlock {
  /// Creates a block.
  const ContentBlock(
      {required this.text, this.media = const [], this.id, this.position});

  /// Reads a block off a post.
  factory ContentBlock.fromJson(Map<String, dynamic> json) => ContentBlock(
        text: asString(json['text']) ?? '',
        media: asModelList(json['media'], MediaItem.fromJson),
        id: asInt(json['id']),
        position: asInt(json['position']),
      );

  /// The block's text.
  final String text;

  /// The attachments on this block.
  final List<MediaItem> media;

  /// The block's id, on a post the API already stored.
  final int? id;

  /// The block's place in a thread.
  final int? position;

  /// Renders the block for a request body.
  Map<String, dynamic> toJson() => pruned({
        'text': text,
        if (media.isNotEmpty) 'media': media.map((m) => m.toJson()).toList(),
        'position': position,
      });

  @override
  String toString() =>
      'ContentBlock(${text.length} chars, ${media.length} media)';
}

/// Advisory feedback from a preflight check. Blockers arrive as issues instead.
class ContentSignal {
  /// Creates a signal.
  const ContentSignal(
      {required this.level, required this.code, required this.message});

  /// Reads a signal off a preflight response.
  factory ContentSignal.fromJson(Map<String, dynamic> json) => ContentSignal(
        level: asString(json['level']) ?? 'info',
        code: asString(json['code']) ?? '',
        message: asString(json['message']) ?? '',
      );

  /// `info` or `warn`.
  final String level;

  /// The machine-readable signal code.
  final String code;

  /// What the signal is telling you.
  final String message;

  @override
  String toString() => 'ContentSignal($level, $code)';
}

/// An account whose credentials looked shaky when a post was published.
class HealthWarning {
  /// Creates a warning.
  const HealthWarning({
    required this.accountId,
    required this.platform,
    required this.healthStatus,
    required this.message,
  });

  /// Reads a warning off a publish response.
  factory HealthWarning.fromJson(Map<String, dynamic> json) => HealthWarning(
        accountId: asString(json['accountId']) ?? '',
        platform: asString(json['platform']) ?? '',
        healthStatus: asString(json['healthStatus']) ?? '',
        message: asString(json['message']) ?? '',
      );

  /// The account the warning is about.
  final String accountId;

  /// The account's network.
  final String platform;

  /// One of [AccountHealthStatus].
  final String healthStatus;

  /// What is wrong.
  final String message;

  @override
  String toString() => 'HealthWarning($platform, $healthStatus)';
}

/// The bare acknowledgement several deletes answer with.
class ApiMessage {
  /// Creates an acknowledgement.
  const ApiMessage({required this.message, this.deleted});

  /// Reads the acknowledgement.
  factory ApiMessage.fromJson(Map<String, dynamic> json) => ApiMessage(
        message: asString(json['message']) ?? '',
        deleted: asInt(json['deleted']),
      );

  /// What the API said.
  final String message;

  /// How many rows were removed, where the endpoint counts them.
  final int? deleted;

  @override
  String toString() => 'ApiMessage($message)';
}

/// The statuses a post moves through.
abstract final class PostStatus {
  /// Composed but not scheduled.
  static const String draft = 'draft';

  /// Waiting for its `scheduleAt`.
  static const String scheduled = 'scheduled';

  /// Being delivered right now.
  static const String publishing = 'publishing';

  /// Live on every target account.
  static const String published = 'published';

  /// Live on some accounts, failed on others.
  static const String partiallyFailed = 'partially_failed';

  /// Failed on every account.
  static const String failed = 'failed';

  /// Stopped before it went out.
  static const String cancelled = 'cancelled';
}

/// The statuses one account's delivery moves through.
abstract final class DeliveryStatus {
  /// Created, not yet queued.
  static const String pending = 'pending';

  /// Handed to a worker.
  static const String queued = 'queued';

  /// Held back, e.g. by a platform rate limit.
  static const String delayed = 'delayed';

  /// Being sent.
  static const String publishing = 'publishing';

  /// Live on the platform.
  static const String published = 'published';

  /// The platform rejected it.
  static const String failed = 'failed';

  /// Stopped before it went out.
  static const String cancelled = 'cancelled';
}

/// How healthy a connected account's credentials are.
abstract final class AccountHealthStatus {
  /// Credentials work.
  static const String healthy = 'healthy';

  /// Credentials work but something is off.
  static const String degraded = 'degraded';

  /// The token expired.
  static const String expired = 'expired';

  /// The user revoked access.
  static const String revoked = 'revoked';

  /// Never checked.
  static const String unknown = 'unknown';
}

/// The events a webhook subscription can ask for.
abstract final class WebhookEvent {
  /// A post reached every account.
  static const String postPublished = 'post.published';

  /// A post failed on every account.
  static const String postFailed = 'post.failed';

  /// A post reached some accounts and failed on others.
  static const String postPartiallyFailed = 'post.partially_failed';

  /// One account's delivery went live.
  static const String deliveryPublished = 'delivery.published';

  /// One account's delivery failed.
  static const String deliveryFailed = 'delivery.failed';

  /// One account's delivery was held back.
  static const String deliveryDelayed = 'delivery.delayed';

  /// A connected account's health changed.
  static const String accountHealthChanged = 'account.health_changed';
}

/// The kinds of workspace a plan can hold.
abstract final class WorkspaceType {
  /// A single person's own space.
  static const String personal = 'PERSONAL';

  /// A shared team space.
  static const String team = 'TEAM';

  /// A whole organization.
  static const String organization = 'ORGANIZATION';

  /// An agency's client.
  static const String client = 'CLIENT';

  /// A single project.
  static const String project = 'PROJECT';

  /// One department.
  static const String department = 'DEPARTMENT';

  /// A one-off event.
  static const String event = 'EVENT';

  /// A short-lived space.
  static const String temporary = 'TEMPORARY';

  /// A community space.
  static const String community = 'COMMUNITY';

  /// One brand.
  static const String brand = 'BRAND';

  /// An agency itself.
  static const String agency = 'AGENCY';
}
