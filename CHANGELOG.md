# Changelog

## Unreleased

- Added: ads tracking. `ads.sendPixelConversions` sends Conversions API events
  to a pixel exactly once per required `idempotencyKey` (the `Idempotency-Key`
  header; a replay answers `replayed: true`), `ads.listConversionBatches` reads
  the stored batches with identifiers hashed, and `PixelConversionEvent` carries
  `eventId`, `actionSource`, `sourceUrl`, `externalId`, `clientIpAddress`,
  `clientUserAgent`, `clickId`, `browserId` and `contentIds`. Pixels:
  `pixels`, `createPixel`, `pixel` (with the install `code`), `updatePixel`,
  `sharePixel`, `pixelStats` and `eventMatchQuality`. Custom conversions:
  `customConversions`, `createCustomConversion`, `customConversion`,
  `updateCustomConversion` and `deleteCustomConversion`. All need the `ads`
  scope only.
- Changed: `ads.uploadConversions` answers a `ConversionUploadResult` (`id`,
  `accepted`, `eventCount`, `replayed`) instead of the accepted count, takes an
  optional `idempotencyKey`, and accepts `PixelConversionEvent`s as well as
  raw maps.

## 0.3.0

- Breaking: `BlogSettings.autoPublish` and the `autoPublish` argument of
  `blog.updateSettings` are removed. Nothing publishes without approval:
  `blog.submitArticle` moves a draft, failed or rejected article to
  `in_review`, and `publishArticle` or a `publishAt` on a draft answers `409`
  until it is submitted.
- Added: `blog.suggestSeeds` suggests about ten search terms from the blog goal
  and topics; pass the current seeds to refine and a prompt to steer. Spends AI
  credits.
- Added: `BlogSettings.goal` (`BlogGoal`), `focusTopics`, `avoidTopics` and
  `planRun` (`BlogPlanRun`), with `goal`, `focusTopics` and `avoidTopics` on
  `blog.updateSettings`; `BlogKeyword.fitReason`; and
  `BlogArticleStatus.inReview`.
- Changed: `blog.planKeywords` no longer fills the calendar. Results land as
  `suggested` keywords; setting one to `planned` picks it for the next free
  date. `reviewHoldDays` is now the days before its planned date that a picked
  keyword starts being written.

- Added: `whatsapp` for a WhatsApp Business connection: the business profile
  (`profile`, `updateProfile`, `requestDisplayName`, `setUsername`), message
  templates including the platform's own library (`templates`, `createTemplate`,
  `importTemplate`, …), groups, blocking, commerce settings and flows
  (`createFlow`, `uploadFlowJson`, `publishFlow`, `flowResponses`, …), plus
  `accountEvents`. All need the `accounts` scope.
- Added: `whatsapp.createSandboxSession` and `sandboxSessions` invite a tester to
  the platform-owned WhatsApp test number. Inviting sends a template, so it needs
  the `publish` scope.

- Added: `blog`, settings, the keyword plan and the articles written from
  it. `getSettings`, `updateSettings`, `rotateWebsiteSecret`, `testWebsite`,
  `listKeywords`, `planKeywords`, `addKeyword`, `updateKeyword`,
  `deleteKeyword`, `listArticles`, `requestArticle`, `getArticle`,
  `updateArticle`, `regenerateArticle`, `publishArticle`, `rejectArticle` and
  `deleteArticle`. Planning, requesting and regenerating spend AI credits and
  answer `402` on an empty balance; publishing needs the `publish` scope.
- Added: `verifyWebhook` checks a delivery's signature over the raw bytes in
  constant time, preferring the timestamped `X-FoPost-Signature-256` within a
  300 second tolerance and falling back to `X-FoPost-Signature` only when no
  timestamp header is present. Returns a `WebhookEnvelope`; read an
  `article.published` one with `BlogArticlePublished.fromJson`.
- Added: `media.limits` returns an `UploadLimits` with the account's per-file
  ceiling (`maxFileBytes`), its source, the connected-account count, the next
  tier, the multipart ceiling, the files-per-upload cap and the accepted types.
- Added: `posts.create` and `posts.update` take `files`, up to five. Files
  within the multipart ceiling go with the request; larger ones are uploaded
  direct and attached to the first content block, so the route never shows.
- Added: `FoPostFile.stream` for a file read from a stream of known length, and
  `FoPostFile.mimeType`. `media.uploadDirectFile` streams such a file to
  storage instead of buffering it. Multipart parts stream too.
- Added: `presign` and `uploadDirect` take `folderId`, `origin`, `brandRole`,
  `brandVoiceId` and `personConsent`; `PresignedUpload.maxFileBytes`.
