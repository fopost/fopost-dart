import '../json.dart';

/// One thing the workspace has told FoPost about itself: an FAQ, a note, a page
/// on its own site, or a plain-text/CSV file from the media library.
class KnowledgeSource {
  /// Creates a knowledge source.
  const KnowledgeSource({
    required this.id,
    required this.kind,
    required this.title,
    required this.status,
    this.statusMessage,
    this.url,
    this.mediaId,
    this.brandVoiceId,
    this.chunkCount = 0,
    this.content,
    this.lastSyncedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Reads a knowledge source.
  factory KnowledgeSource.fromJson(Map<String, dynamic> json) =>
      KnowledgeSource(
        id: asString(json['id']) ?? '',
        kind: asString(json['kind']) ?? '',
        title: asString(json['title']) ?? '',
        status: asString(json['status']) ?? '',
        statusMessage:
            asString(json['statusMessage'] ?? json['status_message']),
        url: asString(json['url']),
        mediaId: asString(json['mediaId'] ?? json['media_id']),
        brandVoiceId: asString(json['brandVoiceId'] ?? json['brand_voice_id']),
        chunkCount: asInt(json['chunkCount'] ?? json['chunk_count']) ?? 0,
        content: asString(json['content']),
        lastSyncedAt: asDate(json['lastSyncedAt'] ?? json['last_synced_at']),
        createdAt: asDate(json['createdAt'] ?? json['created_at']),
        updatedAt: asDate(json['updatedAt'] ?? json['updated_at']),
      );

  /// The source's id.
  final String id;

  /// Where its text comes from: `faq`, `text`, `url` or `file`.
  final String kind;

  /// What it is called.
  final String title;

  /// `pending`, `syncing`, `ready` or `failed`. Only a `ready` source is
  /// searched.
  final String status;

  /// Why the last sync failed, in plain words.
  final String? statusMessage;

  /// The page fetched, for `url` sources.
  final String? url;

  /// The media library item read, for `file` sources.
  final String? mediaId;

  /// The brand it is scoped to; null serves the whole workspace.
  final String? brandVoiceId;

  /// Searchable passages the last sync produced.
  final int chunkCount;

  /// The typed text, for `faq` and `text` sources only.
  final String? content;

  /// When it was last read and indexed.
  final DateTime? lastSyncedAt;

  /// When the source was added.
  final DateTime? createdAt;

  /// When it last changed.
  final DateTime? updatedAt;

  @override
  String toString() => 'KnowledgeSource($title, $status)';
}

/// One retrieved passage, with the source it came from so a reply can cite it.
class KnowledgeMatch {
  /// Creates a match.
  const KnowledgeMatch({
    required this.sourceId,
    required this.sourceTitle,
    required this.sourceKind,
    required this.text,
    this.sourceUrl,
    this.score = 0,
  });

  /// Reads a match.
  factory KnowledgeMatch.fromJson(Map<String, dynamic> json) => KnowledgeMatch(
        sourceId: asString(json['sourceId'] ?? json['source_id']) ?? '',
        sourceTitle:
            asString(json['sourceTitle'] ?? json['source_title']) ?? '',
        sourceKind: asString(json['sourceKind'] ?? json['source_kind']) ?? '',
        sourceUrl: asString(json['sourceUrl'] ?? json['source_url']),
        text: asString(json['text']) ?? '',
        score: asDouble(json['score']) ?? 0,
      );

  /// The source the passage came from.
  final String sourceId;

  /// That source's title, for citing it.
  final String sourceTitle;

  /// That source's kind.
  final String sourceKind;

  /// That source's URL, when it has one.
  final String? sourceUrl;

  /// The passage, as stored.
  final String text;

  /// Similarity to the question, 0-1.
  final double score;

  @override
  String toString() => 'KnowledgeMatch($sourceTitle)';
}

/// What a sync answers: the source, and that it is queued.
class KnowledgeSyncResult {
  /// Creates a sync result.
  const KnowledgeSyncResult({required this.id, required this.status});

  /// Reads a sync result.
  factory KnowledgeSyncResult.fromJson(Map<String, dynamic> json) =>
      KnowledgeSyncResult(
        id: asString(json['id']) ?? '',
        status: asString(json['status']) ?? '',
      );

  /// The source queued.
  final String id;

  /// Where it now sits in its ingest cycle.
  final String status;

  @override
  String toString() => 'KnowledgeSyncResult($id, $status)';
}
