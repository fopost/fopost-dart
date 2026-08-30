# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## What This Is

`fopost` on [pub.dev](https://pub.dev/packages/fopost) — the official Dart SDK
for the FoPost REST API (`https://api.fopost.com/v1`). It wraps posts,
workspaces, accounts, communities, labels, webhooks, analytics, automations and
media. Pure Dart: it depends only on `http` and `meta`, imports Flutter
nowhere, and therefore runs on Flutter (iOS, Android, web, desktop) and on
server-side Dart from the same source.

## Brand Rules

- The product is **FoPost** (`fopost.com`). Never write "OwlStack" — retired
  Aug 2026.
- Never write an email address. Support is <https://fopost.com/contact> and
  GitHub issues.
- Never name AI providers/models, infrastructure vendors, or any person. The
  author is Porter Bridge, LLC.

## Architecture

```
lib/fopost.dart            the public barrel — every export is public API
lib/src/client.dart        FoPost, the entry point; wires the resources
lib/src/http.dart          FoPostHttp, the transport: retries, decoding, multipart
lib/src/errors.dart        FoPostException and its subclasses, plus RateLimit
lib/src/json.dart          permissive decode helpers (asInt, asDate, pruned, …)
lib/src/file.dart          FoPostFile, bytes for a multipart upload
lib/src/version.dart       foPostVersion, reported in the User-Agent
lib/src/env/               FOPOST_* env reads, behind a conditional import
lib/src/models/            hand-written models, one file per domain
lib/src/resources/         one class per API resource, reached as client.posts etc.
```

A request flows: `client.posts.create(...)` builds a pruned body map →
`FoPostHttp.object('POST', '/posts', body: ...)` → `_run` sends and retries →
the `{"data": ...}` envelope is peeled → `Post.fromJson`.

Things to keep true:

- **No code generation.** Models are hand-written `fromJson` factories so
  consumers need no `build_runner`. Do not introduce `json_serializable`.
- **No `dart:io` outside `lib/src/env/`.** That directory uses a conditional
  export (`env_unsupported.dart` if not `dart.library.io`) so the package still
  compiles for the web. Anything else importing `dart:io` breaks Flutter web.
- **Nothing under `lib/src` is public unless `lib/fopost.dart` exports it.**
  `FoPostHttp` and the `json.dart` helpers are deliberately unexported;
  resource constructors are marked `@internal`.
- **A retried request must be replayable.** Bodies are encoded once, up front,
  and multipart requests are rebuilt per attempt from `FoPostFile.bytes`,
  because `MultipartRequest.finalize()` may only be called once.
- **Response bodies are decoded as UTF-8 from `bodyBytes`.** `http`'s
  `Response.body` falls back to latin1 when the API sends no charset.
- Every public symbol carries a dartdoc comment — pub.dev scores it, and
  `--fatal-infos` will not catch a missing one.

## API Contract

- Auth is the header `X-API-Key: <key>`, never a bearer token. The key comes
  from the constructor, else `FOPOST_API_KEY` (IO platforms only).
- Base URL `https://api.fopost.com/v1`, overridden by the constructor or
  `FOPOST_BASE_URL`.
- Headers on every request: `Accept: application/json`,
  `User-Agent: fopost-dart/<version>`, plus `Content-Type: application/json` on
  a body.
- Timeout 30s per attempt. Retries: 3 total attempts, only on **429**, **>=500**
  and transport errors, backing off `500ms * 2^(attempt-1)` capped at 60s, and
  honouring `Retry-After` on a 429 (delta-seconds or HTTP date, capped at 60s).
- Success envelope `{"data": ...}` on most endpoints — resource calls unwrap it,
  `FoPost.request` deliberately does not. Paginated lists add snake_case `meta`
  (`current_page`, `per_page`, `total`, `last_page`, `from`, `to`).
- Error envelope `{"error": "<code>", "message": "<text>"}`; a 402 may carry
  `upgrade_url`. The raw decoded body stays on `FoPostException.body`.
- `X-RateLimit-Limit`, `-Remaining`, `-Reset` are surfaced on
  `FoPostException.rateLimit`.
- Creating a post never publishes it. Publishing is `create` then `publish`, and
  `publish` returns once delivery is **queued**, not live.

`../fopost-api-collections/openapi.json` is the authoritative endpoint list; the
Go SDK in `../fopost-go` is the most complete reference implementation.

## Commands

```bash
dart pub get
dart analyze --fatal-infos     # CI treats infos as failures
dart test                      # fully offline, MockClient only
dart format .
dart pub publish --dry-run     # checks the pub.dev packaging rules
```

## Conventions

- `package:lints/recommended.yaml` plus `always_declare_return_types`,
  `directives_ordering`, `prefer_final_locals`, `prefer_single_quotes`,
  `unawaited_futures`. Format with `dart format`, never by hand.
- Optional request fields are named parameters, collected into a map and passed
  through `pruned()` so an unset field is simply not sent.
- Tests use `package:http/testing.dart`'s `MockClient` through the helpers in
  `test/support.dart`, and must never reach the network. Pass
  `retryBaseDelay: Duration.zero` so retry tests stay instant.
- Comments are short and explain a "why". Public API gets dartdoc; obvious code
  gets nothing.

## Releasing

Bump `version:` in `pubspec.yaml`, add a `CHANGELOG.md` entry, then tag
`v<version>`. `.github/workflows/release.yml` runs analyze and tests and then
`dart pub publish --force`.

**No repository secret is needed.** Publishing uses pub.dev's OIDC automated
publishing, which requires a one-time setup on pub.dev rather than in GitHub:

1. Publish `0.1.0` manually once (`dart pub publish`) so the package exists.
2. On <https://pub.dev/packages/fopost/admin>, enable **Automated publishing**
   → *Publishing from GitHub Actions*.
3. Set the repository to `fopost/fopost-dart` and the tag pattern to
   `v{{version}}`.

The workflow's `permissions: id-token: write` is what lets `setup-dart`
exchange the GitHub identity token for a short-lived pub credential; without
the pub.dev-side setup the publish step fails with a permission error.

## Git

Conventional Commits, atomic — one logical change per commit. Branch
`feature/<description>`, merge to `main` via PR. Never `gh pr create`: push the
branch and hand over the compare link
(`https://github.com/fopost/fopost-dart/compare/main...<branch>`).
