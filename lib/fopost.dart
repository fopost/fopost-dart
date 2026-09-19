/// The official Dart SDK for the [FoPost](https://fopost.com) API.
///
/// Schedule, publish and analyze social media posts across every connected
/// platform. Start with [FoPost]:
///
/// ```dart
/// import 'package:fopost/fopost.dart';
///
/// final client = FoPost(apiKey: 'fp_...');
/// final workspaces = await client.workspaces.list();
/// client.close();
/// ```
library;

export 'src/client.dart';
export 'src/errors.dart';
export 'src/file.dart';
export 'src/models/account.dart';
export 'src/models/ad.dart';
export 'src/models/analytics.dart';
export 'src/models/automation.dart';
export 'src/models/common.dart';
export 'src/models/community.dart';
export 'src/models/inbox.dart';
export 'src/models/label.dart';
export 'src/models/media.dart';
export 'src/models/post.dart';
export 'src/models/validate.dart';
export 'src/models/webhook.dart';
export 'src/models/workspace.dart';
export 'src/resources/accounts.dart';
export 'src/resources/ads.dart';
export 'src/resources/analytics.dart';
export 'src/resources/automations.dart';
export 'src/resources/communities.dart';
export 'src/resources/inbox.dart';
export 'src/resources/labels.dart';
export 'src/resources/media.dart';
export 'src/resources/posts.dart';
export 'src/resources/validate.dart';
export 'src/resources/webhooks.dart';
export 'src/resources/workspaces.dart';
export 'src/version.dart';
