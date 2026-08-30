import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('upload', () {
    test('posts a multipart form with the workspace and every file', () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (_) async => jsonOk([
          {
            'id': 'md_1',
            'type': 'image',
            'name': 'chart.png',
            'url': 'https://cdn.example.com/chart.png',
            'size': 2048,
          }
        ]),
        recorder: seen,
      );

      final uploaded = await client.media.upload('ws_1', [
        FoPostFile(filename: 'chart.png', bytes: [1, 2, 3, 4]),
        FoPostFile.fromString('notes.txt', 'plain text'),
      ]);

      final request = seen.last;
      expect(request.method, 'POST');
      expect(request.url.path, '/v1/media/upload');
      expect(request.headers['content-type'],
          startsWith('multipart/form-data; boundary='));
      expect(request.headers['x-api-key'], 'fp_test_key');

      final body = request.body;
      expect(body, contains('name="workspaceId"'));
      expect(body, contains('ws_1'));
      expect(body, contains('name="files"; filename="chart.png"'));
      expect(body, contains('name="files"; filename="notes.txt"'));
      expect(body, contains('plain text'));

      expect(uploaded.single.id, 'md_1');
      expect(uploaded.single.toMediaItem().url,
          'https://cdn.example.com/chart.png');
      client.close();
    });

    test('refuses an empty file list before touching the network', () {
      final client = fakeClient((_) async => jsonOk([]));
      expect(() => client.media.upload('ws_1', []), throwsArgumentError);
      client.close();
    });

    test('a bulk import sends the CSV under the file field', () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (_) async => jsonOk({'total_rows': 2, 'valid_rows': 1, 'invalid_rows': 1, 'rows': []}),
        recorder: seen,
      );

      final result = await client.posts.validateBulkImport(
        workspaceId: 'ws_1',
        file: FoPostFile.fromString('posts.csv', 'content,schedule_at\nhi,2026-09-01'),
      );

      expect(seen.last.url.path, '/v1/posts/bulk-import/validate');
      expect(seen.last.body, contains('name="file"; filename="posts.csv"'));
      expect(seen.last.body, contains('name="workspace_id"'));
      expect(result.validRows, 1);
      expect(result.invalidRows, 1);
      client.close();
    });
  });

  test('lists the library for a workspace', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonOk([
        {
          'id': 'md_1',
          'name': 'chart.png',
          'url': 'https://cdn.example.com/chart.png',
          'type': 'image',
          'size': 2048,
          'createdAt': '2026-08-30T10:00:00.000Z',
        }
      ]),
      recorder: seen,
    );

    final items = await client.media.list('ws_1');

    expect(seen.last.url.queryParameters['workspaceId'], 'ws_1');
    expect(items.single.size, 2048);
    expect(items.single.toMediaItem().type, 'image');
    client.close();
  });
}
