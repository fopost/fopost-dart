import '../json.dart';

// Per-network extras under /accounts/{id}/<platform>/…, all on the accounts scope.

/// A Pinterest board a Pin can land on.
class PinterestBoard {
  /// Creates a board.
  const PinterestBoard({
    required this.id,
    required this.name,
    this.privacy,
    this.description,
    this.image,
  });

  /// Reads a board.
  factory PinterestBoard.fromJson(Map<String, dynamic> json) => PinterestBoard(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        privacy: asString(json['privacy']),
        description: asString(json['description']),
        image: asString(json['image']),
      );

  /// The board id; pass it as the `board_id` platform setting to pin to it.
  final String id;

  /// The board name.
  final String name;

  /// PUBLIC, PROTECTED or SECRET.
  final String? privacy;

  /// The board description.
  final String? description;

  /// The board cover image.
  final String? image;

  @override
  String toString() => 'PinterestBoard($id, $name)';
}

/// A playlist on the connected YouTube channel.
class YouTubePlaylist {
  /// Creates a playlist.
  const YouTubePlaylist({
    required this.id,
    required this.title,
    this.description,
    this.privacy,
    this.itemCount,
    this.thumbnailUrl,
    this.isDefault = false,
  });

  /// Reads a playlist.
  factory YouTubePlaylist.fromJson(Map<String, dynamic> json) =>
      YouTubePlaylist(
        id: asString(json['id']) ?? '',
        title: asString(json['title']) ?? '',
        description: asString(json['description']),
        privacy: asString(json['privacy']),
        itemCount: asInt(json['item_count']),
        thumbnailUrl: asString(json['thumbnail_url']),
        isDefault: asBool(json['is_default']) ?? false,
      );

  /// The playlist id.
  final String id;

  /// The playlist title.
  final String title;

  /// The playlist description.
  final String? description;

  /// public, unlisted or private.
  final String? privacy;

  /// How many videos are on it.
  final int? itemCount;

  /// The playlist thumbnail.
  final String? thumbnailUrl;

  /// Whether a new video joins this playlist when the post picks none.
  final bool isDefault;

  @override
  String toString() => 'YouTubePlaylist($id, $title)';
}

/// A caption track on one of the channel's videos.
class YouTubeCaptionTrack {
  /// Creates a track.
  const YouTubeCaptionTrack({
    required this.id,
    required this.language,
    this.name = '',
    this.trackKind,
    this.isDraft = false,
    this.isAutoSynced = false,
    this.lastUpdated,
  });

  /// Reads a track.
  factory YouTubeCaptionTrack.fromJson(Map<String, dynamic> json) =>
      YouTubeCaptionTrack(
        id: asString(json['id']) ?? '',
        language: asString(json['language']) ?? '',
        name: asString(json['name']) ?? '',
        trackKind: asString(json['track_kind']),
        isDraft: asBool(json['is_draft']) ?? false,
        isAutoSynced: asBool(json['is_auto_synced']) ?? false,
        lastUpdated: asString(json['last_updated']),
      );

  /// The track id.
  final String id;

  /// A BCP-47 tag.
  final String language;

  /// The track name.
  final String name;

  /// How the track was made.
  final String? trackKind;

  /// Whether the track is a draft.
  final bool isDraft;

  /// Whether YouTube auto-synced the timings.
  final bool isAutoSynced;

  /// When the track last changed.
  final String? lastUpdated;

  @override
  String toString() => 'YouTubeCaptionTrack($id, $language)';
}

/// One caption track read back as text, in SRT.
class YouTubeTranscript {
  /// Creates a transcript.
  const YouTubeTranscript({required this.captionId, required this.transcript});

  /// Reads a transcript.
  factory YouTubeTranscript.fromJson(Map<String, dynamic> json) =>
      YouTubeTranscript(
        captionId: asString(json['caption_id']) ?? '',
        transcript: asString(json['transcript']) ?? '',
      );

  /// The track this text came from.
  final String captionId;

  /// The track as SRT.
  final String transcript;

  @override
  String toString() => 'YouTubeTranscript($captionId)';
}

/// The default post languages for a Bluesky connection.
class BlueskyLanguages {
  /// Creates the language set.
  const BlueskyLanguages({this.languages = const []});

  /// Reads the language set.
  factory BlueskyLanguages.fromJson(Map<String, dynamic> json) =>
      BlueskyLanguages(languages: asStringList(json['languages']));

  /// Up to three BCP-47 tags.
  final List<String> languages;

  @override
  String toString() => 'BlueskyLanguages(${languages.join(', ')})';
}

/// A track from TikTok's Commercial Music Library.
///
/// Pass [id] as the `music_id` platform setting to attach it to a post.
class TikTokMusic {
  /// Creates the track.
  const TikTokMusic({
    required this.id,
    this.title = '',
    this.author,
    this.durationSec,
    this.coverUrl,
    this.previewUrl,
  });

  /// Reads the track.
  factory TikTokMusic.fromJson(Map<String, dynamic> json) => TikTokMusic(
        id: asString(json['id']) ?? '',
        title: asString(json['title']) ?? '',
        author: asString(json['author']),
        durationSec: asInt(json['duration_sec']),
        coverUrl: asString(json['cover_url']),
        previewUrl: asString(json['preview_url']),
      );

