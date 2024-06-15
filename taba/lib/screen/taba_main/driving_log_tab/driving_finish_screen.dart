import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taba/models/sensor_data_model.dart';
import 'package:taba/models/driving_session_model.dart'; // 드라이빙 세션 모델 추가
import 'package:taba/services/driving_session_service.dart';
import 'package:taba/services/kakao_local_service.dart';
import 'package:taba/services/sensor_data_service.dart';
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 추가

class DrivingFinishScreen extends StatefulWidget {
  final int carId;
  final int userId;
  final int? drivingSessionId;

  const DrivingFinishScreen({
    super.key,
    required this.carId,
    required this.userId,
    required this.drivingSessionId,
  });

  @override
  State<DrivingFinishScreen> createState() => _DrivingFinishScreenState();
}

class _DrivingFinishScreenState extends State<DrivingFinishScreen> {
  final KakaoLocalService kakaoService = KakaoLocalService();
  late GoogleMapController mapController;
  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker; // 기본 마커 아이콘
  BitmapDescriptor navigationIcon = BitmapDescriptor.defaultMarker; // 네비게이션 아이콘
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};
  List<LatLng> routeCoordinates = [];
  final SensorDataService sensorDataService = SensorDataService();
  final DrivingSessionService drivingSessionService =
      DrivingSessionService(); // 드라이빙 세션 서비스 추가
  SensorData? firstData;
  SensorData? lastData;
  DrivingSession? drivingSession; // 드라이빙 세션 객체 추가
  String? firstRegion;
  String? lastRegion;
  double distance = 0.0;
  List<SensorData> nonNormalData = [];

  late Map<String, dynamic> _searchResults;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _loadRoute();
  }

  @override
  void initState() {
    super.initState();
    addCustomIcons(); // 사용자 정의 아이콘 추가
    _loadDrivingSession().then((_) => _loadRoute().then((_) {
          if (firstData != null && lastData != null) {
            distance = calculateDistance(
              double.parse(firstData!.latitude.toString()),
              double.parse(firstData!.longitude.toString()),
              double.parse(lastData!.latitude.toString()),
              double.parse(lastData!.longitude.toString()),
            );
            print("Distance: $distance km");
            _updateCameraPosition(); // 경로 데이터를 로드한 후 카메라를 위치
          }
        }));
  }

  Future<void> _loadDrivingSession() async {
    if (widget.drivingSessionId != null) {
      try {
        drivingSession = await drivingSessionService
            .getDrivingSessionsById(widget.drivingSessionId!);
      } catch (e) {
        print('Failed to load driving session data: $e');
      }
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

  Future<void> _loadRoute() async {
    try {
      List<SensorData> sensorDataList = await sensorDataService
          .getAllSensorDataByDrivingSessionId(widget.drivingSessionId ?? 0);

      if (sensorDataList.isNotEmpty) {
        firstData = sensorDataList.first;
        lastData = sensorDataList.last;

        // 'NORMAL'이 아닌 데이터 필터링
        nonNormalData = sensorDataList
            .where((data) => data.drivingHabit != DrivingHabit.NORMAL)
            .toList();

        // nonNormalData의 값을 출력하여 확인
        printNonNormalData();

        // 행정구역 정보 가져오기
        String firstRegionName = await _getRegionName(
            double.parse(firstData!.latitude.toString()),
            double.parse(firstData!.longitude.toString()));
        String lastRegionName = await _getRegionName(
            double.parse(lastData!.latitude.toString()),
            double.parse(lastData!.longitude.toString()));

        setState(() {
          firstRegion = firstRegionName;
          lastRegion = lastRegionName;

          routeCoordinates = sensorDataList
              .map((data) => LatLng(double.parse(data.latitude.toString()),
                  double.parse(data.longitude.toString())))
              .toList();

          _addStartAndEndMarkers(firstData!, lastData!);
          _updatePolyline();
          _updateCameraPosition();
        });
      }
    } catch (e) {
      print('Failed to load route data: $e');
    }
  }

  void printNonNormalData() {
    for (var data in nonNormalData) {
      print('Non-normal data: ${data.drivingHabit.toString()}');
    }
  }

  Future<String> _getRegionName(double latitude, double longitude) async {
    try {
      final regionData =
          await kakaoService.getRegionByCoordinates(latitude, longitude);
      setState(() {
        _searchResults = regionData;
      });
      return _searchResults['address_name'];
    } catch (e) {
      print('Failed to load region data: $e');
      return 'Unknown';
    }
  }

  void _addStartAndEndMarkers(SensorData startData, SensorData endData) {
    markers.add(Marker(
      markerId: const MarkerId('start_marker'),
      position: LatLng(double.parse(startData.latitude.toString()),
          double.parse(startData.longitude.toString())),
      infoWindow: const InfoWindow(title: "출발지"),
      icon: markerIcon,
    ));

    markers.add(Marker(
      markerId: const MarkerId('end_marker'),
      position: LatLng(double.parse(endData.latitude.toString()),
          double.parse(endData.longitude.toString())),
      infoWindow: const InfoWindow(title: "목적지"),
      icon: navigationIcon,
    ));
  }

  void _updateCameraPosition() {
    if (routeCoordinates.isNotEmpty) {
      LatLngBounds bounds = _boundsFromLatLngList(routeCoordinates);
      CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50);
      mapController.animateCamera(cameraUpdate);
    }
  }

  void _updatePolyline() {
    PolylineId id = const PolylineId("route");
    Polyline polyline = Polyline(
      polylineId: id,
      color: const Color(0xff213e57),
      points: routeCoordinates,
      width: 5,
    );
    polylines.add(polyline);
  }

  //모든 경로를 계산하여 총 이동거리를 계산하는 로직
  double calculateTotalDistance(List<LatLng> routeCoordinates) {
    double totalDistance = 0.0;
    for (int i = 0; i < routeCoordinates.length - 1; i++) {
      totalDistance += calculateDistance(
        routeCoordinates[i].latitude,
        routeCoordinates[i].longitude,
        routeCoordinates[i + 1].latitude,
        routeCoordinates[i + 1].longitude,
      );
    }
    return totalDistance;
  }

  //지구는 둥그니까
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
        northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  String getDrivingHabitText() {
    if (drivingSession?.errorStatus == ErrorStatus.ERROR ||
        drivingSession?.errorStatus == ErrorStatus.SOLVE) {
      return '급발진';
    }
    if (nonNormalData.isNotEmpty) {
      return getDrivingHabitTextFromData(nonNormalData.first.drivingHabit!);
    }
    return '완벽한 운전이었어요!';
  }

  String getDrivingHabitTextFromData(DrivingHabit habit) {
    switch (habit) {
      case DrivingHabit.TWOFOOT:
        return '양발운전';
      case DrivingHabit.SUDDENDEPARTURE:
        return '급출발';
      case DrivingHabit.SUDDENSTOP:
        return '급정거';
      case DrivingHabit.NORMAL:
      default:
        return '정상';
    }
  }

  int getDrivingHabitColor(String habitText) {
    if (habitText == '완벽한 운전이었어요!') {
      return 0xff00d3e0; // 청록
    } else if (habitText == '양발운전') {
      return 0xffff6666; // 연한 빨강
    } else if (habitText == '급발진') {
      return 0xffbb0020; // 진한 빨강
    } else if (habitText == '급출발' || habitText == '급정거') {
      return 0xFFF2CF01; // 주황
    } else {
      return 0xff00d3e0; // 기본 색상
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime startTime = DateTime.parse(
        firstData?.timestamp.toString() ?? '1999-03-08 19:42:00');
    final DateTime endTime =
        DateTime.parse(lastData?.timestamp.toString() ?? '1999-03-08 19:42:00');
    final Duration duration = endTime.difference(startTime);
    final totalDistance = calculateTotalDistance(routeCoordinates)
        .toStringAsFixed(2); // 로그로 시간 데이터와 계산된 지속 시간 출력
    print('Start Time: $startTime');
    print('End Time: $endTime');
    print('Duration: $duration');

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    String habitText = getDrivingHabitText();
    int habitColor = getDrivingHabitColor(habitText);

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 6,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: routeCoordinates.isNotEmpty
                      ? routeCoordinates.first
                      : const LatLng(0, 0),
                  zoom: 14,
                ),
                markers: markers,
                polylines: polylines,
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.only(top: 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('yyyy년 MM월 dd일').format(DateTime.parse(
                            firstData?.timestamp.toString() ?? '1999-03-08')),
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                DateFormat('HH:mm').format(DateTime.parse(
                                    firstData?.timestamp.toString() ??
                                        '1999-03-08 19:42:00')),
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.0555556),
                              const CustomIcon(size: 10, colorName: 0xff8c8c8c),
                              SizedBox(width: screenWidth * 0.0555556),
                              Text(
                                firstRegion ?? 'Loading...',
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          Row(children: [
                            SizedBox(width: screenWidth * 0.165),
                            const CustomIconForEnd(
                                size: 4, colorName: 0xffd9d9d9),
                          ]),
                          const SizedBox(height: 2),
                          Row(children: [
                            SizedBox(width: screenWidth * 0.165),
                            const CustomIconForEnd(
                                size: 4, colorName: 0xffd9d9d9),
                          ]),
                          const SizedBox(height: 2),
                          Row(children: [
                            SizedBox(width: screenWidth * 0.165),
                            const CustomIconForEnd(
                                size: 4, colorName: 0xffd9d9d9),
                          ]),
                          const SizedBox(height: 2),
                          Row(children: [
                            SizedBox(width: screenWidth * 0.165),
                            const CustomIconForEnd(
                                size: 4, colorName: 0xffd9d9d9),
                          ]),
                          const SizedBox(height: 2),
                          Row(children: [
                            SizedBox(width: screenWidth * 0.165),
                            const CustomIconForEnd(
                                size: 4, colorName: 0xffd9d9d9),
                          ]),
                          Row(
                            children: [
                              Text(
                                DateFormat('HH:mm').format(DateTime.parse(
                                    lastData?.timestamp.toString() ??
                                        '1999-03-08 19:42:00')),
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.0555556),
                              const CustomIconForEnd(
                                  size: 10, colorName: 0xff14314a),
                              SizedBox(width: screenWidth * 0.0555556),
                              Text(
                                lastRegion ?? 'Loading...',
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            Row(children: [
                              Text(
                                '운행 시간: ',
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: const Color(0xFF8C8C8C),
                                ),
                              ),
                              Text(
                                _formatDuration(DateTime.parse(
                                        lastData?.timestamp.toString() ??
                                            '1999-03-08 19:42:00')
                                    .difference(DateTime.parse(
                                        firstData?.timestamp.toString() ??
                                            '1999-03-08 19:42:00'))),
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: const Color(0xFF8C8C8C),
                                ),
                              ),
                              Text(
                                ' | 거리: ',
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: const Color(0xFF8C8C8C),
                                ),
                              ),
                              Text(
                                '${totalDistance}km',
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: const Color(0xFF8C8C8C),
                                ),
                              ),
                              const SizedBox(width: 20),
                            ]),
                            const SizedBox(height: 5),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CustomIconForEnd(
                                    size: 12, colorName: habitColor),
                                const SizedBox(width: 10),
                                Text(
                                  habitText,
                                  style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String hours = twoDigits(duration.inHours);
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$hours:$minutes:$seconds";
}

// 원 모양 아이콘 설정
class CustomIcon extends StatelessWidget {
  final double size;
  final int colorName;

  const CustomIcon({Key? key, required this.size, required this.colorName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(colorName), // 외곽선 색상
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: size * 0.8, // 아이콘 크기 조정
          height: size * 0.8, // 아이콘 크기 조정
          decoration: const BoxDecoration(
            color: Colors.white, // 아이콘 내부 색상
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// 꽉찬 원 모양 아이콘 설정
class CustomIconForEnd extends StatelessWidget {
  final double size;
  final int colorName;

  const CustomIconForEnd(
      {Key? key, required this.size, required this.colorName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(colorName), // 외곽선 색상
        shape: BoxShape.circle,
      ),
    );
  }
}
