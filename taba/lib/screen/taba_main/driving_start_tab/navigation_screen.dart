import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taba/config.dart';
import 'package:taba/models/car_model.dart';
import 'package:taba/screen/taba_main/driving_log_tab/driving_finish_screen.dart';
import 'package:taba/services/car_service.dart';
import 'package:taba/services/driving_session_service.dart';
import 'package:taba/services/sensor_data_service.dart';
import 'package:taba/models/driving_session_model.dart';
import 'package:taba/models/sensor_data_model.dart';
import 'package:taba/widgets/dialog/custom_alter_dialog.dart';
import 'package:taba/widgets/dialog/yes_no.dart';

// 네비게이션 스크린의 상태 관리를 위한 StatefulWidget 정의
class NavigationScreen extends StatefulWidget {
  final LatLng currentLocation; // 현재 위치
  final LatLng destination; // 목적지 위치
  final int carId; // 자동차 ID
  final int userId; // 사용자 ID

  // 생성자를 통해 위치 정보, 차량 ID, 사용자 ID를 초기화
  const NavigationScreen({
    Key? key,
    required this.currentLocation,
    required this.destination,
    required this.carId,
    required this.userId,
  }) : super(key: key);

  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

// NavigationScreen의 상태를 관리하는 State 클래스
class _NavigationScreenState extends State<NavigationScreen> {
  final Completer<GoogleMapController> _controller =
      Completer(); // Google 지도 컨트롤러
  late LatLng _initialPosition; // 초기 위치 (출발점)
  late DrivingSessionService _drivingSessionService; // 운전 세션 관리 서비스
  late SensorDataService _sensorDataService; // 센서 데이터 관리 서비스
  int? drivingSessionId; // 운전 세션 ID
  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker; // 기본 마커 아이콘
  BitmapDescriptor navigationIcon = BitmapDescriptor.defaultMarker; // 네비게이션 아이콘
  Marker? _destinationMarker; // 목적지 마커
  Marker? _currentLocationMarker; // 현재 위치 마커
  final Set<Polyline> _polylines = {}; //지나온 경로 표시
  final List<LatLng> _routeCoordinates = []; //지나온 경로 표시

  // 블루투스 디바이스 리스트
  List<BluetoothDevice> devices = [];
  Map<String, String> deviceValues = {}; // 디바이스에서 읽은 값들을 저장하는 맵

  // 칼만 필터 속도 변수
  double currentSpeed = 0.0;
  Timer? _sensorDataTimer; // 센서 데이터 업데이트 타이머
  Timer? speedTimer; // 속도 업데이트 타이머
  bool isScanning = false; // 블루투스 스캐닝 여부
  double brakeVal = 0.0; // 브레이크 압력 값
  double accelVal = 0.0; // 가속도 값

  // 칼만 필터 변수
  List<double> speedReadings = []; // 속도 읽기 데이터 리스트
  double? estimatedSpeed; // 추정된 속도
  double processNoise = 0.05; // 프로세스 노이즈
  double measurementNoise = 5.0; // 측정 노이즈
  double errorEstimate = 2.0; // 추정 오류
  double errorMeasurement = 3.0; // 측정 오류

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addObserver(this); // 앱 라이프사이클 옵저버 추가
    FlutterBluePlus.state.listen(_onBluetoothStateChanged); // 블루투스 상태 감시
    startScan(); // 블루투스 스캔 시작
    _initialPosition = widget.currentLocation; // 현재 위치 설정
    _drivingSessionService = DrivingSessionService(); // 운전이력 서비스 초기화
    _sensorDataService = SensorDataService(); // 센서 데이터 서비스 초기화
    addCustomIcons(); // 사용자 정의 아이콘 추가
    _createDrivingSession(); // 운전 세션 생성
  }

  @override
  void dispose() {
    _sensorDataTimer?.cancel();
    speedTimer?.cancel();
    _stopDriving();
    super.dispose();
  }

  // 블루투스 상태가 변경되었을 때 호출되는 함수
  void _onBluetoothStateChanged(BluetoothAdapterState state) {
    if (state == BluetoothState.off) {
      CustomAlertDialog(
        context: context,
        title: '블루투스 연결 끊김',
        message: '블루투스 연결이 끊어졌습니다! 다시 연결해주세요.',
      ).show();
    }
  }

