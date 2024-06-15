enum DrivingStatus { DRIVING, NONE }

enum ErrorStatus { ERROR, NORMAL, SOLVE }

class DrivingSession {
  final int? drivingSessionId;
  final int carId;
  final int userId;
  final DateTime? startDate;
  final String? startTime;
  final DateTime? endDate;
  final String? endTime;
  final double? errorLatitude;
  final double? errorLongitude;
  final DateTime? errorTime;
  final DrivingStatus drivingStatus;
  final ErrorStatus? errorStatus;

  DrivingSession({
    this.drivingSessionId,
    required this.carId,
    required this.userId,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.errorLatitude,
    this.errorLongitude,
    this.errorTime,
    required this.drivingStatus,
    this.errorStatus,
  });

  factory DrivingSession.fromJson(Map<String, dynamic> json) {
    return DrivingSession(
      drivingSessionId: json['driving_session_id'] as int?,
      carId: json['car_id'] as int,
      userId: json['user_id'] as int,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      errorLatitude: json['error_latitude'] != null
          ? double.parse(json['error_latitude'])
          : null,
      errorLongitude: json['error_longitude'] != null
          ? double.parse(json['error_longitude'])
          : null,
      errorTime: json['error_time'] != null
          ? DateTime.parse(json['error_time'])
          : null,
      drivingStatus: DrivingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['driving_status'],
        orElse: () => DrivingStatus.NONE, //기본값
      ),
      errorStatus: ErrorStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['errorStatus'],
        orElse: () => ErrorStatus.NORMAL, //기본값
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'driving_session_id': drivingSessionId,
      'car_id': carId,
      'user_id': userId,
      'driving_status': drivingStatus.toString().split('.').last,
      'errorStatus': errorStatus.toString().split('.').last,
    };

    if (startDate != null) data['start_date'] = startDate!;
    if (startTime != null) data['start_time'] = startTime!.toString();
    if (endDate != null) data['end_date'] = endDate!;
    if (endTime != null) data['end_time'] = endTime!.toString();
    if (errorLatitude != null) {
      data['error_latitude'] = errorLatitude.toString();
    }
    if (errorLongitude != null) {
      data['error_longitude'] = errorLongitude.toString();
    }
    if (errorTime != null) data['error_time'] = errorTime!.toIso8601String();

    return data;
  }

  // API 요청 유형에 따른 특화된 toJson 메서드
  Map<String, dynamic> toJsonForCreation() {
    return {
      'carId': carId,
      'userId': userId,
      'drivingStatus': drivingStatus.toString().split('.').last,
    };
  }
}
