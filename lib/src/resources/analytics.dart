import 'package:meta/meta.dart';

import '../http.dart';
import '../models/analytics.dart';

/// The cross-account reporting surface.
///
/// Reach it as `client.analytics`. [days] and an explicit [from]/[to] range
/// are alternatives; unset parameters leave the API's defaults in place.
class AnalyticsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  AnalyticsResource(this._http);

  final FoPostHttp _http;

  Map<String, dynamic> _window({
    String? accountId,
    String? workspaceId,
    int? days,
    String? from,
    String? to,
    int? limit,
    String? sort,
    String? label,
    int? page,
  }) =>
      {
        'accountId': accountId,
        'workspace_id': workspaceId,
        'days': days,
        'from': from,
        'to': to,
        'limit': limit,
        'sort': sort,
        'label': label,
        'page': page,
      };

  /// Returns the headline numbers for the window.
  Future<AnalyticsOverview> overview({
    String? accountId,
    String? workspaceId,
    int? days,
    String? from,
    String? to,
  }) async =>
      AnalyticsOverview.fromJson(await _http.object(
        'GET',
        '/analytics/overview',
        query: _window(
            accountId: accountId,
            workspaceId: workspaceId,
            days: days,
            from: from,
            to: to),
      ));

  /// Returns one point per day in the window.
  Future<AnalyticsTimeSeries> timeSeries({
    String? accountId,
    String? workspaceId,
    int? days,
    String? from,
    String? to,
  }) async =>
      AnalyticsTimeSeries.fromJson(await _http.object(
        'GET',
        '/analytics/time-series',
        query: _window(
            accountId: accountId,
            workspaceId: workspaceId,
            days: days,
            from: from,
            to: to),
      ));

  /// Returns the best performing posts in the window.
  ///
  /// [sort] takes `recent` to order by date instead of performance.
  Future<List<TopPost>> topPosts({
    String? accountId,
    String? workspaceId,
    int? days,
    String? from,
    String? to,
    int? limit,
    String? sort,
    String? label,
  }) async {
    final rows = await _http.objects(
      'GET',
      '/analytics/top-posts',
      query: _window(
        accountId: accountId,
        workspaceId: workspaceId,
        days: days,
        from: from,
        to: to,
        limit: limit,
        sort: sort,
        label: label,
      ),
    );
    return rows.map(TopPost.fromJson).toList();
  }

  /// Returns a per-label campaign roll-up.
  Future<List<LabelAnalytics>> labels({
    String? accountId,
    String? workspaceId,
    int? days,
    String? from,
    String? to,
  }) async {
    final rows = await _http.objects(
      'GET',
      '/analytics/labels',
      query: _window(
          accountId: accountId,
          workspaceId: workspaceId,
          days: days,
          from: from,
          to: to),
    );
    return rows.map(LabelAnalytics.fromJson).toList();
  }

  /// Returns posts with their delivery breakdown, paginated.
  Future<PostsTable> postsTable({
    String? accountId,
    String? workspaceId,
    int? days,
    String? from,
    String? to,
    int? limit,
    int? page,
  }) async =>
      PostsTable.fromJson(await _http.object(
        'GET',
        '/analytics/posts-table',
        query: _window(
          accountId: accountId,
          workspaceId: workspaceId,
          days: days,
          from: from,
          to: to,
          limit: limit,
          page: page,
        ),
      ));

  /// Returns a year of posting activity.
  Future<List<StreakDay>> postingStreak({String? workspaceId}) async {
    final body = await _http.object('GET', '/analytics/posting-streak',
        query: {'workspace_id': workspaceId});
    final streak = body['streak'];
    if (streak is! List) return const [];
    return streak
        .whereType<Map>()
        .map((e) => StreakDay.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Returns an audience breakdown.
  ///
  /// [audience] is one of `DemographicsAudience`; leaving it unset means
  /// followers.
  Future<Demographics> demographics({
    String? audience,
    String? accountId,
    String? workspaceId,
    int? days,
    String? from,
    String? to,
  }) async {
    final query = _window(
      accountId: accountId,
      workspaceId: workspaceId,
      days: days,
      from: from,
      to: to,
    );
    query['audience'] = audience;
    return Demographics.fromJson(
        await _http.object('GET', '/analytics/demographics', query: query));
  }

  /// Pulls fresh numbers from the platforms.
  ///
  /// This is rate limited harder than the read endpoints, since every call
  /// reaches out to a network.
  Future<CollectSummary> collect({String? accountId}) async =>
      CollectSummary.fromJson(await _http.object('POST', '/analytics/collect',
          query: {'accountId': accountId}));
}
