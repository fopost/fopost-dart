import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

Map<String, dynamic> adJson({String status = AdStatus.paused}) => {
      'id': 'ad_1',
      'workspaceId': 'ws_1',
      'kind': 'boost',
      'name': 'Launch boost',
      'goal': 'engagement',
      'status': status,
      'effectiveStatus': 'PAUSED',
      'connectionId': 'conn_1',
      'accountId': 'acc_1',
      'platform': 'facebook',
      'adAccountId': 'act_123',
      'sourcePostId': 'p_1',
      'budgetMinor': 2000,
      'budgetType': 'daily',
      'currency': 'USD',
      'targeting': {
        'countries': ['US'],
        'ageMin': 18,
        'ageMax': 65,
        'gender': 'all',
        'interests': [
          {'id': '6003', 'name': 'Coffee'}
        ],
      },
      'insights': {
        'impressions': 120,
        'reach': 100,
        'clicks': 4,
        'spendMinor': 350
      },
      'insightsAt': '2026-09-18T12:00:00.000Z',
      'createdAt': '2026-09-17T12:00:00.000Z',
    };

void main() {
  test('boost posts the camelCase body and reads the ad', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({'data': adJson()}, status: 201),
        recorder: seen);

    final ad = await client.ads.boost(
      workspaceId: 'ws_1',
      connectionId: 'conn_1',
      adAccountId: 'act_123',
      postId: 'p_1',
      accountId: 'acc_1',
      name: 'Launch boost',
      goal: AdGoal.engagement,
      budget: const AdBudget(minor: 2000, type: AdBudgetType.daily),
      targeting: const AdTargeting(
        countries: ['US'],
        ageMin: 18,
        ageMax: 65,
        interests: [AdTargetingRef(id: '6003', name: 'Coffee')],
      ),
      paused: false,
    );

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/ads/boost');
    expect(jsonDecode(seen.last.body), {
      'workspaceId': 'ws_1',
      'connectionId': 'conn_1',
      'adAccountId': 'act_123',
      'postId': 'p_1',
      'accountId': 'acc_1',
      'name': 'Launch boost',
      'goal': 'engagement',
      'budget': {'minor': 2000, 'type': 'daily'},
      'targeting': {
        'countries': ['US'],
        'ageMin': 18,
        'ageMax': 65,
        'gender': 'all',
        'interests': [
          {'id': '6003', 'name': 'Coffee'}
        ],
      },
      'paused': false,
    });

    expect(ad.id, 'ad_1');
    expect(ad.kind, 'boost');
    expect(ad.status, AdStatus.paused);
    expect(ad.budgetMinor, 2000);
    expect(ad.targeting?.interests.single.name, 'Coffee');
    expect(ad.insights?.spendMinor, 350);
    expect(ad.insightsAt, DateTime.utc(2026, 9, 18, 12));
    client.close();
  });

  test('create sends the creative and a lifetime budget end', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({'data': adJson()}, status: 201),
        recorder: seen);

    await client.ads.create(
      workspaceId: 'ws_1',
      connectionId: 'conn_1',
      adAccountId: 'act_123',
      pageId: 'page_1',
      name: 'Autumn sale',
      goal: AdGoal.traffic,
      budget: AdBudget(
        minor: 50000,
        type: AdBudgetType.lifetime,
        endAt: DateTime.utc(2026, 10, 1),
      ),
      targeting: const AdTargeting(countries: ['US'], ageMin: 21, ageMax: 45),
      text: 'Autumn sale is on',
      headline: 'Save today',
      destinationUrl: 'https://yourbrand.com/sale',
    );

    expect(seen.last.url.path, '/v1/ads');
    final body = jsonDecode(seen.last.body) as Map<String, dynamic>;
    expect(body['pageId'], 'page_1');
    expect(body['text'], 'Autumn sale is on');
    expect(body['headline'], 'Save today');
    expect(body['destinationUrl'], 'https://yourbrand.com/sale');
    expect(body['budget'], {
      'minor': 50000,
      'type': 'lifetime',
      'endAt': '2026-10-01T00:00:00.000Z'
    });
    expect(body.containsKey('paused'), isFalse);
    expect(body.containsKey('mediaUrl'), isFalse);
    client.close();
  });

  test('refresh, setStatus and delete carry workspace_id in the query',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (request) async => request.method == 'DELETE'
          ? jsonBare({'message': 'Ad deleted'})
          : jsonOk(adJson(status: AdStatus.active)),
      recorder: seen,
    );

    await client.ads.refresh('ad_1', workspaceId: 'ws_1');
    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/ads/ad_1/refresh');
    expect(seen.last.url.queryParameters, {'workspace_id': 'ws_1'});

    final ad = await client.ads
        .setStatus('ad_1', workspaceId: 'ws_1', status: AdStatus.active);
    expect(seen.last.method, 'PATCH');
    expect(seen.last.url.path, '/v1/ads/ad_1');
    expect(seen.last.url.queryParameters, {'workspace_id': 'ws_1'});
    expect(jsonDecode(seen.last.body), {'status': 'active'});
    expect(ad.status, AdStatus.active);

    await client.ads.delete('ad_1', workspaceId: 'ws_1');
    expect(seen.last.method, 'DELETE');
    expect(seen.last.url.path, '/v1/ads/ad_1');
    expect(seen.last.url.queryParameters, {'workspace_id': 'ws_1'});
    client.close();
  });

  test('connections: list, sources, authorize and delete', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (request) async {
        final path = request.url.path;
        if (path.endsWith('/authorize')) {
          return jsonOk({'url': 'https://www.facebook.com/dialog/oauth?x=1'});
        }
        if (request.method == 'DELETE') return jsonBare({'message': 'ok'});
        if (path.endsWith('/sources')) {
          return jsonOk([
            {
              'connectionId': 'conn_1',
              'name': 'Your Brand',
              'adAccounts': [
                {
                  'id': 'act_123',
                  'name': 'Main',
                  'currency': 'USD',
                  'status': 1
                }
              ],
              'pages': [
                {'id': 'page_1', 'name': 'Your Brand', 'instagramUserId': null}
              ],
            }
          ]);
        }
        return jsonOk([
          {
            'id': 'conn_1',
            'provider': 'meta',
            'authType': 'business',
            'name': 'Your Brand',
            'createdAt': '2026-09-01T00:00:00.000Z',
          }
        ]);
      },
      recorder: seen,
    );

    final connections = await client.ads.connections(workspaceId: 'ws_1');
    expect(seen.last.url.path, '/v1/ads/connections');
    expect(connections.single.authType, 'business');

    final sources = await client.ads.sources(workspaceId: 'ws_1');
    expect(sources.single.adAccounts.single.currency, 'USD');
    expect(sources.single.pages.single.instagramUserId, isNull);

    final url = await client.ads.authorizeMeta(
        workspaceId: 'ws_1', method: 'business', returnTo: '/ads');
    expect(seen.last.url.path, '/v1/ads/connections/meta/authorize');
    expect(jsonDecode(seen.last.body),
        {'workspaceId': 'ws_1', 'method': 'business', 'returnTo': '/ads'});
    expect(url, startsWith('https://www.facebook.com/'));

    await client.ads.deleteConnection('conn_1', workspaceId: 'ws_1');
    expect(seen.last.method, 'DELETE');
    expect(seen.last.url.path, '/v1/ads/connections/conn_1');
    expect(seen.last.url.queryParameters, {'workspace_id': 'ws_1'});
    client.close();
  });

  test('audiences: read, create with a typed spec, and search targeting',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (request) async {
        if (request.method == 'POST') {
          return jsonBare({
            'data': {'id': 'aud_9', 'added': 2}
          }, status: 201);
        }
        if (request.url.path.endsWith('/targeting/search')) {
          return jsonOk([
            {'id': '2421', 'name': 'Austin', 'detail': 'Texas'}
          ]);
        }
        return jsonOk({
          'audiences': [
            {
              'id': 'aud_1',
              'name': 'Buyers',
              'subtype': 'CUSTOM',
              'sizeLower': 1000
            }
          ],
          'pixels': [
            {'id': 'px_1', 'name': 'Site'}
          ],
          'workspaceId': 'ws_1',
        });
      },
      recorder: seen,
    );

    final result = await client.ads
        .audiences(connectionId: 'conn_1', adAccountId: 'act_123');
    expect(seen.last.url.path, '/v1/ads/audiences');
    expect(seen.last.url.queryParameters,
        {'connection_id': 'conn_1', 'ad_account_id': 'act_123'});
    expect(result.audiences.single.sizeLower, 1000);
    expect(result.pixels.single.id, 'px_1');

    final created = await client.ads.createAudience(
      workspaceId: 'ws_1',
      connectionId: 'conn_1',
      adAccountId: 'act_123',
      name: 'Lookalike buyers',
      spec: AudienceSpec.lookalike(
          originAudienceId: 'aud_1', country: 'US', ratio: 0.05),
    );
    expect(jsonDecode(seen.last.body), {
      'workspaceId': 'ws_1',
      'connectionId': 'conn_1',
      'adAccountId': 'act_123',
      'name': 'Lookalike buyers',
      'spec': {
        'subtype': 'LOOKALIKE',
        'originAudienceId': 'aud_1',
        'country': 'US',
        'ratio': 0.05,
      },
    });
    expect(created.id, 'aud_9');
    expect(created.added, 2);

    final options = await client.ads.searchTargeting(
        connectionId: 'conn_1', type: TargetingType.city, q: 'Aus');
    expect(seen.last.url.path, '/v1/ads/targeting/search');
    expect(seen.last.url.queryParameters,
        {'connection_id': 'conn_1', 'type': 'city', 'q': 'Aus'});
    expect(options.single.detail, 'Texas');
    client.close();
  });

  test('lead forms: list, create, and page through leads', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (request) async {
        if (request.method == 'POST') {
          return jsonBare({
            'data': {'id': 'form_7'}
          }, status: 201);
        }
        if (request.url.path.endsWith('/leads')) {
          return jsonOk({
            'leads': [
              {
                'id': 'lead_1',
                'createdAt': '2026-09-18T08:00:00+0000',
                'fields': [
                  {
                    'name': 'full_name',
                    'values': ['Ada Example']
                  }
                ],
                'isOrganic': false,
              }
            ],
            'nextCursor': 'abc',
          });
        }
        return jsonOk([
          {
            'connectionId': 'conn_1',
            'connectionName': 'Your Brand',
            'pageId': 'page_1',
            'forms': [
              {
                'id': 'form_1',
                'name': 'Newsletter',
                'leadsCount': 3,
                'questions': ['EMAIL']
              }
            ],
          }
        ]);
      },
      recorder: seen,
    );

    final sources = await client.ads.leadForms(workspaceId: 'ws_1');
    expect(seen.last.url.path, '/v1/ads/lead-forms');
    expect(sources.single.forms.single.leadsCount, 3);

    final id = await client.ads.createLeadForm(
      workspaceId: 'ws_1',
      connectionId: 'conn_1',
      pageId: 'page_1',
      name: 'Newsletter',
      questions: const [LeadFormQuestion.email, LeadFormQuestion.fullName],
      privacyPolicyUrl: 'https://yourbrand.com/privacy',
      thankYouMessage: 'Thanks!',
    );
    expect(seen.last.url.path, '/v1/ads/lead-forms');
    expect(jsonDecode(seen.last.body), {
      'workspaceId': 'ws_1',
      'connectionId': 'conn_1',
      'pageId': 'page_1',
      'name': 'Newsletter',
      'questions': ['EMAIL', 'FULL_NAME'],
      'privacyPolicyUrl': 'https://yourbrand.com/privacy',
      'thankYouMessage': 'Thanks!',
    });
    expect(id, 'form_7');

    final leads = await client.ads.leads('form_7',
        connectionId: 'conn_1', pageId: 'page_1', after: 'xyz');
    expect(seen.last.url.path, '/v1/ads/lead-forms/form_7/leads');
    expect(seen.last.url.queryParameters,
        {'connection_id': 'conn_1', 'page_id': 'page_1', 'after': 'xyz'});
    expect(leads.leads.single.fields.single.values, ['Ada Example']);
    expect(leads.nextCursor, 'abc');
    expect(leads.hasMore, isTrue);
    client.close();
  });

  test('list, external and boostable read their rows', () async {
    final client = fakeClient(
      (request) async {
        final path = request.url.path;
        if (path.endsWith('/external')) {
          return jsonOk([
            {
              'id': '1200',
              'name': 'Brand awareness',
              'effectiveStatus': 'ACTIVE',
              'campaignName': 'Q4',
              'budgetMinor': 1000,
              'budgetType': 'daily',
              'connectionId': 'conn_1',
              'adAccountId': 'act_123',
            }
          ]);
        }
        if (path.endsWith('/boostable')) {
          return jsonOk([
            {
              'id': 'p_1',
              'text': 'Launch day',
              'deliveries': [
                {
                  'accountId': 'acc_1',
                  'platform': 'facebook',
                  'username': 'yourbrand',
                  'postedAt': '2026-09-17T12:00:00.000Z',
                }
              ],
            }
          ]);
        }
        return jsonOk([adJson()]);
      },
    );

    expect((await client.ads.list(workspaceId: 'ws_1')).single.name,
        'Launch boost');
    final external = await client.ads.external(workspaceId: 'ws_1');
    expect(external.single.campaignName, 'Q4');
    expect(external.single.budgetType, AdBudgetType.daily);
    final boostable = await client.ads.boostable(workspaceId: 'ws_1');
    expect(boostable.single.deliveries.single.platform, 'facebook');
    client.close();
  });
}
