import '../json.dart';

/// A video edit operation the API knows, and whether it can run now.
class VideoEditOp {
  /// Creates an operation description.
  const VideoEditOp({
    required this.name,
    required this.available,
    required this.usesAi,
  });

  /// Reads an operation description.
  factory VideoEditOp.fromJson(Map<String, dynamic> json) => VideoEditOp(
        name: asString(json['name']) ?? '',
        available: asBool(json['available']) ?? false,
        usesAi: asBool(json['uses_ai']) ?? false,
      );

  /// The operation name, e.g. `trim` or `subtitles`.
  final String name;

  /// Whether the operation can run on this deployment.
  final bool available;

  /// Whether the operation spends AI credits; an API key then also needs the
  /// `ai` scope.
  final bool usesAi;

  @override
  String toString() => 'VideoEditOp($name)';
}

/// One step of a video edit: an operation name and its parameters.
class VideoEditOperation {
  /// Creates a step.
  const VideoEditOperation(this.op, [this.params = const {}]);

  /// Reads a step.
  factory VideoEditOperation.fromJson(Map<String, dynamic> json) =>
      VideoEditOperation(
        asString(json['op']) ?? '',
        asMap(json['params']),
      );

  /// The operation name, e.g. `trim`.
  final String op;

  /// The operation's parameters, sent as given.
  final Map<String, dynamic> params;

  /// The wire form.
  Map<String, dynamic> toJson() => {
        'op': op,
        if (params.isNotEmpty) 'params': params,
      };

  @override
  String toString() => 'VideoEditOperation($op)';
}

/// The video a finished edit produced.
class VideoEditMedia {
  /// Creates the media reference.
  const VideoEditMedia({required this.id, this.previewUrl, this.mimeType});

  /// Reads the media reference.
  factory VideoEditMedia.fromJson(Map<String, dynamic> json) => VideoEditMedia(
        id: asString(json['id']) ?? '',
        previewUrl: asString(json['preview_url']),
        mimeType: asString(json['mime_type']),
      );

  /// The library asset's id.
  final String id;

  /// A URL that serves the file.
  final String? previewUrl;

  /// The file's MIME type.
  final String? mimeType;

  @override
  String toString() => 'VideoEditMedia($id)';
}

/// A further file an edit produced, such as a clip or a subtitle track.
class VideoEditOutput {
  /// Creates the output.
  const VideoEditOutput({
    required this.mediaId,
    this.label,
    this.mime,
    this.previewUrl,
  });

  /// Reads the output.
  factory VideoEditOutput.fromJson(Map<String, dynamic> json) =>
      VideoEditOutput(
        mediaId: asString(json['media_id']) ?? '',
        label: asString(json['label']),
        mime: asString(json['mime']),
        previewUrl: asString(json['preview_url']),
      );

  /// The library asset's id.
  final String mediaId;

  /// What the file is.
  final String? label;

  /// The file's MIME type.
  final String? mime;

  /// A URL that serves the file.
  final String? previewUrl;

  @override
  String toString() => 'VideoEditOutput($mediaId)';
}

/// A video edit job. Poll `videoEdits.get` until [status] is
/// `succeeded` or `failed`.
class VideoEdit {
  /// Creates a job.
  const VideoEdit({
    required this.id,
    required this.status,
    this.progress,
    this.sourceMediaId,
    this.operations = const [],
    this.resultMediaId,
    this.resultMedia,
    this.extraOutputs = const [],
    this.result,
    this.error,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  /// Reads a job.
  factory VideoEdit.fromJson(Map<String, dynamic> json) => VideoEdit(
        id: asString(json['id']) ?? '',
        status: asString(json['status']) ?? '',
        progress: asDouble(json['progress']),
        sourceMediaId: asString(json['source_media_id']),
        operations:
            asModelList(json['operations'], VideoEditOperation.fromJson),
        resultMediaId: asString(json['result_media_id']),
        resultMedia: json['result_media'] is Map
            ? VideoEditMedia.fromJson(asMap(json['result_media']))
            : null,
        extraOutputs:
            asModelList(json['extra_outputs'], VideoEditOutput.fromJson),
        result: asMapOrNull(json['result']),
        error: asString(json['error']),
        createdAt: asDate(json['created_at']),
        updatedAt: asDate(json['updated_at']),
        completedAt: asDate(json['completed_at']),
      );

  /// The job's id.
  final String id;

  /// One of `queued`, `running`, `succeeded`, `failed`.
  final String status;

  /// How far along the job is.
  final double? progress;

  /// The video being edited.
  final String? sourceMediaId;

  /// The steps, in the order they run.
  final List<VideoEditOperation> operations;

  /// The edited video, once the job succeeded.
  final String? resultMediaId;

  /// The edited video with a URL to serve it.
  final VideoEditMedia? resultMedia;

  /// Further files the job produced.
  final List<VideoEditOutput> extraOutputs;

  /// Operation-specific output, passed through as it came.
  final Map<String, dynamic>? result;

  /// Why the job failed.
  final String? error;

  /// When the job was queued.
  final DateTime? createdAt;

  /// When the job last changed.
  final DateTime? updatedAt;

  /// When the job finished.
  final DateTime? completedAt;

  @override
  String toString() => 'VideoEdit($id $status)';
}
