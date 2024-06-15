import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taba/config.dart';

class KakaoLocalService {
  final String apiKey = Config.kakaoLocalServiceKey;
  //키워드로 행정구역 검색하기
  Future<List<Map<String, dynamic>>> searchKeyword(
      double latitude, double longitude, String query) async {
    const String url = 'https://dapi.kakao.com/v2/local/search/keyword.json';
    final Map<String, String> headers = {
      'Authorization': 'KakaoAK $apiKey',
    };
    final Map<String, String> params = {
      'query': query,
      'y': latitude.toString(),
      'x': longitude.toString(),
      'radius': '20000',
    };

    final uri = Uri.parse(url).replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['documents']);
    } else {
      throw Exception('Failed to load data');
    }
  }

  //좌표로 행정구역 정보 받기
  Future<Map<String, dynamic>> getRegionByCoordinates(
      double latitude, double longitude) async {
    const String url =
        'https://dapi.kakao.com/v2/local/geo/coord2regioncode.json';
    final Map<String, String> headers = {
      'Authorization': 'KakaoAK $apiKey',
    };
    final Map<String, String> params = {
      'x': longitude.toString(),
      'y': latitude.toString(),
    };

    final uri = Uri.parse(url).replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['documents'][0]; // 첫 번째 결과를 반환
    } else {
      throw Exception('Failed to load data');
    }
  }
}
