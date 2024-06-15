import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:http/http.dart' as http;
import 'package:taba/config.dart';

class KakaoLoginService {
  /// 카카오톡으로 로그인하고 인증 코드를 반환합니다.
  Future<String> getAuthCodeWithKakaoTalk() async {
    try {
      var redirectUri = KakaoSdk.redirectUri; // 카카오 개발자 사이트에 등록한 리다이렉트 URI
      var authCode = await AuthCodeClient.instance.authorizeWithTalk(
        clientId: KakaoSdk.appKey, // 일반적으로 KakaoSdk.appKey 사용
        redirectUri: redirectUri,
        codeVerifier: AuthCodeClient.codeVerifier(),
      );
      return authCode;
    } catch (e) {
      print('Error getting auth code via KakaoTalk: $e');
      rethrow;
    }
  }

  /// 카카오 계정 웹으로 로그인하고 인증 코드를 반환
  Future<String> getAuthCodeWithKakaoAccount() async {
    try {
      var redirectUri = KakaoSdk.redirectUri; // 카카오 개발자 사이트에 등록한 리다이렉트 URI
      var authCode = await AuthCodeClient.instance.authorize(
        clientId: KakaoSdk.appKey, // 일반적으로 KakaoSdk.appKey 사용
        redirectUri: redirectUri,
        codeVerifier: AuthCodeClient.codeVerifier(),
      );
      return authCode;
    } catch (e) {
      print('Error getting auth code via Kakao Account: $e');
      rethrow;
    }
  }

  // 서버에 인가 코드 전송하고 액세스 토큰 받아오기
  Future<String?> sendKakaoAuthCodeToServer(String authCode) async {
    try {
      var response = await http
          .post(
            Uri.parse('${Config.baseUrl}/api/oauth/kakao'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'authorizationCode': authCode}),
          )
          .timeout(const Duration(seconds: 5)); // 5초 타임아웃 설정

      if (response.statusCode == 200) {
        print('Server successfully received the auth code.');
        return jsonDecode(response.body)['accessToken'];
      } else {
        print('Failed to send auth code to server');
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error sending auth code to server: $e');
      return null;
    }
  }
}
