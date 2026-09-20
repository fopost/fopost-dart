# fopost

[![pub package](https://img.shields.io/pub/v/fopost.svg)](https://pub.dev/packages/fopost)
[![CI](https://github.com/fopost/fopost-dart/actions/workflows/ci.yml/badge.svg)](https://github.com/fopost/fopost-dart/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Official Dart SDK for the [FoPost](https://fopost.com) API. Schedule and publish
to +30 social platforms from your code.

```bash
dart pub add fopost
```

Requires Dart 3.4 or newer. Pure Dart, depending only on `http` and `meta`, so
the same client runs in Flutter (iOS, Android, web, desktop) and on the server.
There is no code generation and no build step.

> **0.x release.** The public API is still settling and minor versions may
> contain breaking changes. Pin an exact version if that matters to you.

## Quick start

```dart
import 'package:fopost/fopost.dart';

Future<void> main() async {
  final client = FoPost(apiKey: 'fp_...'); // or set FOPOST_API_KEY

  final workspace = (await client.workspaces.list()).first;
  final accounts = await client.accounts.list(workspaceId: workspace.id);

  final post = await client.posts.create(
    workspaceId: workspace.id,
    accounts: accounts.map((account) => account.id).toList(),
    content: 'Hello from Dart',
  );

  await client.posts.publish(post.id);

  client.close();
}
```

Get a key from **Settings → API Keys** in the FoPost dashboard
(<https://fopost.com/dashboard/settings/api-keys>). Call `close()` when you are done
with a client, so the underlying connection pool is released.

## Flutter

Add the dependency to `pubspec.yaml` and use it exactly as above — nothing in
this package imports `dart:io` on a path the web can reach.

```yaml
dependencies:
  fopost: ^0.3.0
```

Two things to know:

- **No environment on the web.** `FOPOST_API_KEY` and `FOPOST_BASE_URL` are read
  through `dart:io`, which Flutter web does not have, so a web build must pass
  `apiKey:` to the constructor.
- **Keys belong on your server.** An API key shipped inside a mobile or web
  build can be extracted from it. Call FoPost from your own backend and let the
  app talk to that, or restrict the key's scopes to exactly what the app needs.

Uploads take bytes rather than a path, so the same code works everywhere:

```dart
final bytes = await File('chart.png').readAsBytes();      // dart:io
final bytes = await pickedFile.readAsBytes();             // image_picker, web included

final uploaded = await client.media.upload(workspace.id, [
  FoPostFile(filename: 'chart.png', bytes: bytes),
]);
```

For a direct upload the bytes go straight to storage instead of through the
API: `uploadDirect` presigns a slot, `PUT`s the bytes to it, and completes.
`presign` and `complete` are also exposed for doing the `PUT` yourself:

```dart
final asset = await client.media.uploadDirect(
  workspace.id,
  'chart.png',
  'image/png',
  bytes,
);
```

## Content

`content` takes a `String` for a single post, or a list for a thread. Each entry
is a `String`, a `ContentBlock`, or a raw map, and media is attached per block:

```dart
await client.posts.create(
  workspaceId: workspace.id,
  accounts: accountIds,
  content: [
    'First post in the thread',
    ContentBlock(
      text: 'Second one, with an image',
      media: [uploaded.first.toMediaItem()],
    ),
  ],
);
```

## Scheduling and publishing

`status` is `'draft'` or `'scheduled'`; a scheduled post needs `scheduleAt`. To
send something out now, create it and call `publish`. Nothing reaches a platform
without one of those two, and `publish` returns when delivery is **queued**, not
when it is live.

```dart
await client.posts.create(
  workspaceId: workspace.id,
  accounts: accountIds,
  content: 'Scheduled with the SDK',
  status: PostStatus.scheduled,
  scheduleAt: DateTime.utc(2026, 9, 1, 10),
);
```

`preflight` reports per-account blockers and advisory signals without
publishing, and `publish(..., dryRun: true)` validates the whole delivery plan:

```dart
final check = await client.posts.preflight(post.id);
for (final account in check.accounts) {
  print('${account.platform} ready=${account.ready} ${account.issues}');
}
```

After publishing, `deliveries` is the per-account state, `retry` re-sends only
what failed, and `cancel` stops what has not gone out yet.

## Pagination

`posts.list` returns one `Page` with its `meta`. `posts.stream` walks every page
for you:

```dart
final page = await client.posts.list(
  workspaceId: workspace.id,
  status: PostStatus.published,
  perPage: 50,
);
print('${page.meta.total} published posts');

await for (final post in client.posts.stream(workspaceId: workspace.id)) {
  print('${post.id} ${post.status}');
}
```

Unset parameters are not sent, so the API applies its own defaults.

## Configuration

```dart
final client = FoPost(
  apiKey: 'fp_...',
  baseUrl: 'http://localhost:8080/v1',        // point at another deployment
  timeout: const Duration(seconds: 30),       // per attempt
  maxRetries: 3,                              // total attempts, so 2 retries
  userAgent: 'my-app/2.0',                    // prefixed to the SDK's
  httpClient: myClient,                       // bring your own transport
);
```

| Env var           | Used for                                              |
| ----------------- | ----------------------------------------------------- |
| `FOPOST_API_KEY`  | API key, when `apiKey` is not passed                  |
| `FOPOST_BASE_URL` | API root, when `baseUrl` is not passed                |

Both are read through `dart:io` and are simply absent on the web.

A client you pass in with `httpClient` is never closed by `close()` — close it
where you created it.

## Retries

Every request is attempted up to `maxRetries` times, which defaults to 3, so two
retries. Only these are retried:

- **429** — waiting the interval `Retry-After` asks for, in either delta-seconds
  or HTTP-date form, capped at 60 seconds
- **5xx**
- **transport errors** — a socket failure, a DNS failure, or the timeout

Everything else, including a 400 or a 404, throws on the first response, because
the request itself is what needs changing. Backoff between attempts is
exponential: 500ms, then 1s, capped at 60s.

## Errors

Every non-2xx response throws a subclass of `FoPostException`, carrying the
API's `statusCode`, `code`, `message`, and the raw decoded `body`.

```dart
try {
  await client.posts.publish(postId);
} on FoPostPaymentRequiredException catch (error) {
  print('Subscription needed — upgrade at ${error.upgradeUrl}');
} on FoPostRateLimitException catch (error) {
  print('Rate limited, retry in ${error.retryAfter}');
} on FoPostException catch (error) {
  print('${error.statusCode} ${error.code}: ${error.message}');
}
```

| Status  | Exception                           | Meaning                                     |
| ------- | ----------------------------------- | ------------------------------------------- |
| 400/422 | `FoPostValidationException`         | the body did not pass validation            |
| 401     | `FoPostAuthenticationException`     | missing, invalid, or expired key            |
| 402     | `FoPostPaymentRequiredException`    | no active subscription, or credits exhausted |
| 403     | `FoPostPermissionDeniedException`   | valid key, but no scope or workspace access |
| 404     | `FoPostNotFoundException`           | no such resource, or outside the key's reach |
| 429     | `FoPostRateLimitException`          | over the plan's per-minute ceiling          |
| 5xx     | `FoPostServerException`             | the API failed to handle the request        |
| —       | `FoPostConnectionException`         | the request never reached the API           |

`error.rateLimit` carries the `X-RateLimit-*` headers that came with the
response, and `error.bodyMap` gives you any extra fields the API sent.

## Resources

| Resource      | Covers                                                                                                                                                                                                    |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `posts`       | `list`, `stream`, `get`, `create`, `update`, `delete`, `duplicate`, `publish`, `retry`, `cancel`, `preflight`, `deliveries`, `publishRuns`, `analytics`, `bulkShift`, `bulkLabel`, `bulkDelete`, `validateBulkImport`, `commitBulkImport`, `rollbackBulkImport` |
| `workspaces`  | `list`, `get`, `create`, `update`, `delete`, `analytics`                                                                                                                                                  |
| `accountGroups`| `list`, `get`, `create`, `update`, `delete`, `setMembers`                                                                                                                                                  |
| `accounts`    | `list`, `get`, `create`, `rename`, `move`, `delete`, `setPrimary`, `validate`, `health`, `healthSummary`, `refreshToken`, `analytics`, `createTelegramConnectCode`, `getTelegramConnectStatus`, `getTelegramBotCommands`, `setTelegramBotCommands`, `deleteTelegramBotCommands`, `slackChannels`, `slackMembers`, `getSlackIdentity`, `updateSlackIdentity`, `iceBreakers`, `setIceBreakers`, `deleteIceBreakers`, `persistentMenu`, `setPersistentMenu`, `deletePersistentMenu`, `greeting`, `setGreeting`, `deleteGreeting`, `webhookSubscription`, `resubscribeWebhook`, `discordChannels`, `switchDiscordChannel`, `getDiscordIdentity`, `updateDiscordIdentity`, `discordPins`, `deleteDiscordMessage`, `pinDiscordMessage`, `unpinDiscordMessage`, `crosspostDiscordMessage`, `createDiscordThread`, `sendDiscordDirectMessage`, `discordEvents`, `getDiscordEvent`, `createDiscordEvent`, `updateDiscordEvent`, `deleteDiscordEvent`, `discordMembers`, `discordMember`, `discordRoles`, `createDiscordRole`, `updateDiscordRole`, `deleteDiscordRole`, `addDiscordMemberRole`, `removeDiscordMemberRole` |
| `communities` | `list`, `sync`, `search`, `add`, `remove`                                                                                                                                                                 |
| `labels`      | `list`, `get`, `create`, `update`, `delete`                                                                                                                                                               |
| `webhooks`    | `list`, `create`, `update`, `delete`, `test`                                                                                                                                                              |
| `analytics`   | `overview`, `timeSeries`, `topPosts`, `labels`, `postsTable`, `postingStreak`, `demographics`, `collect`                                                                                                   |
| `automations` | `list`, `get`, `create`, `update`, `delete`, `toggle`, `runs`, `run`, `trigger`, `stats`                                                                                                                   |
| `media`       | `list`, `upload`, `presign`, `complete`, `uploadDirect`, `delete`                                                                                                                                                                                |
| `inbox`       | `list`, `threads`, `conversations`, `unreadCount`, `accounts`, `platforms`, `markThreadRead`, `refresh`, `listApprovals`, `approveReply`, `rejectReply`, `update`, `editComment`, `reply`, `hide`, `unhide`, `delete`, `like`, `unlike`, `pin`, `unpin`, `react`, `startConversation`, `setTyping`, `handover` |
| `ads`         | `list`, `external`, `boostable`, `connections`, `sources`, `authorizeMeta`, `deleteConnection`, `boost`, `create`, `refresh`, `setStatus`, `delete`, `accountTree`, `createCampaign`, `campaign`, `updateCampaign`, `deleteCampaign`, `duplicateCampaign`, `createAdSet`, `adSet`, `updateAdSet`, `deleteAdSet`, `duplicateAdSet`, `createNetworkAd`, `networkAd`, `updateNetworkAd`, `deleteNetworkAd`, `duplicateNetworkAd`, `bulkSetStatus`, `creatives`, `createCreative`, `creative`, `deleteCreative`, `audiences`, `createAudience`, `audience`, `updateAudience`, `deleteAudience`, `addAudienceUsers`, `searchTargeting`, `estimateReach`, `insights`, `adInsights`, `leadForms`, `createLeadForm`, `leadForm`, `archiveLeadForm`, `leads`, `leadsFeed`, `leadPages`, `subscribeLeadPage`, `unsubscribeLeadPage` |
| `knowledge`   | `list`, `create`, `update`, `delete`, `sync`, `search`                                                                                                                                                    |
| `validate`    | `post`, `length`, `media`                                                                                                                                                                                 |

For an endpoint the SDK does not wrap yet, `request` sends an authenticated call
and hands back the decoded body as it came, envelope and all:

```dart
final body = await client.request('GET', '/platforms');
```

## Scopes and limits

Requests send `X-API-Key`. A key carries only the scopes granted when it was
created: `posts` (which also covers publishing, deliveries, media, and `validate`),
`workspaces`, `accounts`, `labels`, `webhooks`, `analytics`, `automations`,
`inbox`, `ads`. Spending money through `ads` (`boost`, `create`, `setStatus`,
`delete`, `bulkSetStatus`, and every create, update, delete and duplicate on
campaigns, ad sets and network ads) needs `publish` as well, and anything
created starts paused unless `paused: false` is passed. The inbox actions `editComment`, `like`, `unlike`,
`pin`, `unpin`, `react`, `startConversation`, `setTyping` and `handover`, deleting our own
reply, and a reply with `mediaIds` or `quickReplies` need `publish` as well.
A key may also be bound to a single workspace, in which case naming any other
one returns `403`.

Mutating endpoints require an active subscription. Rate limits are per key, per
minute, and every response carries `X-RateLimit-Limit`,
`X-RateLimit-Remaining` and `X-RateLimit-Reset`.

## Example

[`example/example.dart`](example/example.dart) creates a post, previews it, and
publishes it on request:

```bash
export FOPOST_API_KEY=fp_...
dart run example/example.dart "Hello from the Dart SDK" --publish
```

## Contributing

Issues and pull requests are welcome at
[fopost/fopost-dart](https://github.com/fopost/fopost-dart).

```bash
dart pub get
dart analyze --fatal-infos
dart test
dart format .
```

The test suite runs entirely offline against a stubbed transport, so it never
touches the real API.

## License

MIT. See [LICENSE](LICENSE).

Docs at [fopost.com/docs](https://fopost.com/docs). Questions or a problem:
[fopost.com/contact](https://fopost.com/contact) or
[GitHub issues](https://github.com/fopost/fopost-dart/issues).
