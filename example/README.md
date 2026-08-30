# Examples

## Create and publish a post

[`example.dart`](example.dart) picks the first workspace and its connected
accounts, composes a post, runs a preflight check, and publishes it when you
pass `--publish`.

```bash
export FOPOST_API_KEY=fp_...
dart run example/example.dart "Hello from the Dart SDK"
dart run example/example.dart "Hello from the Dart SDK" --publish
```

Get a key from **Settings → API Keys** in the FoPost dashboard. On Flutter web
there is no environment, so pass the key to the constructor instead:

```dart
final client = FoPost(apiKey: 'fp_...');
```
