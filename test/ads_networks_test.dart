import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

/// A second ad network behind the same endpoints.
void main() {
  test('authorize reaches whichever network the registry named', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (request) async => jsonOk({'url': 'https://www.linkedin.com/oauth'}),
      recorder: seen,
    );

    final url = await client.ads
        .authorize('linkedin', workspaceId: 'ws_1', returnTo: '/ads');

    expect(seen.last.url.path, '/v1/ads/connections/linkedin/authorize');
    expect(jsonDecode(seen.last.body),
        {'workspaceId': 'ws_1', 'returnTo': '/ads'});
    expect(url, 'https://www.linkedin.com/oauth');
  });

  test('providers carry what each network supports', () async {
    final client = fakeClient(
      (request) async => jsonOk([
        {
          'id': 'linkedin',
          'name': 'LinkedIn Ads',
          'configured': false,
          'connectMethods': <String>[],
          'capabilities': {'conversions': true},
          'targetingFacets': ['country', 'job_title'],
          'trackingMacros': [
            {'token': '{{LINKEDIN_CAMPAIGN_ID}}', 'description': 'Campaign'}
          ],
        }
      ]),
    );

    final providers = await client.ads.providers();

    expect(providers.single.configured, isFalse);
    expect(providers.single.capabilities['conversions'], isTrue);
    expect(providers.single.targetingFacets, ['country', 'job_title']);
    expect(providers.single.trackingMacros.single.token,
        '{{LINKEDIN_CAMPAIGN_ID}}');
  });

  test('company rows travel with the request', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (request) async => jsonOk({'added': 2}),
      recorder: seen,
    );

    final added = await client.ads.addAudienceCompanies(
      'urn:li:adSegment:44',
      workspaceId: 'ws_1',
      connectionId: 'conn_1',
      companies: const [
        AdCompany(domain: 'northwind.example'),
        AdCompany(name: 'Contoso'),
      ],
    );

    expect(added, 2);
    expect(jsonDecode(seen.last.body), {
      'companies': [
        {'domain': 'northwind.example'},
        {'name': 'Contoso'},
      ]
    });
  });

  test('conversion events send the identity the API hashes', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (request) async => jsonOk({'accepted': 1}),
      recorder: seen,
    );

    final accepted = await client.ads.sendConversionEvents(
      'urn:li:conversion:9',
      workspaceId: 'ws_1',
      connectionId: 'conn_1',
      events: const [
        ConversionEvent(happenedAt: 1758326400000, email: 'buyer@example.test'),
      ],
    );

    expect(accepted, 1);
    expect(seen.last.url.path,
        '/v1/ads/linkedin/conversion-rules/urn%3Ali%3Aconversion%3A9/events');
    expect(seen.last.url.queryParameters['connection_id'], 'conn_1');
  });
}
