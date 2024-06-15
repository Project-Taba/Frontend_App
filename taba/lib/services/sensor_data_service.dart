import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taba/config.dart';
import 'package:taba/models/sensor_data_model.dart';
import 'package:url_launcher/url_launcher.dart';

class SensorDataService {
  final String baseUrl = Config.baseUrl;

  SensorDataService();
  //전화 걸기 기능을 위한 함수 추가
  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  // 센서 데이터 생성
  Future<String> createSensorData(SensorData sensorData) async {
    final url = Uri.parse('$baseUrl/api/sensordata');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(sensorData.toJsonForCreation()),
    );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (responseData['success']) {
      print('sensor data created successfully ' +
          responseData['data']['error_status']);
      // ERROR 상태 검사
      if (responseData['data']['error_status'] == 'ERROR') {
        makePhoneCall('010-6741-0000');
        return 'ERROR'; // ERROR 상태 반환
      }
      return responseData['data']['error_status']; // 성공 시 상태 반환
    } else {
      throw Exception(
          'Failed to create sensor data: ${responseData['error']['message']}');
    }
  }

  // 세션별 센서 데이터 가져오기
  Future<List<SensorData>> getAllSensorDataByDrivingSessionId(
      int drivingSessionId) async {
    final url = Uri.parse('$baseUrl/api/sensordata/$drivingSessionId');
    final response = await http.get(url);

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (responseData['success']) {
      return (responseData['data'] as List)
          .map((e) => SensorData.fromJson(e))
          .toList();
    } else {
      throw Exception(
          'Failed to retrieve sensor data: ${responseData['error']['message']}');
    }
  }

  // 센서 데이터 삭제
  Future<void> deleteSensorDataById(int id) async {
    final url = Uri.parse('$baseUrl/api/sensordata/$id');
    final response = await http.delete(url);

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (!responseData['success']) {
      throw Exception(
          'Failed to delete sensor data: ${responseData['error']['message']}');
    }
  }

  // 특정 세션의 모든 센서 데이터 삭제
  Future<void> deleteSensorDataBySessionId(int sessionId) async {
    final url = Uri.parse('$baseUrl/api/sensordata/sessionid/$sessionId');
    final response = await http.delete(url);

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (!responseData['success']) {
      throw Exception(
          'Failed to delete sensor data for session: ${responseData['error']['message']}');
    }
  }
}