  /// The track id, travelling as the `music_id` platform setting.
  final String id;

  /// The track title.
  final String title;

  /// Who performs it.
  final String? author;

  /// How long it runs.
  final int? durationSec;

  /// Cover artwork.
  final String? coverUrl;

  /// A short preview.
  final String? previewUrl;

  @override
  String toString() => 'TikTokMusic($id, $title)';
}

/// A place a post can be tagged with.
///
/// Pass [id] as the `location_id` platform setting.
class TikTokPlace {
  /// Creates the place.
  const TikTokPlace({
    required this.id,
    this.name = '',
    this.address,
    this.city,
    this.country,
  });

  /// Reads the place.
  factory TikTokPlace.fromJson(Map<String, dynamic> json) => TikTokPlace(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        address: asString(json['address']),
        city: asString(json['city']),
        country: asString(json['country']),
      );

  /// The place id, travelling as the `location_id` platform setting.
  final String id;

  /// The place name.
  final String name;

  /// Street address.
  final String? address;

  /// City.
  final String? city;

  /// Country.
  final String? country;

  @override
  String toString() => 'TikTokPlace($id, $name)';
}

/// One of the account's own videos, resolved from a share link.
class TikTokVideoSource {
  /// Creates the video.
  const TikTokVideoSource({
    required this.videoId,
    this.title,
    this.description,
    this.durationSec,
    this.coverImageUrl,
    this.shareUrl,
    this.embedLink,
    this.downloadUrl,
  });

  /// Reads the video.
  factory TikTokVideoSource.fromJson(Map<String, dynamic> json) =>
      TikTokVideoSource(
        videoId: asString(json['video_id']) ?? '',
        title: asString(json['title']),
        description: asString(json['description']),
        durationSec: asInt(json['duration_sec']),
        coverImageUrl: asString(json['cover_image_url']),
        shareUrl: asString(json['share_url']),
        embedLink: asString(json['embed_link']),
        downloadUrl: asString(json['download_url']),
      );

  /// TikTok's own id for the video.
  final String videoId;

  /// The video title.
  final String? title;

  /// The caption.
  final String? description;

  /// How long it runs.
  final int? durationSec;

  /// The cover frame.
  final String? coverImageUrl;

  /// The public share link.
  final String? shareUrl;

  /// The embed link.
  final String? embedLink;

  /// What a repurpose run reads. TikTok serves no raw media file, so this is
  /// the share address.
  final String? downloadUrl;

  @override
  String toString() => 'TikTokVideoSource($videoId)';
}

/// The switches TikTok enforces at publish time, set on the TikTok account.
class TikTokCreatorInfo {
  /// Creates the creator info.
  const TikTokCreatorInfo({
    this.username,
    this.nickname,
    this.avatarUrl,
    this.privacyLevelOptions = const [],
    this.commentDisabled = false,
    this.duetDisabled = false,
    this.stitchDisabled = false,
    this.maxVideoPostDurationSec,
  });

  /// Reads the creator info.
  factory TikTokCreatorInfo.fromJson(Map<String, dynamic> json) =>
      TikTokCreatorInfo(
        username: asString(json['username']),
        nickname: asString(json['nickname']),
        avatarUrl: asString(json['avatar_url']),
        privacyLevelOptions: asStringList(json['privacy_level_options']),
        commentDisabled: asBool(json['comment_disabled']) ?? false,
        duetDisabled: asBool(json['duet_disabled']) ?? false,
        stitchDisabled: asBool(json['stitch_disabled']) ?? false,
        maxVideoPostDurationSec: asInt(json['max_video_post_duration_sec']),
      );

  /// The creator's handle.
  final String? username;

  /// The creator's display name.
  final String? nickname;

  /// The creator's avatar.
  final String? avatarUrl;

  /// The levels this creator may publish at right now.
  final List<String> privacyLevelOptions;

  /// Whether comments are off on the account.
  final bool commentDisabled;

  /// Whether Duet is off on the account.
  final bool duetDisabled;

  /// Whether Stitch is off on the account.
  final bool stitchDisabled;

  /// The creator's own video length cap.
  final int? maxVideoPostDurationSec;

  @override
  String toString() => 'TikTokCreatorInfo($username)';
}

/// A track a Reel can carry.
class InstagramAudio {
  /// Creates a track.
  const InstagramAudio({
    required this.id,
    this.title,
    this.artist,
    this.durationMs,
    this.audioType,
    this.coverArtworkUrl,
    this.previewUrl,
    this.username,
    this.isAdsEligible,
  });

  /// Reads a track.
  factory InstagramAudio.fromJson(Map<String, dynamic> json) => InstagramAudio(
        id: asString(json['id']) ?? '',
        title: asString(json['title']),
        artist: asString(json['artist']),
        durationMs: asInt(json['duration_ms']),
        audioType: asString(json['audio_type']),
        coverArtworkUrl: asString(json['cover_artwork_url']),
        previewUrl: asString(json['preview_url']),
        username: asString(json['username']),
        isAdsEligible: asBool(json['is_ads_eligible']),
      );

