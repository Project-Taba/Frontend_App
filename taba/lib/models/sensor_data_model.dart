import 'dart:convert';

import 'package:taba/models/driving_session_model.dart';

enum DrivingHabit {
  //정상,양발운전,급출발,급정거
  NORMAL,
  TWOFOOT,
  SUDDENDEPARTURE,
  SUDDENSTOP
}

class SensorData {
  final int? sensorId;
  final int drivingSessionId;
  final DateTime? timestamp;
  final double brakePressure;
  final double accelPressure;
  final double speed;
  final String latitude;
  final String longitude;
  final ErrorStatus? errorStatus;
  final DrivingHabit? drivingHabit;

  SensorData(
      {this.sensorId,
      required this.drivingSessionId,
      this.timestamp,
      required this.brakePressure,
      required this.accelPressure,
      required this.speed,
      required this.latitude,
      required this.longitude,
      this.errorStatus,
      this.drivingHabit});

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      sensorId: json['sensor_id'],
      drivingSessionId: json['driving_session_id'],
      timestamp: DateTime.parse(json['timeStamp']),
      brakePressure: json['brakePressure'],
      accelPressure: json['accelPressure'],
      speed: json['speed'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      errorStatus: ErrorStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['error_status'],
        orElse: () => ErrorStatus.NORMAL,
      ),
      drivingHabit: DrivingHabit.values.firstWhere(
        (e) => e.toString().split('.').last == json['driving_habit'],
        orElse: () => DrivingHabit.NORMAL,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driving_session_id': drivingSessionId,
      'timeStamp': timestamp!.toIso8601String(),
      'brakePressure': brakePressure,
      'accelPressure': accelPressure,
      'speed': speed,
      'latitude': latitude,
      'longitude': longitude,
      'error_status': errorStatus.toString().split('.').last,
      'driving_habit': drivingHabit.toString().split('.').last,
    };
  }

  Map<String, dynamic> toJsonForCreation() {
    return {
      'driving_session_id': drivingSessionId,
      'brakePressure': brakePressure,
      'accelPressure': accelPressure,
      'speed': speed,
      'latitude': latitude,
      'longitude': longitude,
      'driving_habit': drivingHabit.toString().split('.').last,
    };
  }
}
