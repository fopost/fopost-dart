import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('ice breakers round-trip and clear', () async {
    final seen = RecordedRequests();
    final breakers = [
      {'question': 'Hours?', 'payload': 'HOURS'}
    ];
    var calls = 0;
    final client = fakeClient((_) async {
      calls++;
      return jsonOk({'ice_breakers': calls == 3 ? [] : breakers});
    }, recorder: seen);

    final listed = await client.accounts.iceBreakers('acc_1');
    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/accounts/acc_1/messaging/ice-breakers');
    expect(listed.first.payload, 'HOURS');

    final saved = await client.accounts.setIceBreakers(
        'acc_1', [const MetaIceBreaker(question: 'Hours?', payload: 'HOURS')]);
    expect(seen.last.method, 'PUT');
    expect(jsonDecode(seen.last.body), {'ice_breakers': breakers});
    expect(saved.first.question, 'Hours?');

    final cleared = await client.accounts.deleteIceBreakers('acc_1');
    expect(seen.last.method, 'DELETE');
    expect(cleared, isEmpty);
    client.close();
  });

  test('a link menu item omits the payload key', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'persistent_menu': [
                {
                  'locale': 'default',
                  'call_to_actions': [
                    {
                      'type': 'web_url',
                      'title': 'Shop',
                      'url': 'https://example.com/shop'
                    }
                  ]
                }
              ]
            }),
        recorder: seen);

    final saved = await client.accounts.setPersistentMenu('acc_1', [
      const MetaPersistentMenuEntry(callToActions: [
        MetaMenuItem.link(title: 'Shop', url: 'https://example.com/shop')
      ])
    ]);

    expect(seen.last.method, 'PUT');
    expect(seen.last.url.path, '/v1/accounts/acc_1/messaging/persistent-menu');
    final sent = jsonDecode(seen.last.body) as Map<String, dynamic>;
    final items = (sent['persistent_menu'] as List).first['call_to_actions']
        as List<dynamic>;
    expect((items.first as Map).containsKey('payload'), isFalse);
    expect(saved.first.callToActions.first.url, 'https://example.com/shop');
    client.close();
  });

  test('the greeting defaults its locale', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'greeting': [
                {'locale': 'default', 'text': 'Hi!'}
              ]
            }),
        recorder: seen);

    final saved = await client.accounts
        .setGreeting('acc_1', [const MetaGreetingText(text: 'Hi!')]);

    expect(jsonDecode(seen.last.body), {
      'greeting': [
        {'locale': 'default', 'text': 'Hi!'}
      ]
    });
    expect(saved.first.locale, 'default');
    client.close();
  });

  test('a lapsed subscription is reported and resubscribed', () async {
    final seen = RecordedRequests();
    var calls = 0;
    final client = fakeClient((_) async {
      calls++;
      return calls == 1
          ? jsonOk({
              'subscribed': false,
              'fields': ['feed'],
              'missing_fields': ['messages']
            })
          : jsonOk({
              'subscribed': true,
              'fields': ['feed', 'messages'],
              'missing_fields': <String>[]
            });
    }, recorder: seen);

    final lapsed = await client.accounts.webhookSubscription('acc_1');
    expect(seen.last.url.path, '/v1/accounts/acc_1/webhook-subscription');
    expect(lapsed.subscribed, isFalse);
    expect(lapsed.missingFields, ['messages']);

    final fixed = await client.accounts.resubscribeWebhook('acc_1');
    expect(seen.last.method, 'POST');
    expect(fixed.subscribed, isTrue);
    client.close();
  });

  test('handover passes to an app and takes control back', () async {
    final seen = RecordedRequests();
    var calls = 0;
    final client = fakeClient((_) async {
      calls++;
      return calls == 1
          ? jsonOk({'app_id': '263902037430900', 'control': 'passed'})
          : jsonOk({'app_id': null, 'control': 'taken'});
    }, recorder: seen);

    final passed = await client.inbox
        .handover('t_1', accountId: 'acc_1', appId: '263902037430900');
    expect(seen.last.url.path, '/v1/inbox/conversations/t_1/handover');
    expect(jsonDecode(seen.last.body),
        {'account_id': 'acc_1', 'app_id': '263902037430900'});
    expect(passed.control, 'passed');

    final taken = await client.inbox.handover('t_1', accountId: 'acc_1');
    expect(jsonDecode(seen.last.body), {'account_id': 'acc_1'});
    expect(taken.appId, isNull);
    client.close();
  });
}