- Added: a `413` is thrown as `FoPostFileTooLargeException` with
  `maxFileBytes`, `fileBytes` and `upgradeUrl`.
- Changed: the direct-upload path no longer documents a 50 MB ceiling; the
  account's `maxFileBytes` (up to 5 GB) applies. `FoPostFile.bytes` is now
  nullable, since a stream-backed file has none.
- Added: `InboxItem.moderationStatus` carries the platform's own state for a
  comment (`published`, `held`, `spam`, `rejected`), and
  `InboxAccount.reconnectRequired` flags an account connected before the inbox
  asked for a permission it needs.
- Added: `broadcasts` — one message into every conversation the workspace
  already has with a segment of its contacts. `list`, `get`, `create`,
  `update`, `delete`, `send`, `cancel` and `recipients`. Reading needs the
  `inbox` scope; `send` and `cancel` also need `publish`.
- Added: `sequences` — a series of messages on a delay. `list`, `get`,
  `create`, `update`, `delete`, `enroll`, `unenroll` and `enrollments`.
  `enroll` and `unenroll` need `publish`.
- Added: both honour each network's messaging window server-side. Messenger
  and Instagram take a business-initiated message only within 24 hours of the
  contact's last one, so recipients outside it come back skipped with
  `window_closed` and nothing is attempted — the number sent is often lower
  than the audience.
- Added: `contacts` — the people behind the inbox. `list`, `get`, `create`,
  `update`, `delete`, `conversations` and `import`, plus `listFields`,
  `createField`, `updateField` and `deleteField` for the columns a workspace
  keeps about a person. Needs the `inbox` scope.
- Added: `contacts.conversationAnalytics` — inbox volume and reply time per
  thread. Needs the `analytics` scope, and each row's `key` is an opaque handle
  for the thread rather than the id or handle the inbox groups on.
- Added: Meta messaging settings on `accounts`: `iceBreakers`, `setIceBreakers` and
  `deleteIceBreakers` (Facebook Pages and Instagram), plus `persistentMenu`,
  `setPersistentMenu`, `deletePersistentMenu`, `greeting`, `setGreeting` and
  `deleteGreeting` (Facebook Pages). A network without a field answers 400.
- Added: `accounts.webhookSubscription` reports whether the network is still delivering
  events for an account, and `resubscribeWebhook` puts a lapsed subscription back.
- Added: `inbox.handover` passes a Messenger thread to another Meta app, or takes it back
  when no `appId` is given (`inbox` scope, plus `publish`).
- Added: `client.googleAds` wraps the Google Ads surface: keywords and keyword
  ideas, search terms, bid strategies, ad schedule, negative keyword lists,
  assets, Performance Max asset groups, Local Services leads, conversions, and
  `query` for a raw GAQL read.
- Added: `client.ads.authorizeGoogle` starts a Google Ads connection.
- Added: `client.blogs` for content that already lives on a connected site —
  `listBlogs`, `listArticles`, `getArticle`, `createArticle`, `updateArticle`,
  `deleteArticle`, `listProducts` and `updateProduct`, with `RemoteBlog`,
  `RemoteArticle` and `RemoteProduct`. Reads need the `posts` scope; the writes
  need `posts` and `publish`. Updating an article changes the live one in place
  and never creates a duplicate.

- Added: `accounts.slackChannels`, `slackMembers`, `getSlackIdentity` and
  `updateSlackIdentity` for a Slack account's channels, workspace members and
  posting identity. A `clear*` flag on `updateSlackIdentity` sends `null`.
  Needs the `accounts` scope.
- Added: the Discord bot surface on `accounts` — `discordChannels`,
  `switchDiscordChannel`, `getDiscordIdentity`, `updateDiscordIdentity`,
  `discordPins`, `deleteDiscordMessage`, `pinDiscordMessage`,
  `unpinDiscordMessage`, `crosspostDiscordMessage`, `createDiscordThread`,
  `sendDiscordDirectMessage`, `discordEvents`, `getDiscordEvent`,
  `createDiscordEvent`, `updateDiscordEvent`, `deleteDiscordEvent`,
  `discordMembers`, `discordMember`, `discordRoles`, `createDiscordRole`,
  `updateDiscordRole`, `deleteDiscordRole`, `addDiscordMemberRole` and
  `removeDiscordMemberRole`. Needs the `accounts` scope, plus `publish` for
  anything that posts; a webhook connection answers `409 webhook_connection`.
- Added: `DiscordChannel.canPost` — false when a channel permission in Discord shuts
  the bot out. `switchDiscordChannel` answers `409 channel_not_writable` for one.
