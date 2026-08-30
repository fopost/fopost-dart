import '../json.dart';
import 'common.dart';

/// A label as it appears on a post.
class PostLabelRef {
  /// Creates a label reference.
  const PostLabelRef(
      {required this.id, required this.name, required this.color});

  /// Reads a label reference.
  factory PostLabelRef.fromJson(Map<String, dynamic> json) => PostLabelRef(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        color: asString(json['color']) ?? '',
      );

  /// The label's id.
  final String id;

  /// The label's name.
  final String name;

  /// The label's hex color.
  final String color;

  @override
  String toString() => 'PostLabelRef($name)';
}

/// One account a post targets, with its delivery outcome.
class PostAccountResult {
  /// Creates an account result.
  const PostAccountResult({
    required this.id,
    required this.platform,
    required this.username,
    this.name,
    this.avatar,
    this.publishStatus,
    this.postedAt,
    this.platformPostId,
    this.externalUrl,
    this.errorCode,
    this.errorMessage,
    this.attempts,
    this.maxAttempts,
  });

  /// Reads an account result off a post.
  factory PostAccountResult.fromJson(Map<String, dynamic> json) =>
      PostAccountResult(
        id: asString(json['id']) ?? '',
        platform: asString(json['platform']) ?? '',
        username: asString(json['username']) ?? '',
        name: asString(json['name']),
        avatar: asString(json['avatar']),
        publishStatus: asString(json['publish_status']),
        postedAt: asDate(json['posted_at']),
        platformPostId: asString(json['platform_post_id']),
        externalUrl: asString(json['external_url']),
        errorCode: asString(json['error_code']),
        errorMessage: asString(json['error_message']),
        attempts: asInt(json['attempts']),
        maxAttempts: asInt(json['max_attempts']),
      );

  /// The connected account's id.
  final String id;

  /// The account's network.
  final String platform;

  /// The account's handle.
  final String username;

  /// The account's display name.
  final String? name;

  /// The account's avatar URL.
  final String? avatar;

  /// One of [DeliveryStatus].
  final String? publishStatus;

  /// When the post went live on this account.
  final DateTime? postedAt;

  /// The platform's own id for the published post.
  final String? platformPostId;

  /// The public permalink, once it is live.
  final String? externalUrl;

  /// The machine-readable failure code, when it failed.
  final String? errorCode;

  /// The human-readable failure, when it failed.
  final String? errorMessage;

  /// How many delivery attempts have been made.
  final int? attempts;

  /// How many attempts the API will make in total.
  final int? maxAttempts;

  @override
  String toString() => 'PostAccountResult($platform/$username, $publishStatus)';
}

/// A composed post and everything scheduled or delivered from it.
class Post {
  /// Creates a post.
  const Post({
    required this.id,
    required this.workspaceId,
    required this.status,
    required this.content,
    this.contentType,
    this.scheduleAt,
    this.repeatable = false,
    this.repeatableTimes,
    this.repeatableGap,
    this.repeatableGapUnit,
    this.remainingPosts,
    this.title,
    this.summary,
    this.autoPlug = false,
    this.autoPlugContent,
    this.accounts = const [],
    this.labels = const [],
    this.settings = const {},
    this.createdAt,
    this.updatedAt,
  });

