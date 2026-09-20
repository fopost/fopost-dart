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

    final url = await client.ads
        .authorize(workspaceId: 'ws_1', method: 'business', returnTo: '/ads');
    expect(seen.last.url.path, '/v1/ads/connections/meta/authorize');
    expect(jsonDecode(seen.last.body),
        {'workspaceId': 'ws_1', 'method': 'business', 'returnTo': '/ads'});
    expect(url, startsWith('https://www.facebook.com/'));

    // The provider names the path, so a connection is not Meta-only.
    await client.ads.authorize(workspaceId: 'ws_1', provider: 'pinterest');
    expect(seen.last.url.path, '/v1/ads/connections/pinterest/authorize');

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

  test('accountTree nests ad sets and ads under campaigns', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'adAccountId': 'act_123',
              'currency': 'USD',
              'workspaceId': 'ws_1',
              'campaigns': [
                {
                  'id': 'c_1',
                  'name': 'Launch',
                  'status': 'ACTIVE',
                  'budgetMinor': null,
                  'adSets': [
                    {
                      'id': 's_1',
                      'name': 'US',
                      'campaignId': 'c_1',
                      'status': 'PAUSED',
                      'budgetMinor': 2000,
                      'budgetType': 'daily',
                      'ads': [
                        {
                          'id': 'a_1',
                          'name': 'Morning',
                          'adSetId': 's_1',
                          'creativeId': 'cr_1',
                          'status': 'PAUSED',
                        }
                      ],
                    }
                  ],
                }
              ],
            }),
        recorder: seen);

    final tree = await client.ads
        .accountTree('act_123', connectionId: 'conn_1', workspaceId: 'ws_1');

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/ads/accounts/act_123/tree');
    expect(seen.last.url.queryParameters,
        {'workspace_id': 'ws_1', 'connection_id': 'conn_1'});
    final campaign = tree.campaigns.single;
    expect(campaign.budgetMinor, isNull);
    expect(campaign.adSets.single.budgetMinor, 2000);
    expect(campaign.adSets.single.ads.single.creativeId, 'cr_1');
    client.close();
  });

  test('campaign writes carry workspace and connection in the query', () async {
    final seen = RecordedRequests();
    final client = fakeClient((request) async {
      if (request.url.path.endsWith('/duplicate')) {
        return jsonBare({
          'data': {'id': 'c_2'}
        }, status: 201);
      }
      if (request.method == 'DELETE') {
        return jsonBare({'message': 'Campaign deleted'});
      }
      return jsonOk({'id': 'c_1', 'name': 'Launch', 'status': 'ACTIVE'});
    }, recorder: seen);

    await client.ads.updateCampaign('c_1',
        workspaceId: 'ws_1', connectionId: 'conn_1', status: AdStatus.active);
    expect(seen.last.method, 'PATCH');
    expect(seen.last.url.path, '/v1/ads/campaigns/c_1');
    expect(seen.last.url.queryParameters,
        {'workspace_id': 'ws_1', 'connection_id': 'conn_1'});
    expect(jsonDecode(seen.last.body), {'status': 'active'});

    final copy = await client.ads.duplicateCampaign('c_1',
        workspaceId: 'ws_1', connectionId: 'conn_1', paused: false);
    expect(copy, 'c_2');
    expect(seen.last.url.path, '/v1/ads/campaigns/c_1/duplicate');
    expect(jsonDecode(seen.last.body), {'paused': false});

    await client.ads
        .deleteCampaign('c_1', workspaceId: 'ws_1', connectionId: 'conn_1');
    expect(seen.last.method, 'DELETE');
    expect(seen.last.url.path, '/v1/ads/campaigns/c_1');
    client.close();
  });

  test('bulkSetStatus sends each object with its level', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk([
              {'id': 'c_1', 'level': 'campaign', 'ok': true, 'error': null},
              {'id': 'a_1', 'level': 'ad', 'ok': false, 'error': 'Not found'},
            ]),
        recorder: seen);

    final results = await client.ads.bulkSetStatus(
      workspaceId: 'ws_1',
      connectionId: 'conn_1',
      status: AdStatus.paused,
      objects: const [
        AdObjectRef(id: 'c_1', level: AdObjectLevel.campaign),
        AdObjectRef(id: 'a_1', level: AdObjectLevel.ad),
      ],
    );

    expect(seen.last.url.path, '/v1/ads/status');
    expect(jsonDecode(seen.last.body)['objects'], [
      {'id': 'c_1', 'level': 'campaign'},
      {'id': 'a_1', 'level': 'ad'},
    ]);
    expect(results.last.ok, isFalse);
    expect(results.last.error, 'Not found');
    client.close();
  });

  test('insights send the range, breakdown and daily flag', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'objectId': 'c_1',
              'currency': 'USD',
              'since': '2026-09-01',
              'until': '2026-09-07',
              'breakdownBy': 'age',
              'totals': {
                'impressions': 1000,
                'reach': 800,
                'clicks': 25,
                'spendMinor': 1200,
                'ctr': 2.5,
                'leads': 3,
              },
              'breakdown': [
                {
                  'key': '25-34',
                  'metrics': {'impressions': 600}
                }
              ],
              'timeline': [
                {
                  'date': '2026-09-01',
                  'metrics': {'spendMinor': 150}
                }
              ],
            }),
        recorder: seen);

    final report = await client.ads.insights(
      connectionId: 'conn_1',
      objectId: 'c_1',
      since: '2026-09-01',
      until: '2026-09-07',
      breakdown: AdInsightsBreakdown.age,
      daily: true,
    );
    expect(seen.last.url.path, '/v1/ads/insights');
    expect(seen.last.url.queryParameters, {
      'connection_id': 'conn_1',
      'object_id': 'c_1',
      'since': '2026-09-01',
      'until': '2026-09-07',
      'breakdown': 'age',
      'daily': 'true',
    });
    expect(report.totals?.ctr, 2.5);
    expect(report.breakdown.single.key, '25-34');
    expect(report.timeline.single.key, '2026-09-01');
    expect(report.timeline.single.metrics.spendMinor, 150);

    await client.ads.adInsights('ad_1',
        workspaceId: 'ws_1', since: '2026-09-01', until: '2026-09-07');
    expect(seen.last.url.path, '/v1/ads/ad_1/insights');
    expect(seen.last.url.queryParameters,
        {'workspace_id': 'ws_1', 'since': '2026-09-01', 'until': '2026-09-07'});
    client.close();
  });

  test('leadsFeed passes the cursor back', () async {
    final seen = RecordedRequests();
    final client = fakeClient((request) async {
      if (request.url.queryParameters['cursor'] == 'cur_2') {
        return jsonOk({'leads': [], 'nextCursor': null});
      }
      return jsonOk({
        'leads': [
          {
            'id': 'l_1',
            'leadId': 'm_1',
            'pageId': '1234',
            'formId': 'form_1',
            'isOrganic': false,
            'fields': [
              {
                'name': 'email',
                'values': ['sam@yourbrand.com']
              }
            ],
            'submittedAt': '2026-09-10T12:00:00.000Z',
          }
        ],
        'nextCursor': 'cur_2',
      });
    }, recorder: seen);

    final first = await client.ads
        .leadsFeed(workspaceId: 'ws_1', formId: 'form_1', limit: 50);
    expect(seen.last.url.path, '/v1/ads/leads');
    expect(seen.last.url.queryParameters,
        {'workspace_id': 'ws_1', 'form_id': 'form_1', 'limit': '50'});
    expect(first.leads.single.leadId, 'm_1');
    expect(first.leads.single.submittedAt, DateTime.utc(2026, 9, 10, 12));
    expect(first.hasMore, isTrue);

    final second = await client.ads.leadsFeed(
        workspaceId: 'ws_1',
        formId: 'form_1',
        cursor: first.nextCursor,
        limit: 50);
    expect(seen.last.url.queryParameters['cursor'], 'cur_2');
    expect(second.leads, isEmpty);
    expect(second.hasMore, isFalse);
    client.close();
  });

  test('creatives carry urlTags and lead pages subscribe', () async {
    final seen = RecordedRequests();
    final client = fakeClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/creatives')) {
        return jsonBare({
          'data': {
            'id': 'cr_1',
            'name': 'Carousel',
            'format': 'carousel',
            'callToAction': 'SHOP_NOW',
            'urlTags': 'utm_source=meta',
          }
        }, status: 201);
      }
      if (path.endsWith('/users')) return jsonOk({'added': 2});
      if (request.method == 'DELETE') {
        return jsonBare({'message': 'Unsubscribed'});
      }
      return jsonBare({
        'data': {'pageId': '1234', 'backfilled': 7}
      }, status: 201);
    }, recorder: seen);

    final creative = await client.ads.createCreative(
      workspaceId: 'ws_1',
      connectionId: 'conn_1',
      adAccountId: 'act_123',
      pageId: '1234',
      name: 'Carousel',
      format: AdCreativeFormat.carousel,
      text: 'Hi',
      urlTags: 'utm_source=meta',
      cards: const [
        AdCreativeCard(mediaUrl: 'https://cdn.yourbrand.com/1.png'),
        AdCreativeCard(mediaUrl: 'https://cdn.yourbrand.com/2.png'),
      ],
    );
    final body = jsonDecode(seen.last.body) as Map<String, dynamic>;
    expect(body['urlTags'], 'utm_source=meta');
    expect((body['cards'] as List).length, 2);
    expect(body.containsKey('callToAction'), isFalse);
    expect(creative.callToAction, 'SHOP_NOW');

    final page = await client.ads.subscribeLeadPage(
        workspaceId: 'ws_1', connectionId: 'conn_1', pageId: '1234');
    expect(page.backfilled, 7);

    await client.ads.unsubscribeLeadPage('1234',
        workspaceId: 'ws_1', connectionId: 'conn_1');
    expect(seen.last.url.path, '/v1/ads/lead-pages/1234');
    expect(seen.last.url.queryParameters['connection_id'], 'conn_1');

    final added = await client.ads.addAudienceUsers('aud_1',
        workspaceId: 'ws_1',
        connectionId: 'conn_1',
        emails: ['a@yourbrand.com', 'b@yourbrand.com']);
    expect(added, 2);
    expect(seen.last.url.path, '/v1/ads/audiences/aud_1/users');
    client.close();
  });
}
