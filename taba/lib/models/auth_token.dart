// lib/models/auth_token.dart

import 'dart:convert';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String grantType;
  final int expiresIn;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.grantType,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      grantType: json['grantType'],
      expiresIn: json['expiresIn'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'grantType': grantType,
      'expiresIn': expiresIn,
    };
  }
}
