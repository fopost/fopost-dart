import 'package:test/test.dart';

import 'support.dart';

void main() {
  inboxAnalyticsTests();
  test('decay reads the bands and the half life', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'days': 30,
              'postsMeasured': 2,
              'halfLifeBucket': '1h_3h',
              'bands': [
                {
                  'bucket': 'under_1h',
                  'label': 'First hour',
                  'posts': 2,
                  'avgEngagements': 25,
                  'avgImpressions': 300,
                  'shareOfFinal': 0.3,
                },
                {
                  'bucket': '6h_12h',
                  'label': '6-12 hours',
                  'posts': 0,
                  'avgEngagements': 0,
                  'avgImpressions': 0,
                  'shareOfFinal': null,
                },
              ],
            }),
        recorder: seen);

    final decay = await client.analytics.decay(days: 30, accountId: 'acc_1');

    expect(seen.last.url.path, '/v1/analytics/decay');
    expect(seen.last.url.queryParameters, {'accountId': 'acc_1', 'days': '30'});
    expect(decay.halfLifeBucket, '1h_3h');
    expect(decay.postsMeasured, 2);
    expect(decay.bands.first.shareOfFinal, 0.3);
    // A band nothing was measured in reports no share rather than zero
    expect(decay.bands.last.shareOfFinal, isNull);
    client.close();
  });

  test('frequency reads the weeks and the best cadence', () async {
    final client = fakeClient((_) async => jsonOk({
          'days': 90,
          'weeks': [
            {
              'weekStart': '2026-03-02',
              'posts': 2,
              'engagements': 240,
              'avgEngagementsPerPost': 120,
            }
          ],
          'bands': [
            {
              'band': 'under_3',
              'label': '1-2 a week',
              'weeks': 1,
              'posts': 2,
              'avgPostsPerWeek': 2,
              'avgEngagementsPerPost': 120,
              'engagementRate': 0.12,
            }
          ],
          'best': {
            'band': 'under_3',
            'label': '1-2 a week',
            'avgEngagementsPerPost': 120,
          },
        }));

    final cadence = await client.analytics.frequency(days: 90);

    expect(cadence.weeks.single.weekStart, '2026-03-02');
    expect(cadence.bands.single.engagementRate, 0.12);
    expect(cadence.best?.label, '1-2 a week');
    client.close();
  });

  test('a timeline can be addressed by permalink', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'postId': null,
              'deliveries': [
                {
                  'accountId': 'acc_1',
                  'platform': 'twitter',
                  'username': 'acme',
                  'externalPostId': '1',
                  'postedAt': '2026-03-02T00:00:00.000Z',
                  'points': [
                    {
                      'at': '2026-03-02T00:30:00.000Z',
                      'ageMinutes': 30,
                      'engagements': 40,
                      'impressions': 400,
                      'reach': null,
                      'likes': 30,
                      'comments': null,
                      'shares': null,
                      'videoViews': null,
                      'delta': {
                        'impressions': 400,
                        'reach': 0,
                        'engagements': 40,
                        'likes': 30,
                        'comments': 0,
                        'shares': 0,
                      },
                    }
                  ],
                }
              ],
            }),
        recorder: seen);

    final timeline =
        await client.analytics.timeline('https://x.com/acme/status/1');

    expect(
      seen.last.url.toString(),
      contains(
          '/v1/analytics/posts/https%3A%2F%2Fx.com%2Facme%2Fstatus%2F1/timeline'),
    );
    // A post made on the network has no FoPost id
    expect(timeline.postId, isNull);
    expect(timeline.deliveries.single.points.single.ageMinutes, 30);
    expect(timeline.deliveries.single.points.single.delta.engagements, 40);
    client.close();
  });

  test('changes carries the cursor', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'since': '2026-03-02T00:00:00.000Z',
              'cursor': '2026-03-02T06:00:00.000Z',
              'hasMore': true,
              'changes': [
                {
                  'accountId': 'acc_1',
                  'platform': 'twitter',
                  'externalPostId': '1',
                  'postId': 'post_1',
                  'postedAt': '2026-03-02T00:00:00.000Z',
                  'fetchedAt': '2026-03-02T06:00:00.000Z',
                  'impressions': 900,
                  'reach': null,
                  'engagements': 90,
                  'likes': 70,
                  'comments': 10,
                  'shares': 10,
                }
              ],
            }),
        recorder: seen);

    final page = await client.analytics
        .changes(since: '2026-03-02T00:00:00Z', limit: 100);

    expect(seen.last.url.queryParameters['since'], '2026-03-02T00:00:00Z');
    expect(seen.last.url.queryParameters['limit'], '100');
    expect(page.hasMore, isTrue);
    expect(page.changes.single.postId, 'post_1');
    client.close();
  });

  test('collectPost reports each delivery', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'collected': 1,
              'deliveries': [
                {
                  'accountId': 'acc_1',
                  'platform': 'twitter',
                  'externalPostId': '1',
                  'collected': true,
                  'fetchedAt': '2026-03-02T00:30:00.000Z',
                  'message': null,
                }
              ],
            }),
        recorder: seen);

    final result = await client.analytics.collectPost('post_1');

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/posts/post_1/analytics/collect');
    expect(result.collected, 1);
    expect(result.deliveries.single.collected, isTrue);
    client.close();
  });

  test('nativePosts keeps the meta envelope', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({
              'data': [
                {
                  'externalPostId': '1',
                  'text': 'Posted by hand',
                  'permalink': 'https://x.com/acme/status/1',
                  'thumbnailUrl': null,
                  'mediaType': null,
                  'postedAt': '2026-03-02T00:00:00.000Z',
                  'fetchedAt': '2026-03-02T06:00:00.000Z',
                  'metrics': {
                    'impressions': 900,
                    'reach': null,
                    'engagements': 90,
                    'likes': 70,
                    'comments': 10,
                    'shares': 10,
                    'videoViews': null,
                  },
                }
              ],
              'meta': {'page': 1, 'perPage': 20, 'total': 1},
            }),
        recorder: seen);

    final page =
        await client.analytics.nativePosts('acc_1', page: 1, perPage: 20);

    expect(seen.last.url.path, '/v1/accounts/acc_1/native-posts');
    expect(seen.last.url.queryParameters, {'page': '1', 'per_page': '20'});
    expect(page.data, hasLength(1));
    expect(page.data.single.permalink, 'https://x.com/acme/status/1');
    expect(page.data.single.metrics.engagements, 90);
    expect(page.meta.total, 1);
    client.close();
  });
}