  /// Reads a post.
  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: asString(json['id']) ?? '',
        workspaceId:
            asString(json['workspace_id'] ?? json['workspaceId']) ?? '',
        status: asString(json['status']) ?? '',
        content: asModelList(json['content'], ContentBlock.fromJson),
        contentType: asString(json['content_type']),
        scheduleAt: asDate(json['schedule_at']),
        repeatable: asBool(json['repeatable']) ?? false,
        repeatableTimes: asInt(json['repeatable_times']),
        repeatableGap: asInt(json['repeatable_gap']),
        repeatableGapUnit: asString(json['repeatable_gap_unit']),
        remainingPosts: asInt(json['remaining_posts']),
        title: asString(json['title']),
        summary: asString(json['summary']),
        autoPlug: asBool(json['auto_plug']) ?? false,
        autoPlugContent: asString(json['auto_plug_content']),
        accounts: asModelList(json['accounts'], PostAccountResult.fromJson),
        labels: asModelList(json['labels'], PostLabelRef.fromJson),
        settings: asMap(json['settings']),
        createdAt: asDate(json['created_at']),
        updatedAt: asDate(json['updated_at']),
      );

  /// The post's id.
  final String id;

  /// The workspace the post belongs to.
  final String workspaceId;

  /// One of [PostStatus].
  final String status;

  /// The post's blocks, in order.
  final List<ContentBlock> content;

  /// `post`, `thread`, or `reel`.
  final String? contentType;

  /// When a scheduled post goes out.
  final DateTime? scheduleAt;

  /// Whether the post repeats on a cadence.
  final bool repeatable;

  /// How many times it repeats.
  final int? repeatableTimes;

  /// The gap between repeats.
  final int? repeatableGap;

  /// The unit the gap is counted in.
  final String? repeatableGapUnit;

  /// Repeats still to come.
  final int? remainingPosts;

  /// The post's title, where the platform has one.
  final String? title;

  /// The post's summary, where the platform has one.
  final String? summary;

  /// Whether a follow-up comment is posted automatically.
  final bool autoPlug;

  /// The follow-up comment's text.
  final String? autoPlugContent;

  /// The accounts this post targets, with their outcomes.
  final List<PostAccountResult> accounts;

  /// The campaign labels on this post.
  final List<PostLabelRef> labels;

  /// Per-platform options, keyed by platform.
  final Map<String, dynamic> settings;

  /// When the post was composed.
  final DateTime? createdAt;

  /// When the post last changed.
  final DateTime? updatedAt;

  /// The first block's text, which is the post's body for a single post.
  String get text => content.isEmpty ? '' : content.first.text;

  @override
  String toString() => 'Post($id, $status)';
}

/// The id and status of the copy `duplicate` created.
class DuplicatedPost {
  /// Creates a duplicate result.
  const DuplicatedPost({required this.id, required this.status});

  /// Reads a duplicate result.
  factory DuplicatedPost.fromJson(Map<String, dynamic> json) => DuplicatedPost(
        id: asString(json['id']) ?? '',
        status: asString(json['status']) ?? '',
      );

  /// The new post's id.
  final String id;

  /// The new post's status, always a draft.
  final String status;

  @override
  String toString() => 'DuplicatedPost($id)';
}

/// One account's delivery as reported by publish or retry.
class PublishDelivery {
  /// Creates a delivery record.
  const PublishDelivery({
    required this.id,
    required this.accountId,
    required this.status,
    this.errorCode,
    this.errorMessage,
    this.platformPostId,
    this.externalUrl,
    this.postedAt,
    this.attempts,
    this.scheduledPublishAt,
    this.delayReason,
    this.delayMessage,
  });

  /// Reads a delivery record.
  factory PublishDelivery.fromJson(Map<String, dynamic> json) =>
      PublishDelivery(
        id: asString(json['id']) ?? '',
        accountId: asString(json['accountId']) ?? '',
        status: asString(json['status']) ?? '',
        errorCode: asString(json['errorCode']),
        errorMessage: asString(json['errorMessage']),
        platformPostId: asString(json['platformPostId']),
        externalUrl: asString(json['externalUrl']),
        postedAt: asDate(json['postedAt']),
        attempts: asInt(json['attempts']),
        scheduledPublishAt: asDate(json['scheduledPublishAt']),
        delayReason: asString(json['delayReason']),
        delayMessage: asString(json['delayMessage']),
      );

  /// The delivery's id.
  final String id;

  /// The account it targets.
  final String accountId;

  /// One of [DeliveryStatus].
  final String status;

