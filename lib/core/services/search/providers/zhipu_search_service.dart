import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../search_service.dart';

class ZhipuSearchService extends SearchService<ZhipuOptions> {
  @override
  String get name => 'Zhipu (智谱)';
  
  @override
  Widget description(BuildContext context) {
    return const Text(
      '智谱AI旗下中文AI搜索服务。'
      '针对中文内容和查询进行了优化。',
      style: TextStyle(fontSize: 12),
    );
  }
  
  @override
  Future<SearchResult> search({
    required String query,
    required SearchCommonOptions commonOptions,
    required ZhipuOptions serviceOptions,
  }) async {
    try {
      final body = jsonEncode({
        'search_query': query,
        'search_engine': 'search_std',
        'count': commonOptions.resultSize,
      });
      
      final response = await http.post(
        Uri.parse('https://open.bigmodel.cn/api/paas/v4/web_search'),
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
      final searchResult = data['search_result'] ?? [];
      final results = (searchResult as List).map((item) {
        return SearchResultItem(
          title: item['title'] ?? '',
          url: item['link'] ?? '',
          text: item['content'] ?? '',
        );
      }).toList();
      
      return SearchResult(items: results);
    } catch (e) {
      throw Exception('Zhipu search failed: $e');
    }
  }
}