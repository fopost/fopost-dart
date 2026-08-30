import '../json.dart';
import 'post.dart';

/// The audiences a demographics breakdown can describe.
abstract final class DemographicsAudience {
  /// Everyone who follows the accounts.
  static const String followers = 'followers';

  /// Everyone who interacted in the window.
  static const String engaged = 'engaged';

  /// Everyone the posts reached in the window.
  static const String reached = 'reached';
}

/// Period-over-period changes, as fractions. A null field means there was no
/// earlier period to compare against.
class AnalyticsDeltas {
  /// Creates a deltas block.
  const AnalyticsDeltas({
    this.followers,
    this.posts,
    this.engagement,
    this.impressions,
    this.likes,
    this.comments,
    this.shares,
    this.profileViews,
  });

  /// Reads a deltas block.
  factory AnalyticsDeltas.fromJson(Map<String, dynamic> json) => AnalyticsDeltas(
        followers: asDouble(json['followers']),
        posts: asDouble(json['posts']),
        engagement: asDouble(json['engagement']),
        impressions: asDouble(json['impressions']),
        likes: asDouble(json['likes']),
        comments: asDouble(json['comments']),
        shares: asDouble(json['shares']),
        profileViews: asDouble(json['profileViews']),
      );

  /// Change in followers.
  final double? followers;

  /// Change in posts published.
  final double? posts;

  /// Change in engagement.
  final double? engagement;

  /// Change in impressions.
  final double? impressions;

  /// Change in likes.
  final double? likes;

  /// Change in comments.
  final double? comments;

  /// Change in shares.
  final double? shares;

  /// Change in profile views.
  final double? profileViews;

  @override
  String toString() => 'AnalyticsDeltas(followers: $followers)';
}

/// One platform's share of an overview.
class PlatformBreakdown {
  /// Creates a platform breakdown.
  const PlatformBreakdown({required this.platform, this.accounts = 0, this.followers = 0});

  /// Reads a platform breakdown.
  factory PlatformBreakdown.fromJson(Map<String, dynamic> json) => PlatformBreakdown(
        platform: asString(json['platform']) ?? '',
        accounts: asInt(json['accounts']) ?? 0,
        followers: asInt(json['followers']) ?? 0,
      );

  /// The network.
  final String platform;

  /// Connected accounts on it.
  final int accounts;

  /// Followers across those accounts.
  final int followers;

  @override
  String toString() => 'PlatformBreakdown($platform, $followers followers)';
}

/// One account's contribution to an overview.
class OverviewAccount {
  /// Creates an overview account.
  const OverviewAccount({
    required this.accountId,
    required this.platform,
    this.username,
    this.name,
    this.avatar,
    this.followers,
    this.totalPosts,
    this.fetchedAt,
  });

  /// Reads an overview account.
  factory OverviewAccount.fromJson(Map<String, dynamic> json) => OverviewAccount(
        accountId: asString(json['accountId']) ?? '',
        platform: asString(json['platform']) ?? '',
        username: asString(json['username']),
        name: asString(json['name']),
        avatar: asString(json['avatar']),
        followers: asInt(json['followers']),
        totalPosts: asInt(json['totalPosts']),
        fetchedAt: asDate(json['fetchedAt']),
      );

  /// The account's id.
  final String accountId;

  /// The account's network.
  final String platform;

  /// The account's handle.
  final String? username;

  /// The account's display name.
  final String? name;

  /// The account's avatar URL.
  final String? avatar;

  /// Followers, where the platform reports them.
  final int? followers;

  /// Posts on the account.
  final int? totalPosts;

  /// When these numbers were pulled.
  final DateTime? fetchedAt;

  @override
  String toString() => 'OverviewAccount($platform/$username)';
}