  /// The machine-readable failure code.
  final String? errorCode;

  /// The human-readable failure.
  final String? errorMessage;

  /// The platform's own id for the published post.
  final String? platformPostId;

  /// The public permalink.
  final String? externalUrl;

  /// When it went live.
  final DateTime? postedAt;

  /// Attempts made so far.
  final int? attempts;

  /// When a delayed delivery will be tried again.
  final DateTime? scheduledPublishAt;

  /// Why it was held back.
  final String? delayReason;

  /// A human-readable version of [delayReason].
  final String? delayMessage;

  @override
  String toString() => 'PublishDelivery($accountId, $status)';
}

/// The outcome of a publish.
///
/// On a dry run, [dryRun] is true and [deliveries] is empty — the per-account
/// plan is in [accounts] instead.
class PublishResult {
  /// Creates a publish result.
  const PublishResult({
    this.dryRun = false,
    this.postStatus,
    this.postId,
    this.deliveries = const [],
    this.healthWarnings = const [],
    this.accounts = const [],
  });

  /// Reads a publish result.
  factory PublishResult.fromJson(Map<String, dynamic> json) {
    final post = asMap(json['post']);
    return PublishResult(
      dryRun: asBool(json['dryRun']) ?? false,
      postStatus: asString(json['post_status'] ?? post['status']),
      postId: asString(post['id']),
      deliveries: asModelList(json['deliveries'], PublishDelivery.fromJson),
      healthWarnings:
          asModelList(json['healthWarnings'], HealthWarning.fromJson),
      accounts: asModelList(json['accounts'], PlannedAccount.fromJson),
    );
  }

  /// Whether this was a validation run that reached no platform.
  final bool dryRun;

  /// The post's status after the call.
  final String? postStatus;

  /// The post that was published.
  final String? postId;

  /// One record per account the post was queued for.
  final List<PublishDelivery> deliveries;

  /// Accounts whose credentials look shaky.
  final List<HealthWarning> healthWarnings;

  /// The per-account plan, on a dry run.
  final List<PlannedAccount> accounts;

  @override
  String toString() =>
      'PublishResult($postStatus, ${deliveries.length} deliveries)';
}

/// One account named in a dry-run plan.
class PlannedAccount {
  /// Creates a planned account.
  const PlannedAccount({required this.accountId, required this.platform});

  /// Reads a planned account.
  factory PlannedAccount.fromJson(Map<String, dynamic> json) => PlannedAccount(
        accountId: asString(json['accountId']) ?? '',
        platform: asString(json['platform']) ?? '',
      );

  /// The account's id.
  final String accountId;

  /// The account's network.
  final String platform;

  @override
  String toString() => 'PlannedAccount($platform)';
}

/// An account that has run out of delivery attempts.
class ExceededAccount {
  /// Creates an exceeded-account record.
  const ExceededAccount(
      {required this.accountId, required this.platform, this.attempts});

  /// Reads an exceeded-account record.
  factory ExceededAccount.fromJson(Map<String, dynamic> json) =>
      ExceededAccount(
        accountId: asString(json['accountId']) ?? '',
        platform: asString(json['platform']) ?? '',
        attempts: asInt(json['attempts']),
      );

  /// The account's id.
  final String accountId;

  /// The account's network.
  final String platform;

  /// How many attempts were made.
  final int? attempts;

  @override
  String toString() => 'ExceededAccount($platform, $attempts attempts)';
}

/// What a retry re-sent, and what it could not.
class RetryResult {
  /// Creates a retry result.
  const RetryResult(
      {this.postStatus, this.deliveries = const [], this.exceeded = const []});

  /// Reads a retry result.
  factory RetryResult.fromJson(Map<String, dynamic> json) => RetryResult(
        postStatus: asString(json['post_status']),
        deliveries: asModelList(json['deliveries'], PublishDelivery.fromJson),
        exceeded: asModelList(json['exceeded'], ExceededAccount.fromJson),
      );

