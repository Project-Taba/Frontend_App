import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Bluetooth 기능을 사용하기 위한 패키지
import 'package:http/http.dart' as http; // HTTP 요청을 처리하기 위한 패키지
import 'dart:convert'; // JSON 데이터 처리를 위한 패키지
import 'dart:async'; // 비동기 작업을 관리하기 위한 패키지
import 'package:geolocator/geolocator.dart'; // 위치 정보 서비스를 제공하는 패키지
import 'dart:math' as math; // 수학 함수를 사용하기 위한 패키지

class DrivingScreen extends StatefulWidget {
  const DrivingScreen({Key? key}) : super(key: key);

  @override
  _DrivingScreenState createState() => _DrivingScreenState();
}

class _DrivingScreenState extends State<DrivingScreen> {
  List<BluetoothDevice> devices = [];
  Map<String, String> deviceValues = {};
  double currentSpeed = 0.0;
  Timer? speedTimer; // Timer for updating speed
  Timer? postTimer; // Timer for sending POST requests
  Timer? calibrationTimer; // Timer for calibration POST requests
  bool isMeasuring = false;
  bool isCalibrating = false;
  bool isScanning = false;

  List<double> speedReadings = [];
  double? estimatedSpeed;
  double processNoise = 0.05;
  double measurementNoise = 5.0;
  double errorEstimate = 2.0;
  double errorMeasurement = 3.0;

  @override
  void initState() {
    super.initState();
    startScan();
  }

  @override
  void dispose() {
    speedTimer?.cancel();
    postTimer?.cancel();

    calibrationTimer?.cancel();
    super.dispose();
  }

  void startScan() async {
    setState(() {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (result.device.advName == 'ESP32 Force Sensor A' ||
              result.device.advName == 'ESP32 Force Sensor B') {
            if (!devices.contains(result.device)) {
              setState(() {
                devices.add(result.device);
              });
              connectToDevice(result.device);
            }
          }
        }
      });
      isScanning = true;
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    setState(() {
      isScanning = false;
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      discoverServices(device);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to device: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(seconds: 5), () {
        connectToDevice(device); // Retry connection after a delay
      });
    }
  }

  void discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          characteristic.setNotifyValue(true);
          characteristic.lastValueStream.listen((value) {
            if (isMeasuring || isCalibrating) {
              setState(() {
                deviceValues[device.advName] = String.fromCharCodes(value);
              });
            }
          });
        }
      }
    }
  }

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

    setState(() {
      currentSpeed = estimatedSpeed!.round().toDouble();
    });
  }

  void sendDataToServer(String sensorType) async {
    String accelValue = deviceValues['ESP32 Force Sensor A'] ?? '0';
    String brakeValue = deviceValues['ESP32 Force Sensor B'] ?? '0';
    double brakeVal = double.tryParse(brakeValue) ?? 0.0;
    double accelVal = double.tryParse(accelValue) ?? 0.0;

    final url = Uri.parse('http://192.168.68.154:8000/api/$sensorType');

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          <String, dynamic>{
            'sensor_id': 1,
            'brake_value': brakeVal,
            'accel_value': accelVal,
            'speed': currentSpeed,
          },
        ),
      );

      if (response.statusCode == 200) {
        print('Data sent successfully for $sensorType');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data sent to server successfully'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        print('Failed to send data with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw HttpException(
            'Failed to send data with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending data to the server: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending data to the server: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void toggleMeasurement() {
    setState(() {
      if (isMeasuring) {
        speedTimer?.cancel();
        postTimer?.cancel();
        isMeasuring = false;
      } else {
        speedTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
          Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.bestForNavigation)
              .then((Position position) {
            updateSpeed(position);
          });
        });
        postTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          sendDataToServer("testdata/");
        });
        isMeasuring = true;
      }
    });
  }

  void toggleCalibration() {
    setState(() {
      if (isCalibrating) {
        calibrationTimer?.cancel(); // Cancel existing timer if any
        isCalibrating = false;
      } else {
        calibrationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          sendDataToServer("calibration/");
        });
        isCalibrating = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TABA app v1'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMeasuring || isCalibrating)
              ...deviceValues.entries
                  .map((e) => Text('${e.key}\nValue: ${e.value}'))
                  .toList(),
            Text('Current Speed: ${currentSpeed.round()} km/h'),
            const SizedBox(height: 100),
            ElevatedButton(
              onPressed: toggleMeasurement,
              child: Text(isMeasuring ? '운행 종료' : '운행 시작'),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: toggleCalibration,
              child: Text(isCalibrating ? '캘리브레이션 종료' : '캘리브레이션 시작'),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: isScanning ? stopScan : startScan,
              child: Text(isScanning ? '블루투스 탐색 종료' : '블루투스 탐색 시작'),
            ),
          ],
        ),
      ),
    );
  }
}
