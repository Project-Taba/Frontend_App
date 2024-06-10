import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taba/config.dart';
import 'package:taba/models/driving_session_model.dart';

class DrivingSessionService {
  final String baseUrl = Config.baseUrl;

  DrivingSessionService();

  // 새 운전 세션 생성
  Future<int> createDrivingSession(DrivingSession session) async {
    final url = Uri.parse('$baseUrl/api/drivingsessions');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(session.toJsonForCreation()),
    );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (responseData['success']) {
      print('Driving session created successfully');
      // 서버로부터 받은 세션 ID를 안전하게 int로 변환
      int sessionId =
          int.parse(responseData['data']['driving_session_id'].toString());
      return sessionId; // 성공 시 세션 ID 반환
    } else {
      throw Exception(
          'Failed to create driving session: ${responseData['error']['message']}');
    }
  }

  // 운전 세션 종료
  Future<void> endDrivingSession(int id, DrivingStatus drivingStatus) async {
    final url = Uri.parse('$baseUrl/api/drivingsessions/end/$id');
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'drivingStatus': drivingStatus.name, // Enum 값을 문자열로 변환하여 전송
      }),
    );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (responseData['success']) {
      print('Driving session end successfully' +
          responseData['data']['driving_session_id']);
      return responseData['data']['driving_session_id']; // 성공 시 세션 ID 반환
    } else {
      print('Driving session end failed' +
          responseData['data']['driving_session_id']);
      throw Exception(
          'Failed to  driving session: ${responseData['error']['message']}');
    }
  }

  // 운전 세션 오류 보고
  Future<void> reportDrivingSessionError(
      int id, Map<String, dynamic> errorData) async {
    final url = Uri.parse('$baseUrl/api/drivingsessions/error/$id');
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(errorData),
    );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (!responseData['success']) {
      throw Exception(
          'Failed to report error: ${responseData['error']['message']}');
    }
  }

  // 운전 세션 삭제
  Future<void> deleteDrivingSession(int id) async {
    final url = Uri.parse('$baseUrl/api/drivingsessions/$id');
    final response = await http.delete(url);

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (!responseData['success']) {
      throw Exception(
          'Failed to delete driving session: ${responseData['error']['message']}');
    }
  }

  // 운전이력 id로 가져오기
  Future<DrivingSession> getDrivingSessionsById(int drivingSessionId) async {
    final url = Uri.parse('$baseUrl/api/drivingsessions/$drivingSessionId');
    final response = await http.get(url);

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (responseData['success']) {
      return DrivingSession.fromJson(responseData['data']);
    } else {
      throw Exception(
          'Failed to retrieve sessions: ${responseData['error']['message']}');
    }
  }

  // 사용자별 모든 운전 세션 가져오기
  Future<List<DrivingSession>> getAllDrivingSessionsByUser(int userId) async {
    final url = Uri.parse('$baseUrl/api/drivingsessions/findbyuser/$userId');
    final response = await http.get(url);

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (responseData['success']) {
      List<dynamic> dataList = responseData['data'];
      return dataList.map((data) => DrivingSession.fromJson(data)).toList();
    } else {
      throw Exception(
          'Failed to retrieve sessions: ${responseData['error']['message']}');
    }
  }

  //운전 해결 API (이 API 호출시 ERROR->SOLVE로 변환)
  Future<void> solveErrorStatus(int id) async {
    final url = Uri.parse('$baseUrl/api/drivingsessions/solve/$id');
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
    );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (responseData['success']) {
      print('Driving session end successfully' +
          responseData['data']['driving_session_id']);
      return responseData['data']['driving_session_id']; // 성공 시 세션 ID 반환
    } else {
      print('Driving session end failed' +
          responseData['data']['driving_session_id']);
      throw Exception(
          'Failed to  driving session: ${responseData['error']['message']}');
    }
  }
}