  /// The post's status after the retry.
  final String? postStatus;

  /// The deliveries that were re-queued.
  final List<PublishDelivery> deliveries;

  /// The accounts out of attempts.
  final List<ExceededAccount> exceeded;

  @override
  String toString() => 'RetryResult(${deliveries.length} retried)';
}

/// What a cancel stopped.
class CancelResult {
  /// Creates a cancel result.
  const CancelResult({this.postStatus, this.deliveries = const []});

  /// Reads a cancel result.
  factory CancelResult.fromJson(Map<String, dynamic> json) => CancelResult(
        postStatus: asString(json['post_status']),
        deliveries: asModelList(json['deliveries'], PublishDelivery.fromJson),
      );

  /// The post's status after the cancel.
  final String? postStatus;

  /// The deliveries that were stopped.
  final List<PublishDelivery> deliveries;

  @override
  String toString() => 'CancelResult(${deliveries.length} cancelled)';
}

/// One account's readiness. [issues] block publishing; [signals] are advisory.
class PreflightAccount {
  /// Creates a preflight account.
  const PreflightAccount({
    required this.accountId,
    required this.platform,
    required this.ready,
    this.username,
    this.issues = const [],
    this.score,
    this.signals = const [],
  });

  /// Reads a preflight account.
  factory PreflightAccount.fromJson(Map<String, dynamic> json) =>
      PreflightAccount(
        accountId: asString(json['accountId']) ?? '',
        platform: asString(json['platform']) ?? '',
        ready: asBool(json['ready']) ?? false,
        username: asString(json['username']),
        issues: asStringList(json['issues']),
        score: asDouble(json['score']),
        signals: asModelList(json['signals'], ContentSignal.fromJson),
      );

  /// The account's id.
  final String accountId;

  /// The account's network.
  final String platform;

  /// Whether the post can go out to this account.
  final bool ready;

  /// The account's handle.
  final String? username;

  /// What blocks publishing.
  final List<String> issues;

  /// The content score, where one was computed.
  final double? score;

  /// Advisory feedback.
  final List<ContentSignal> signals;

  @override
  String toString() => 'PreflightAccount($platform, ready: $ready)';
}

/// A post checked against every target platform, without publishing.
class PreflightResult {
  /// Creates a preflight result.
  const PreflightResult(
      {required this.ready,
      this.postId,
      this.postStatus,
      this.accounts = const []});

  /// Reads a preflight result.
  factory PreflightResult.fromJson(Map<String, dynamic> json) {
    final post = asMap(json['post']);
    return PreflightResult(
      ready: asBool(json['ready']) ?? false,
      postId: asString(post['id']),
      postStatus: asString(post['status']),
      accounts: asModelList(json['accounts'], PreflightAccount.fromJson),
    );
  }

  /// Whether every account is ready.
  final bool ready;

  /// The post that was checked.
  final String? postId;

  /// The post's status.
  final String? postStatus;

  /// One entry per target account.
  final List<PreflightAccount> accounts;

  @override
  String toString() => 'PreflightResult(ready: $ready)';
}

/// One account's delivery record for a post.
class Delivery {
  /// Creates a delivery.
  const Delivery({
    required this.id,
    required this.accountId,
    required this.status,
    this.platform,
    this.username,
    this.accountName,
    this.errorCode,
    this.errorMessage,
    this.attempts,
    this.maxAttempts,
    this.scheduledPublishAt,
    this.delayReason,
    this.delayMessage,
    this.postedAt,
    this.lastAttemptAt,
    this.platformPostId,
    this.externalUrl,
  });

