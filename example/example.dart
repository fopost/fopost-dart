// Creates a post, previews it against every target platform, and optionally
// publishes it.
//
//   export FOPOST_API_KEY=fp_...
//   dart run example/example.dart "Hello from the Dart SDK" --publish

import 'dart:io';

import 'package:fopost/fopost.dart';

Future<void> main(List<String> args) async {
  final publish = args.contains('--publish');
  final words = args.where((arg) => arg != '--publish').join(' ');
  final text = words.isEmpty ? 'Hello from the FoPost Dart SDK' : words;

  // With no apiKey the client reads FOPOST_API_KEY from the environment.
  final client = FoPost();

  try {
    final workspaces = await client.workspaces.list();
    if (workspaces.isEmpty) {
      stderr.writeln('No workspaces on this account.');
      exitCode = 1;
      return;
    }
    final workspace = workspaces.first;

    final accounts = await client.accounts.list(workspaceId: workspace.id);
    if (accounts.isEmpty) {
      stderr.writeln('No connected accounts in ${workspace.name}.');
      exitCode = 1;
      return;
    }

    final post = await client.posts.create(
      workspaceId: workspace.id,
      accounts: accounts.map((account) => account.id).toList(),
      content: text,
    );
    stdout.writeln('Created ${post.id} in ${workspace.name} (${post.status})');

    final check = await client.posts.preflight(post.id);
    for (final account in check.accounts) {
      stdout.writeln('  ${account.platform.padRight(12)} '
          'ready=${account.ready} issues=${account.issues}');
    }

    if (!publish) {
      stdout.writeln('Pass --publish to send it out.');
      return;
    }
    if (!check.ready) {
      stderr.writeln('Preflight found blockers; not publishing.');
      exitCode = 1;
      return;
    }

    final result = await client.posts.publish(post.id);
    stdout.writeln('Queued: ${result.postStatus}');
    for (final delivery in result.deliveries) {
      stdout.writeln('  ${delivery.accountId} -> ${delivery.status}');
    }
  } on FoPostPaymentRequiredException catch (error) {
    stderr.writeln('${error.message} — upgrade at ${error.upgradeUrl}');
    exitCode = 1;
  } on FoPostRateLimitException catch (error) {
    stderr.writeln('Rate limited; try again in ${error.retryAfter}');
    exitCode = 1;
  } on FoPostException catch (error) {
    stderr.writeln('API error: $error');
    exitCode = 1;
  } finally {
    client.close();
  }
}
