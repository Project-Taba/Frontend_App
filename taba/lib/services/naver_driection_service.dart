import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taba/config.dart';
import 'package:taba/models/naver_direction_model.dart';

class NaverDirectionService {
  final String baseUrl =
      'https://naveropenapi.apigw.ntruss.com/map-direction/v1/driving';
  final String apiKeyId = Config.naverDirectionApiKeyId;
  final String apiKey = Config.naverDirectionApiKey;

  Future<DirectionResponse> getDirections({
    required String start,
    required String goal,
    String? option,
    String? waypoints,
    int? cartype,
    String? fueltype,
    double? mileage,
    String? lang,
  }) async {
    final queryParameters = {
      'start': start,
      'goal': goal,
      'option': option ?? 'traoptimal',
      if (waypoints != null) 'waypoints': waypoints,
      if (cartype != null) 'cartype': cartype.toString(),
      if (fueltype != null) 'fueltype': fueltype,
      if (mileage != null) 'mileage': mileage.toString(),
      if (lang != null) 'lang': lang,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);
    final response = await http.get(uri, headers: {
      'X-NCP-APIGW-API-KEY-ID': apiKeyId,
      'X-NCP-APIGW-API-KEY': apiKey,
    });

    if (response.statusCode == 200) {
      // UTF-8로 강제 디코딩
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
      print('API Response: $responseBody'); // 응답 내용을 출력하여 디버깅
      if (responseBody['code'] == 0 && responseBody['route'] != null) {
        return DirectionResponse.fromJson(responseBody);
      } else {
        throw Exception('Failed to get directions: ${responseBody['message']}');
      }
    } else {
      throw Exception('Failed to load directions: ${response.reasonPhrase}');
    }
  }
}