  /// Reads a delivery.
  factory Delivery.fromJson(Map<String, dynamic> json) => Delivery(
        id: asString(json['id']) ?? '',
        accountId: asString(json['accountId']) ?? '',
        status: asString(json['status']) ?? '',
        platform: asString(json['platform']),
        username: asString(json['username']),
        accountName: asString(json['accountName']),
        errorCode: asString(json['errorCode']),
        errorMessage: asString(json['errorMessage']),
        attempts: asInt(json['attempts']),
        maxAttempts: asInt(json['maxAttempts']),
        scheduledPublishAt: asDate(json['scheduledPublishAt']),
        delayReason: asString(json['delayReason']),
        delayMessage: asString(json['delayMessage']),
        postedAt: asDate(json['postedAt']),
        lastAttemptAt: asDate(json['lastAttemptAt']),
        platformPostId: asString(json['platformPostId']),
        externalUrl: asString(json['externalUrl']),
      );

  /// The delivery's id.
  final String id;

  /// The account it targets.
  final String accountId;

  /// One of [DeliveryStatus].
  final String status;

  /// The account's network.
  final String? platform;

  /// The account's handle.
  final String? username;

  /// The account's display name.
  final String? accountName;

  /// The machine-readable failure code.
  final String? errorCode;

  /// The human-readable failure.
  final String? errorMessage;

  /// Attempts made so far.
  final int? attempts;

  /// Attempts the API will make in total.
  final int? maxAttempts;

  /// When a delayed delivery will be tried again.
  final DateTime? scheduledPublishAt;

  /// Why it was held back.
  final String? delayReason;

  /// A human-readable version of [delayReason].
  final String? delayMessage;

  /// When it went live.
  final DateTime? postedAt;

  /// When it was last attempted.
  final DateTime? lastAttemptAt;

  /// The platform's own id for the published post.
  final String? platformPostId;

  /// The public permalink.
  final String? externalUrl;

  @override
  String toString() => 'Delivery($platform, $status)';
}

/// One account's outcome within a single publish run.
class PublishRunDelivery {
  /// Creates a run delivery.
  const PublishRunDelivery({
    required this.accountId,
    required this.platform,
    required this.status,
    this.accountName,
    this.username,
    this.attemptNumber,
    this.errorCode,
    this.errorMessage,
    this.platformPostId,
    this.externalUrl,
    this.startedAt,
    this.completedAt,
    this.durationMs,
  });

  /// Reads a run delivery.
  factory PublishRunDelivery.fromJson(Map<String, dynamic> json) =>
      PublishRunDelivery(
        accountId: asString(json['account_id']) ?? '',
        platform: asString(json['platform']) ?? '',
        status: asString(json['status']) ?? '',
        accountName: asString(json['account_name']),
        username: asString(json['username']),
        attemptNumber: asInt(json['attempt_number']),
        errorCode: asString(json['error_code']),
        errorMessage: asString(json['error_message']),
        platformPostId: asString(json['platform_post_id']),
        externalUrl: asString(json['external_url']),
        startedAt: asDate(json['started_at']),
        completedAt: asDate(json['completed_at']),
        durationMs: asInt(json['duration_ms']),
      );

  /// The account's id.
  final String accountId;

  /// The account's network.
  final String platform;

  /// One of [DeliveryStatus].
  final String status;

  /// The account's display name.
  final String? accountName;

  /// The account's handle.
  final String? username;

  /// Which attempt this was.
  final int? attemptNumber;

  /// The machine-readable failure code.
  final String? errorCode;

  /// The human-readable failure.
  final String? errorMessage;

  /// The platform's own id for the published post.
  final String? platformPostId;

  /// The public permalink.
  final String? externalUrl;

  /// When the attempt started.
  final DateTime? startedAt;

  /// When the attempt finished.
  final DateTime? completedAt;

  /// How long the attempt took.
  final int? durationMs;

  @override
  String toString() => 'PublishRunDelivery($platform, $status)';
}

/// One attempt at publishing a post, with its per-account results.
class PublishRun {
  /// Creates a publish run.
  const PublishRun({
    required this.id,
    required this.status,
    this.runNumber,
    this.startedAt,
    this.completedAt,
    this.deliveries = const [],
  });

