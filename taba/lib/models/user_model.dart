import 'package:flutter/material.dart';

enum OAuthProvider { NAVER, KAKAO }

class User {
  final int id;
  final OAuthProvider oauthProvider;
  final String name;
  final String email;
  final String? password;
  final String gender;
  final String birthyear;
  final String birthday;
  final String mobile;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.oauthProvider,
    required this.name,
    required this.email,
    this.password,
    required this.gender,
    required this.birthyear,
    required this.birthday,
    required this.mobile,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      oauthProvider: OAuthProvider.values.firstWhere(
          (e) => e.toString() == 'OAuthProvider.${json['oauthProvider']}'),
      name: json['name'],
      email: json['email'],
      password: json['password'],
      gender: json['gender'],
      birthyear: json['birthyear'],
      birthday: json['birthday'],
      mobile: json['mobile'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oauthProvider': oauthProvider.toString().split('.').last,
      'name': name,
      'email': email,
      'password': password,
      'gender': gender,
      'birthyear': birthyear,
      'birthday': birthday,
      'mobile': mobile,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