void inboxAnalyticsTests() {
  test('inbox reads totals, breakdowns and the heatmap', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'totals': {
                'received': 40,
                'sent': 25,
                'answered': 22,
                'open': 6,
                'conversations': 18,
                'median_response_minutes': 42.5,
              },
              'deltas': {'received': 10, 'sent': null, 'answered': -5},
              'series': [
                {
                  'date': '2026-10-17',
                  'received': 20,
                  'sent': 12,
                  'answered': 11
                }
              ],
              'by_platform': [
                {'platform': 'instagram', 'received': 30, 'sent': 20}
              ],
              'by_type': [
                {'type': 'comment', 'count': 25}
              ],
              'by_account': [
                {
                  'account_id': 'acc_1',
                  'platform': 'instagram',
                  'username': 'yourbrand',
                  'name': 'Your Brand',
                  'avatar': null,
                  'received': 30,
                  'sent': 20,
                }
              ],
              'response_time': [
                {'bucket': 'under_1h', 'count': 15}
              ],
              'heatmap': [
                {'weekday': 1, 'hour': 9, 'count': 4}
              ],
              'time_zone': 'Europe/Zagreb',
            }),
        recorder: seen);

    final report = await client.analytics
        .inbox(workspaceId: 'ws_1', days: 7, tz: 'Europe/Zagreb');

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/analytics/inbox');
    expect(seen.last.url.queryParameters,
        {'workspace_id': 'ws_1', 'days': '7', 'tz': 'Europe/Zagreb'});
    expect(report.totals.received, 40);
    expect(report.totals.medianResponseMinutes, 42.5);
    expect(report.deltas.received, 10);
    expect(report.deltas.sent, isNull);
    expect(report.series.single.date, '2026-10-17');
    expect(report.byPlatform.single.platform, 'instagram');
    expect(report.byType.single.count, 25);
    expect(report.byAccount.single.username, 'yourbrand');
    expect(report.responseTime.single.bucket, 'under_1h');
    expect(report.heatmap.single.hour, 9);
    expect(report.timeZone, 'Europe/Zagreb');
  });
}
