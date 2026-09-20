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
    final client =
        fakeClient((_) async => jsonOk({'accepted': 2}), recorder: seen);

    final accepted = await client.ads.uploadConversions(
      workspaceId: 'ws_1',
      connectionId: 'conn_1',
      adAccountId: '7011',
      pixelId: 'px_1',
      events: [
        {'eventName': 'CompletePayment', 'occurredAt': '2026-09-18T10:04:00Z'}
      ],
    );

    expect(accepted, 2);
    expect(seen.last.url.path, '/v1/ads/conversions');
    expect(jsonDecode(seen.last.body)['pixelId'], 'px_1');
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
