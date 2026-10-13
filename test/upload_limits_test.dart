import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'posts_test.dart' show postJson;
import 'support.dart';

Map<String, dynamic> limitsJson({int multipart = 100 * 1024 * 1024}) => {
      'maxFileBytes': 400 * 1024 * 1024,
      'source': 'accounts',
      'connectedAccounts': 5,
      'largeUploadsEnabled': false,
      'nextTier': {'upToAccounts': 15, 'maxFileBytes': 2 * 1024 * 1024 * 1024},
      'multipartMaxFileBytes': multipart,
      'maxFilesPerUpload': 5,
      'directUploadAvailable': true,
      'allowedTypes': ['image/png', 'video/mp4'],
    };

Map<String, dynamic> presignJson() => {
      'uploadId': 'up_1',
      'uploadUrl': 'https://storage.example.com/up_1?sig=abc',
      'method': 'PUT',
      'headers': {'Content-Type': 'video/mp4'},
      'expiresAt': '2026-09-19T10:00:00.000Z',
      'maxFileBytes': 400 * 1024 * 1024,
    };

Map<String, dynamic> uploadedJson() => {
      'id': 'md_1',
      'type': 'video',
      'name': 'launch.mp4',
      'url': 'https://cdn.example.com/launch.mp4',
      'size': 12,
    };

