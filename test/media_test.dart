import 'dart:convert';
import 'dart:typed_data';

import 'package:fopost/fopost.dart';
import 'package:http/http.dart' as http;
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
        (_) async => jsonOk(
            {'total_rows': 2, 'valid_rows': 1, 'invalid_rows': 1, 'rows': []}),
        recorder: seen,
      );

      final result = await client.posts.validateBulkImport(
        workspaceId: 'ws_1',
        file: FoPostFile.fromString(
            'posts.csv', 'content,schedule_at\nhi,2026-09-01'),
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

  group('uploadDirect', () {
    test('presigns, PUTs the bytes without an API key, then completes',
        () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (request) async {
          if (request.url.path == '/v1/media/presign') {
            return jsonBare({
              'data': {
                'uploadId': 'up_1',
                'uploadUrl': 'https://storage.example.com/up_1?sig=abc',
                'method': 'PUT',
                'headers': {'Content-Type': 'image/png'},
                'expiresAt': '2026-09-19T10:00:00.000Z',
              }
            }, status: 201);
          }
          if (request.url.host == 'storage.example.com') {
            return http.Response('', 200);
          }
          return jsonBare({
            'data': {
              'id': 'md_1',
              'type': 'image',
              'name': 'chart.png',
              'url': 'https://cdn.example.com/chart.png',
              'previewUrl': 'https://api.fopost.com/v1/media/md_1/file',
              'size': 4,
            }
          }, status: 201);
        },
        recorder: seen,
      );

      final asset = await client.media.uploadDirect(
        'ws_1',
        'chart.png',
        'image/png',
        Uint8List.fromList([1, 2, 3, 4]),
      );

      expect(seen.length, 3);

      final presign = seen.all[0];
      expect(presign.method, 'POST');
      expect(presign.url.path, '/v1/media/presign');
      expect(presign.headers['x-api-key'], 'fp_test_key');
      expect(jsonDecode(presign.body), {
        'workspaceId': 'ws_1',
        'filename': 'chart.png',
        'mimeType': 'image/png',
        'size': 4,
      });

      final put = seen.all[1];
      expect(put.method, 'PUT');
      expect(put.url.toString(), 'https://storage.example.com/up_1?sig=abc');
      expect(put.headers['content-type'], 'image/png');
      expect(put.headers.containsKey('x-api-key'), isFalse);
      expect(put.headers.containsKey('user-agent'), isFalse);
      expect(put.bodyBytes, [1, 2, 3, 4]);
      expect(put.contentLength, 4);

      final complete = seen.all[2];
      expect(complete.method, 'POST');
      expect(complete.url.path, '/v1/media/presign/up_1/complete');
      expect(complete.headers['x-api-key'], 'fp_test_key');

      expect(asset.id, 'md_1');
      expect(asset.toMediaItem().url, 'https://cdn.example.com/chart.png');
      client.close();
    });

    test('a rejected PUT throws before complete is called', () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (request) async {
          if (request.url.path == '/v1/media/presign') {
            return jsonOk({
              'uploadId': 'up_1',
              'uploadUrl': 'https://storage.example.com/up_1',
              'method': 'PUT',
              'headers': {'Content-Type': 'image/png'},
            });
          }
          return http.Response('denied', 403);
        },
        recorder: seen,
      );

      await expectLater(
        client.media.uploadDirect(
            'ws_1', 'chart.png', 'image/png', Uint8List.fromList([1])),
        throwsA(isA<FoPostPermissionDeniedException>()),
      );
      expect(seen.length, 2);
      client.close();
    });

    test('complete surfaces the API error', () async {
      final client = fakeClient(
        (_) async => jsonError(410, 'upload_expired', 'Upload expired'),
      );

      await expectLater(
        client.media.complete('up_1'),
        throwsA(isA<FoPostException>()
            .having((e) => e.statusCode, 'statusCode', 410)
            .having((e) => e.code, 'code', 'upload_expired')),
      );
      client.close();
    });
  });
}
