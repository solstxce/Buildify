import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class CloudflareConfig {
  const CloudflareConfig({
    required this.apiToken,
    required this.zoneId,
    required this.baseDomain,
  });

  final String apiToken;
  final String zoneId;
  final String baseDomain;
}

class CloudflareService {
  CloudflareService({FlutterSecureStorage? secureStorage, http.Client? client})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
      _client = client ?? http.Client();

  static const _tokenKey = 'cloudflare_api_token';
  static const _zoneKey = 'cloudflare_zone_id';
  static const _domainKey = 'cloudflare_base_domain';

  final FlutterSecureStorage _secureStorage;
  final http.Client _client;

  Future<void> saveConfig(CloudflareConfig config) async {
    await _secureStorage.write(key: _tokenKey, value: config.apiToken);
    await _secureStorage.write(key: _zoneKey, value: config.zoneId);
    await _secureStorage.write(key: _domainKey, value: config.baseDomain);
  }

  Future<CloudflareConfig?> loadConfig() async {
    final token = await _secureStorage.read(key: _tokenKey);
    final zone = await _secureStorage.read(key: _zoneKey);
    final domain = await _secureStorage.read(key: _domainKey);
    if (token == null || zone == null || domain == null) return null;
    return CloudflareConfig(apiToken: token, zoneId: zone, baseDomain: domain);
  }

  Future<String> upsertCnameRecord({
    required CloudflareConfig config,
    required String subdomain,
    required String targetHostname,
    bool proxied = true,
  }) async {
    final fullName = '$subdomain.${config.baseDomain}';
    final baseUri =
        'https://api.cloudflare.com/client/v4/zones/${config.zoneId}/dns_records';
    final headers = {
      'Authorization': 'Bearer ${config.apiToken}',
      'Content-Type': 'application/json',
    };

    final lookupRes = await _client.get(
      Uri.parse('$baseUri?type=CNAME&name=$fullName'),
      headers: headers,
    );
    if (lookupRes.statusCode >= 300) {
      throw Exception('cloudflare lookup failed: ${lookupRes.body}');
    }
    final lookup = jsonDecode(lookupRes.body) as Map<String, dynamic>;
    final results = (lookup['result'] as List<dynamic>? ?? []);

    final payload = jsonEncode({
      'type': 'CNAME',
      'name': fullName,
      'content': targetHostname,
      'ttl': 1,
      'proxied': proxied,
    });

    if (results.isNotEmpty) {
      final recordId = results.first['id'] as String;
      final updateRes = await _client.put(
        Uri.parse('$baseUri/$recordId'),
        headers: headers,
        body: payload,
      );
      if (updateRes.statusCode >= 300) {
        throw Exception('cloudflare update failed: ${updateRes.body}');
      }
    } else {
      final createRes = await _client.post(
        Uri.parse(baseUri),
        headers: headers,
        body: payload,
      );
      if (createRes.statusCode >= 300) {
        throw Exception('cloudflare create failed: ${createRes.body}');
      }
    }
    return 'https://$fullName';
  }
}