/// The headline roll-up across every account in scope.
class AnalyticsOverview {
  /// Creates an overview.
  const AnalyticsOverview({
    this.totalAccounts = 0,
    this.totalFollowers = 0,
    this.totalPosts = 0,
    this.totalEngagement = 0,
    this.totalImpressions = 0,
    this.totalReach = 0,
    this.totalLikes = 0,
    this.totalComments = 0,
    this.totalShares = 0,
    this.totalReposts = 0,
    this.totalSaves = 0,
    this.totalClicks = 0,
    this.totalVideoViews = 0,
    this.totalProfileViews = 0,
    this.engagementRate,
    this.deltas = const AnalyticsDeltas(),
    this.platforms = const [],
    this.accounts = const [],
  });

  /// Reads an overview.
  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) => AnalyticsOverview(
        totalAccounts: asInt(json['totalAccounts']) ?? 0,
        totalFollowers: asInt(json['totalFollowers']) ?? 0,
        totalPosts: asInt(json['totalPosts']) ?? 0,
        totalEngagement: asInt(json['totalEngagement']) ?? 0,
        totalImpressions: asInt(json['totalImpressions']) ?? 0,
        totalReach: asInt(json['totalReach']) ?? 0,
        totalLikes: asInt(json['totalLikes']) ?? 0,
        totalComments: asInt(json['totalComments']) ?? 0,
        totalShares: asInt(json['totalShares']) ?? 0,
        totalReposts: asInt(json['totalReposts']) ?? 0,
        totalSaves: asInt(json['totalSaves']) ?? 0,
        totalClicks: asInt(json['totalClicks']) ?? 0,
        totalVideoViews: asInt(json['totalVideoViews']) ?? 0,
        totalProfileViews: asInt(json['totalProfileViews']) ?? 0,
        engagementRate: asDouble(json['engagementRate']),
        deltas: AnalyticsDeltas.fromJson(asMap(json['deltas'])),
        platforms: asModelList(json['platforms'], PlatformBreakdown.fromJson),
        accounts: asModelList(json['accounts'], OverviewAccount.fromJson),
      );

  /// Accounts in scope.
  final int totalAccounts;

  /// Followers across them.
  final int totalFollowers;

  /// Posts published in the window.
  final int totalPosts;

  /// Every interaction, summed.
  final int totalEngagement;

  /// Times posts were shown.
  final int totalImpressions;

  /// Unique accounts reached.
  final int totalReach;

  /// Likes.
  final int totalLikes;

  /// Comments.
  final int totalComments;

  /// Shares.
  final int totalShares;

  /// Reposts.
  final int totalReposts;

  /// Saves or bookmarks.
  final int totalSaves;

  /// Link clicks.
  final int totalClicks;

  /// Video views.
  final int totalVideoViews;

  /// Profile views.
  final int totalProfileViews;

  /// Engagement as a fraction of impressions.
  final double? engagementRate;

  /// Period-over-period changes.
  final AnalyticsDeltas deltas;

  /// One entry per network.
  final List<PlatformBreakdown> platforms;

  /// One entry per account.
  final List<OverviewAccount> accounts;

  @override
  String toString() => 'AnalyticsOverview($totalFollowers followers, $totalPosts posts)';
}

/// One day of activity.
class TimeSeriesPoint {
  /// Creates a point.
  const TimeSeriesPoint({
    required this.date,
    this.engagements = 0,
    this.impressions = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.followers = 0,
    this.posts = 0,
  });

  /// Reads a point.
  factory TimeSeriesPoint.fromJson(Map<String, dynamic> json) => TimeSeriesPoint(
        date: asString(json['date']) ?? '',
        engagements: asInt(json['engagements']) ?? 0,
        impressions: asInt(json['impressions']) ?? 0,
        likes: asInt(json['likes']) ?? 0,
        comments: asInt(json['comments']) ?? 0,
        shares: asInt(json['shares']) ?? 0,
        followers: asInt(json['followers']) ?? 0,
        posts: asInt(json['posts']) ?? 0,
      );

  /// The day, as `YYYY-MM-DD`.
  final String date;

  /// Every interaction that day.
  final int engagements;

  /// Impressions that day.
  final int impressions;

  /// Likes that day.
  final int likes;

  /// Comments that day.
  final int comments;

