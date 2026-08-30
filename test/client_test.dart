import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('authentication', () {
    test('sends the key as X-API-Key, never as a bearer token', () async {
      final seen = RecordedRequests();
      final client = fakeClient((_) async => jsonOk([]), recorder: seen);

      await client.workspaces.list();

      expect(seen.last.headers['x-api-key'], 'fp_test_key');
      expect(seen.last.headers.containsKey('authorization'), isFalse);
      expect(seen.last.headers['accept'], 'application/json');
      expect(seen.last.headers['user-agent'], startsWith('fopost-dart/'));
      client.close();
    });

    test('refuses to build without a key', () {
      expect(() => FoPost(apiKey: ''), throwsArgumentError);
    });

    test('prefixes a caller user agent ahead of the SDK one', () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (_) async => jsonOk([]),
        recorder: seen,
        userAgent: 'my-app/2.0',
      );

      await client.workspaces.list();

      expect(seen.last.headers['user-agent'],
          'my-app/2.0 fopost-dart/$foPostVersion');
      client.close();
    });
  });

  group('requests', () {
    test('builds the URL from the base, path and query', () async {
      final seen = RecordedRequests();
      final client = fakeClient((_) async => jsonOk([]), recorder: seen);

      await client.posts
          .list(workspaceId: 'ws_1', status: 'published', perPage: 50);

      final url = seen.last.url;
      expect(url.path, '/v1/posts');
      expect(url.queryParameters, {
        'workspace_id': 'ws_1',
        'status': 'published',
        'per_page': '50',
      });
      client.close();
    });

    test('leaves unset filters out of the query entirely', () async {
      final seen = RecordedRequests();
      final client = fakeClient((_) async => jsonOk([]), recorder: seen);

      await client.posts.list(workspaceId: 'ws_1');

      expect(seen.last.url.queryParameters.keys, ['workspace_id']);
      client.close();
    });

    test('honours a base URL override', () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (_) async => jsonOk([]),
        recorder: seen,
        baseUrl: 'http://localhost:8080/v1/',
      );

      await client.workspaces.list();

      expect(seen.last.url.toString(), 'http://localhost:8080/v1/workspaces');
      client.close();
    });

    test('unwraps the data envelope on a resource call', () async {
      final client = fakeClient((_) async => jsonOk([
            {'id': 'ws_1', 'name': 'Studio', 'slug': 'studio'}
          ]));

      final workspaces = await client.workspaces.list();

      expect(workspaces.single.name, 'Studio');
      client.close();
    });

    test('request() is the escape hatch and leaves the envelope alone',
        () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (_) async => jsonOk({'platforms': 30}),
        recorder: seen,
      );

      final body =
          await client.request('GET', '/platforms', query: {'active': true});

      expect(body, {
        'data': {'platforms': 30}
      });
      expect(seen.last.url.path, '/v1/platforms');
      expect(seen.last.url.queryParameters['active'], 'true');
      client.close();
    });

    test('sends a JSON body with the right content type', () async {
      final seen = RecordedRequests();
      final client =
          fakeClient((_) async => jsonOk({'id': 'lb_1'}), recorder: seen);

      await client.labels
          .create(workspaceId: 'ws_1', name: 'Launch', color: '#2563eb');

      expect(seen.last.headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(seen.last.body), {
        'workspace_id': 'ws_1',
        'name': 'Launch',
        'color': '#2563eb',
      });
      client.close();
    });

    test('tolerates a 204 with no body', () async {
      final client = fakeClient((_) async => http.Response('', 204));
      await expectLater(client.posts.delete('p_1'), completes);
      client.close();
    });
  });
}
