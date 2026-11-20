import 'package:fopost/fopost.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'support.dart';

Map<String, dynamic> uploadedJson() => {
      'id': 'font_1',
      'family': 'Brand Sans',
      'style': 'italic',
      'weight': 700,
      'format': 'woff2',
      'file_url': 'https://api.fopost.com/v1/fonts/font_1/file',
      'created_at': '2026-11-01T08:00:00.000Z',
    };

void main() {
  test('list reads the library and the workspace uploads', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({
              'library': [
                {
                  'slug': 'geist',
                  'family': 'Geist',
                  'category': 'sans-serif',
                  'scripts': ['latin'],
                  'weights': [400, 700],
                  'files': [
                    {
                      'path': '/fonts/geist.woff2',
                      'subset': 'latin',
                      'weight': 400,
                      'style': 'normal',
                      'unicode_range': 'U+0000-00FF',
                    }
                  ],
                }
              ],
              'uploaded': [uploadedJson()],
            }),
        recorder: seen);

    final fonts = await client.fonts.list(workspaceId: 'ws_1');

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/fonts');
    expect(seen.last.url.queryParameters, {'workspace_id': 'ws_1'});
    final library = fonts.library.single;
    expect(library.slug, 'geist');
    expect(library.family, 'Geist');
    expect(library.category, 'sans-serif');
    expect(library.scripts, ['latin']);
    expect(library.weights, [400, 700]);
    expect(library.files.single.path, '/fonts/geist.woff2');
    expect(library.files.single.unicodeRange, 'U+0000-00FF');
    expect(fonts.uploaded.single.id, 'font_1');
  });

  test('list without a workspace sends no query', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({'library': <Object>[], 'uploaded': <Object>[]}),
        recorder: seen);

    final fonts = await client.fonts.list();

    expect(seen.last.url.queryParameters, isEmpty);
    expect(fonts.uploaded, isEmpty);
  });

  test('upload posts a multipart form with the file under "file"', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare(uploadedJson(), status: 201),
        recorder: seen);

    final font = await client.fonts.upload(
      'ws_1',
      FoPostFile(filename: 'Brand.woff2', bytes: [119, 79, 70, 50]),
      family: 'Brand Sans',
      weight: 700,
      style: 'italic',
    );

    final request = seen.last;
    expect(request.method, 'POST');
    expect(request.url.path, '/v1/fonts');
    expect(request.headers['content-type'],
        startsWith('multipart/form-data; boundary='));
    final body = request.body;
    expect(body, contains('name="workspace_id"'));
    expect(body, contains('name="family"'));
    expect(body, contains('Brand Sans'));
    expect(body, contains('name="weight"'));
    expect(body, contains('name="style"'));
    expect(body, contains('name="file"; filename="Brand.woff2"'));

    expect(font.id, 'font_1');
    expect(font.family, 'Brand Sans');
    expect(font.style, 'italic');
    expect(font.weight, 700);
    expect(font.format, 'woff2');
    expect(font.fileUrl, 'https://api.fopost.com/v1/fonts/font_1/file');
    expect(font.createdAt, DateTime.utc(2026, 11, 1, 8));
  });

  test('upload leaves unset fields out of the form', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare(uploadedJson(), status: 201),
        recorder: seen);

    await client.fonts
        .upload('ws_1', FoPostFile(filename: 'Brand.ttf', bytes: [1, 2]));

    final body = seen.last.body;
    expect(body, contains('name="workspace_id"'));
    expect(body, isNot(contains('name="family"')));
    expect(body, isNot(contains('name="weight"')));
    expect(body, isNot(contains('name="style"')));
  });

  test('delete sends a DELETE and accepts a 204', () async {
    final seen = RecordedRequests();
    final client =
        fakeClient((_) async => http.Response('', 204), recorder: seen);

    await client.fonts.delete('font_1');

    expect(seen.last.method, 'DELETE');
    expect(seen.last.url.path, '/v1/fonts/font_1');
  });
}
