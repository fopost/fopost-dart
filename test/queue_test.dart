import 'dart:convert';

import 'package:test/test.dart';

import 'support.dart';

Map<String, dynamic> slotJson({String? accountId}) => {
      'id': 'slot_1',
      'workspace_id': 'ws_1',
      'account_id': accountId,
      'weekday': 2,
      'time': '09:30',
      'timezone': 'Europe/Zagreb',
      'created_at': '2026-10-01T08:00:00.000Z',
    };

void main() {
  test('slots lists a workspace', () async {
    final seen = RecordedRequests();
    final client =
        fakeClient((_) async => jsonOk([slotJson()]), recorder: seen);

    final slots = await client.queue.slots(workspaceId: 'ws_1');

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/queue/slots');
    expect(seen.last.url.queryParameters, {'workspace_id': 'ws_1'});
    expect(slots.single.id, 'slot_1');
    expect(slots.single.accountId, isNull);
    expect(slots.single.weekday, 2);
    expect(slots.single.time, '09:30');
    expect(slots.single.timezone, 'Europe/Zagreb');
    expect(slots.single.createdAt, DateTime.utc(2026, 10, 1, 8));
  });

  test('createSlot sends the slot and omits an unset account', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonBare(slotJson(), status: 201),
        recorder: seen);

    final slot = await client.queue.createSlot(
      workspaceId: 'ws_1',
      weekday: 2,
      time: '09:30',
      timezone: 'Europe/Zagreb',
    );

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/queue/slots');
    expect(jsonDecode(seen.last.body), {
      'workspace_id': 'ws_1',
      'weekday': 2,
      'time': '09:30',
      'timezone': 'Europe/Zagreb',
    });
    expect(slot.id, 'slot_1');
  });

  test('updateSlot sends only what changed and reads the moved posts',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({
              ...slotJson(accountId: 'acc_1'),
              'moved': [
                {
                  'id': 'p_1',
                  'from': '2026-10-06T07:30:00.000Z',
                  'to': '2026-10-06T07:45:00.000Z',
                }
              ],
            }),
        recorder: seen);

    final result = await client.queue.updateSlot('slot_1', time: '09:45');

    expect(seen.last.method, 'PUT');
    expect(seen.last.url.path, '/v1/queue/slots/slot_1');
    expect(jsonDecode(seen.last.body), {'time': '09:45'});
    expect(result.slot.accountId, 'acc_1');
    expect(result.moved.single.id, 'p_1');
    expect(result.moved.single.to, DateTime.utc(2026, 10, 6, 7, 45));
  });

  test('updateSlot can clear the account', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({...slotJson(), 'moved': <Object>[]}),
        recorder: seen);

    await client.queue.updateSlot('slot_1', clearAccountId: true);

    expect(jsonDecode(seen.last.body), {'account_id': null});
  });

  test('deleteSlot reads the flag and the moved posts', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({
              'deleted': true,
              'moved': [
                {
                  'id': 'p_2',
                  'from': '2026-10-06T07:30:00.000Z',
                  'to': '2026-10-07T07:30:00.000Z',
                }
              ],
            }),
        recorder: seen);

    final result = await client.queue.deleteSlot('slot_1');

    expect(seen.last.method, 'DELETE');
    expect(seen.last.url.path, '/v1/queue/slots/slot_1');
    expect(result.deleted, isTrue);
    expect(result.moved.single.id, 'p_2');
  });

  test('next reads the time, or null when no slot applies', () async {
    final seen = RecordedRequests();
    var next = '2026-10-06T07:30:00.000Z';
    final client =
        fakeClient((_) async => jsonBare({'next': next}), recorder: seen);

    expect(await client.queue.next(workspaceId: 'ws_1', accountId: 'acc_1'),
        DateTime.utc(2026, 10, 6, 7, 30));
    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/queue/next');
    expect(seen.last.url.queryParameters,
        {'workspace_id': 'ws_1', 'account_id': 'acc_1'});

    next = '';
    expect(await client.queue.next(workspaceId: 'ws_1'), isNull);
  });

  test('preview reads the upcoming times', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async =>
            jsonOk(['2026-10-06T07:30:00.000Z', '2026-10-07T07:30:00.000Z']),
        recorder: seen);

    final times = await client.queue.preview(workspaceId: 'ws_1', count: 2);

    expect(seen.last.url.path, '/v1/queue/preview');
    expect(
        seen.last.url.queryParameters, {'workspace_id': 'ws_1', 'count': '2'});
    expect(times, [
      DateTime.utc(2026, 10, 6, 7, 30),
      DateTime.utc(2026, 10, 7, 7, 30),
    ]);
  });
}