- Added: per-network extras on `accounts`, all `accounts` scope: Pinterest boards
  (`pinterestBoards`, `createPinterestBoard`), YouTube playlists and captions
  (`youtubePlaylists`, `createYouTubePlaylist`, `setDefaultYouTubePlaylist`,
  `youtubeCaptions`, `uploadYouTubeCaptions`, `youtubeTranscript`), Bluesky post
  languages (`blueskyLanguages`, `setBlueskyLanguages`), TikTok music and place
  search plus video lookup (`tiktokMusic`, `tiktokLocations`,
  `tiktokVideoLookup`), TikTok creator info
  (`tiktokCreatorInfo`), Instagram audio, publishing limit and stories
  (`instagramAudio`, `instagramPublishingLimit`, `instagramStories`,
  `instagramStoryInsights`) and LinkedIn mentions (`linkedinMentions`), with a
  model each.
- Added: `accounts.redditSubreddits`, `redditSubredditRules`, `redditFlairs`
  and `setRedditDefaultSubreddit` for the subreddits a Reddit account is in, a
  subreddit's rules and post flairs, and where posts go when a post names no
  subreddit. Needs the `accounts` scope.
- Added: `validate.subreddit`, which answers whether a subreddit exists and
  takes a post from an account. Needs the `posts` scope.
- Added: `inbox.vote`, which votes an item up or down, or takes the vote back
  with `none`. Needs `inbox` and `publish`.
- Added: `Account.reconnectRequired`, and `vote` and `canVote` on an inbox
  item.

- Added: the ads campaign tree (`accountTree`; get, create, update, delete
  and duplicate for campaigns, ad sets and network ads; `bulkSetStatus`),
  creatives (`creatives`, `createCreative`, `creative`, `deleteCreative`),
  audience management (`audience`, `updateAudience`, `deleteAudience`,
  `addAudienceUsers`), `estimateReach`, date-range `insights` and
  `adInsights`, and lead forms with the stored leads feed (`leadForm`,
  `archiveLeadForm`, `leadsFeed`, `leadPages`, `subscribeLeadPage`,
  `unsubscribeLeadPage`). Campaign, ad set and network ad writes and bulk
  status need the `publish` scope on top of `ads`.
- Added: `urlTags` on `ads.create`, a query string appended to every link in
  the ad.
- Added: `validate` resource (`post`, `length`, `media`) for standalone checks
  that store nothing. Needs the `posts` scope.
- Added: `accountGroups` resource (`list`, `get`, `create`, `update`,
  `delete`, `setMembers`) and `accounts.rename` / `accounts.move`. Needs the
  `accounts` scope.
- Added: `accounts.list(groupId:)`, `platformName` on `Account` and
  `AccountDetail`, and `accountGroupId` on `posts.create`, where `accounts` is
  now optional.
- Added: `accounts.createTelegramConnectCode` / `getTelegramConnectStatus` to
  connect a Telegram chat with a one-time code, and
  `accounts.getTelegramBotCommands` / `setTelegramBotCommands` /
  `deleteTelegramBotCommands` for the bot's command menu in a connected chat.
  Needs the `accounts` scope.
- Added: inbox actions `like`, `unlike`, `pin`, `unpin`, `react`,
  `editComment`, `startConversation` and `setTyping`, all needing the
  `publish` scope. `reply` takes optional `mediaIds` and `quickReplies`, and
  its `text` may be null when `mediaIds` is given. `delete` also removes our
  own replies.
- Added: `liked`, `pinned`, `reaction`, `editedAt` and the `canLike`,
  `canPin`, `canEdit`, `canReact`, `canSendMedia`, `canQuickReply`,
  `canPrivateReply` flags on `InboxItem`; `canStartConversation` on
  `InboxAccount`.

## 0.2.0

- Added: `inbox` and `ads` resources, with their models. The four `ads` calls
  that spend money (`boost`, `create`, `setStatus`, `delete`) need the `publish`
  scope as well as `ads`.
- `PageMeta` also reads the `page`/`perPage`/`total` shape the inbox lists send.

## 0.1.0

First release.

- `FoPost` client over the FoPost REST API, with `X-API-Key` auth, a 30 second
  per-request timeout, and automatic retries on 429, 5xx and transport errors.
- Resources: `posts`, `workspaces`, `accounts`, `communities`, `labels`,
  `webhooks`, `analytics`, `automations`, `media`.
- Typed models with hand-written `fromJson`, so no build step is needed.
- Typed exceptions per status: validation, authentication, payment required
  (carrying `upgradeUrl`), permission denied, not found, rate limit (carrying
  `retryAfter`) and server errors.
- `FoPost.request` as an escape hatch for endpoints the SDK does not wrap.
- Pure Dart, so it runs on Flutter (iOS, Android, web, desktop) and on the
  server.
