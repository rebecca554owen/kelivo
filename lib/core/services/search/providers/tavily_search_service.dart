import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../search_service.dart';

class TavilySearchService extends SearchService<TavilyOptions> {
  @override
  String get name => 'Tavily';
  
  @override
  Widget description(BuildContext context) {
    return const Text(
      '为大型语言模型（LLMs）优化的AI搜索API。'
      '提供高质量、相关的搜索结果。',
      style: TextStyle(fontSize: 12),
    );
  }
  
  @override
  Future<SearchResult> search({
    required String query,
    required SearchCommonOptions commonOptions,
    required TavilyOptions serviceOptions,
  }) async {
    try {
      final body = jsonEncode({
        'query': query,
        'max_results': commonOptions.resultSize,
      });
      
      final response = await http.post(
        Uri.parse('https://api.tavily.com/search'),
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
          text: item['content'] ?? '',
        );
      }).toList();
      
      return SearchResult(
        answer: data['answer'],
        items: results,
      );
    } catch (e) {
      throw Exception('Tavily search failed: $e');
    }
  }
}