  /// Shares that day.
  final int shares;

  /// Followers at the end of the day.
  final int followers;

  /// Posts published that day.
  final int posts;

  @override
  String toString() => 'TimeSeriesPoint($date)';
}

/// Daily activity over the window.
class AnalyticsTimeSeries {
  /// Creates a series.
  const AnalyticsTimeSeries({this.days = 0, this.series = const []});

  /// Reads a series.
  factory AnalyticsTimeSeries.fromJson(Map<String, dynamic> json) => AnalyticsTimeSeries(
        days: asInt(json['days']) ?? 0,
        series: asModelList(json['series'], TimeSeriesPoint.fromJson),
      );

  /// How many days the window covers.
  final int days;

  /// One point per day.
  final List<TimeSeriesPoint> series;

  @override
  String toString() => 'AnalyticsTimeSeries($days days)';
}

/// One platform a top post reached.
class TopPostPlatform {
  /// Creates a platform reference.
  const TopPostPlatform({required this.platform, this.username, this.url});

  /// Reads a platform reference.
  factory TopPostPlatform.fromJson(Map<String, dynamic> json) => TopPostPlatform(
        platform: asString(json['platform']) ?? '',
        username: asString(json['username']),
        url: asString(json['url']),
      );

  /// The network.
  final String platform;

  /// The account's handle.
  final String? username;

  /// The public permalink.
  final String? url;

  @override
  String toString() => 'TopPostPlatform($platform)';
}

/// A top post's numbers.
class TopPostMetrics {
  /// Creates a metrics block.
  const TopPostMetrics({
    this.engagements = 0,
    this.impressions = 0,
    this.reach = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.reposts = 0,
    this.clicks = 0,
    this.saves = 0,
    this.videoViews = 0,
  });

  /// Reads a metrics block.
  factory TopPostMetrics.fromJson(Map<String, dynamic> json) => TopPostMetrics(
        engagements: asInt(json['engagements']) ?? 0,
        impressions: asInt(json['impressions']) ?? 0,
        reach: asInt(json['reach']) ?? 0,
        likes: asInt(json['likes']) ?? 0,
        comments: asInt(json['comments']) ?? 0,
        shares: asInt(json['shares']) ?? 0,
        reposts: asInt(json['reposts']) ?? 0,
        clicks: asInt(json['clicks']) ?? 0,
        saves: asInt(json['saves']) ?? 0,
        videoViews: asInt(json['videoViews']) ?? 0,
      );

  /// Every interaction, summed.
  final int engagements;

  /// Times the post was shown.
  final int impressions;

  /// Unique accounts that saw it.
  final int reach;

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

  @override
  String toString() => 'TopPostMetrics($engagements engagements)';
}

/// One high-performing post.
class TopPost {
  /// Creates a top post.
  const TopPost({
    required this.rank,
    required this.metrics,
    this.postId,
    this.externalPostId,
    this.source,
    this.preview,
    this.permalink,
    this.thumbnailUrl,
    this.status,
    this.createdAt,
    this.platforms = const [],
    this.labels = const [],
  });

  /// Reads a top post.
  factory TopPost.fromJson(Map<String, dynamic> json) => TopPost(
        rank: asInt(json['rank']) ?? 0,
        metrics: TopPostMetrics.fromJson(asMap(json['metrics'])),
        postId: asString(json['postId']),
        externalPostId: asString(json['externalPostId']),
        source: asString(json['source']),
        preview: asString(json['preview']),
        permalink: asString(json['permalink']),
        thumbnailUrl: asString(json['thumbnailUrl']),
        status: asString(json['status']),
        createdAt: asDate(json['createdAt']),
        platforms: asModelList(json['platforms'], TopPostPlatform.fromJson),
        labels: asModelList(json['labels'], PostLabelRef.fromJson),
      );

  /// Where this post placed, counting from one.
  final int rank;

  /// The post's numbers.
  final TopPostMetrics metrics;

  /// The FoPost post id, when the post was published from here.
  final String? postId;

