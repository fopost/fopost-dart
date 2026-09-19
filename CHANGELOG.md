# Changelog

## Unreleased

- Added: `validate` resource (`post`, `length`, `media`) for standalone checks
  that store nothing. Needs the `posts` scope.
- Added: `accountGroups` resource (`list`, `get`, `create`, `update`,
  `delete`, `setMembers`) and `accounts.rename` / `accounts.move`. Needs the
  `accounts` scope.
- Added: `accounts.list(groupId:)`, `platformName` on `Account` and
  `AccountDetail`, and `accountGroupId` on `posts.create`, where `accounts` is
  now optional.

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
