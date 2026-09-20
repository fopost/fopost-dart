import 'package:http/http.dart' as http;

import 'env/env.dart';
import 'http.dart';
import 'resources/account_groups.dart';
import 'resources/accounts.dart';
import 'resources/activity.dart';
import 'resources/ads.dart';
import 'resources/analytics.dart';
import 'resources/automations.dart';
import 'resources/broadcasts.dart';
import 'resources/communities.dart';
import 'resources/contacts.dart';
import 'resources/google_ads.dart';
import 'resources/google_business.dart';
import 'resources/inbox.dart';
import 'resources/knowledge.dart';
import 'resources/labels.dart';
import 'resources/media.dart';
import 'resources/posts.dart';
import 'resources/validate.dart';
import 'resources/webhooks.dart';
import 'resources/workspaces.dart';
import 'version.dart';

/// The FoPost API, one client per API key.
///
/// ```dart
/// final client = FoPost(apiKey: 'fp_...');
///
/// final workspace = (await client.workspaces.list()).first;
/// final accounts = await client.accounts.list(workspaceId: workspace.id);
///
/// final post = await client.posts.create(
///   workspaceId: workspace.id,
///   accounts: accounts.map((a) => a.id).toList(),
///   content: 'Hello from Dart',
/// );
/// await client.posts.publish(post.id);
///
/// client.close();
/// ```
///
/// Pure Dart, so the same client runs on Flutter (iOS, Android, web, desktop)
/// and on the server. Call [close] when you are done with it.
class FoPost {
  /// Builds a client for [apiKey], created in the FoPost dashboard under
  /// Settings → API Keys.
  ///
  /// Leaving [apiKey] unset falls back to the `FOPOST_API_KEY` environment
  /// variable, and [baseUrl] to `FOPOST_BASE_URL`. There are no environment
  /// variables on the web, so a browser or Flutter web app must pass the key.
  ///
  /// Pass [httpClient] to bring your own transport — a client with a proxy, a
  /// logging interceptor, or a test double. The SDK never closes a client it
  /// did not create.
  FoPost({
    String? apiKey,
    String? baseUrl,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
    String? userAgent,
    Duration retryBaseDelay = const Duration(milliseconds: 500),
  }) {
    final key = apiKey ?? envValue('FOPOST_API_KEY');
    if (key == null || key.isEmpty) {
      throw ArgumentError(
        'an API key is required — pass FoPost(apiKey: ...) or set FOPOST_API_KEY',
      );
    }

    final root = baseUrl ?? envValue('FOPOST_BASE_URL') ?? defaultBaseUrl;
    _http = FoPostHttp(
      apiKey: key,
      baseUrl: root.replaceAll(RegExp(r'/+$'), ''),
      httpClient: httpClient ?? http.Client(),
      ownsClient: httpClient == null,
      timeout: timeout,
      maxRetries: maxRetries < 1 ? 1 : maxRetries,
      userAgent: userAgent == null
          ? 'fopost-dart/$foPostVersion'
          : '$userAgent fopost-dart/$foPostVersion',
      retryBaseDelay: retryBaseDelay,
    );

    posts = PostsResource(_http);
    workspaces = WorkspacesResource(_http);
    accounts = AccountsResource(_http);
    communities = CommunitiesResource(_http);
    labels = LabelsResource(_http);
    activity = ActivityResource(_http);
    accountGroups = AccountGroupsResource(_http);
    webhooks = WebhooksResource(_http);
    analytics = AnalyticsResource(_http);
    automations = AutomationsResource(_http);
    media = MediaResource(_http);
    inbox = InboxResource(_http);
    contacts = ContactsResource(_http);
    broadcasts = BroadcastsResource(_http);
    sequences = SequencesResource(_http);
    knowledge = KnowledgeResource(_http);
    ads = AdsResource(_http);
    googleAds = GoogleAdsResource(_http);
    validate = ValidateResource(_http);
    googleBusiness = GoogleBusinessResource(_http);
  }

  /// The production API, including its version prefix.
  static const String defaultBaseUrl = 'https://api.fopost.com/v1';

  late final FoPostHttp _http;

  /// Posts, publishing, deliveries, and bulk operations.
  late final PostsResource posts;

  /// Workspaces, the tenant boundary every other resource is scoped to.
  late final WorkspacesResource workspaces;

  /// Connected social accounts.
  late final AccountsResource accounts;

  /// The communities an account can post into.
  late final CommunitiesResource communities;

  /// Campaign labels.
  late final LabelsResource labels;

  /// What happened in a workspace, and the security audit log.
  late final ActivityResource activity;

  /// Named sets of accounts a post can target at once.
  late final AccountGroupsResource accountGroups;

  /// Outbound webhook subscriptions.
  late final WebhooksResource webhooks;

  /// Cross-account reporting.
  late final AnalyticsResource analytics;

  /// Automations and their runs.
  late final AutomationsResource automations;

  /// The media library.
  late final MediaResource media;

  /// Comments, mentions and direct messages on connected accounts.
  late final InboxResource inbox;

  /// The people behind that inbox, and the fields a workspace keeps about them.
  late final ContactsResource contacts;

  /// One message into every conversation the workspace already has with a
  /// segment of its contacts.
  late final BroadcastsResource broadcasts;

  /// A series of messages on a delay, walked per enrolled contact.
  late final SequencesResource sequences;

  /// The workspace knowledge base, which grounds drafted replies.
  late final KnowledgeResource knowledge;

  /// Boosts, ads, audiences and lead forms.
  late final AdsResource ads;

  /// Google Ads only: keywords, assets, conversions and raw GAQL.
  late final GoogleAdsResource googleAds;

  /// Standalone checks on a draft, a text's length, or a media URL.
  late final ValidateResource validate;

  /// Manage a connected Google Business Profile location.
  late final GoogleBusinessResource googleBusiness;

  /// The API root every request is sent to.
  String get baseUrl => _http.baseUrl;

  /// Sends an authenticated request to an endpoint the SDK does not wrap yet.
  ///
  /// The decoded body comes back exactly as the API sent it, envelope and all,
  /// so a `{"data": ...}` response arrives as a map with a `data` key. Errors
  /// and retries work the same as on every other call.
  ///
  /// ```dart
  /// final body = await client.request('GET', '/platforms');
  /// ```
  Future<dynamic> request(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) =>
      _http.raw(method, path, body: body, query: query);

  /// Releases the underlying HTTP client.
  ///
  /// A client you supplied yourself is left alone — close it where you made it.
  void close() => _http.close();
}
