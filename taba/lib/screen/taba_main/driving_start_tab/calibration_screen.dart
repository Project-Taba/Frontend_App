import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:taba/screen/taba_main/driving_start_tab/goal_finding_screen.dart';
import 'package:taba/services/taba_bluetooth_service.dart';
import 'package:taba/services/calibration_service.dart'; // 서비스 임포트 추가
import 'package:taba/models/calibration_model.dart'; // 모델 임포트 추가
import 'package:taba/widgets/bar/sub_app_bar.dart';

class CalibrationScreen extends StatefulWidget {
  final int carId;
  final String baseUrl;
  final int userId;

  const CalibrationScreen({
    super.key,
    required this.carId,
    required this.baseUrl,
    required this.userId,
  });

  @override
  _CalibrationScreenState createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  late CalibrationService calibrationService;
  List<BluetoothDevice> devices = [];
  Map<String, String> deviceValues = {};
  int _accelMaxValue = 0;
  int _brakeMaxValue = 0;
  double _progress = 0;
  String _statusMessage = 'TABA에 오신것을 환영합니다!';
  Timer? _timer;
  bool _isCalibratingAccel = false;
  bool _isCalibratingBrake = false;
  bool _showStatusBox = true;
  int _currentPressureValue = 0;
  bool isScanning = false;
  bool isBluetoothConnected = false; // 블루투스 연결 상태를 나타내는 변수 추가
  int _countdown = 9;
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    calibrationService = CalibrationService();
    startScan();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scanSubscription?.cancel();
    stopScan();
    super.dispose();
  }

  void startScan() async {
    setState(() {
      isScanning = true;
      _statusMessage = "블루투스 디바이스 검색 중...";
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.name == 'ESP32 Force Sensor A' ||
            result.device.name == 'ESP32 Force Sensor B') {
          if (!devices.contains(result.device)) {
            setState(() {
              devices.add(result.device);
              _statusMessage = "${result.device.name}에 연결 시도 중...";
            });
            connectToDevice(result.device);
          }
        }
      }
      isScanning = false; // 스캔 완료 후 상태 업데이트
    });

    await Future.delayed(const Duration(seconds: 10)); // 스캔 시간 제한

    if (devices.isEmpty) {
      setState(() {
        _statusMessage = "디바이스를 찾을 수 없습니다.\n블루투스를 껐다 켜주세요!";
        isScanning = false;
      });
      await Future.delayed(const Duration(seconds: 3)); // 메시지 3초간 표시
      if (mounted) {
        Navigator.of(context).pop(); // 3초 후 이전 화면으로 돌아감
      }
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        isBluetoothConnected = true; // 블루투스가 성공적으로 연결되면 true로 설정
      });
      discoverServices(device);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('디바이스 연결 실패: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          characteristic.value.listen((value) {
            setState(() {
              deviceValues[device.name] = String.fromCharCodes(value);
              int newValue = int.tryParse(deviceValues[device.name]!) ?? 0;
              if (_isCalibratingAccel &&
                  device.name == 'ESP32 Force Sensor A') {
                _currentPressureValue = newValue;
                if (_currentPressureValue > _accelMaxValue) {
                  _accelMaxValue = _currentPressureValue;
                }
              } else if (_isCalibratingBrake &&
                  device.name == 'ESP32 Force Sensor B') {
                _currentPressureValue = newValue;
                if (_currentPressureValue > _brakeMaxValue) {
                  _brakeMaxValue = _currentPressureValue;
                }
              }
            });
          });
        }
      }
    }
    setState(() {
      _statusMessage =
          "TABA AI의 정확한\n\"급발진\" 판단을 위해\n회원님의 엑셀, 브레이크 페달\n최대 압력을 측정하겠습니다.\n\n 안전한 측정을 위해\n \"시동을 꺼주시고\" 측정해주세요!";
      _showStatusBox = true; // 캘리브레이션 시작 메시지 박스를 보여줌
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    setState(() {
      isScanning = false;
    });
  }

  void startCalibration(String type) {
    if (_isCalibratingAccel || _isCalibratingBrake) {
      return;
    }

    setState(() {
      _currentPressureValue = 0; // 캘리브레이션 시작 시 압력 값을 0으로 초기화
      _showStatusBox = false; // 캘리브레이션 시작 시 상태 박스 숨김
      _progress = 0;
      _countdown = 8;
      if (type == 'ACCEL') {
        _isCalibratingAccel = true;
        _statusMessage = '엑셀 캘리브레이션을 시작합니다...';
      } else {
        _isCalibratingBrake = true;
        _statusMessage = '브레이크 캘리브레이션을 시작합니다...';
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
          _progress += 12.5; // 8초 동안 12.5씩 증가해서 100%가 됨
        });
      } else {
        timer.cancel();
        setState(() {
          _progress = 100;
          if (_isCalibratingAccel) {
            _isCalibratingAccel = false;
            _statusMessage = '엑셀 압력 측정이 완료되었습니다!\n\n"최대값은 $_accelMaxValue"입니다.';
          } else if (_isCalibratingBrake) {
            _isCalibratingBrake = false;
            _statusMessage =
                '브레이크 압력 측정이 완료되었습니다!\n\n"최대값은 $_brakeMaxValue"입니다.';
          }
          _showStatusBox = true; // 캘리브레이션 완료 후 상태 메시지 박스를 다시 보여줌
          if (_accelMaxValue != 0 && _brakeMaxValue != 0) {
            _showCompletionDialog();
          }
        });
      }
    });
  }

  Future<void> _createCalibration(String sensorType, int value) async {
    final calibration = Calibration(
      sensorType: sensorType == 'ACCEL' ? SensorType.ACCEL : SensorType.BRAKE,
      pressureMax: value.toDouble(),
      pressureMin: 0.0, // 최소값은 0으로 가정
      carId: widget.carId,
    );

    try {
      await calibrationService.createCalibration(calibration);
      print('$sensorType 값 서버로 전송 성공: $value');
    } catch (e) {
      print('Failed to create calibration for $sensorType. Error: $e');
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54, // 배경색을 회색으로 설정
      builder: (BuildContext dialogContext) {
        return Center(
          // 화면 가운데에 위치
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: MediaQuery.of(dialogContext).size.width * 0.8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          "캘리브레이션이 완료되었습니다.\n다시 측정하시겠습니까?",
                          style: GoogleFonts.notoSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "엑셀 압력 최댓값: $_accelMaxValue\n브레이크 압력 최대값: $_brakeMaxValue",
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _dialogButton(dialogContext, '다시 측정하기', () {
                        Navigator.of(dialogContext).pop();
                        startCalibrationSequence();
                      }, 'bottomLeft'),
                      _dialogButton(dialogContext, '운전 시작하기', () async {
                        await _createCalibration('ACCEL', _accelMaxValue);
                        await _createCalibration('BRAKE', _brakeMaxValue);
                        Navigator.of(dialogContext).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => GoalFindingScreen(
                                    carId: widget.carId,
                                    userId: widget.userId,
                                  )),
                        );
                      }, 'bottomRight'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dialogButton(BuildContext context, String text,
      VoidCallback onPressed, String corner) {
    BorderRadius borderRadius;

    switch (corner) {
      case 'topLeft':
        borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(8.0),
        );
        break;
      case 'topRight':
        borderRadius = const BorderRadius.only(
          topRight: Radius.circular(8.0),
        );
        break;
      case 'bottomLeft':
        borderRadius = const BorderRadius.only(
          bottomLeft: Radius.circular(8.0),
        );
        break;
      case 'bottomRight':
        borderRadius = const BorderRadius.only(
          bottomRight: Radius.circular(8.0),
        );
        break;
      case 'topLeftBottomRight':
        borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          bottomRight: Radius.circular(8.0),
        );
        break;
      case 'topRightBottomLeft':
        borderRadius = const BorderRadius.only(
          topRight: Radius.circular(8.0),
          bottomLeft: Radius.circular(8.0),
        );
        break;
      default:
        borderRadius = BorderRadius.circular(0); // No rounded corners
    }

    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14314A),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: const BorderSide(
              color: Colors.black,
            ),
          ),
        ),
        onPressed: onPressed,
        child: Text(text,
            style: GoogleFonts.notoSans(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  void startCalibrationSequence() {
    setState(() {
      _accelMaxValue = 0;
      _brakeMaxValue = 0;
      _isCalibratingAccel = false;
      _isCalibratingBrake = false;
      _showStatusBox = true;
      _statusMessage = 'TABA에 오신것을 환영합니다!';
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: const SubAppBar(),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Visibility(
              visible: _showStatusBox,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  _statusMessage,
                  style: GoogleFonts.notoSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
            ),
            if (_isCalibratingAccel || _isCalibratingBrake) ...[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_currentPressureValue',
                    style: GoogleFonts.notoSans(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    width: 200,
                    height: 200,
                    child: SfRadialGauge(
                      axes: <RadialAxis>[
                        RadialAxis(
                          minimum: 0,
                          maximum: 100,
                          showLabels: false,
                          showTicks: false,
                          axisLineStyle: const AxisLineStyle(
                            thickness: 0.2,
                            cornerStyle: CornerStyle.bothCurve,
                            color: Color(0xFFE9EDF0),
                            thicknessUnit: GaugeSizeUnit.factor,
                          ),
                          pointers: <GaugePointer>[
                            RangePointer(
                              value: _progress,
                              cornerStyle: CornerStyle.bothCurve,
                              width: 0.2,
                              sizeUnit: GaugeSizeUnit.factor,
                              color: const Color(0xFF14314A),
                            ),
                          ],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(
                              positionFactor: 0.1,
                              angle: 90,
                              widget: Text(
                                '$_countdown',
                                style: GoogleFonts.notoSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            if (isBluetoothConnected) // 블루투스가 연결된 경우에만 버튼을 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: screenWidth * 0.4, // screenWidth를 사용하여 버튼 크기 조정
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14314A),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(
                            color: Colors.black,
                          ),
                        ),
                      ),
                      onPressed: _isCalibratingAccel
                          ? null
                          : () => startCalibration('ACCEL'),
                      child: Text(
                        '엑셀 압력 측정',
                        style: GoogleFonts.notoSans(
                            fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: screenWidth * 0.4, // screenWidth를 사용하여 버튼 크기 조정
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14314A),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(
                            color: Colors.black,
                          ),
                        ),
                      ),
                      onPressed: _isCalibratingBrake
                          ? null
                          : () => startCalibration('BRAKE'),
                      child: Text(
                        '브레이크 압력 측정',
                        style: GoogleFonts.notoSans(
                            fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