  /// The platform's own id, when the post was found on the account.
  final String? externalPostId;

  /// `fopost` or `platform`.
  final String? source;

  /// The start of the post's text.
  final String? preview;

  /// The public permalink.
  final String? permalink;

  /// A thumbnail for the post.
  final String? thumbnailUrl;

  /// The post's status.
  final String? status;

  /// When the post was composed.
  final DateTime? createdAt;

  /// One entry per platform it reached.
  final List<TopPostPlatform> platforms;

  /// The campaign labels on it.
  final List<PostLabelRef> labels;

  @override
  String toString() => 'TopPost(#$rank)';
}

/// One campaign label's performance.
class LabelAnalytics {
  /// Creates a label roll-up.
  const LabelAnalytics({
    required this.labelId,
    required this.name,
    this.color,
    this.postCount = 0,
    this.impressions = 0,
    this.reach = 0,
    this.engagements = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.engagementRate,
    this.followerDelta,
  });

  /// Reads a label roll-up.
  factory LabelAnalytics.fromJson(Map<String, dynamic> json) => LabelAnalytics(
        labelId: asString(json['labelId']) ?? '',
        name: asString(json['name']) ?? '',
        color: asString(json['color']),
        postCount: asInt(json['postCount']) ?? 0,
        impressions: asInt(json['impressions']) ?? 0,
        reach: asInt(json['reach']) ?? 0,
        engagements: asInt(json['engagements']) ?? 0,
        likes: asInt(json['likes']) ?? 0,
        comments: asInt(json['comments']) ?? 0,
        shares: asInt(json['shares']) ?? 0,
        engagementRate: asDouble(json['engagementRate']),
        followerDelta: asInt(json['followerDelta']),
      );

  /// The label's id.
  final String labelId;

  /// The label's name.
  final String name;

  /// The label's hex color.
  final String? color;

  /// Posts carrying the label.
  final int postCount;

  /// Impressions across them.
  final int impressions;

  /// Unique accounts reached.
  final int reach;

  /// Every interaction, summed.
  final int engagements;

  /// Likes.
  final int likes;

  /// Comments.
  final int comments;

  /// Shares.
  final int shares;

  /// Engagement as a fraction of impressions.
  final double? engagementRate;

  /// Followers gained while the campaign ran.
  final int? followerDelta;

  @override
  String toString() => 'LabelAnalytics($name, $postCount posts)';
}

/// One row of the posts table, with its per-platform delivery breakdown.
class PostsTableRow {
  /// Creates a row.
  const PostsTableRow({
    required this.postId,
    this.preview,
    this.status,
    this.createdAt,
    this.scheduledAt,
    this.platforms = const [],
    this.total = 0,
    this.published = 0,
    this.failed = 0,
    this.pending = 0,
  });

  /// Reads a row.
  factory PostsTableRow.fromJson(Map<String, dynamic> json) {
    final summary = asMap(json['deliverySummary']);
    return PostsTableRow(
      postId: asString(json['postId']) ?? '',
      preview: asString(json['preview']),
      status: asString(json['status']),
      createdAt: asDate(json['createdAt']),
      scheduledAt: asDate(json['scheduledAt']),
      platforms: asModelList(json['platforms'], PostsTablePlatform.fromJson),
      total: asInt(summary['total']) ?? 0,
      published: asInt(summary['published']) ?? 0,
      failed: asInt(summary['failed']) ?? 0,
      pending: asInt(summary['pending']) ?? 0,
    );
  }

  /// The post's id.
  final String postId;

  /// The start of the post's text.
  final String? preview;

  /// The post's status.
  final String? status;

  /// When the post was composed.
  final DateTime? createdAt;

  /// When it is scheduled to go out.
  final DateTime? scheduledAt;

  /// One entry per target platform.
  final List<PostsTablePlatform> platforms;

  /// How many deliveries the post has.
  final int total;

  /// How many are live.
  final int published;

  /// How many failed.
  final int failed;

  /// How many are still waiting.
  final int pending;

