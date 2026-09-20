import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('a template create returns the review status the platform gave it',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'id': 'tpl-1',
              'name': 'order_shipped',
              'language': 'en_US',
              'category': 'UTILITY',
              'status': 'PENDING',
              'rejectedReason': null,
              'components': <Object?>[],
              'qualityScore': null,
            }),
        recorder: seen);

    final template = await client.whatsapp.createTemplate(
      'a1',
      name: 'order_shipped',
      language: 'en_US',
      category: 'UTILITY',
      components: const [
        {'type': 'BODY', 'text': 'On its way.'},
      ],
    );

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/accounts/a1/whatsapp/templates');
    // Nothing marks a template approved but the platform.
    expect(template.status, 'PENDING');
    expect(template.name, 'order_shipped');
  });

  test('deleting a template names it in the query', () async {
    final seen = RecordedRequests();
    final client =
        fakeClient((_) async => jsonOk({'deleted': true}), recorder: seen);

    await client.whatsapp.deleteTemplate('a1', 'tpl-1', name: 'order_shipped');

    expect(seen.last.method, 'DELETE');
    expect(seen.last.url.path, '/v1/accounts/a1/whatsapp/templates/tpl-1');
    expect(seen.last.url.queryParameters['name'], 'order_shipped');
  });

  test('a sandbox session carries only the last four digits', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'id': 'ses-1',
              'status': 'invited',
              'phoneNumberLast4': '4567',
              'invitedAt': '2026-09-20T10:00:00Z',
              'activatedAt': null,
              'expiresAt': '2026-09-21T10:00:00Z',
            }),
        recorder: seen);

    final session = await client.whatsapp.createSandboxSession(
      workspaceId: 'ws',
      phoneNumber: '+15551234567',
    );

    expect(seen.last.url.path, '/v1/whatsapp/sandbox/sessions');
    expect(session.phoneNumberLast4, '4567');
    expect(session.status, 'invited');
  });
}
