import 'package:geolocator/geolocator.dart';

class KalmanFilterSpeedService {
  List<double> speedReadings = [];
  double? estimatedSpeed;
  double processNoise = 0.05;
  double measurementNoise = 5.0;
  double errorEstimate = 2.0;
  double errorMeasurement = 3.0;
  final void Function(double) onSpeedUpdate;

  KalmanFilterSpeedService(this.onSpeedUpdate);

  void updateSpeed(Position position) {
    double currentSpeedKmH = position.speed * 3.6;
    speedReadings.add(currentSpeedKmH);
    if (speedReadings.length > 5) {
      speedReadings.removeAt(0);
    }
    double averageSpeed =
        speedReadings.reduce((a, b) => a + b) / speedReadings.length;

    if (estimatedSpeed == null) {
      estimatedSpeed = averageSpeed;
    } else {
      double kalmanGain = errorEstimate / (errorEstimate + errorMeasurement);
      estimatedSpeed =
          estimatedSpeed! + kalmanGain * (averageSpeed - estimatedSpeed!);
      errorEstimate = (1.0 - kalmanGain) * errorEstimate +
          (estimatedSpeed! - averageSpeed).abs() * processNoise;
    }

    onSpeedUpdate(estimatedSpeed!.round().toDouble());
  }
}
