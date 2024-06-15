import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taba/models/driving_session_model.dart';
import 'package:taba/models/sensor_data_model.dart';
import 'package:taba/screen/taba_main/driving_log_tab/driving_finish_screen.dart';
import 'package:taba/services/driving_session_service.dart';
import 'package:taba/services/kakao_local_service.dart';
import 'package:taba/services/sensor_data_service.dart';
import 'package:taba/widgets/bar/driving_session_bar.dart';

class DrivingHistory extends StatefulWidget {
  final int userId;

  const DrivingHistory({Key? key, required this.userId}) : super(key: key);

  @override
  _DrivingHistoryState createState() => _DrivingHistoryState();
}

class _DrivingHistoryState extends State<DrivingHistory> {
  final DrivingSessionService sessionService = DrivingSessionService();
  final SensorDataService sensorDataService = SensorDataService();
  final KakaoLocalService kakaoService = KakaoLocalService();
  List<DrivingSession>? sessions;
  Map<int, double> totalDistance = {};
  Map<int, String> regionNames = {};
  Map<int, String> durations = {};
  Map<int, String> drivingHabits = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadSessions();
  }

  Future<void> loadSessions() async {
    try {
      var loadedSessions =
          await sessionService.getAllDrivingSessionsByUser(widget.userId);
      for (var session in loadedSessions) {
        print(
            'Session ID: ${session.drivingSessionId}, Error Status: ${session.errorStatus}'); // 디버깅 메시지 추가

        var sensorData = await sensorDataService
            .getAllSensorDataByDrivingSessionId(session.drivingSessionId!);
        var distance = calculateTotalDistance(sensorData
            .map((data) => LatLng(
                double.parse(data.latitude), double.parse(data.longitude)))
            .toList());
        var regionName = await _getRegionName(
            double.parse(sensorData.last.latitude),
            double.parse(sensorData.last.longitude));
        var duration = formatDuration(DateTime.parse(
                sensorData.last.timestamp.toString() ?? '1999-03-08 19:42:00')
            .difference(DateTime.parse(sensorData.first.timestamp.toString() ??
                '1999-03-08 19:42:00')));

        var drivingHabit = getDrivingHabitText(session, sensorData);

        if (session.drivingSessionId != null) {
          durations[session.drivingSessionId!] = duration;
          totalDistance[session.drivingSessionId!] = distance;
          regionNames[session.drivingSessionId!] = regionName;
          drivingHabits[session.drivingSessionId!] = drivingHabit;
        }
      }
      setState(() {
        sessions = loadedSessions;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return "${twoDigits(hours)}시간 ${twoDigits(minutes)}분";
    } else {
      return "${twoDigits(minutes)}분";
    }
  }

  double calculateTotalDistance(List<LatLng> routeCoordinates) {
    return routeCoordinates
        .asMap()
        .entries
        .skip(1)
        .map((e) => calculateDistance(
            routeCoordinates[e.key - 1].latitude,
            routeCoordinates[e.key - 1].longitude,
            e.value.latitude,
            e.value.longitude))
        .reduce((sum, element) => sum + element);
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<String> _getRegionName(double latitude, double longitude) async {
    try {
      final regionData =
          await kakaoService.getRegionByCoordinates(latitude, longitude);
      return regionData['address_name'];
    } catch (e) {
      print('Failed to load region data: $e');
      return 'Unknown';
    }
  }

  String getDrivingHabitText(
      DrivingSession session, List<SensorData> sensorDataList) {
    if (session.errorStatus == ErrorStatus.ERROR ||
        session.errorStatus == ErrorStatus.SOLVE) {
      return '급발진';
    }
    for (var data in sensorDataList) {
      if (data.drivingHabit != DrivingHabit.NORMAL) {
        switch (data.drivingHabit) {
          case DrivingHabit.TWOFOOT:
            return '양발운전';
          case DrivingHabit.SUDDENDEPARTURE:
            return '급출발';
          case DrivingHabit.SUDDENSTOP:
            return '급정거';
          default:
            return '알 수 없음';
        }
      }
    }
    return '완벽한 운전이었어요!';
  }

  int getDrivingHabitColor(DrivingHabit habit) {
    switch (habit) {
      case DrivingHabit.TWOFOOT:
        return 0xffbb0020; // 빨강
      case DrivingHabit.SUDDENDEPARTURE:
      case DrivingHabit.SUDDENSTOP:
        return 0xFFF2CF01; // 주황
      case DrivingHabit.NORMAL:
      default:
        return 0xff00d3e0; // 청록
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        //appBar: AppBar(title: Text('운전 이력', style: GoogleFonts.notoSans())),
        appBar: DrivingSessionBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: const DrivingSessionBar(),
        body: Center(child: Text("Error: $errorMessage")),
      );
    }

    return Scaffold(
      appBar: const DrivingSessionBar(),
      body: ListView.builder(
        itemCount: sessions!.length,
        itemBuilder: (context, index) {
          var session = sessions![index];
          var startTime = DateFormat('HH시 mm분')
              .format(DateFormat('HH:mm:ss.SSS').parse(session.startTime!));
          var habitText = drivingHabits[session.drivingSessionId] ?? '알 수 없음';
          var habitColor = habitText == '완벽한 운전이었어요!'
              ? 0xff00d3e0
              : (habitText == '양발운전'
                  ? 0xffFF6F61 // 연한 빨강
                  : (habitText == '급발진'
                      ? 0xffbb0020 // 진한 빨강
                      : (habitText == '급출발' || habitText == '급정거'
                          ? 0xFFF2CF01 // 주황
                          : 0xff00d3e0))); // 기본 색상

          return GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DrivingFinishScreen(
                          userId: widget.userId,
                          carId: session.carId,
                          drivingSessionId: session.drivingSessionId)));
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 2,
                      offset: const Offset(1, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR')
                            .format(session.startDate!),
                        style: GoogleFonts.notoSans(
                            fontSize: 16, color: const Color(0xFF595959)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${regionNames[session.drivingSessionId]}",
                        style: GoogleFonts.notoSans(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "$startTime 출발 | ",
                            style: GoogleFonts.notoSans(
                                fontSize: 14, color: const Color(0xFF595959)),
                          ),
                          Text(
                            "${totalDistance[session.drivingSessionId]?.toStringAsFixed(2)} km | ",
                            style: GoogleFonts.notoSans(
                                fontSize: 14, color: const Color(0xFF595959)),
                          ),
                          Text(
                            "${durations[session.drivingSessionId]} 소요",
                            style: GoogleFonts.notoSans(
                                fontSize: 14, color: const Color(0xFF595959)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(habitColor),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: Text(
                          habitText,
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