  @override
  String toString() => 'PostsTableRow($postId, $published/$total published)';
}

/// One platform on a posts-table row.
class PostsTablePlatform {
  /// Creates a platform cell.
  const PostsTablePlatform({required this.platform, this.username, this.url, this.deliveryStatus});

  /// Reads a platform cell.
  factory PostsTablePlatform.fromJson(Map<String, dynamic> json) => PostsTablePlatform(
        platform: asString(json['platform']) ?? '',
        username: asString(json['username']),
        url: asString(json['url']),
        deliveryStatus: asString(json['deliveryStatus']),
      );

  /// The network.
  final String platform;

  /// The account's handle.
  final String? username;

  /// The public permalink.
  final String? url;

  /// One of `DeliveryStatus`.
  final String? deliveryStatus;

  @override
  String toString() => 'PostsTablePlatform($platform, $deliveryStatus)';
}

/// A page of posts with their delivery breakdown.
class PostsTable {
  /// Creates a posts table.
  const PostsTable({
    this.posts = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 0,
    this.statusSummary = const {},
  });

  /// Reads a posts table.
  factory PostsTable.fromJson(Map<String, dynamic> json) {
    final summary = <String, int>{};
    asMap(json['statusSummary']).forEach((key, value) {
      final count = asInt(value);
      if (count != null) summary[key] = count;
    });
    return PostsTable(
      posts: asModelList(json['posts'], PostsTableRow.fromJson),
      total: asInt(json['total']) ?? 0,
      page: asInt(json['page']) ?? 1,
      limit: asInt(json['limit']) ?? 0,
      statusSummary: summary,
    );
  }

  /// The rows on this page.
  final List<PostsTableRow> posts;

  /// How many rows match in total.
  final int total;

  /// The page this is.
  final int page;

  /// How many rows a page holds.
  final int limit;

  /// Matching posts counted by status.
  final Map<String, int> statusSummary;

  @override
  String toString() => 'PostsTable(${posts.length} of $total)';
}

/// One day of posting activity.
class StreakDay {
  /// Creates a streak day.
  const StreakDay({
    required this.date,
    this.count = 0,
    this.publishedCount = 0,
    this.failedCount = 0,
    this.scheduledCount = 0,
  });

  /// Reads a streak day.
  factory StreakDay.fromJson(Map<String, dynamic> json) => StreakDay(
        date: asString(json['date']) ?? '',
        count: asInt(json['count']) ?? 0,
        publishedCount: asInt(json['publishedCount']) ?? 0,
        failedCount: asInt(json['failedCount']) ?? 0,
        scheduledCount: asInt(json['scheduledCount']) ?? 0,
      );

  /// The day, as `YYYY-MM-DD`.
  final String date;

  /// Posts touching that day.
  final int count;

  /// Of those, how many went live.
  final int publishedCount;

  /// Of those, how many failed.
  final int failedCount;

  /// Of those, how many are still scheduled.
  final int scheduledCount;

  @override
  String toString() => 'StreakDay($date, $count)';
}

/// One slice of an audience: a value and its share.
class DemographicsBucket {
  /// Creates a bucket.
  const DemographicsBucket({required this.key, required this.value, required this.share});

  /// Reads a bucket.
  factory DemographicsBucket.fromJson(Map<String, dynamic> json) => DemographicsBucket(
        key: asString(json['key']) ?? '',
        value: asDouble(json['value']) ?? 0,
        share: asDouble(json['share']) ?? 0,
      );

  /// What the slice is, e.g. `25-34` or `US`.
  final String key;

  /// The raw count.
  final double value;

  /// The slice's share of the whole, as a fraction.
  final double share;

  @override
  String toString() => 'DemographicsBucket($key, $share)';
}

/// An account named in a demographics response.
class DemographicsAccountRef {
  /// Creates an account reference.
  const DemographicsAccountRef({required this.accountId, required this.platform, this.username});

