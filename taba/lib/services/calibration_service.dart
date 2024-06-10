import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taba/config.dart';
import 'package:taba/models/calibration_model.dart';

class CalibrationService {
  String baseUrl = Config.baseUrl;

  // POST 요청: 새로운 Calibration 데이터 서버에 전송
  Future<Calibration> createCalibration(Calibration calibration) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/calibrations'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(calibration.toJson()),
    );
    final responseData =
        json.decode(utf8.decode(response.bodyBytes)); // UTF-8 디코딩 사용
    if (responseData['success'] == true) {
      return Calibration.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to fetch calibration: ${responseData['error']}');
    }
  }

  // GET 요청: ID로 Calibration 데이터 조회
  Future<Calibration> getCalibrationById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/calibrations/$id'),
    );

    final responseData =
        json.decode(utf8.decode(response.bodyBytes)); // UTF-8 디코딩 사용
    if (responseData['success'] == true) {
      return Calibration.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to fetch calibration: ${responseData['error']}');
    }
  }

  // PATCH 요청: Calibration 데이터 업데이트
  Future<void> updateCalibration(int id, Calibration calibration) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/calibrations/$id'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(calibration.toJson()),
    );

    final responseData = json.decode(response.body);
    if (responseData['success'] != true) {
      throw Exception('Failed to update calibration: ${responseData['error']}');
    }
  }

  // DELETE 요청: Calibration 데이터 삭제
  Future<void> deleteCalibration(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/calibrations/$id'),
    );

    final responseData = json.decode(response.body);
    if (responseData['success'] != true) {
      throw Exception('Failed to delete calibration: ${responseData['error']}');
    }
  }

  // GET 요청: 특정 차량의 모든 Calibration 데이터 조회
  Future<List<Calibration>> getAllCalibrationsByCarId(int carId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/calibrations/car-id/$carId'),
    );

    final responseData = json.decode(response.body);
    if (responseData['success'] == true) {
      final List<dynamic> calibrationListJson = responseData['data'];
      return calibrationListJson
          .map((json) => Calibration.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to fetch calibrations: ${responseData['error']}');
    }
  }

  // GET 요청: 특정 차량이름의 모든 Calibration 데이터 조회
  Future<List<Calibration>> getAllCalibrationsByCarName(String carName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/calibrations/car-name/$carName'),
    );

    final responseData = json.decode(response.body);
    if (responseData['success'] == true) {
      final List<dynamic> calibrationListJson = responseData['data'];
      return calibrationListJson
          .map((json) => Calibration.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to fetch calibrations: ${responseData['error']}');
    }
  }

  // GET 요청: 특정 차량이름의 모든 Calibration 데이터 응답 반환
  Future<Map<String, dynamic>> getCalibrationsResponseByCarName(
      String carName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/calibrations/car-name/$carName'),
    );

    final responseData = json.decode(response.body);

    return responseData;
  }
}
