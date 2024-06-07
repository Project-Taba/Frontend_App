import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:taba/config.dart';
import 'package:url_launcher/url_launcher.dart';

class NaverLoginService {
  // 네이버 계정으로 로그인하고 사용자 정보 및 액세스 토큰을 반환
  Future<Map<String, dynamic>?> getNaverAccountInfo() async {
    try {
      NaverLoginResult result = await FlutterNaverLogin.logIn();
      if (result.status == NaverLoginStatus.loggedIn) {
        print('accessToken = ${result.accessToken.accessToken}');
        print('id = ${result.account.id}');
        print('email = ${result.account.email}');
        print('name = ${result.account.name}');
        // 사용자 정보와 액세스 토큰을 반환
        return {
          'email': result.account.email,
          'name': result.account.name,
          'gender': result.account.gender,
          'birthday': result.account.birthday,
          'birthyear': result.account.birthyear,
          'mobile': result.account.mobile
        };
      } else {
        print('Login failed');
        return null;
      }
    } catch (e) {
      print('Error during Naver login: $e');
      return null;
    }
  }

  // 네이버 사용자 정보를 서버로 전송하고 서버에서 JWT 토큰을 받아오는 함수
  Future<String?> sendNaverUserInfoToServer(
      Map<String, dynamic> userInfo) async {
    try {
      var response = await http
          .post(
            Uri.parse('${Config.baseUrl}/api/oauth/naver'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': userInfo['name'],
              'email': userInfo['email'],
              'gender': userInfo['gender'],
              'birthday': userInfo['birthday'],
              'birthyear': userInfo['birthyear'],
              'mobile': userInfo['mobile']
            }),
          )
          .timeout(const Duration(seconds: 5)); // 5초 타임아웃 설정

      if (response.statusCode == 200) {
        print('taba:' + jsonDecode(response.body)['accessToken']);
        print('Server successfully received the user info.');
        return jsonDecode(response.body)['accessToken']; // JWT 액세스 토큰을 반환
      } else {
        print('Failed to send user info to server');
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error sending user info to server: $e');
      return null;
    }
  }
}