void main() {
  group('media.limits', () {
    test('reads the limits for a workspace', () async {
      final seen = RecordedRequests();
      final client =
          fakeClient((_) async => jsonOk(limitsJson()), recorder: seen);

      final limits = await client.media.limits(workspaceId: 'ws_1');

      expect(seen.last.method, 'GET');
      expect(seen.last.url.path, '/v1/media/limits');
      expect(seen.last.url.queryParameters, {'workspaceId': 'ws_1'});
      expect(limits.maxFileBytes, 400 * 1024 * 1024);
      expect(limits.source, 'accounts');
      expect(limits.connectedAccounts, 5);
      expect(limits.nextTier?.upToAccounts, 15);
      expect(limits.multipartMaxFileBytes, 100 * 1024 * 1024);
      expect(limits.maxFilesPerUpload, 5);
      expect(limits.directUploadAvailable, isTrue);
      expect(limits.allowedTypes, ['image/png', 'video/mp4']);
      client.close();
    });

    test('omits the workspace when none is given', () async {
      final seen = RecordedRequests();
      final client =
          fakeClient((_) async => jsonOk(limitsJson()), recorder: seen);
      await client.media.limits();
      expect(seen.last.url.queryParameters, isEmpty);
      client.close();
    });
  });

  group('presign', () {
    test('sends the optional fields and reads maxFileBytes', () async {
      final seen = RecordedRequests();
      final client =
          fakeClient((_) async => jsonOk(presignJson()), recorder: seen);

      final slot = await client.media.presign(
        workspaceId: 'ws_1',
        filename: 'face.png',
        mimeType: 'image/png',
        size: 3 * 1024 * 1024 * 1024,
        folderId: 'fld_1',
        origin: 'chat',
        brandRole: 'person',
        brandVoiceId: 'bv_1',
        personConsent: {'subject': 'A. Person', 'statement': 'agreed'},
      );

      expect(jsonDecode(seen.last.body), {
        'workspaceId': 'ws_1',
        'filename': 'face.png',
        'mimeType': 'image/png',
        'size': 3 * 1024 * 1024 * 1024,
        'folderId': 'fld_1',
        'origin': 'chat',
        'brandRole': 'person',
        'brandVoiceId': 'bv_1',
        'personConsent': {'subject': 'A. Person', 'statement': 'agreed'},
      });
      expect(slot.maxFileBytes, 400 * 1024 * 1024);
      client.close();
    });
  });

  group('uploadDirectFile', () {
    test('streams a stream-backed file with its declared length', () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (request) async {
          if (request.url.path == '/v1/media/presign') {
            return jsonOk(presignJson());
          }
          if (request.url.host == 'storage.example.com') {
            return http.Response('', 200);
          }
          return jsonOk(uploadedJson());
        },
        recorder: seen,
      );

      var opened = 0;
      final asset = await client.media.uploadDirectFile(
        'ws_1',
        FoPostFile.stream(
          filename: 'launch.mp4',
          mimeType: 'video/mp4',
          length: 12,
          open: () {
            opened++;
            return Stream.fromIterable([
              [1, 2, 3, 4, 5, 6],
              [7, 8, 9, 10, 11, 12],
            ]);
          },
        ),
      );

      expect(opened, 1);
      expect(jsonDecode(seen.all[0].body)['size'], 12);
      final put = seen.all[1];
      expect(put.method, 'PUT');
      expect(put.contentLength, 12);
      expect(put.bodyBytes, List.generate(12, (i) => i + 1));
      expect(put.headers['content-type'], 'video/mp4');
      expect(put.headers.containsKey('x-api-key'), isFalse);
      expect(asset.id, 'md_1');
      client.close();
    });

    test('refuses a file without a mimeType before any request', () async {
      final seen = RecordedRequests();
      final client = fakeClient((_) async => jsonOk({}), recorder: seen);
      await expectLater(
        client.media
            .uploadDirectFile('ws_1', FoPostFile(filename: 'a', bytes: [1])),
        throwsArgumentError,
      );
      expect(seen.length, 0);
      client.close();
    });
  });

  group('posts with files', () {
    test('small files go in one multipart request to the post endpoint',
        () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (request) async {
          if (request.url.path == '/v1/media/limits') {
            return jsonOk(limitsJson());
          }
          return jsonOk(postJson());
        },
        recorder: seen,
      );

      final post = await client.posts.create(
        workspaceId: 'ws_1',
        accounts: ['acc_1'],
        content: 'Hello with a chart',
        files: [
          FoPostFile(
              filename: 'chart.png', mimeType: 'image/png', bytes: [1, 2, 3]),
        ],
      );

      expect(seen.length, 2);
      expect(seen.all[0].url.path, '/v1/media/limits');
      expect(seen.all[0].url.queryParameters['workspaceId'], 'ws_1');

      final create = seen.all[1];
      expect(create.method, 'POST');
      expect(create.url.path, '/v1/posts');
      expect(create.headers['content-type'],
          startsWith('multipart/form-data; boundary='));
      expect(create.body, contains('name="post"'));
      expect(create.body, contains('name="files"; filename="chart.png"'));
      final postField = RegExp(r'name="post"\r\n\r\n(.*?)\r\n', dotAll: true)
          .firstMatch(create.body)!
          .group(1)!;
      expect(jsonDecode(postField), {
        'workspace_id': 'ws_1',
        'accounts': ['acc_1'],
        'content': [
          {'text': 'Hello with a chart'}
        ],
      });
      expect(post.id, 'p_1');
      client.close();
    });

    test('a file over the multipart ceiling is uploaded direct and attached',
        () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (request) async {
          switch (request.url.path) {
            case '/v1/media/limits':
              return jsonOk(limitsJson(multipart: 8));
            case '/v1/media/presign':
              return jsonOk(presignJson());
            case '/v1/media/presign/up_1/complete':
              return jsonOk(uploadedJson());
          }
          if (request.url.host == 'storage.example.com') {
            return http.Response('', 200);
          }
          return jsonOk(postJson());
        },
        recorder: seen,
      );

      await client.posts.create(
        workspaceId: 'ws_1',
        accounts: ['acc_1'],
        content: 'Launch day',
        files: [
          FoPostFile(
            filename: 'launch.mp4',
            mimeType: 'video/mp4',
            bytes: List.filled(12, 7),
          ),
        ],
      );

      expect(
        seen.all.map((r) => r.url.path).toList(),
        [
          '/v1/media/limits',
          '/v1/media/presign',
          '/up_1',
          '/v1/media/presign/up_1/complete',
          '/v1/posts',
        ],
      );
      final create = seen.last;
      expect(create.headers['content-type'], 'application/json');
      expect(jsonDecode(create.body), {
        'workspace_id': 'ws_1',
        'accounts': ['acc_1'],
        'content': [
          {
            'text': 'Launch day',
            'media': [
              {
                'type': 'video',
                'name': 'launch.mp4',
                'url': 'https://cdn.example.com/launch.mp4',
                'size': 12,
              }
            ],
          }
        ],
      });
      client.close();
    });

    test('a failed limits call falls back to the 100 MB multipart ceiling',
        () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (request) async {
          if (request.url.path == '/v1/media/limits') {
            return jsonError(404, 'not_found', 'no such route');
          }
          return jsonOk(postJson());
        },
        recorder: seen,
      );

      await client.posts.create(
        workspaceId: 'ws_1',
        content: 'Hi',
        files: [
          FoPostFile(filename: 'a.png', mimeType: 'image/png', bytes: [1])
        ],
      );

      expect(
          seen.last.headers['content-type'], startsWith('multipart/form-data'));
      client.close();
    });

    test('update without content appends direct uploads to the first block',
        () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (request) async {
          switch (request.url.path) {
            case '/v1/media/limits':
              return jsonOk(limitsJson(multipart: 8));
            case '/v1/media/presign':
              return jsonOk(presignJson());
            case '/v1/media/presign/up_1/complete':
              return jsonOk(uploadedJson());
          }
          if (request.url.host == 'storage.example.com') {
            return http.Response('', 200);
          }
          if (request.method == 'GET') {
            final existing = postJson(text: 'Already here');
            (existing['content'] as List)[0] = {
              'text': 'Already here',
              'media': [
                {
                  'type': 'image',
                  'name': 'old.png',
                  'url': 'https://cdn.example.com/old.png'
                }
              ],
            };
            return jsonOk(existing);
          }
          return jsonOk(postJson());
        },
        recorder: seen,
      );

      await client.posts.update(
        'p_1',
        title: 'Renamed',
        files: [
          FoPostFile(
            filename: 'launch.mp4',
            mimeType: 'video/mp4',
            bytes: List.filled(12, 7),
          ),
        ],
      );

      final get = seen.all[1];
      expect(get.method, 'GET');
      expect(get.url.path, '/v1/posts/p_1');

      final update = seen.last;
      expect(update.method, 'PUT');
      expect(update.url.path, '/v1/posts/p_1');
      final body = jsonDecode(update.body) as Map<String, dynamic>;
      expect(body['title'], 'Renamed');
      final media = (body['content'] as List).first['media'] as List;
      expect(media.map((m) => m['name']), ['old.png', 'launch.mp4']);
      client.close();
    });

    test('small files on update go as a multipart PUT', () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (request) async {
          if (request.url.path == '/v1/media/limits') {
            return jsonOk(limitsJson());
          }
          return jsonOk(postJson());
        },
        recorder: seen,
      );

      await client.posts.update(
        'p_1',
        files: [
          FoPostFile(filename: 'a.png', mimeType: 'image/png', bytes: [1])
        ],
      );

      expect(seen.last.method, 'PUT');
      expect(seen.last.url.path, '/v1/posts/p_1');
      expect(
          seen.last.headers['content-type'], startsWith('multipart/form-data'));
      client.close();
    });

    test('refuses more than five files or a file without a mimeType', () {
      final client = fakeClient((_) async => jsonOk(postJson()));
      expect(
        () => client.posts.create(
          workspaceId: 'ws_1',
          content: 'x',
          files: List.generate(
            6,
            (i) => FoPostFile(
                filename: '$i.png', mimeType: 'image/png', bytes: [1]),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => client.posts.create(
          workspaceId: 'ws_1',
          content: 'x',
          files: [
            FoPostFile(filename: 'a.png', bytes: [1])
          ],
        ),
        throwsArgumentError,
      );
      client.close();
    });
  });

  group('file_too_large', () {
    test('a 413 surfaces its status and max_file_bytes', () async {
      final client = fakeClient(
        (request) async {
          if (request.url.path == '/v1/media/limits') {
            return jsonOk(limitsJson());
          }
          return jsonError(
            413,
            'file_too_large',
            'That file is over your upload ceiling',
            extra: {
              'max_file_bytes': 104857600,
              'file_bytes': 209715200,
              'upgrade_url': 'https://fopost.com/app/settings/billing',
            },
          );
        },
      );

      await expectLater(
        client.posts.create(
          workspaceId: 'ws_1',
          content: 'Too big',
          files: [
            FoPostFile(filename: 'a.mp4', mimeType: 'video/mp4', bytes: [1])
          ],
        ),
        throwsA(isA<FoPostFileTooLargeException>()
            .having((e) => e.statusCode, 'statusCode', 413)
            .having((e) => e.code, 'code', 'file_too_large')
            .having((e) => e.maxFileBytes, 'maxFileBytes', 104857600)
            .having((e) => e.fileBytes, 'fileBytes', 209715200)
            .having((e) => e.upgradeUrl, 'upgradeUrl',
                'https://fopost.com/app/settings/billing')
            .having((e) => e.bodyMap['max_file_bytes'], 'body', 104857600)),
      );
      client.close();
    });
  });
}