  // 사용자 정의 아이콘을 추가하는 메소드
  void addCustomIcons() {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(), "assets/images/marker4.png")
        .then((icon) {
      setState(() {
        markerIcon = icon; // 마커 아이콘 설정
      });
    });

    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(), "assets/images/navigation3.png")
        .then((icon) {
      setState(() {
        navigationIcon = icon; // 네비게이션 아이콘 설정
      });
    });
  }

  // 블루투스 스캔을 시작하는 메서드
  void startScan() async {
    setState(() {
      FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 10)); // 10초 동안 스캔
      FlutterBluePlus.scanResults.listen((results) {
        // 스캔 결과 리스닝
        for (ScanResult result in results) {
          // 결과에 대해 반복
          if (result.device.advName == 'ESP32 Force Sensor A' ||
              result.device.advName == 'ESP32 Force Sensor B') {
            // 필요한 디바이스 필터링
            if (!devices.contains(result.device)) {
              // 새 디바이스인 경우
              setState(() {
                devices.add(result.device); // 디바이스 리스트에 추가
              });
              connectToDevice(result.device); // 디바이스에 연결 시도
            }
          }
        }
      });
      isScanning = true; // 스캐닝 상태 설정
    });
  }

  // 블루투스 스캔을 중지하는 메서드
  void stopScan() {
    FlutterBluePlus.stopScan(); // 스캔 중지
    setState(() {
      isScanning = false; // 스캔 중지 상태 설정
    });
  }

  // 디바이스에 연결을 시도하는 함수
  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(); // 디바이스 연결 시도
      discoverServices(device); // 연결된 디바이스의 서비스 탐색
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error Bluetooth connecting to device: $e'), // 연결 실패 메시지
          duration: const Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(seconds: 5), () {
        connectToDevice(device); // 연결 실패시 재시도
      });
    }
  }

  // 연결된 디바이스의 서비스를 탐색하는 함수
  void discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services =
        await device.discoverServices(); // 서비스 목록 탐색
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          // 특성이 notify 가능한 경우
          characteristic.setNotifyValue(true); // Notify 활성화
          characteristic.lastValueStream.listen((value) {
            // Notify 값 스트림 수신
            String valueString = String.fromCharCodes(value); // 값 스트링 변환
            setState(() {
              deviceValues[device.advName] = valueString; // 디바이스 값 업데이트
              if (device.advName == 'ESP32 Force Sensor A') {
                accelVal = double.tryParse(valueString) ?? 0.0; // 가속도 값 파싱
              } else if (device.advName == 'ESP32 Force Sensor B') {
                brakeVal = double.tryParse(valueString) ?? 0.0; // 브레이크 값 파싱
              }
            });
          });
        }
      }
    }
  }

  // 칼만 필터를 적용하여 속도를 업데이트하는 로직
  void updateSpeed(Position position) {
    double currentSpeedKmH = position.speed * 3.6; // m/s를 km/h로 변환
    speedReadings.add(currentSpeedKmH); // 속도 읽기 목록에 추가
    if (speedReadings.length > 5) {
      speedReadings.removeAt(0); // 5개 초과시 가장 오래된 데이터 제거
    }
    double averageSpeed = speedReadings.reduce((a, b) => a + b) /
        speedReadings.length; // 평균 속도 계산

    if (estimatedSpeed == null) {
      estimatedSpeed = averageSpeed; // 초기 추정 속도 설정
    } else {
      double kalmanGain =
          errorEstimate / (errorEstimate + errorMeasurement); // 칼만 이득 계산
      estimatedSpeed = estimatedSpeed! +
          kalmanGain * (averageSpeed - estimatedSpeed!); // 추정 속도 업데이트
      errorEstimate = (1.0 - kalmanGain) * errorEstimate +
          (estimatedSpeed! - averageSpeed).abs() * processNoise; // 추정 오류 업데이트
    }

    setState(() {
      currentSpeed = estimatedSpeed!.round().toDouble(); // 현재 속도 상태 업데이트
    });
  }

  // 운전 세션을 생성하는 메서드
  Future<void> _createDrivingSession() async {
    try {
      DrivingSession newSession = DrivingSession(
        carId: widget.carId,
        userId: widget.userId,
        drivingStatus: DrivingStatus.DRIVING,
      );
      int sessionId = await _drivingSessionService
          .createDrivingSession(newSession); // 세션 생성 요청
      setState(() {
        drivingSessionId = sessionId; // 생성된 세션 ID 저장
      });
      _startSensorDataTransmission(); // 센서 데이터 전송 시작
    } catch (e) {
      print('Failed to create driving session: $e'); // 세션 생성 실패시 로그 출력
    }
  }

  // 지도 생성시 호출되는 콜백
  void _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller); // Completer에 controller 저장
    try {
      final mapController =
          await _controller.future; // Completer에서 GoogleMapController를 가져옴.
      String style = await DefaultAssetBundle.of(context)
          .loadString('assets/map_style.json'); // 맵 스타일 설정
      mapController.setMapStyle(style); // 맵 스타일 설정
      print('set load map style');
      _startNavigation(mapController); // 네비게이션 시작
    } catch (e) {
      print('Failed to load map style: $e');
    }
  }

  // 맵 스타일을 설정하는 비동기 함수
  Future<void> _setMapStyle(GoogleMapController controller) async {
    String style = await DefaultAssetBundle.of(context)
        .loadString('assets/images/map_style.json');
    controller.setMapStyle(style); // 맵에 스타일 적용
  }

  // 네비게이션을 시작하는 함수
  Future<void> _startNavigation(GoogleMapController mapController) async {
    setState(() {
      _currentLocationMarker = Marker(
        markerId: const MarkerId('current_location'),
        position: _initialPosition,
        icon: navigationIcon,
      );
      _destinationMarker = Marker(
        markerId: const MarkerId('destination_marker'),
        position: widget.destination,
        icon: markerIcon,
      );
    });
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: _initialPosition,
      zoom: 18,
      tilt: 60,
    )));
  }

  // 폴리라인을 업데이트하는 메서드
  void _updatePolyline() {
    setState(() {
      _polylines.add(Polyline(
        polylineId: const PolylineId("route"),
        points: _routeCoordinates,
        color: const Color(0xff213e57),
        width: 8,
        endCap: Cap.roundCap,
        startCap: Cap.buttCap,
        jointType: JointType.round,
      ));
    });
  }

  //현재 위치에 마커를 표시하는 로직 추가
  Future<void> _startSensorDataTransmission() async {
    String accelValue = deviceValues['ESP32 Force Sensor A'] ?? '0'; // 가속도 센서 값
    String brakeValue =
        deviceValues['ESP32 Force Sensor B'] ?? '0'; // 브레이크 센서 값
    accelVal = double.tryParse(accelValue) ?? 0.0;
    brakeVal = double.tryParse(brakeValue) ?? 0.0;

    // 위치 갱신 타이머(약 0.5초마다 위치 데이터 업데이트)
    speedTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      Position newPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation);
      LatLng newLocation = LatLng(newPosition.latitude, newPosition.longitude);

      // 여기서 현재 위치에 대한 마커를 업데이트
      setState(() {
        _currentLocationMarker = Marker(
            markerId: const MarkerId('current_location'),
            position: newLocation,
            icon: navigationIcon,
            rotation: newPosition.heading // 아이콘의 방향을 반영
            );
        _initialPosition = newLocation; // 초기 위치 업데이트
        _routeCoordinates.add(newLocation); // 경로에 새 위치 추가
        _updatePolyline(); // 폴리라인 업데이트
      });
      updateSpeed(newPosition); // 위치에 따라 속도 업데이트
      final GoogleMapController controller =
          await _controller.future; // GoogleMapController 인스턴스 가져오기
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: newLocation,
        zoom: 18,
        tilt: 60,
        bearing: newPosition.heading, // 카메라의 회전 방향 설정
      ))); // 카메라를 새 위치로 이동
    });

    double lastSpeed = 0.0; //이전 속도를 저장할 변수 선언
    // 센서 데이터 전송 타이머(약 1초마다 센서 데이터를 전송함)
    _sensorDataTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      // 현재 가속도와 브레이크 압력 값에 따라 운전 습관 판단
      DrivingHabit currentHabit = DrivingHabit.NORMAL;
      double speedDifference = currentSpeed - lastSpeed; // 현재 속도와 이전 속도의 차이 계산
      if (accelVal > 0 && brakeVal > 0) {
        // 양발 운전 감지
        currentHabit = DrivingHabit.TWOFOOT;
      }
      // 급출발 또는 급정거 감지
      else if (speedDifference >= 10) {
        currentHabit = DrivingHabit.SUDDENDEPARTURE;
      } else if (speedDifference <= -10) {
        currentHabit = DrivingHabit.SUDDENSTOP;
      }
      SensorData sensorData = SensorData(
          drivingSessionId: drivingSessionId!,
          brakePressure: brakeVal,
          accelPressure: accelVal,
          speed: currentSpeed,
          latitude: _initialPosition.latitude.toString(),
          longitude: _initialPosition.longitude.toString(),
          drivingHabit: currentHabit);
      //AI가 ERROR 감지시 바로 전화를 거는 로직 추가
      String result = await _sensorDataService.createSensorData(sensorData);
      if (result == 'ERROR') {
        _endDrivingSession(); //운전 종료
        _sensorDataTimer?.cancel(); // ERROR 시 타이머 중지
        speedTimer?.cancel(); // 속도 업데이트 타이머도 중지
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    });
  }

  // 운전 종료 함수
  void _stopDriving() {
    YesNoDialog(
        context: context,
        message: "운전을 종료하시겠습니까?",
        yesText: "네",
        noText: "아니요",
        onYesPressed: () {
          _endDrivingSession(); // 운전 세션 종료
          updateCarDrivingScore(); // 운전 점수 업데이트
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DrivingFinishScreen(
                  carId: widget.carId,
                  userId: widget.userId,
                  drivingSessionId: drivingSessionId),
            ),
          );
        },
        onNoPressed: () {
          Navigator.of(context).pop(); // 다이얼로그 닫기
        }).show();
  }

  // 운전 세션 종료 처리 함수
  Future<void> _endDrivingSession() async {
    _sensorDataTimer?.cancel(); // 센서 데이터 전송 중지
    speedTimer?.cancel(); //칼만필터 속도 타이머 중지
    stopScan(); //블루투스 스캔 종료

    if (drivingSessionId != null) {
      await _drivingSessionService.endDrivingSession(
          drivingSessionId!, DrivingStatus.NONE);
    }
  }

  // 차량 운전 점수 업데이트 메서드 추가
  Future<void> updateCarDrivingScore() async {
    try {
      // 센서 데이터를 가져옴
      List<SensorData> sensorDataList = await _sensorDataService
          .getAllSensorDataByDrivingSessionId(drivingSessionId!);
      print('Sensor data retrieved: $sensorDataList');

      // 각 센서 데이터의 drivingHabit 값을 출력
      for (var data in sensorDataList) {
        print('Driving Habit: ${data.drivingHabit}');
      }

      // 각 이벤트의 개수를 셈
      int suddenDepartureCount = sensorDataList
          .where((data) => data.drivingHabit == DrivingHabit.SUDDENDEPARTURE)
          .length;
      int suddenStopCount = sensorDataList
          .where((data) => data.drivingHabit == DrivingHabit.SUDDENSTOP)
          .length;
      int twoFootCount = sensorDataList
          .where((data) => data.drivingHabit == DrivingHabit.TWOFOOT)
          .length;

      print('Sudden Departure Count: $suddenDepartureCount');
      print('Sudden Stop Count: $suddenStopCount');
      print('Two Foot Count: $twoFootCount');

      // 점수 계산
      int scoreDeduction =
          (suddenDepartureCount + suddenStopCount) * -3 + twoFootCount * -10;

      // 기존 차량 정보를 가져옴
      CarService carService = CarService(baseUrl: Config.baseUrl);
      Car car = await carService.getCarById(widget.carId.toString());

      // 기존 점수와 새 점수를 계산
      int currentScore = car.drivingScore; // 기본 점수 100
      int newScore = currentScore + scoreDeduction;

      // 점수가 0 이하로 내려가지 않도록 보정
      if (newScore < 0) {
        newScore = 0;
      }

      print('Current Score: $currentScore');
      print('New Score: $newScore');

      // 새로운 점수로 차량 정보 업데이트
      await carService.updateCarScore(widget.carId.toString(), newScore);
      print('Car updated successfully with new score: $newScore');
    } catch (e) {
      print('Error updating driving score: $e');
    }
  }

