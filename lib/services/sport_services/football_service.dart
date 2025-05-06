import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:the_shot2/models/sport_models/fixture.dart';
import 'package:the_shot2/models/sport_models/standing.dart';

class FootballService {
  static const String _apiKey = 'b12261a0957e48d88c23a441713b1c92';
  static const String _baseUrl = 'http://api.football-data.org/v4';
  static final _cacheManager = DefaultCacheManager();

  Future<List<Standing>> fetchLeagueStandings(String leagueId) async {
    final cacheKey = 'standings_$leagueId';
    final cachedFile = await _cacheManager.getFileFromCache(cacheKey);

    if (cachedFile != null) {
      try {
        final cachedData = await cachedFile.file.readAsString();
        final data = jsonDecode(cachedData);
        return (data['standings'][0]['table'] as List<dynamic>)
            .map((item) => Standing.fromJson(item))
            .toList();
      } catch (e) {
        // Ignore cache errors
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/competitions/$leagueId/standings'),
        headers: {'X-Auth-Token': _apiKey},
      );
      print('Football API Standings: ${response.statusCode}');

      if (response.statusCode == 200) {
        await _cacheManager.putFile(
          cacheKey,
          utf8.encode(response.body),
          maxAge: const Duration(hours: 24),
        );
        final data = jsonDecode(response.body);
        return (data['standings'][0]['table'] as List<dynamic>)
            .map((item) => Standing.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to fetch standings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching standings: $e');
    }
  }

  Future<List<Fixture>> fetchUpcomingFixtures(String leagueId) async {
    final cacheKey = 'fixtures_$leagueId';
    final cachedFile = await _cacheManager.getFileFromCache(cacheKey);

    if (cachedFile != null) {
      try {
        final cachedData = await cachedFile.file.readAsString();
        final data = jsonDecode(cachedData);
        return (data['matches'] as List<dynamic>)
            .map((item) => Fixture.fromJson(item))
            .toList();
      } catch (e) {
        // Ignore cache errors
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/competitions/$leagueId/matches?status=SCHEDULED'),
        headers: {'X-Auth-Token': _apiKey},
      );
      print('Football API Fixtures: ${response.statusCode}');

      if (response.statusCode == 200) {
        await _cacheManager.putFile(
          cacheKey,
          utf8.encode(response.body),
          maxAge: const Duration(hours: 24),
        );
        final data = jsonDecode(response.body);
        return (data['matches'] as List<dynamic>)
            .map((item) => Fixture.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to fetch fixtures: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching fixtures: $e');
    }
  }
}