  /// The track id; pass it as the `audio_id` platform setting.
  final String id;

  /// The track title.
  final String? title;

  /// The track artist.
  final String? artist;

  /// How long the track runs.
  final int? durationMs;

  /// music or original_sound.
  final String? audioType;

  /// The cover artwork.
  final String? coverArtworkUrl;

  /// A preview of the track.
  final String? previewUrl;

  /// The handle behind an original sound.
  final String? username;

  /// Whether the track may be used in an ad.
  final bool? isAdsEligible;

  @override
  String toString() => 'InstagramAudio($id, $title)';
}

/// What this account has published in the rolling window, and what is left.
class InstagramPublishingLimit {
  /// Creates the limit.
  const InstagramPublishingLimit({
    this.quotaUsage = 0,
    this.quotaTotal,
    this.quotaDurationSec,
    this.remaining,
  });

  /// Reads the limit.
  factory InstagramPublishingLimit.fromJson(Map<String, dynamic> json) =>
      InstagramPublishingLimit(
        quotaUsage: asInt(json['quota_usage']) ?? 0,
        quotaTotal: asInt(json['quota_total']),
        quotaDurationSec: asInt(json['quota_duration_sec']),
        remaining: asInt(json['remaining']),
      );

  /// How many containers were published in the window.
  final int quotaUsage;

  /// The ceiling for the window.
  final int? quotaTotal;

  /// How long the window runs.
  final int? quotaDurationSec;

  /// What is left before Instagram refuses the next post.
  final int? remaining;

  @override
  String toString() => 'InstagramPublishingLimit($quotaUsage/$quotaTotal)';
}

/// A story still inside its 24 hours.
class InstagramStory {
  /// Creates a story.
  const InstagramStory({
    required this.id,
    this.mediaType,
    this.mediaProductType,
    this.permalink,
    this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    this.timestamp,
    this.insights,
  });

  /// Reads a story.
  factory InstagramStory.fromJson(Map<String, dynamic> json) => InstagramStory(
        id: asString(json['id']) ?? '',
        mediaType: asString(json['media_type']),
        mediaProductType: asString(json['media_product_type']),
        permalink: asString(json['permalink']),
        mediaUrl: asString(json['media_url']),
        thumbnailUrl: asString(json['thumbnail_url']),
        caption: asString(json['caption']),
        timestamp: asString(json['timestamp']),
        insights: _insights(json['insights']),
      );

  /// The story media id.
  final String id;

  /// IMAGE or VIDEO.
  final String? mediaType;

  /// The product type Instagram reports.
  final String? mediaProductType;

  /// The story permalink.
  final String? permalink;

  /// The story media.
  final String? mediaUrl;

  /// The story thumbnail.
  final String? thumbnailUrl;

  /// The story caption.
  final String? caption;

  /// When the story posted.
  final String? timestamp;

  /// Present only when asked for, and empty for a story too young to report.
  final Map<String, int>? insights;

  @override
  String toString() => 'InstagramStory($id)';
}

/// The insight set for one story.
class InstagramStoryInsights {
  /// Creates the insight set.
  const InstagramStoryInsights({
    required this.storyId,
    this.insights = const {},
  });

  /// Reads the insight set.
  factory InstagramStoryInsights.fromJson(Map<String, dynamic> json) =>
      InstagramStoryInsights(
        storyId: asString(json['story_id']) ?? '',
        insights: _insights(json['insights']) ?? const {},
      );

  /// The story these numbers belong to.
  final String storyId;

  /// Views, reach, replies and navigation.
  final Map<String, int> insights;

  @override
  String toString() => 'InstagramStoryInsights($storyId)';
}

/// An entity a LinkedIn post can mention.
class LinkedInMention {
  /// Creates a mention.
  const LinkedInMention({
    required this.urn,
    required this.name,
    required this.annotation,
    this.vanityName,
    this.logoUrl,
    this.type,
  });

  /// Reads a mention.
  factory LinkedInMention.fromJson(Map<String, dynamic> json) =>
      LinkedInMention(
        urn: asString(json['urn']) ?? '',
        name: asString(json['name']) ?? '',
        annotation: asString(json['annotation']) ?? '',
        vanityName: asString(json['vanity_name']),
        logoUrl: asString(json['logo_url']),
        type: asString(json['type']),
      );

  /// The entity URN.
  final String urn;

  /// The entity's own name, which LinkedIn matches the link text against.
  final String name;

  /// What the post text carries for LinkedIn to render a link.
  final String annotation;

  /// The entity's vanity name.
  final String? vanityName;

  /// The entity logo.
  final String? logoUrl;

  /// What kind of entity it is.
  final String? type;

  @override
  String toString() => 'LinkedInMention($urn, $name)';
}

Map<String, int>? _insights(Object? value) {
  if (value is! Map) return null;
  final out = <String, int>{};
  value.forEach((key, entry) {
    final number = asInt(entry);
    if (number != null) out['$key'] = number;
  });
  return out;
}
