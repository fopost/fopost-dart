import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

Map<String, dynamic> sessionJson({String status = 'pending', String? url}) => {
      'id': 'cs_1',
      'status': status,
      'external_user_id': 'user-42',
      'platforms': ['twitter', 'linkedin'],
      'redirect_url': 'https://yourbrand.com/connected',
      'branding': {'name': 'Your Brand', 'logo_url': null},
      'account_id': status == 'used' ? 'acc_1' : null,
      if (url != null) 'url': url,
      'expires_at': '2026-10-18T12:00:00.000Z',
      'used_at': status == 'used' ? '2026-10-18T11:00:00.000Z' : null,
      'created_at': '2026-10-18T10:00:00.000Z',
    };

void main() {
  test('create sends the request and reads the hosted link', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare(
            sessionJson(url: 'https://app.fopost.com/connect/cs_1'),
            status: 201),
        recorder: seen);

    final session = await client.connectSessions.create(
      workspaceId: 'ws_1',
      externalUserId: 'user-42',
      platforms: ['twitter', 'linkedin'],
      redirectUrl: 'https://yourbrand.com/connected',
      brandingName: 'Your Brand',
    );

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/connect-sessions');
    expect(jsonDecode(seen.last.body), {
      'workspaceId': 'ws_1',
      'externalUserId': 'user-42',
      'platforms': ['twitter', 'linkedin'],
      'redirectUrl': 'https://yourbrand.com/connected',
      'branding': {'name': 'Your Brand'},
    });
    expect(session.id, 'cs_1');
    expect(session.status, ConnectSessionStatus.pending);
    expect(session.url, 'https://app.fopost.com/connect/cs_1');
    expect(session.platforms, ['twitter', 'linkedin']);
    expect(session.branding?.name, 'Your Brand');
    expect(session.branding?.logoUrl, isNull);
    expect(session.accountId, isNull);
    expect(session.expiresAt, DateTime.utc(2026, 10, 18, 12));
  });

  test('create omits branding when nothing was given', () async {
    final seen = RecordedRequests();
    final client =
        fakeClient((_) async => jsonBare(sessionJson()), recorder: seen);

    await client.connectSessions
        .create(externalUserId: 'user-42', platforms: ['twitter']);

    expect(jsonDecode(seen.last.body), {
      'externalUserId': 'user-42',
      'platforms': ['twitter'],
    });
  });

  test('get reads a used session', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare(sessionJson(status: 'used')),
        recorder: seen);

    final session = await client.connectSessions.get('cs_1');

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/connect-sessions/cs_1');
    expect(session.status, ConnectSessionStatus.used);
    expect(session.accountId, 'acc_1');
    expect(session.url, isNull);
    expect(session.usedAt, DateTime.utc(2026, 10, 18, 11));
  });
}