  /// Reads a publish run.
  factory PublishRun.fromJson(Map<String, dynamic> json) => PublishRun(
        id: asString(json['id']) ?? '',
        status: asString(json['status']) ?? '',
        runNumber: asInt(json['run_number']),
        startedAt: asDate(json['started_at']),
        completedAt: asDate(json['completed_at']),
        deliveries:
            asModelList(json['deliveries'], PublishRunDelivery.fromJson),
      );

  /// The run's id.
  final String id;

  /// The run's status.
  final String status;

  /// Which run this was, counting from one.
  final int? runNumber;

  /// When the run started.
  final DateTime? startedAt;

  /// When the run finished.
  final DateTime? completedAt;

  /// One entry per account in this run.
  final List<PublishRunDelivery> deliveries;

  @override
  String toString() => 'PublishRun(#$runNumber, $status)';
}

/// A post's totals across every platform it reached.
class PostAnalyticsTotals {
  /// Creates a totals block.
  const PostAnalyticsTotals({
    this.impressions = 0,
    this.reach = 0,
    this.engagements = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.reposts = 0,
    this.clicks = 0,
    this.saves = 0,
    this.videoViews = 0,
    this.follows = 0,
  });

  /// Reads a totals block.
  factory PostAnalyticsTotals.fromJson(Map<String, dynamic> json) =>
      PostAnalyticsTotals(
        impressions: asInt(json['impressions']) ?? 0,
        reach: asInt(json['reach']) ?? 0,
        engagements: asInt(json['engagements']) ?? 0,
        likes: asInt(json['likes']) ?? 0,
        comments: asInt(json['comments']) ?? 0,
        shares: asInt(json['shares']) ?? 0,
        reposts: asInt(json['reposts']) ?? 0,
        clicks: asInt(json['clicks']) ?? 0,
        saves: asInt(json['saves']) ?? 0,
        videoViews: asInt(json['videoViews']) ?? 0,
        follows: asInt(json['follows']) ?? 0,
      );

  /// Times the post was shown.
  final int impressions;

  /// Unique accounts that saw it.
  final int reach;

  /// Every interaction, summed.
  final int engagements;

  /// Likes.
  final int likes;

  /// Comments.
  final int comments;

  /// Shares.
  final int shares;

  /// Reposts.
  final int reposts;

  /// Link clicks.
  final int clicks;

  /// Saves or bookmarks.
  final int saves;

  /// Video views.
  final int videoViews;

  /// Follows the post drove.
  final int follows;

  @override
  String toString() => 'PostAnalyticsTotals($engagements engagements)';
}

/// One platform's numbers for a post. A null field means the platform does not
/// report that metric.
class PostPlatformMetrics {
  /// Creates a metrics block.
  const PostPlatformMetrics({
    this.impressions,
    this.reach,
    this.engagements,
    this.likes,
    this.comments,
    this.shares,
    this.reposts,
    this.clicks,
    this.saves,
    this.videoViews,
    this.watchTimeMs,
    this.avgWatchTimeMs,
    this.follows,
    this.reactionsBreakdown = const {},
    this.fetchedAt,
  });

  /// Reads a metrics block.
  factory PostPlatformMetrics.fromJson(Map<String, dynamic> json) =>
      PostPlatformMetrics(
        impressions: asInt(json['impressions']),
        reach: asInt(json['reach']),
        engagements: asInt(json['engagements']),
        likes: asInt(json['likes']),
        comments: asInt(json['comments']),
        shares: asInt(json['shares']),
        reposts: asInt(json['reposts']),
        clicks: asInt(json['clicks']),
        saves: asInt(json['saves']),
        videoViews: asInt(json['videoViews']),
        watchTimeMs: asInt(json['watchTimeMs']),
        avgWatchTimeMs: asInt(json['avgWatchTimeMs']),
        follows: asInt(json['follows']),
        reactionsBreakdown: asMap(json['reactionsBreakdown']),
        fetchedAt: asDate(json['fetchedAt']),
      );

