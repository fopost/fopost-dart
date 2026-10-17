import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

const _facebookSet = {
  'platform': 'facebook',
  'account': {
    'fetched_at': '2026-09-20T02:00:00.000Z',
    'metrics': [
      {
        'key': 'page_daily_video_ad_break_earnings',
        'label': 'Ad Break Earnings',
        'kind': 'currency_usd',
        'value': 42.15,
      },
      {
        'key': 'page_impressions_paid',
        'label': 'Paid Impressions',
        'kind': 'count',
        'value': 1500,
      },
    ],
  },
  'post': {
    'external_post_id': '123_456',
    'fetched_at': '2026-09-20T02:00:00.000Z',
    'metrics': <Object?>[],
  },
};

void main() {
  test('platformMetrics asks for raw and reads the set', () async {
    final seen = RecordedRequests();
    final client =
        fakeClient((_) async => jsonOk(_facebookSet), recorder: seen);

    final metrics = await client.accounts.platformMetrics('acc_1');

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/accounts/acc_1/insights');
    expect(seen.last.url.queryParameters['raw'], 'true');
    expect(metrics.platform, 'facebook');
    expect(metrics.account.fetchedAt, '2026-09-20T02:00:00.000Z');
    expect(metrics.account.metrics.map((m) => m.key),
        ['page_daily_video_ad_break_earnings', 'page_impressions_paid']);
    expect(metrics.account.metrics.first.number, 42.15);
    expect(metrics.post.externalPostId, '123_456');
    expect(metrics.post.metrics, isEmpty);
    client.close();
  });

  test('a series value survives as a list', () async {
    final client = fakeClient((_) async => jsonOk({
          'platform': 'youtube',
          'account': {
            'fetched_at': null,
            'metrics': [
              {
                'key': 'daily_views',
                'label': 'Views by Day',
                'kind': 'series',
                'value': [
                  {'day': '2026-09-19', 'views': 600}
                ],
              }
            ],
          },
          'post': {
            'external_post_id': null,
            'fetched_at': null,
            'metrics': <Object?>[]
          },
        }));

    final row =
        (await client.accounts.platformMetrics('acc_1')).account.metrics.first;

    expect(row.number, isNull);
    expect((row.value! as List).first, {'day': '2026-09-19', 'views': 600});
    client.close();
  });

  test('a pending metric grant throws', () async {
    final client = fakeClient(
      (_) async => jsonError(503, 'platform_metrics_unavailable',
          'google-business metrics are not available on this deployment yet.'),
      maxRetries: 1,
    );

    await expectLater(
      client.accounts.platformMetrics('acc_1'),
      throwsA(predicate<FoPostException>((e) =>
          e.statusCode == 503 && e.code == 'platform_metrics_unavailable')),
    );
    client.close();
  });
}
