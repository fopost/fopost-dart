import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

Map<String, dynamic> jobJson({String status = 'succeeded'}) => {
      'id': 've_1',
      'status': status,
      'progress': 1,
      'source_media_id': 'md_1',
      'operations': [
        {
          'op': 'trim',
          'params': {'start': 2, 'end': 12}
        }
      ],
      'result_media_id': 'md_2',
      'result_media': {
        'id': 'md_2',
        'preview_url': 'https://api.fopost.com/v1/media/md_2/file',
        'mime_type': 'video/mp4',
      },
      'extra_outputs': [
        {
          'media_id': 'md_3',
          'label': 'Subtitles',
          'mime': 'text/vtt',
          'preview_url': null,
        }
      ],
      'result': {'clips': 1},
      'error': null,
      'created_at': '2026-11-01T08:00:00.000Z',
      'updated_at': '2026-11-01T08:01:00.000Z',
      'completed_at': '2026-11-01T08:01:00.000Z',
    };

void main() {
  test('ops reads every operation', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk([
              {'name': 'trim', 'available': true, 'uses_ai': false},
              {'name': 'subtitles', 'available': false, 'uses_ai': true},
            ]),
        recorder: seen);

    final ops = await client.videoEdits.ops();

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/video-edits/ops');
    expect(ops.first.name, 'trim');
    expect(ops.first.available, isTrue);
    expect(ops.first.usesAi, isFalse);
    expect(ops.last.usesAi, isTrue);
  });

  test('list sends the filters and reads jobs', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonOk([jobJson()]), recorder: seen);

    final jobs = await client.videoEdits.list(mediaId: 'md_1', limit: 5);

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/video-edits');
    expect(seen.last.url.queryParameters, {'media_id': 'md_1', 'limit': '5'});
    final job = jobs.single;
    expect(job.id, 've_1');
    expect(job.status, 'succeeded');
    expect(job.progress, 1.0);
    expect(job.sourceMediaId, 'md_1');
    expect(job.operations.single.op, 'trim');
    expect(job.operations.single.params, {'start': 2, 'end': 12});
    expect(job.resultMediaId, 'md_2');
    expect(job.resultMedia!.previewUrl,
        'https://api.fopost.com/v1/media/md_2/file');
    expect(job.resultMedia!.mimeType, 'video/mp4');
    expect(job.extraOutputs.single.mediaId, 'md_3');
    expect(job.extraOutputs.single.label, 'Subtitles');
    expect(job.extraOutputs.single.mime, 'text/vtt');
    expect(job.result, {'clips': 1});
    expect(job.error, isNull);
    expect(job.completedAt, DateTime.utc(2026, 11, 1, 8, 1));
  });

  test('create sends the operations and reads the queued job', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({
              ...jobJson(status: 'queued'),
              'result_media_id': null,
              'result_media': null,
              'progress': 0,
            }, status: 201),
        recorder: seen);

    final job = await client.videoEdits.create(
      workspaceId: 'ws_1',
      mediaId: 'md_1',
      operations: [
        const VideoEditOperation('trim', {'start': 2, 'end': 12}),
        const VideoEditOperation('denoise'),
      ],
    );

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/video-edits');
    expect(jsonDecode(seen.last.body), {
      'workspace_id': 'ws_1',
      'media_id': 'md_1',
      'operations': [
        {
          'op': 'trim',
          'params': {'start': 2, 'end': 12}
        },
        {'op': 'denoise'},
      ],
    });
    expect(job.status, 'queued');
    expect(job.resultMedia, isNull);
    expect(job.resultMediaId, isNull);
  });

  test('create omits an unset workspace', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonBare(jobJson(), status: 201),
        recorder: seen);

    await client.videoEdits.create(
        mediaId: 'md_1', operations: [const VideoEditOperation('denoise')]);

    expect(
        (jsonDecode(seen.last.body) as Map).containsKey('workspace_id'), false);
  });

  test('get reads one job', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonBare(jobJson()), recorder: seen);

    final job = await client.videoEdits.get('ve_1', workspaceId: 'ws_1');

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/video-edits/ve_1');
    expect(seen.last.url.queryParameters, {'workspace_id': 'ws_1'});
    expect(job.id, 've_1');
  });
}
