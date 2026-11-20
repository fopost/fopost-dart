import 'dart:convert';

import 'package:test/test.dart';

import 'support.dart';

Map<String, dynamic> designJson({bool withDocument = true}) => {
      'id': 'dsg_1',
      'name': 'Launch',
      'kind': 'carousel',
      'width': 1080,
      'height': 1350,
      if (withDocument)
        'document': {
          'pages': [
            {'id': 'p1', 'layers': <Object>[]}
          ]
        },
      'thumbnail_media_id': 'md_9',
      'thumbnail_url': 'https://api.fopost.com/v1/media/md_9/file',
      'created_at': '2026-11-01T08:00:00.000Z',
      'updated_at': '2026-11-02T08:00:00.000Z',
    };

Map<String, dynamic> versionJson() => {
      'id': 'ver_1',
      'version': 3,
      'created_at': '2026-11-02T08:00:00.000Z',
    };

void main() {
  test('list sends the filters and reads designs without documents', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk([designJson(withDocument: false)]),
        recorder: seen);

    final designs = await client.designs
        .list(workspaceId: 'ws_1', kind: 'carousel', limit: 10, offset: 20);

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/designs');
    expect(seen.last.url.queryParameters, {
      'workspace_id': 'ws_1',
      'kind': 'carousel',
      'limit': '10',
      'offset': '20',
    });
    final design = designs.single;
    expect(design.id, 'dsg_1');
    expect(design.kind, 'carousel');
    expect(design.width, 1080);
    expect(design.height, 1350);
    expect(design.document, isNull);
    expect(design.thumbnailMediaId, 'md_9');
    expect(design.thumbnailUrl, 'https://api.fopost.com/v1/media/md_9/file');
    expect(design.createdAt, DateTime.utc(2026, 11, 1, 8));
    expect(design.updatedAt, DateTime.utc(2026, 11, 2, 8));
  });

  test('create sends the document as given and omits unset fields', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({'data': designJson()}, status: 201),
        recorder: seen);

    final design = await client.designs.create(
      workspaceId: 'ws_1',
      kind: 'carousel',
      document: {
        'pages': [
          {'id': 'p1', 'layers': <Object>[]}
        ]
      },
    );

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/designs');
    expect(jsonDecode(seen.last.body), {
      'workspace_id': 'ws_1',
      'kind': 'carousel',
      'document': {
        'pages': [
          {'id': 'p1', 'layers': <Object>[]}
        ]
      },
    });
    expect(design.document!['pages'], hasLength(1));
  });

  test('get reads one design', () async {
    final seen = RecordedRequests();
    final client =
        fakeClient((_) async => jsonOk(designJson()), recorder: seen);

    final design = await client.designs.get('dsg_1');

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/designs/dsg_1');
    expect(design.name, 'Launch');
  });

  test('update patches only what changed and reads the saved version',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({'data': designJson(), 'version': versionJson()}),
        recorder: seen);

    final change = await client.designs
        .update('dsg_1', name: 'Launch v2', createVersion: true);

    expect(seen.last.method, 'PATCH');
    expect(seen.last.url.path, '/v1/designs/dsg_1');
    expect(jsonDecode(seen.last.body),
        {'name': 'Launch v2', 'create_version': true});
    expect(change.design.id, 'dsg_1');
    expect(change.version!.id, 'ver_1');
    expect(change.version!.version, 3);
  });

  test('update reads a null version', () async {
    final client = fakeClient(
        (_) async => jsonBare({'data': designJson(), 'version': null}));

    final change = await client.designs.update('dsg_1', name: 'x');

    expect(change.version, isNull);
  });

  test('delete sends a DELETE', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({'id': 'dsg_1', 'deleted': true}),
        recorder: seen);

    await client.designs.delete('dsg_1');

    expect(seen.last.method, 'DELETE');
    expect(seen.last.url.path, '/v1/designs/dsg_1');
  });

  test('versions asks for documents only when told to', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk([
              {
                ...versionJson(),
                'document': {'pages': <Object>[]}
              }
            ]),
        recorder: seen);

    await client.designs.versions('dsg_1');
    expect(seen.last.url.path, '/v1/designs/dsg_1/versions');
    expect(seen.last.url.queryParameters, isEmpty);

    final versions =
        await client.designs.versions('dsg_1', includeDocument: true);
    expect(seen.last.url.queryParameters, {'include': 'document'});
    expect(versions.single.version, 3);
    expect(versions.single.document, {'pages': <Object>[]});
    expect(versions.single.createdAt, DateTime.utc(2026, 11, 2, 8));
  });

  test('restoreVersion posts to the version and reads the change', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({'data': designJson(), 'version': versionJson()}),
        recorder: seen);

    final change = await client.designs.restoreVersion('dsg_1', 'ver_1');

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/designs/dsg_1/versions/ver_1/restore');
    expect(change.design.id, 'dsg_1');
    expect(change.version!.id, 'ver_1');
  });

  test('duplicate sends the new name', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({'data': designJson()}, status: 201),
        recorder: seen);

    final copy = await client.designs.duplicate('dsg_1', name: 'Copy');

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/designs/dsg_1/duplicate');
    expect(jsonDecode(seen.last.body), {'name': 'Copy'});
    expect(copy.id, 'dsg_1');
  });

  test('export sends the format and pages and reads the files', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'format': 'png',
              'files': [
                {
                  'media_id': 'md_1',
                  'page_index': 0,
                  'mime_type': 'image/png',
                  'preview_url': 'https://api.fopost.com/v1/media/md_1/file',
                }
              ],
            }),
        recorder: seen);

    final result =
        await client.designs.export('dsg_1', format: 'png', pageIndexes: [0]);

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/designs/dsg_1/export');
    expect(jsonDecode(seen.last.body), {
      'format': 'png',
      'page_indexes': [0],
    });
    expect(result.format, 'png');
    expect(result.files.single.mediaId, 'md_1');
    expect(result.files.single.pageIndex, 0);
    expect(result.files.single.mimeType, 'image/png');
    expect(result.files.single.previewUrl,
        'https://api.fopost.com/v1/media/md_1/file');
  });

  test('bulk sends the rows and reads every copy', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({
              'data': [designJson(), designJson()]
            }, status: 201),
        recorder: seen);

    final created = await client.designs.bulk('dsg_1',
        rows: [
          {'title': 'One'},
          {'title': 'Two'},
        ],
        nameColumn: 'title');

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/designs/dsg_1/bulk');
    expect(jsonDecode(seen.last.body), {
      'rows': [
        {'title': 'One'},
        {'title': 'Two'},
      ],
      'name_column': 'title',
    });
    expect(created, hasLength(2));
  });

  test('posts reads the posts that used the design', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk([
              {
                'id': 'post_1',
                'status': 'published',
                'title': null,
                'text': 'Out now',
                'schedule_at': null,
                'published_at': '2026-11-03T10:00:00.000Z',
                'platforms': ['instagram', 'linkedin'],
                'engagement': 42,
                'views': 1200,
              }
            ]),
        recorder: seen);

    final posts = await client.designs.posts('dsg_1');

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/designs/dsg_1/posts');
    final post = posts.single;
    expect(post.id, 'post_1');
    expect(post.status, 'published');
    expect(post.text, 'Out now');
    expect(post.publishedAt, DateTime.utc(2026, 11, 3, 10));
    expect(post.platforms, ['instagram', 'linkedin']);
    expect(post.engagement, 42);
    expect(post.views, 1200);
  });

  test('textToSlides sends the text and reads the outline', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'cover': {'title': 'Five ideas', 'subtitle': 'A short guide'},
              'slides': [
                {'heading': 'One', 'body': 'First idea'},
              ],
              'cta': {'heading': 'Follow', 'body': 'For more'},
              'brand': {
                'colors': ['#111111'],
                'fonts': {'heading': 'Geist'},
                'logo_media_id': null,
              },
            }),
        recorder: seen);

    final outline = await client.designs
        .textToSlides(workspaceId: 'ws_1', text: 'Long text', maxSlides: 6);

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/designs/text-to-slides');
    expect(jsonDecode(seen.last.body), {
      'workspace_id': 'ws_1',
      'text': 'Long text',
      'max_slides': 6,
    });
    expect(outline.coverTitle, 'Five ideas');
    expect(outline.coverSubtitle, 'A short guide');
    expect(outline.slides.single.heading, 'One');
    expect(outline.cta.body, 'For more');
    expect(outline.brandColors, ['#111111']);
    expect(outline.headingFont, 'Geist');
    expect(outline.bodyFont, isNull);
    expect(outline.logoMediaId, isNull);
  });

  test('fromPost sends the post and style', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({'data': designJson()}, status: 201),
        recorder: seen);

    final design = await client.designs.fromPost(
      workspaceId: 'ws_1',
      postId: 'post_1',
      style: 'post',
      accountId: 'acc_1',
      carousel: false,
    );

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/designs/from-post');
    expect(jsonDecode(seen.last.body), {
      'workspace_id': 'ws_1',
      'post_id': 'post_1',
      'style': 'post',
      'account_id': 'acc_1',
      'carousel': false,
    });
    expect(design.id, 'dsg_1');
  });
}
