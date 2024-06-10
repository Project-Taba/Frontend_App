import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class TabaBluetoothService {
  final String baseUrl;
  Function(String, String)? onValueChanged;

  List<BluetoothDevice> devices = [];
  Map<String, String> deviceValues = {};
  bool isMeasuring = false;
  bool isCalibrating = false;

  TabaBluetoothService({required this.baseUrl, this.onValueChanged});

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? postTimer;

  void startScan() {
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.name == 'ESP32 Force Sensor A' ||
            result.device.name == 'ESP32 Force Sensor B') {
          if (!devices.contains(result.device)) {
            devices.add(result.device);
            connectToDevice(result.device);
          }
        }
      }
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  void stopScan() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      discoverServices(device);
    } catch (e) {
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
          await characteristic.setNotifyValue(true);
          characteristic.value.listen((value) {
            String stringValue = String.fromCharCodes(value);
            deviceValues[device.name] = stringValue;
            if (onValueChanged != null) {
              onValueChanged!(device.name, stringValue);
            }
          });
        }
      }
    }
  }

  Future<void> sendCalibrationToServer(
      String sensorType, int carId, int value) async {
    final url = Uri.parse('$baseUrl/api/calibrations');

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          <String, dynamic>{
            'sensorType': sensorType,
            'pressureMax': value,
            'pressureMin': 0, // Min value is 항상 0
            'carId': carId,
          },
        ),
      );

      if (response.statusCode == 201) {
        print('Data sent successfully for $sensorType');
      } else {
        print('Failed to send data with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending data to the server: $e');
    }
  }

  // 운행 중일 때
  Future<String> sendSensorDataToServer(
      int drivingSessionId, double speed) async {
    String accelValue = deviceValues['ESP32 Force Sensor A'] ?? '0';
    String brakeValue = deviceValues['ESP32 Force Sensor B'] ?? '0';
    int brakeVal = int.tryParse(brakeValue) ?? 0;
    int accelVal = int.tryParse(accelValue) ?? 0;

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);

    final url = Uri.parse('$baseUrl/api/sensordata');

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        <String, dynamic>{
          'driving_session_id': drivingSessionId,
          'brakePressure': brakeVal,
          'accelPressure': accelVal,
          'speed': speed,
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        },
      ),
    );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (responseData['success']) {
      print('Driving session created successfully' +
          responseData['data']['error_status']);
      return responseData['data']['error_status']; // 성공 시 세션 ID 반환
    } else {
      throw Exception(
          'Failed to create driving session: ${responseData['error']['message']}');
    }
  }

  void startMeasurement(
      int drivingSessionId, double Function() getCurrentSpeed) {
    setIsMeasuring(true);
    postTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      sendSensorDataToServer(drivingSessionId, getCurrentSpeed());
    });
  }

  void stopMeasurement() {
    setIsMeasuring(false);
    postTimer?.cancel();
  }

  void setIsMeasuring(bool value) {
    isMeasuring = value;
  }

  void setIsCalibrating(bool value) {
    isCalibrating = value;
  }
}
