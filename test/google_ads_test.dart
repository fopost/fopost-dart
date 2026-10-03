import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

const scope = GoogleAdsScope(
  workspaceId: 'ws_1',
  connectionId: 'conn_1',
  customerId: '1234567890',
);

void main() {
  test('keywords name the connection and the customer', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonBare({
        'data': [
          {
            'id': '1234567890~keyword~77~99',
            'adGroupId': '1234567890~adGroup~77',
            'text': 'running shoes',
            'matchType': 'EXACT',
            'status': 'ENABLED',
            'cpcBidMinor': 180,
            'negative': false,
          }
        ]
      }),
      recorder: seen,
    );

    final keywords = await client.googleAds
        .keywords(scope, adGroupId: '1234567890~adGroup~77');

    expect(keywords.single.text, 'running shoes');
    expect(keywords.single.cpcBidMinor, 180);
    expect(seen.last.url.path, '/v1/ads/google/keywords');
    expect(seen.last.url.queryParameters['connection_id'], 'conn_1');
    expect(seen.last.url.queryParameters['customer_id'], '1234567890');
    expect(
        seen.last.url.queryParameters['ad_group_id'], '1234567890~adGroup~77');
  });

  test('create keyword sends the scope in the body', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonBare({
        'data': {'id': '1234567890~keyword~77~99'}
      }, status: 201),
      recorder: seen,
    );

    final id = await client.googleAds.createKeyword(
      scope,
      adGroupId: '1234567890~adGroup~77',
      text: 'running shoes',
      matchType: 'EXACT',
    );

    expect(id, '1234567890~keyword~77~99');
    final body = jsonDecode(seen.last.body) as Map<String, dynamic>;
    expect(body['customerId'], '1234567890');
    expect(body['matchType'], 'EXACT');
  });

  test('delete carries the scope in the body', () async {
    final seen = RecordedRequests();
    final client =
        fakeClient((_) async => jsonBare({'data': null}), recorder: seen);

    await client.googleAds.deleteAsset('1234567890~asset~4321', scope);

    expect(seen.last.method, 'DELETE');
    expect(seen.last.url.path, '/v1/ads/google/assets/1234567890~asset~4321');
    expect(jsonDecode(seen.last.body), {
      'workspaceId': 'ws_1',
      'connectionId': 'conn_1',
      'customerId': '1234567890',
    });
  });

  test('ad schedule is replaced with put', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonBare({
        'data': {'slots': 2}
      }),
      recorder: seen,
    );

    final slots = await client.googleAds.setAdSchedule(
      scope,
      campaignId: '1234567890~campaign~55',
      slots: [
        {'dayOfWeek': 'MONDAY', 'startHour': 9, 'endHour': 18}
      ],
    );

    expect(slots, 2);
    expect(seen.last.method, 'PUT');
  });

  test('query returns rows as google sends them', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonBare({
        'data': {
          'rows': [
            {
              'campaign': {'id': '55'}
            }
          ]
        }
      }),
      recorder: seen,
    );

    final rows = await client.googleAds
        .query(scope, query: 'SELECT campaign.id FROM campaign');

    expect(rows.length, 1);
    expect(seen.last.url.path, '/v1/ads/insights/query');
  });

  test('authorize google has its own route', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonBare({
        'data': {'url': 'https://accounts.google.com/o/x'}
      }),
      recorder: seen,
    );

    final url = await client.ads.authorizeGoogle(workspaceId: 'ws_1');

    expect(url, 'https://accounts.google.com/o/x');
    expect(seen.last.url.path, '/v1/ads/connections/google/authorize');
  });
}
