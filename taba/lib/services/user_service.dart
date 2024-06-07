import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taba/models/user_model.dart';

class UserService {
  final String baseUrl;

  UserService({required this.baseUrl});

  // 액세스 토큰으로 사용자 정보 가져오기
  Future<User> fetchUserByAccessToken(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/token/$accessToken'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (responseData['success'] == true) {
      final Map<String, dynamic> data = responseData['data'];
      return User.fromJson(data);
    } else {
      throw Exception('Failed to fetch user by access token');
    }
  }

  // 모든 사용자 정보 가져오기
  Future<List<User>> fetchAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (responseData['success'] == true) {
      final List<dynamic> data = responseData['data'];
      return data.map((userJson) => User.fromJson(userJson)).toList();
    } else {
      throw Exception('Failed to fetch all users');
    }
  }

  // 사용자 ID로 사용자 정보 가져오기
  Future<User> fetchUserById(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (responseData['success'] == true) {
      final Map<String, dynamic> data = responseData['data'];
      return User.fromJson(data);
    } else {
      throw Exception('Failed to fetch user by ID');
    }
  }

  // 사용자 이름으로 사용자 정보 가져오기
  Future<User> fetchUserByName(String name) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/name/$name'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (responseData['success'] == true) {
      final Map<String, dynamic> data = responseData['data'];
      return User.fromJson(data);
    } else {
      throw Exception('Failed to fetch user by name');
    }
  }
}
