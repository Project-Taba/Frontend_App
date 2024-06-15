enum SensorType { ACCEL, BRAKE }

class Calibration {
  final int? calibrationId;
  final SensorType sensorType;
  final double pressureMax;
  final double pressureMin;
  final DateTime? calibrationTime;
  final int carId;

  Calibration({
    this.calibrationId,
    required this.sensorType,
    required this.pressureMax,
    required this.pressureMin,
    this.calibrationTime,
    required this.carId,
  });

  factory Calibration.fromJson(Map<String, dynamic> json) {
    return Calibration(
      calibrationId: json['calibration_id'],
      sensorType: SensorType.values.firstWhere(
          (e) => e.toString() == 'SensorType.${json['sensorType']}'),
      pressureMax: json['pressureMax'],
      pressureMin: json['pressureMin'],
      calibrationTime: DateTime.parse(json['created_at']),
      carId: json['carId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sensorType': sensorType.toString().split('.').last,
      'pressureMax': pressureMax,
      'pressureMin': pressureMin,
      'carId': carId,
    };
  }
}