  /// Times the post was shown.
  final int? impressions;

  /// Unique accounts that saw it.
  final int? reach;

  /// Every interaction, summed.
  final int? engagements;

  /// Likes.
  final int? likes;

  /// Comments.
  final int? comments;

  /// Shares.
  final int? shares;

  /// Reposts.
  final int? reposts;

  /// Link clicks.
  final int? clicks;

  /// Saves or bookmarks.
  final int? saves;

  /// Video views.
  final int? videoViews;

  /// Total watch time.
  final int? watchTimeMs;

  /// Average watch time per view.
  final int? avgWatchTimeMs;

  /// Follows the post drove.
  final int? follows;

  /// Per-reaction counts, where the platform breaks them out.
  final Map<String, dynamic> reactionsBreakdown;

  /// When these numbers were pulled.
  final DateTime? fetchedAt;

  @override
  String toString() => 'PostPlatformMetrics($engagements engagements)';
}

/// A post's performance on one platform.
class PostPlatformAnalytics {
  /// Creates a per-platform block.
  const PostPlatformAnalytics({
    required this.platform,
    required this.metrics,
    this.username,
    this.externalPostId,
    this.permalink,
    this.thumbnailUrl,
    this.mediaType,
    this.postedAt,
  });

  /// Reads a per-platform block.
  factory PostPlatformAnalytics.fromJson(Map<String, dynamic> json) =>
      PostPlatformAnalytics(
        platform: asString(json['platform']) ?? '',
        metrics: PostPlatformMetrics.fromJson(asMap(json['metrics'])),
        username: asString(json['username']),
        externalPostId: asString(json['externalPostId']),
        permalink: asString(json['permalink']),
        thumbnailUrl: asString(json['thumbnailUrl']),
        mediaType: asString(json['mediaType']),
        postedAt: asDate(json['postedAt']),
      );

  /// The network.
  final String platform;

  /// The numbers.
  final PostPlatformMetrics metrics;

  /// The account's handle.
  final String? username;

  /// The platform's own id for the post.
  final String? externalPostId;

  /// The public permalink.
  final String? permalink;

  /// A thumbnail for the post.
  final String? thumbnailUrl;

  /// What kind of media the post carries.
  final String? mediaType;

  /// When it went live.
  final DateTime? postedAt;

  @override
  String toString() => 'PostPlatformAnalytics($platform)';
}

/// A post's performance, totalled and per platform.
class PostAnalytics {
  /// Creates post analytics.
  const PostAnalytics({
    required this.postId,
    required this.totals,
    this.platforms = const [],
    this.lastFetchedAt,
  });

  /// Reads post analytics.
  factory PostAnalytics.fromJson(Map<String, dynamic> json) => PostAnalytics(
        postId: asString(json['postId']) ?? '',
        totals: PostAnalyticsTotals.fromJson(asMap(json['totals'])),
        platforms:
            asModelList(json['platforms'], PostPlatformAnalytics.fromJson),
        lastFetchedAt: asDate(json['lastFetchedAt']),
      );

  /// The post these numbers belong to.
  final String postId;

  /// The numbers summed across every platform.
  final PostAnalyticsTotals totals;

  /// One entry per platform the post reached.
  final List<PostPlatformAnalytics> platforms;

  /// When the numbers were last refreshed.
  final DateTime? lastFetchedAt;

  @override
  String toString() => 'PostAnalytics($postId)';
}

/// How many posts a bulk action changed.
class BulkResult {
  /// Creates a bulk result.
  const BulkResult({required this.updated, required this.action, this.mode});

  /// Reads a bulk result.
  factory BulkResult.fromJson(Map<String, dynamic> json) => BulkResult(
        updated: asInt(json['updated']) ?? 0,
        action: asString(json['action']) ?? '',
        mode: asString(json['mode']),
      );

  /// How many posts changed.
  final int updated;

