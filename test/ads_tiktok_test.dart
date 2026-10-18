import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('reads business centers, identities and spark posts', () async {
    final seen = RecordedRequests();
    final client = fakeClient((request) async {
      if (request.url.path.endsWith('/business-centers')) {
        return jsonOk([
          {'id': 'bc1', 'name': 'Brand HQ', 'role': 'ADMIN'}
        ]);
      }
      if (request.url.path.endsWith('/identities')) {
        return jsonOk([
          {'id': 'idt_1', 'type': 'CUSTOMIZED_USER', 'name': 'Your Brand'}
        ]);
      }
      return jsonOk([
        {'id': 'item_99', 'identityId': 'idt_1', 'views': 48213}
      ]);
    }, recorder: seen);

    final centers = await client.ads
        .tiktokBusinessCenters(connectionId: 'conn_1', workspaceId: 'ws_1');
    expect(centers.single.name, 'Brand HQ');
    expect(seen.last.url.path, '/v1/ads/tiktok/business-centers');

    final identities = await client.ads.tiktokIdentities(
        connectionId: 'conn_1', adAccountId: '7011', workspaceId: 'ws_1');
    expect(identities.single.type, 'CUSTOMIZED_USER');

    final posts = await client.ads.sparkPosts(
        connectionId: 'conn_1',
        adAccountId: '7011',
        identityId: 'idt_1',
        workspaceId: 'ws_1');
    expect(posts.single.views, 48213);
    expect(seen.last.url.queryParameters['identity_id'], 'idt_1');
  });

  test('sends sparkPostId on an ad and smartPlus on a campaign', () async {
    final seen = RecordedRequests();
    final client = fakeClient((request) async {
      if (request.url.path.endsWith('/campaigns')) {
        return jsonOk({'id': 'c1', 'name': 'Smart', 'status': 'PAUSED'},
            headers: const {});
      }
      return jsonOk({
        'id': 'ad_1',
        'workspaceId': 'ws_1',
        'kind': 'ad',
        'name': 'Spark',
        'goal': 'traffic',
        'status': AdStatus.paused,
      });
    }, recorder: seen);

    await client.ads.create(
      workspaceId: 'ws_1',
      connectionId: 'conn_1',
      adAccountId: '7011',
      pageId: 'idt_1',
      name: 'Spark',
      goal: AdGoal.traffic,
      budget: const AdBudget(minor: 2000, type: AdBudgetType.daily),
      targeting: const AdTargeting(countries: ['US'], ageMin: 18, ageMax: 44),
      text: '',
      sparkPostId: 'item_99',
    );
    expect(jsonDecode(seen.last.body)['sparkPostId'], 'item_99');

    await client.ads.createCampaign(
      workspaceId: 'ws_1',
      connectionId: 'conn_1',
      adAccountId: '7011',
      name: 'Smart',
      goal: AdGoal.traffic,
      smartPlus: true,
    );
    expect(jsonDecode(seen.last.body)['smartPlus'], true);
  });

  test('uploads conversions and reports what the network accepted', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk(
            {'id': 'cb_1', 'accepted': 2, 'eventCount': 2, 'replayed': false}),
        recorder: seen);

    final result = await client.ads.uploadConversions(
      workspaceId: 'ws_1',
      connectionId: 'conn_1',
      adAccountId: '7011',
      pixelId: 'px_1',
      events: [
        {'eventName': 'CompletePayment', 'occurredAt': '2026-09-18T10:04:00Z'}
      ],
    );

    expect(result.accepted, 2);
    expect(result.id, 'cb_1');
    expect(result.replayed, isFalse);
    expect(seen.last.url.path, '/v1/ads/conversions');
    expect(seen.last.headers.containsKey('Idempotency-Key'), isFalse);
    expect(jsonDecode(seen.last.body)['pixelId'], 'px_1');
  });

  test('sends pixel conversions once per Idempotency-Key', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk(
            {'id': 'cb_2', 'accepted': 1, 'eventCount': 1, 'replayed': true},
            headers: const {'idempotency-replayed': 'true'}),
        recorder: seen);

    final result = await client.ads.sendPixelConversions(
      idempotencyKey: 'order-991',
      workspaceId: 'ws_1',
      connectionId: 'conn_1',
      adAccountId: 'act_1',
      pixelId: 'px_1',
      events: const [
        PixelConversionEvent(
          eventName: 'Purchase',
          occurredAt: '2026-10-18T09:00:00Z',
          eventId: 'order-991',
          actionSource: ConversionActionSource.website,
          email: 'buyer@yourbrand.com',
          valueMinor: 4999,
          currency: 'USD',
          contentIds: ['sku_1'],
        ),
      ],
    );

    expect(result.replayed, isTrue);
    expect(seen.last.url.path, '/v1/ads/conversions/events');
    expect(seen.last.headers['Idempotency-Key'], 'order-991');
    final event = jsonDecode(seen.last.body)['events'][0];
    expect(event['actionSource'], 'website');
    expect(event['contentIds'], ['sku_1']);
    expect(event.containsKey('phone'), isFalse);
  });

  test('lists conversion batches with hashed identifiers', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk([
              {
                'id': 'cb_1',
                'workspaceId': 'ws_1',
                'connectionId': 'conn_1',
                'adAccountId': 'act_1',
                'pixelId': 'px_1',
                'idempotencyKey': 'order-991',
                'eventCount': 1,
                'accepted': 1,
                'events': [
                  {
                    'eventName': 'Purchase',
                    'occurredAt': '2026-10-18T09:00:00Z',
                    'actionSource': 'website',
                    'emailHash': 'ab12',
                    'valueMinor': 4999,
                  }
                ],
                'createdAt': '2026-10-18T09:00:01Z',
              }
            ]),
        recorder: seen);

    final batches =
        await client.ads.listConversionBatches(workspaceId: 'ws_1', limit: 10);
    expect(batches.single.idempotencyKey, 'order-991');
    expect(batches.single.events.single.emailHash, 'ab12');
    expect(seen.last.url.queryParameters['limit'], '10');
  });

  test('reads a pixel with its install code and stats', () async {
    final seen = RecordedRequests();
    final client = fakeClient((request) async {
      if (request.url.path.endsWith('/stats')) {
        return jsonOk({
          'since': '2026-09-20',
          'until': '2026-10-18',
          'events': [
            {'eventName': 'PageView', 'count': 1200}
          ],
        });
      }
      if (request.url.path.endsWith('/match-quality')) {
        return jsonOk([
          {
            'eventName': 'Purchase',
            'score': 7.5,
            'matchKeys': [
              {'identifier': 'email', 'coveragePercent': 80}
            ],
          }
        ]);
      }
      return jsonOk({
        'id': 'px_1',
        'name': 'Site',
        'code': '<script>fbq()</script>',
        'isUnavailable': false,
        'dataUseSetting': 'advertising_and_analytics',
      });
    }, recorder: seen);

    final pixel = await client.ads
        .pixel('px_1', connectionId: 'conn_1', adAccountId: 'act_1');
    expect(pixel.code, contains('fbq'));
    expect(pixel.dataUseSetting, PixelDataUseSetting.advertisingAndAnalytics);
    expect(seen.last.url.path, '/v1/ads/pixels/px_1');
    expect(seen.last.url.queryParameters['ad_account_id'], 'act_1');

    final stats = await client.ads
        .pixelStats('px_1', connectionId: 'conn_1', adAccountId: 'act_1');
    expect(stats.events.single.count, 1200);

    final quality = await client.ads.eventMatchQuality('px_1',
        connectionId: 'conn_1', adAccountId: 'act_1');
    expect(quality.single.score, 7.5);
    expect(quality.single.matchKeys.single.coveragePercent, 80);
  });

  test('creates and deletes a custom conversion', () async {
    final seen = RecordedRequests();
    final client = fakeClient((request) async {
      if (request.method == 'DELETE') return jsonBare(null, status: 204);
      return jsonBare({
        'data': {
          'id': 'cc_1',
          'name': 'Checkout',
          'pixelId': 'px_1',
          'eventType': 'PURCHASE',
          'rule': {'eventName': 'PageView', 'urlContains': '/thanks'},
          'isArchived': false,
          'isUnavailable': false,
        }
      }, status: 201);
    }, recorder: seen);

    final created = await client.ads.createCustomConversion(
      workspaceId: 'ws_1',
      connectionId: 'conn_1',
      adAccountId: 'act_1',
      pixelId: 'px_1',
      name: 'Checkout',
      eventType: CustomConversionEventType.purchase,
      rule: const CustomConversionRule(urlContains: '/thanks'),
      defaultValueMinor: 2500,
    );
    expect(created.id, 'cc_1');
    expect(created.rule?.urlContains, '/thanks');
    expect(seen.last.url.path, '/v1/ads/custom-conversions');
    final body = jsonDecode(seen.last.body);
    expect(body['eventType'], 'PURCHASE');
    expect(body['rule'], {'urlContains': '/thanks'});
    expect(body['defaultValueMinor'], 2500);
    expect(body.containsKey('description'), isFalse);

    await client.ads.deleteCustomConversion('cc_1',
        workspaceId: 'ws_1', connectionId: 'conn_1', adAccountId: 'act_1');
    expect(seen.last.method, 'DELETE');
    expect(seen.last.url.path, '/v1/ads/custom-conversions/cc_1');
    expect(jsonDecode(seen.last.body)['adAccountId'], 'act_1');
  });

  test('reads a page of comments and answers, hides and deletes one', () async {
    final seen = RecordedRequests();
    final client = fakeClient((request) async {
      if (request.method == 'GET') {
        return jsonOk({
          'comments': [
            {'id': 'cm_1', 'text': 'nice', 'likes': 3, 'hidden': true}
          ],
          'nextCursor': '2',
        });
      }
      if (request.url.path.endsWith('/reply')) {
        return jsonOk({'replyId': 'cm_2'});
      }
      return jsonBare({'message': 'ok'});
    }, recorder: seen);

    final page = await client.ads
        .comments(connectionId: 'conn_1', adId: 'ad_1', workspaceId: 'ws_1');
    expect(page.nextCursor, '2');
    expect(page.comments.single.hidden, isTrue);
    expect(page.comments.single.likes, 3);

    final replyId = await client.ads.replyToComment('cm_1',
        workspaceId: 'ws_1',
        connectionId: 'conn_1',
        adId: 'ad_1',
        text: 'Friday!');
    expect(replyId, 'cm_2');
    expect(seen.last.url.path, '/v1/ads/comments/cm_1/reply');

    await client.ads.setCommentHidden('cm_1',
        workspaceId: 'ws_1',
        connectionId: 'conn_1',
        adId: 'ad_1',
        hidden: true);
    expect(jsonDecode(seen.last.body)['hidden'], true);

    await client.ads.deleteComment('cm_1',
        workspaceId: 'ws_1', connectionId: 'conn_1', adId: 'ad_1');
    // The ad travels in the body, because the path already carries the comment.
    expect(seen.last.method, 'DELETE');
    expect(jsonDecode(seen.last.body)['adId'], 'ad_1');
  });
}