// 위젯 트리 빌드 함수
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: () async {
        _stopDriving();
        return false; // 뒤로가기를 막고, 직접 처리하도록 설정
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // 기능 버튼 (예: 현재 위치로 돌아가기)
            final GoogleMapController controller = await _controller.future;
            controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: _initialPosition,
                  zoom: 18,
                  tilt: 60,
                ),
              ),
            );
          },
          backgroundColor: Colors.white.withOpacity(0.9),
          foregroundColor: Colors.blue[500],
          child: const Icon(Icons.location_searching),
        ),
        floatingActionButtonLocation:
            CustomFabLocation(0.04, 0.25), // 위치 지정: 화면 왼쪽 아래쪽
        body: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 18,
                tilt: 60,
              ),
              markers: {
                if (_destinationMarker != null) _destinationMarker!,
                if (_currentLocationMarker != null) _currentLocationMarker!,
              },
              polylines: _polylines,
              mapType: MapType.normal,
            ),
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF14314A).withOpacity(0.7),
                    minimumSize: Size(screenWidth * 0.7666667, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _stopDriving,
                  child: Text(
                    '운전 종료',
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 48,
              left: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF14314A).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '속도: ${currentSpeed.round()} km/h', // 가정: currentSpeed는 현재 속도 변수
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '브레이크: ${brakeVal.round()}', // 가정: brakeVal은 브레이크 값 변수
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      '엑셀: ${accelVal.round()}', // 가정: accelVal은 가속 값 변수
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 커스텀 플로팅액션버튼 위치를 설정하는 클래스
class CustomFabLocation extends FloatingActionButtonLocation {
  final double x;
  final double y;

  CustomFabLocation(this.x, this.y);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // xOffset와 yOffset을 사용하여 버튼 위치 조정
    final double xOffset = x * scaffoldGeometry.scaffoldSize.width;
    final double yOffset = y * scaffoldGeometry.scaffoldSize.height;
    return Offset(xOffset, scaffoldGeometry.scaffoldSize.height - yOffset);
  }
}