  /// Which action ran.
  final String action;

  /// The labelling mode, on a label action.
  final String? mode;

  @override
  String toString() => 'BulkResult($action, $updated updated)';
}

/// One CSV row as the bulk-import validator read it.
class BulkImportRow {
  /// Creates a row.
  const BulkImportRow({
    required this.row,
    this.contentPreview,
    this.scheduleAt,
    this.accounts = const [],
    this.labels,
    this.hasMedia = false,
    this.errors = const [],
  });

  /// Reads a row.
  factory BulkImportRow.fromJson(Map<String, dynamic> json) => BulkImportRow(
        row: asInt(json['row']) ?? 0,
        contentPreview: asString(json['content_preview']),
        scheduleAt: asDate(json['schedule_at']),
        accounts: asStringList(json['accounts']),
        labels: asInt(json['labels']),
        hasMedia: asBool(json['has_media']) ?? false,
        errors: asStringList(json['errors']),
      );

  /// The 1-based row number in the CSV.
  final int row;

  /// The start of the row's text.
  final String? contentPreview;

  /// When this row's post would go out.
  final DateTime? scheduleAt;

  /// The accounts the row targets.
  final List<String> accounts;

  /// How many labels the row carries.
  final int? labels;

  /// Whether the row attaches media.
  final bool hasMedia;

  /// What is wrong with this row, if anything.
  final List<String> errors;

  /// Whether this row would import cleanly.
  bool get isValid => errors.isEmpty;

  @override
  String toString() => 'BulkImportRow($row, ${errors.length} errors)';
}

/// The dry run of a CSV import.
class BulkImportValidation {
  /// Creates a validation result.
  const BulkImportValidation({
    required this.totalRows,
    required this.validRows,
    required this.invalidRows,
    this.rows = const [],
  });

  /// Reads a validation result.
  factory BulkImportValidation.fromJson(Map<String, dynamic> json) =>
      BulkImportValidation(
        totalRows: asInt(json['total_rows']) ?? 0,
        validRows: asInt(json['valid_rows']) ?? 0,
        invalidRows: asInt(json['invalid_rows']) ?? 0,
        rows: asModelList(json['rows'], BulkImportRow.fromJson),
      );

  /// Rows in the file.
  final int totalRows;

  /// Rows that would import.
  final int validRows;

  /// Rows that would not.
  final int invalidRows;

  /// The rows themselves.
  final List<BulkImportRow> rows;

  @override
  String toString() => 'BulkImportValidation($validRows/$totalRows valid)';
}

/// One post a committed CSV import created.
class BulkImportedPost {
  /// Creates an imported post reference.
  const BulkImportedPost({required this.id, this.scheduleAt});

  /// Reads an imported post reference.
  factory BulkImportedPost.fromJson(Map<String, dynamic> json) =>
      BulkImportedPost(
        id: asString(json['id']) ?? '',
        scheduleAt: asDate(json['schedule_at']),
      );

  /// The new post's id.
  final String id;

  /// When it goes out.
  final DateTime? scheduleAt;

  @override
  String toString() => 'BulkImportedPost($id)';
}

/// What a committed CSV import created. Keep [batchId] to roll it back.
class BulkImportResult {
  /// Creates an import result.
  const BulkImportResult(
      {required this.batchId, required this.created, this.posts = const []});

  /// Reads an import result.
  factory BulkImportResult.fromJson(Map<String, dynamic> json) =>
      BulkImportResult(
        batchId: asString(json['batch_id']) ?? '',
        created: asInt(json['created']) ?? 0,
        posts: asModelList(json['posts'], BulkImportedPost.fromJson),
      );

  /// The batch, which `rollbackBulkImport` undoes.
  final String batchId;

  /// How many posts were created.
  final int created;

  /// The posts themselves.
  final List<BulkImportedPost> posts;

  @override
  String toString() => 'BulkImportResult($batchId, $created created)';
}
