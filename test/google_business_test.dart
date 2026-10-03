import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  const base = '/v1/accounts/acc_1/gbp';

  test('every method maps onto its route', () async {
    final seen = RecordedRequests();
    final client =
        fakeClient((_) async => jsonOk({'ok': true}), recorder: seen);
    final gbp = client.googleBusiness;

    final calls = <List<Object>>[
      ['GET', '$base/location', () => gbp.getLocation('acc_1')],
      ['PATCH', '$base/location', () => gbp.updateLocation('acc_1', {})],
      ['GET', '$base/attributes', () => gbp.getAttributes('acc_1')],
      ['PATCH', '$base/attributes', () => gbp.updateAttributes('acc_1', [])],
      ['GET', '$base/menus', () => gbp.getMenus('acc_1')],
      ['PUT', '$base/menus', () => gbp.replaceMenus('acc_1', [])],
      ['GET', '$base/services', () => gbp.getServices('acc_1')],
      ['PUT', '$base/services', () => gbp.replaceServices('acc_1', [])],
      ['GET', '$base/media', () => gbp.listMedia('acc_1')],
      ['POST', '$base/media', () => gbp.addMedia('acc_1', mediaId: 'm_1')],
      ['DELETE', '$base/media/CAoSL', () => gbp.deleteMedia('acc_1', 'CAoSL')],
      ['GET', '$base/place-actions', () => gbp.listPlaceActions('acc_1')],
      [
        'POST',
        '$base/place-actions',
        () => gbp.createPlaceAction('acc_1',
            uri: 'https://example.test/book', placeActionType: 'APPOINTMENT')
      ],
      [
        'PATCH',
        '$base/place-actions/links-1',
        () => gbp.updatePlaceAction('acc_1', 'links-1', isPreferred: true)
      ],
      [
        'DELETE',
        '$base/place-actions/links-1',
        () => gbp.deletePlaceAction('acc_1', 'links-1')
      ],
      ['GET', '$base/verification', () => gbp.getVerificationOptions('acc_1')],
      [
        'POST',
        '$base/verification/start',
        () => gbp.startVerification('acc_1', method: 'SMS')
      ],
      [
        'POST',
        '$base/verification/complete',
        () => gbp.completeVerification('acc_1',
            verificationName: 'v1', pin: '123456')
      ],
      [
        'GET',
        '$base/performance',
        () => gbp.getPerformance('acc_1',
            startDate: '2026-09-01', endDate: '2026-09-07')
      ],
    ];

    for (final call in calls) {
      await (call[2] as Function)();
      expect(seen.last.method, call[0], reason: call[1] as String);
      expect(seen.last.url.path, call[1]);
    }
    client.close();
  });

  test('a patch carries only the fields the caller set', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonOk({}), recorder: seen);

    await client.googleBusiness
        .updateLocation('acc_1', {'store_code': 'S-12', 'description': null});

    expect(jsonDecode(seen.last.body),
        {'store_code': 'S-12', 'description': null});
    client.close();
  });

  test('a photo is named by its library id', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonOk({}), recorder: seen);

    await client.googleBusiness
        .addMedia('acc_1', mediaId: 'm_1', category: 'INTERIOR');

    expect(jsonDecode(seen.last.body),
        {'media_id': 'm_1', 'category': 'INTERIOR'});
    client.close();
  });

  test('performance sends the metrics the API reads', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonOk({}), recorder: seen);

    await client.googleBusiness.getPerformance('acc_1',
        startDate: '2026-09-01',
        endDate: '2026-09-07',
        dailyMetrics: ['CALL_CLICKS', 'WEBSITE_CLICKS']);

    // The Dart client joins a list with commas, which the API reads as well
    // as it reads a repeated parameter.
    expect(seen.last.url.queryParameters['daily_metrics'],
        'CALL_CLICKS,WEBSITE_CLICKS');
    expect(seen.last.url.queryParameters['start_date'], '2026-09-01');
    client.close();
  });

  test('search keywords asks the same route for the monthly terms', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonOk({}), recorder: seen);

    await client.googleBusiness.getSearchKeywords('acc_1',
        startDate: '2026-08-01', endDate: '2026-09-01');

    expect(seen.last.url.path, '$base/performance');
    expect(seen.last.url.queryParameters['keywords'], 'true');
    client.close();
  });

  test('assign hands the location to another workspace', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({'id': 'acc_1', 'workspace_id': 'ws_2'}),
        recorder: seen);

    final moved =
        await client.googleBusiness.assign('acc_1', workspaceId: 'ws_2');

    expect(seen.last.url.path, '$base/assign');
    expect(jsonDecode(seen.last.body), {'workspace_id': 'ws_2'});
    expect(moved.id, 'acc_1');
    client.close();
  });

  test('a pending api grant surfaces as a 503', () async {
    final client = fakeClient(
      (_) async => jsonError(503, 'configuration_error', 'Not available yet'),
      maxRetries: 1,
    );

    await expectLater(
      client.googleBusiness.getLocation('acc_1'),
      throwsA(isA<FoPostException>()
          .having((e) => e.statusCode, 'statusCode', 503)
          .having((e) => e.code, 'code', 'configuration_error')),
    );
    client.close();
  });
}