  /// Reads an account reference.
  factory DemographicsAccountRef.fromJson(Map<String, dynamic> json) =>
      DemographicsAccountRef(
        accountId: asString(json['accountId']) ?? '',
        platform: asString(json['platform']) ?? '',
        username: asString(json['username']),
      );

  /// The account's id.
  final String accountId;

  /// The account's network.
  final String platform;

  /// The account's handle.
  final String? username;

  @override
  String toString() => 'DemographicsAccountRef($platform)';
}

/// An audience breakdown.
class Demographics {
  /// Creates a breakdown.
  const Demographics({
    required this.audience,
    this.age = const [],
    this.gender = const [],
    this.country = const [],
    this.city = const [],
    this.contributingAccounts = const [],
    this.unsupportedAccounts = const [],
  });

  /// Reads a breakdown.
  factory Demographics.fromJson(Map<String, dynamic> json) {
    final dimensions = asMap(json['dimensions']);
    return Demographics(
      audience: asString(json['audience']) ?? DemographicsAudience.followers,
      age: asModelList(dimensions['age'], DemographicsBucket.fromJson),
      gender: asModelList(dimensions['gender'], DemographicsBucket.fromJson),
      country: asModelList(dimensions['country'], DemographicsBucket.fromJson),
      city: asModelList(dimensions['city'], DemographicsBucket.fromJson),
      contributingAccounts:
          asModelList(json['contributingAccounts'], DemographicsAccountRef.fromJson),
      unsupportedAccounts:
          asModelList(json['unsupportedAccounts'], DemographicsAccountRef.fromJson),
    );
  }

  /// One of [DemographicsAudience].
  final String audience;

  /// The age breakdown.
  final List<DemographicsBucket> age;

  /// The gender breakdown.
  final List<DemographicsBucket> gender;

  /// The country breakdown.
  final List<DemographicsBucket> country;

  /// The city breakdown.
  final List<DemographicsBucket> city;

  /// The accounts these numbers came from.
  final List<DemographicsAccountRef> contributingAccounts;

  /// The accounts whose platform does not report demographics.
  final List<DemographicsAccountRef> unsupportedAccounts;

  @override
  String toString() => 'Demographics($audience)';
}

/// One account that failed during a collection run.
class CollectError {
  /// Creates a collection error.
  const CollectError({required this.accountId, required this.stage, this.platform, this.username, this.message});

  /// Reads a collection error.
  factory CollectError.fromJson(Map<String, dynamic> json) => CollectError(
        accountId: asString(json['accountId']) ?? '',
        stage: asString(json['stage']) ?? '',
        platform: asString(json['platform']),
        username: asString(json['username']),
        message: asString(json['message']),
      );

  /// The account that failed.
  final String accountId;

  /// `account`, `demographics`, `timeline`, or `post`.
  final String stage;

  /// The account's network.
  final String? platform;

  /// The account's handle.
  final String? username;

  /// What went wrong.
  final String? message;

  @override
  String toString() => 'CollectError($platform, $stage)';
}

/// What a collection run refreshed.
class CollectSummary {
  /// Creates a collection summary.
  const CollectSummary({
    this.accounts = 0,
    this.posts = 0,
    this.demographics = 0,
    this.errors = 0,
    this.errorDetails = const [],
  });

  /// Reads a collection summary.
  factory CollectSummary.fromJson(Map<String, dynamic> json) => CollectSummary(
        accounts: asInt(json['accounts']) ?? 0,
        posts: asInt(json['posts']) ?? 0,
        demographics: asInt(json['demographics']) ?? 0,
        errors: asInt(json['errors']) ?? 0,
        errorDetails: asModelList(json['errorDetails'], CollectError.fromJson),
      );

  /// Accounts refreshed.
  final int accounts;

  /// Posts refreshed.
  final int posts;

  /// Demographics breakdowns refreshed.
  final int demographics;

  /// How many accounts failed.
  final int errors;

  /// Those failures, one per account and stage.
  final List<CollectError> errorDetails;

  @override
  String toString() => 'CollectSummary($accounts accounts, $errors errors)';
}
