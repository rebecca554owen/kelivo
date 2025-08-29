import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../search_service.dart';

class ExaSearchService extends SearchService<ExaOptions> {
  @override
  String get name => 'Exa';
  
  @override
  Widget description(BuildContext context) {
    return const Text(
      'Neural search engine with semantic understanding. '
      'Great for research and finding specific content.',
      style: TextStyle(fontSize: 12),
    );
  }
  
  @override
  Future<SearchResult> search({
    required String query,
    required SearchCommonOptions commonOptions,
    required ExaOptions serviceOptions,
  }) async {
    try {
      final body = jsonEncode({
        'query': query,
        'numResults': commonOptions.resultSize,
        'contents': {
          'text': true,
        },
      });
      
      final response = await http.post(
        Uri.parse('https://api.exa.ai/search'),
        headers: {
          'Authorization': 'Bearer ${serviceOptions.apiKey}',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(Duration(milliseconds: commonOptions.timeout));
      
      if (response.statusCode != 200) {
        throw Exception('API request failed: ${response.statusCode}');
      }
      
      final data = jsonDecode(response.body);
      final results = (data['results'] as List).map((item) {
        return SearchResultItem(
          title: item['title'] ?? '',
          url: item['url'] ?? '',
          text: item['text'] ?? '',
        );
      }).toList();
      
      return SearchResult(items: results);
    } catch (e) {
      throw Exception('Exa search failed: $e');
    }
  }
}