import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/account.dart';
import '../models/platform_extras.dart';
import 'base.dart';

/// Connected social accounts.
///
/// Reach it as `client.accounts`.
class AccountsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  AccountsResource(this._http);

  final FoPostHttp _http;

  /// Returns the connected accounts the key can reach, optionally narrowed to
  /// one workspace or one account group.
  Future<List<Account>> list({String? workspaceId, String? groupId}) async {
    final rows = await _http.objects('GET', '/accounts',
        query: {'workspaceId': workspaceId, 'group_id': groupId});
    return rows.map(Account.fromJson).toList();
  }

  /// Returns one account.
  Future<AccountDetail> get(String id) async => AccountDetail.fromJson(
      await _http.object('GET', '/accounts/${segment(id)}'));

  /// Connects an account from credentials you already hold.
  ///
  /// Platforms that use OAuth are connected in the dashboard instead.
  Future<AccountDetail> create({
    required String workspaceId,
    required String platform,
    required String username,
    required String name,
    String? avatar,
    Map<String, dynamic>? credentials,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'platform': platform,
      'username': username,
      'name': name,
      'avatar': avatar,
      'credentials': credentials,
    });
    return AccountDetail.fromJson(
        await _http.object('POST', '/accounts', body: body));
  }

  /// Sets the name FoPost shows for an account. A null or empty
  /// [displayName] restores the platform's own name.
  Future<RenamedAccount> rename(String id, String? displayName) async =>
      RenamedAccount.fromJson(await _http.object(
          'PATCH', '/accounts/${segment(id)}',
          body: {'display_name': displayName}));

  /// Moves an account to another workspace the caller owns.
  ///
  /// A 409 with the code `move_blocked` lists the reasons under
  /// `blocking_tables` in [FoPostException.bodyMap].
  Future<MovedAccount> move(String id, {required String workspaceId}) async =>
      MovedAccount.fromJson(await _http.object(
          'POST', '/accounts/${segment(id)}/move',
          body: {'workspace_id': workspaceId}));

  /// Disconnects an account.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/accounts/${segment(id)}');

  /// Toggles which account leads its platform in the workspace.
  Future<PrimaryAccount> setPrimary(String id) async => PrimaryAccount.fromJson(
      await _http.object('POST', '/accounts/${segment(id)}/primary'));

  /// Checks an account's credentials against the platform.
  Future<AccountValidation> validate(String id) async =>
      AccountValidation.fromJson(
          await _http.object('POST', '/accounts/${segment(id)}/validate'));

  /// Returns an account's health.
  ///
  /// Pass [refresh] to re-check it live rather than reading the last stored
  /// result.
  Future<AccountHealth> health(String id, {bool refresh = false}) async =>
      AccountHealth.fromJson(await _http.object(
        'GET',
        '/accounts/${segment(id)}/health',
        query: {if (refresh) 'refresh': 'true'},
      ));

  /// Returns the health of every account, optionally narrowed to one workspace.
  Future<AccountHealthSummary> healthSummary({String? workspaceId}) async =>
      AccountHealthSummary.fromJson(await _http.object(
        'GET',
        '/accounts/health',
        query: {'workspaceId': workspaceId},
      ));

  /// Renews an account's OAuth token ahead of its expiry.
  Future<RefreshedToken> refreshToken(String id) async =>
      RefreshedToken.fromJson(
          await _http.object('POST', '/accounts/${segment(id)}/refresh-token'));

  /// Returns an account's stored snapshots, newest first.
  Future<AccountAnalyticsHistory> analytics(String id, {int? limit}) async =>
      AccountAnalyticsHistory.fromJson(await _http.object(
        'GET',
        '/accounts/${segment(id)}/analytics',
        query: {'limit': limit},
      ));

  /// Mints a one-time code, valid for 15 minutes. Sending `/connect <code>` to
  /// the bot in a chat connects that chat. Omit [workspaceId] for a key bound
  /// to one workspace.
  Future<TelegramConnectCode> createTelegramConnectCode(
          {String? workspaceId}) async =>
      TelegramConnectCode.fromJson(await _http.object(
        'POST',
        '/accounts/telegram/connect-code',
        body: pruned({'workspaceId': workspaceId}),
      ));

  /// Returns where a Telegram connect code stands: `pending`, `connected`,
  /// `failed`, or `expired`.
  Future<TelegramConnectStatus> getTelegramConnectStatus(String code) async =>
      TelegramConnectStatus.fromJson(await _http.object(
        'GET',
        '/accounts/telegram/connect-code/status',
        query: {'code': code},
      ));

  /// Returns the command menu the bot shows in a connected Telegram chat.
  Future<List<TelegramBotCommand>> getTelegramBotCommands(String id) async =>
      _commands(await _http.object(
          'GET', '/accounts/${segment(id)}/telegram/commands'));

  /// Replaces the command menu for a connected Telegram chat (1-100 commands).
  Future<List<TelegramBotCommand>> setTelegramBotCommands(
          String id, List<TelegramBotCommand> commands) async =>
      _commands(await _http.object(
        'PUT',
        '/accounts/${segment(id)}/telegram/commands',
        body: {'commands': commands.map((c) => c.toJson()).toList()},
      ));

  /// Clears the command menu for a connected Telegram chat.
  Future<List<TelegramBotCommand>> deleteTelegramBotCommands(String id) async =>
      _commands(await _http.object(
          'DELETE', '/accounts/${segment(id)}/telegram/commands'));

  /// Returns the channels the Slack app can post to: every public channel,
  /// and private ones the app was invited to. A 409 `webhook_connection`
  /// means the account posts through a webhook.
  Future<List<SlackChannel>> slackChannels(String id) async {
    final rows =
        await _http.objects('GET', '/accounts/${segment(id)}/slack/channels');
    return rows.map(SlackChannel.fromJson).toList();
  }

  /// Returns the people in the connected Slack workspace, for addressing a DM.
  Future<List<SlackMember>> slackMembers(String id) async {
    final rows =
        await _http.objects('GET', '/accounts/${segment(id)}/slack/members');
    return rows.map(SlackMember.fromJson).toList();
  }

  /// Returns the name and icon a Slack account posts under.
  Future<SlackIdentity> getSlackIdentity(String id) async =>
      SlackIdentity.fromJson(
          await _http.object('GET', '/accounts/${segment(id)}/slack/identity'));

  /// Sets the name and icon a Slack account posts under.
  ///
  /// An unset field keeps its value; a `clear*` flag sends `null` and clears
  /// it. Set [iconUrl] or [iconEmoji], not both; setting one clears the other.
  Future<SlackIdentity> updateSlackIdentity(
    String id, {
    String? username,
    String? iconUrl,
    String? iconEmoji,
    bool clearUsername = false,
    bool clearIconUrl = false,
    bool clearIconEmoji = false,
  }) async =>
      SlackIdentity.fromJson(await _http.object(
        'PATCH',
        '/accounts/${segment(id)}/slack/identity',
        body: {
          if (username != null || clearUsername) 'username': username,
          if (iconUrl != null || clearIconUrl) 'icon_url': iconUrl,
          if (iconEmoji != null || clearIconEmoji) 'icon_emoji': iconEmoji,
        },
      ));

  // ─── Meta messaging settings (Facebook Pages, Instagram) ─────────

  /// Returns the prompts shown before the first message. A network without
  /// them answers 400.
  Future<List<MetaIceBreaker>> iceBreakers(String id) async =>
      _iceBreakers(await _http.object(
          'GET', '/accounts/${segment(id)}/messaging/ice-breakers'));

  /// Replaces the ice breakers, up to four.
  Future<List<MetaIceBreaker>> setIceBreakers(
    String id,
    List<MetaIceBreaker> iceBreakers,
  ) async =>
      _iceBreakers(await _http.object(
        'PUT',
        '/accounts/${segment(id)}/messaging/ice-breakers',
        body: {'ice_breakers': iceBreakers.map((b) => b.toJson()).toList()},
      ));

  /// Clears the ice breakers.
  Future<List<MetaIceBreaker>> deleteIceBreakers(String id) async =>
      _iceBreakers(await _http.object(
          'DELETE', '/accounts/${segment(id)}/messaging/ice-breakers'));

  /// Returns the always-visible Messenger menu. Facebook Pages only.
  Future<List<MetaPersistentMenuEntry>> persistentMenu(String id) async =>
      _menu(await _http.object(
          'GET', '/accounts/${segment(id)}/messaging/persistent-menu'));

  /// Replaces the menu, one entry per locale, up to three items each.
  Future<List<MetaPersistentMenuEntry>> setPersistentMenu(
    String id,
    List<MetaPersistentMenuEntry> menu,
  ) async =>
      _menu(await _http.object(
        'PUT',
        '/accounts/${segment(id)}/messaging/persistent-menu',
        body: {'persistent_menu': menu.map((e) => e.toJson()).toList()},
      ));

  /// Clears the menu.
  Future<List<MetaPersistentMenuEntry>> deletePersistentMenu(String id) async =>
      _menu(await _http.object(
          'DELETE', '/accounts/${segment(id)}/messaging/persistent-menu'));

  /// Returns the text shown before a Messenger conversation starts.
  /// Facebook Pages only.
  Future<List<MetaGreetingText>> greeting(String id) async => _greeting(
      await _http.object('GET', '/accounts/${segment(id)}/messaging/greeting'));

  /// Replaces the greeting, one entry per locale, each up to 160 characters.
  Future<List<MetaGreetingText>> setGreeting(
    String id,
    List<MetaGreetingText> greeting,
  ) async =>
      _greeting(await _http.object(
        'PUT',
        '/accounts/${segment(id)}/messaging/greeting',
        body: {'greeting': greeting.map((g) => g.toJson()).toList()},
      ));

  /// Clears the greeting.
  Future<List<MetaGreetingText>> deleteGreeting(String id) async =>
      _greeting(await _http.object(
          'DELETE', '/accounts/${segment(id)}/messaging/greeting'));

  /// Returns what the network is delivering to the FoPost webhook for this
  /// account.
  Future<WebhookSubscription> webhookSubscription(String id) async =>
      WebhookSubscription.fromJson(await _http.object(
          'GET', '/accounts/${segment(id)}/webhook-subscription'));

  /// Subscribes to every field this account needs, lapsed or not.
  Future<WebhookSubscription> resubscribeWebhook(String id) async =>
      WebhookSubscription.fromJson(await _http.object(
          'POST', '/accounts/${segment(id)}/webhook-subscription'));

  // ─── Discord (bot connections) ──────────────────────────────────────

  /// Returns the text channels the bot can post to in the connected server.
  ///
  /// A 409 `webhook_connection` means the account posts through a webhook;
  /// upgrade it to the bot first. The same applies to every other Discord call.
  Future<List<DiscordChannel>> discordChannels(String id) async {
    final rows = await _http.objects('GET', _discord(id, '/channels'));
    return rows.map(DiscordChannel.fromJson).toList();
  }

  /// Moves the account to another channel in the same server.
  Future<DiscordChannel> switchDiscordChannel(
          String id, String channelId) async =>
      DiscordChannel.fromJson(await _http.object(
        'PATCH',
        _discord(id, '/channels/current'),
        body: {'channel_id': channelId},
      ));

  /// Returns the nickname and avatar the bot wears in the server.
  Future<DiscordIdentity> getDiscordIdentity(String id) async =>
      DiscordIdentity.fromJson(
          await _http.object('GET', _discord(id, '/identity')));

  /// Sets the nickname and avatar the bot wears in the server.
  ///
  /// An unset field keeps its value; a `clear*` flag sends `null` and clears it.
  Future<DiscordIdentity> updateDiscordIdentity(
    String id, {
    String? username,
    String? avatarUrl,
    bool clearUsername = false,
    bool clearAvatarUrl = false,
  }) async =>
      DiscordIdentity.fromJson(await _http.object(
        'PATCH',
        _discord(id, '/identity'),
        body: {
          if (username != null || clearUsername) 'username': username,
          if (avatarUrl != null || clearAvatarUrl) 'avatar_url': avatarUrl,
        },
      ));

  /// Returns the pinned messages in the account's channel.
  Future<List<DiscordMessage>> discordPins(String id) async {
    final rows = await _http.objects('GET', _discord(id, '/messages/pinned'));
    return rows.map(DiscordMessage.fromJson).toList();
  }

  /// Removes a message from the account's channel.
  Future<DiscordAck> deleteDiscordMessage(String id, String messageId) async =>
      DiscordAck.fromJson(await _http.object(
          'DELETE', _discord(id, '/messages/${segment(messageId)}')));

  /// Pins a message in the account's channel.
  Future<DiscordAck> pinDiscordMessage(String id, String messageId) async =>
      DiscordAck.fromJson(await _http.object(
          'POST', _discord(id, '/messages/${segment(messageId)}/pin')));

  /// Unpins a message in the account's channel.
  Future<DiscordAck> unpinDiscordMessage(String id, String messageId) async =>
      DiscordAck.fromJson(await _http.object(
          'DELETE', _discord(id, '/messages/${segment(messageId)}/pin')));

  /// Publishes an announcement-channel message to every server following it.
  Future<DiscordMessageRef> crosspostDiscordMessage(
          String id, String messageId) async =>
      DiscordMessageRef.fromJson(await _http.object(
          'POST', _discord(id, '/messages/${segment(messageId)}/crosspost')));

  /// Starts a thread on a message.
  ///
  /// [autoArchiveDuration] is 60, 1440, 4320 or 10080 minutes.
  Future<DiscordThread> createDiscordThread(
    String id,
    String messageId, {
    required String name,
    int? autoArchiveDuration,
  }) async =>
      DiscordThread.fromJson(await _http.object(
        'POST',
        _discord(id, '/messages/${segment(messageId)}/thread'),
        body: {
          'name': name,
          if (autoArchiveDuration != null)
            'auto_archive_duration': autoArchiveDuration,
        },
      ));

  /// Sends one message to a member of the server.
  Future<DiscordMessageRef> sendDiscordDirectMessage(
    String id,
    String memberId,
    String content,
  ) async =>
      DiscordMessageRef.fromJson(await _http.object(
        'POST',
        _discord(id, '/dm'),
        body: {'member_id': memberId, 'content': content},
      ));

  /// Returns the server's scheduled events.
  Future<List<DiscordScheduledEvent>> discordEvents(String id) async {
    final rows = await _http.objects('GET', _discord(id, '/events'));
    return rows.map(DiscordScheduledEvent.fromJson).toList();
  }

  /// Returns one scheduled event.
  Future<DiscordScheduledEvent> getDiscordEvent(
          String id, String eventId) async =>
      DiscordScheduledEvent.fromJson(await _http.object(
          'GET', _discord(id, '/events/${segment(eventId)}')));

  /// Adds an event to the server's calendar.
  ///
  /// Give [channelId] for an event in a voice or stage channel, or [location]
  /// with an [endTime] for one elsewhere.
  Future<DiscordScheduledEvent> createDiscordEvent(
    String id, {
    required String name,
    required String startTime,
    String? endTime,
    String? description,
    String? channelId,
    String? location,
  }) async =>
      DiscordScheduledEvent.fromJson(await _http.object(
        'POST',
        _discord(id, '/events'),
        body: _eventBody(
          name: name,
          startTime: startTime,
          endTime: endTime,
          description: description,
          channelId: channelId,
          location: location,
        ),
      ));

  /// Changes a scheduled event; an unset field is left as it is.
  Future<DiscordScheduledEvent> updateDiscordEvent(
    String id,
    String eventId, {
    String? name,
    String? startTime,
    String? endTime,
    String? description,
    String? channelId,
    String? location,
    String? status,
  }) async =>
      DiscordScheduledEvent.fromJson(await _http.object(
        'PATCH',
        _discord(id, '/events/${segment(eventId)}'),
        body: _eventBody(
          name: name,
          startTime: startTime,
          endTime: endTime,
          description: description,
          channelId: channelId,
          location: location,
          status: status,
        ),
      ));

  /// Removes a scheduled event.
  Future<DiscordAck> deleteDiscordEvent(String id, String eventId) async =>
      DiscordAck.fromJson(await _http.object(
          'DELETE', _discord(id, '/events/${segment(eventId)}')));

  /// Returns the server's roster, or the members whose name starts with [query].
  Future<List<DiscordMember>> discordMembers(
    String id, {
    String? query,
    int? limit,
  }) async {
    final rows = await _http.objects(
      'GET',
      _discord(id, '/members'),
      query: {
        if (query != null) 'q': query,
        if (limit != null) 'limit': '$limit',
      },
    );
    return rows.map(DiscordMember.fromJson).toList();
  }

  /// Returns one member of the server.
  Future<DiscordMember> discordMember(String id, String memberId) async =>
      DiscordMember.fromJson(await _http.object(
          'GET', _discord(id, '/members/${segment(memberId)}')));

  /// Returns the server's roles, highest first.
  Future<List<DiscordRole>> discordRoles(String id) async {
    final rows = await _http.objects('GET', _discord(id, '/roles'));
    return rows.map(DiscordRole.fromJson).toList();
  }

  /// Adds a role to the server.
  Future<DiscordRole> createDiscordRole(
    String id, {
    required String name,
    int? color,
    bool? hoist,
    bool? mentionable,
    String? permissions,
  }) async =>
      DiscordRole.fromJson(await _http.object(
        'POST',
        _discord(id, '/roles'),
        body: _roleBody(
          name: name,
          color: color,
          hoist: hoist,
          mentionable: mentionable,
          permissions: permissions,
        ),
      ));

  /// Changes a role on the server; an unset field is left as it is.
  Future<DiscordRole> updateDiscordRole(
    String id,
    String roleId, {
    String? name,
    int? color,
    bool? hoist,
    bool? mentionable,
    String? permissions,
  }) async =>
      DiscordRole.fromJson(await _http.object(
        'PATCH',
        _discord(id, '/roles/${segment(roleId)}'),
        body: _roleBody(
          name: name,
          color: color,
          hoist: hoist,
          mentionable: mentionable,
          permissions: permissions,
        ),
      ));

  /// Removes a role from the server.
  Future<DiscordAck> deleteDiscordRole(String id, String roleId) async =>
      DiscordAck.fromJson(await _http.object(
          'DELETE', _discord(id, '/roles/${segment(roleId)}')));

  /// Gives a member a role.
  Future<DiscordAck> addDiscordMemberRole(
          String id, String roleId, String memberId) async =>
      DiscordAck.fromJson(
          await _http.object('PUT', _memberRole(id, roleId, memberId)));

  /// Takes a role from a member.
  Future<DiscordAck> removeDiscordMemberRole(
          String id, String roleId, String memberId) async =>
      DiscordAck.fromJson(
          await _http.object('DELETE', _memberRole(id, roleId, memberId)));

  String _discord(String id, String suffix) =>
      '/accounts/${segment(id)}/discord$suffix';

  String _memberRole(String id, String roleId, String memberId) =>
      _discord(id, '/roles/${segment(roleId)}/members/${segment(memberId)}');

  Map<String, dynamic> _eventBody({
    String? name,
    String? startTime,
    String? endTime,
    String? description,
    String? channelId,
    String? location,
    String? status,
  }) =>
      {
        if (name != null) 'name': name,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (description != null) 'description': description,
        if (channelId != null) 'channel_id': channelId,
        if (location != null) 'location': location,
        if (status != null) 'status': status,
      };

  Map<String, dynamic> _roleBody({
    String? name,
    int? color,
    bool? hoist,
    bool? mentionable,
    String? permissions,
  }) =>
      {
        if (name != null) 'name': name,
        if (color != null) 'color': color,
        if (hoist != null) 'hoist': hoist,
        if (mentionable != null) 'mentionable': mentionable,
        if (permissions != null) 'permissions': permissions,
      };

  List<TelegramBotCommand> _commands(Map<String, dynamic> json) =>
      asModelList(json['commands'], TelegramBotCommand.fromJson);

  List<MetaIceBreaker> _iceBreakers(Map<String, dynamic> json) =>
      asModelList(json['ice_breakers'], MetaIceBreaker.fromJson);

  List<MetaPersistentMenuEntry> _menu(Map<String, dynamic> json) =>
      asModelList(json['persistent_menu'], MetaPersistentMenuEntry.fromJson);

  List<MetaGreetingText> _greeting(Map<String, dynamic> json) =>
      asModelList(json['greeting'], MetaGreetingText.fromJson);
  // --- Per-network extras ---------------------------------------------

  /// Returns the boards this Pinterest connection can pin to.
  Future<List<PinterestBoard>> pinterestBoards(String id) async {
    final rows =
        await _http.objects('GET', '/accounts/${segment(id)}/pinterest/boards');
    return rows.map(PinterestBoard.fromJson).toList();
  }

  /// Creates a board. [privacy] is PUBLIC, PROTECTED or SECRET.
  Future<PinterestBoard> createPinterestBoard(
    String id, {
    required String name,
    String? description,
    String? privacy,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null) body['description'] = description;
    if (privacy != null) body['privacy'] = privacy;
    return PinterestBoard.fromJson(
      await _http.object('POST', '/accounts/${segment(id)}/pinterest/boards',
          body: body),
    );
  }

  /// Returns the channel's own playlists, with the stored default marked.
  Future<List<YouTubePlaylist>> youtubePlaylists(String id) async {
    final rows = await _http.objects(
        'GET', '/accounts/${segment(id)}/youtube/playlists');
    return rows.map(YouTubePlaylist.fromJson).toList();
  }

  /// Creates a playlist. [privacy] is public, unlisted or private.
  Future<YouTubePlaylist> createYouTubePlaylist(
    String id, {
    required String title,
    String? description,
    String? privacy,
  }) async {
    final body = <String, dynamic>{'title': title};
    if (description != null) body['description'] = description;
    if (privacy != null) body['privacy'] = privacy;
    return YouTubePlaylist.fromJson(
      await _http.object('POST', '/accounts/${segment(id)}/youtube/playlists',
          body: body),
    );
  }

  /// Stores the playlist a new video joins when the post picks none. A null
  /// [playlistId] clears it; the stored value comes back.
  Future<String?> setDefaultYouTubePlaylist(
      String id, String? playlistId) async {
    final data = await _http.object(
      'PUT',
      '/accounts/${segment(id)}/youtube/playlists/default',
      body: <String, dynamic>{'playlist_id': playlistId},
    );
    return asString(data['playlist_id']);
  }

  /// Returns the caption tracks on one of the channel's videos.
  Future<List<YouTubeCaptionTrack>> youtubeCaptions(
    String id,
    String videoId,
  ) async {
    final rows = await _http.objects(
      'GET',
      '/accounts/${segment(id)}/youtube/videos/${segment(videoId)}/captions',
    );
    return rows.map(YouTubeCaptionTrack.fromJson).toList();
  }

  /// Uploads a caption track. [body] is the subtitle file itself; YouTube
  /// reads SRT and WebVTT and works out which from the bytes.
  Future<YouTubeCaptionTrack> uploadYouTubeCaptions(
    String id,
    String videoId, {
    required String language,
    required String body,
    String? name,
    bool? isDraft,
  }) async {
    final payload = <String, dynamic>{'language': language, 'body': body};
    if (name != null) payload['name'] = name;
    if (isDraft != null) payload['is_draft'] = isDraft;
    return YouTubeCaptionTrack.fromJson(
      await _http.object(
        'POST',
        '/accounts/${segment(id)}/youtube/videos/${segment(videoId)}/captions',
        body: payload,
      ),
    );
  }

  /// Returns one caption track as text.
  Future<YouTubeTranscript> youtubeTranscript(
    String id,
    String captionId,
  ) async =>
      YouTubeTranscript.fromJson(
        await _http.object(
          'GET',
          '/accounts/${segment(id)}/youtube/captions/${segment(captionId)}',
        ),
      );

  /// Returns what a post from this Bluesky connection is written in when the
  /// post itself does not say.
  Future<BlueskyLanguages> blueskyLanguages(String id) async =>
      BlueskyLanguages.fromJson(
        await _http.object('GET', '/accounts/${segment(id)}/bluesky/languages'),
      );

  /// Stores up to three BCP-47 tags. An empty list clears the default.
  Future<BlueskyLanguages> setBlueskyLanguages(
    String id,
    List<String> languages,
  ) async =>
      BlueskyLanguages.fromJson(
        await _http.object(
          'PUT',
          '/accounts/${segment(id)}/bluesky/languages',
          body: <String, dynamic>{'languages': languages},
        ),
      );

  /// Returns the switches TikTok enforces at publish time, which are changed
  /// in the TikTok app.
  Future<TikTokCreatorInfo> tiktokCreatorInfo(String id) async =>
      TikTokCreatorInfo.fromJson(
        await _http.object(
          'GET',
          '/accounts/${segment(id)}/tiktok/creator-info',
        ),
      );

  /// Searches TikTok's Commercial Music Library.
  ///
  /// Needs the Marketing API product on the TikTok app; without it the call
  /// throws rather than answering an empty list.
  Future<List<TikTokMusic>> tiktokMusic(
    String id, {
    required String query,
    int? limit,
  }) async {
    final rows = await _http.objects(
      'GET',
      '/accounts/${segment(id)}/tiktok/music',
      query: <String, dynamic>{'q': query, 'limit': limit},
    );
    return rows.map(TikTokMusic.fromJson).toList();
  }

  /// Searches the places a post can be tagged with.
  ///
  /// Same TikTok product as the music library.
  Future<List<TikTokPlace>> tiktokLocations(
    String id, {
    required String query,
    int? limit,
  }) async {
    final rows = await _http.objects(
      'GET',
      '/accounts/${segment(id)}/tiktok/locations',
      query: <String, dynamic>{'q': query, 'limit': limit},
    );
    return rows.map(TikTokPlace.fromJson).toList();
  }

  /// Resolves a share link to one of this account's own videos, for
  /// repurposing.
  Future<TikTokVideoSource> tiktokVideoLookup(String id, String url) async =>
      TikTokVideoSource.fromJson(
        await _http.object(
          'POST',
          '/accounts/${segment(id)}/tiktok/video-download',
          body: <String, dynamic>{'url': url},
        ),
      );

  /// Returns tracks a Reel can carry. With no [query] Instagram answers with
  /// what is trending.
  Future<List<InstagramAudio>> instagramAudio(
    String id, {
    String? query,
    String? audioType,
  }) async {
    final rows = await _http.objects(
      'GET',
      '/accounts/${segment(id)}/instagram/audio',
      query: <String, dynamic>{'q': query, 'audio_type': audioType},
    );
    return rows.map(InstagramAudio.fromJson).toList();
  }

  /// Returns how many posts are left before Instagram refuses the next one.
  Future<InstagramPublishingLimit> instagramPublishingLimit(String id) async =>
      InstagramPublishingLimit.fromJson(
        await _http.object(
          'GET',
          '/accounts/${segment(id)}/instagram/publishing-limit',
        ),
      );

  /// Returns stories still inside their 24 hours, posted through FoPost or
  /// not. Asking for [insights] costs one extra call per story.
  Future<List<InstagramStory>> instagramStories(
    String id, {
    bool insights = false,
  }) async {
    final rows = await _http.objects(
      'GET',
      '/accounts/${segment(id)}/instagram/stories',
      query: insights ? <String, dynamic>{'insights': true} : null,
    );
    return rows.map(InstagramStory.fromJson).toList();
  }

  /// Returns the insight set for one story.
  Future<InstagramStoryInsights> instagramStoryInsights(
    String id,
    String storyId,
  ) async =>
      InstagramStoryInsights.fromJson(
        await _http.object(
          'GET',
          '/accounts/${segment(id)}/instagram/stories/${segment(storyId)}/insights',
        ),
      );

  /// Returns organizations a LinkedIn post can mention. People are not
  /// searchable: LinkedIn has no public person search.
  Future<List<LinkedInMention>> linkedinMentions(
    String id,
    String query,
  ) async {
    final rows = await _http.objects(
      'GET',
      '/accounts/${segment(id)}/linkedin/mentions',
      query: <String, dynamic>{'q': query},
    );
    return rows.map(LinkedInMention.fromJson).toList();
  }
}
