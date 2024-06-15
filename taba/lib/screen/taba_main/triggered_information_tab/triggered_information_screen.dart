import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taba/models/driving_session_model.dart';
import 'package:taba/models/sensor_data_model.dart';
import 'package:taba/services/driving_session_service.dart';
import 'package:taba/services/kakao_local_service.dart';
import 'package:intl/intl.dart';
import 'package:taba/widgets/dialog/yes_no.dart';
import 'package:taba/services/sensor_data_service.dart';

class TriggeredInformationScreen extends StatefulWidget {
  final int userId;

  const TriggeredInformationScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  TriggeredInformationScreenState createState() =>
      TriggeredInformationScreenState();
}

class TriggeredInformationScreenState
    extends State<TriggeredInformationScreen> {
  late Future<List<DrivingSession>> _drivingSessions;
  final DrivingSessionService _drivingSessionService = DrivingSessionService();
  final KakaoLocalService _kakaoLocalService = KakaoLocalService();
  final SensorDataService _sensorDataService = SensorDataService();

  @override
  void initState() {
    super.initState();
    _drivingSessions = _loadDrivingSessions();
  }

  Future<List<DrivingSession>> _loadDrivingSessions() async {
    List<DrivingSession> sessions =
        await _drivingSessionService.getAllDrivingSessionsByUser(widget.userId);

    // Enum 값을 올바르게 인식하는지 확인하는 로깅 코드 추가
    for (var session in sessions) {
      print(
          "Session ID: ${session.drivingSessionId}, Error Status: ${session.errorStatus}");
    }

    return sessions
        .where((session) =>
            session.errorStatus == ErrorStatus.ERROR ||
            session.errorStatus == ErrorStatus.SOLVE)
        .toList();
  }

  void reloadTriggeredInfo() {
    setState(() {
      _drivingSessions = _loadDrivingSessions();
    });
  }

  Future<String> _getRegionName(double latitude, double longitude) async {
    try {
      final region =
          await _kakaoLocalService.getRegionByCoordinates(latitude, longitude);
      return region['region_1depth_name'] +
          ' ' +
          region['region_2depth_name'] +
          ' ' +
          region['region_3depth_name'];
    } catch (e) {
      return 'Unknown location';
    }
  }

  void _solvedYesNoDialog(BuildContext context, int sessionId) {
    YesNoDialog(
      context: context,
      message: "사고 해결 완료되셨습니까?\n완료된 사건은 돌이킬 수 없습니다.",
      yesText: "예",
      noText: "아니오",
      onYesPressed: () async {
        Navigator.of(context).pop();
        await _drivingSessionService.solveErrorStatus(sessionId);
        reloadTriggeredInfo();
      },
      onNoPressed: () {
        Navigator.of(context).pop();
      },
    ).show();
  }

  Future<void> _showSensorDataDialog(
      BuildContext context, int sessionId) async {
    final sensorDataList =
        await _sensorDataService.getAllSensorDataByDrivingSessionId(sessionId);
    showDialog(
      context: context,
      builder: (context) => SensorDataDialog(sensorDataList: sensorDataList),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<DrivingSession>>(
        future: _drivingSessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(
                child: Text("Error loading triggered information"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(
              "회원님은 급발진 사고 이력이 없으십니다.",
              style: GoogleFonts.notoSans(
                fontWeight: FontWeight.w300,
                color: Colors.grey,
                fontSize: 18,
              ),
            ));
          } else {
            return ListView(
              children: snapshot.data!
                  .map((session) => DrivingSessionTile(
                        session: session,
                        onSolvePressed: () => _solvedYesNoDialog(
                            context, session.drivingSessionId!),
                        onShowSensorDataPressed: () => _showSensorDataDialog(
                            context, session.drivingSessionId!),
                      ))
                  .toList(),
            );
          }
        },
      ),
    );
  }
}

class DrivingSessionTile extends StatelessWidget {
  final DrivingSession session;
  final KakaoLocalService kakaoLocalService = KakaoLocalService();
  final VoidCallback onSolvePressed;
  final VoidCallback onShowSensorDataPressed;

  DrivingSessionTile(
      {Key? key,
      required this.session,
      required this.onSolvePressed,
      required this.onShowSensorDataPressed})
      : super(key: key);

  String _formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd, HH:mm').format(dateTime);
  }

  Future<String> _getRegionName(double latitude, double longitude) async {
    try {
      final region =
          await kakaoLocalService.getRegionByCoordinates(latitude, longitude);
      return region['region_1depth_name'] +
          ' ' +
          region['region_2depth_name'] +
          ' ' +
          region['region_3depth_name'];
    } catch (e) {
      return 'Unknown location';
    }
  }

  void _showYesNoDialog(BuildContext context) {
    YesNoDialog(
      context: context,
      message: "급발진 상황 당시 자료를\n확인하시겠습니까?",
      yesText: "예",
      noText: "아니오",
      onYesPressed: () {
        Navigator.of(context).pop();
        onShowSensorDataPressed(); // 센서 데이터 다이얼로그 표시
      },
      onNoPressed: () {
        Navigator.of(context).pop();
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return FutureBuilder<String>(
      future: _getRegionName(
          session.errorLatitude ?? 0, session.errorLongitude ?? 0),
      builder: (context, snapshot) {
        String location = 'Loading location...';
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          location = snapshot.data!;
        }

        return Column(
          children: [
            SizedBox(height: screenHeight * 0.01875),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      top: screenHeight * 0.007), // 아이콘을 아래로 1px 이동
                  child: Image.asset('assets/images/person.png'),
                ),
                Container(
                  width: screenWidth * 0.8,
                  padding: EdgeInsets.only(
                      left: screenWidth * 0.069444,
                      right: screenWidth * 0.044444,
                      top: screenHeight * 0.011625,
                      bottom: 16.0),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/speech_bubble.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(session.errorTime ?? DateTime.now()),
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.00875),
                      Text(
                        location,
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F1F1F),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01875),
                      ElevatedButton(
                        onPressed: () {
                          _showYesNoDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF537A9B),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(4), // 둥근 모서리 반경 설정
                          ),
                          minimumSize: Size(screenWidth * 0.7,
                              screenHeight * 0.0525), // 버튼의 최소 크기 설정 (너비, 높이)
                        ),
                        child: Text(
                          '엑셀, 브레이크 압력 확인',
                          style: GoogleFonts.notoSans(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.01875),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      top: screenHeight * 0.011625), // 아이콘을 아래로 1px 이동
                  child: Image.asset('assets/images/person.png'),
                ),
                Container(
                  width: screenWidth * 0.8,
                  padding: EdgeInsets.only(
                      left: screenWidth * 0.069444,
                      top: screenHeight * 0.011625,
                      bottom: 10.0),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/speech_bubble.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '보험사 직원에게 위 데이터를 보여주세요',
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '보험사 직원을 통해 사건이 해결되셨나요?\n해결 완료가 되신 분은 TABA 시스템의 더 좋은 서비스를 위해 \n완료 버튼을 눌러주세요.',
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F1F1F),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.0075),
                      ElevatedButton(
                        onPressed: onSolvePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF537A9B),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(4), // 둥근 모서리 반경 설정
                          ),
                          minimumSize: Size(screenWidth * 0.7,
                              screenHeight * 0.0525), // 버튼의 최소 크기 설정 (너비, 높이)
                        ),
                        child: Text(
                          '해결 완료',
                          style: GoogleFonts.notoSans(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.04875),
          ],
        );
      },
    );
  }
}

// SensorDataDialog 추가
class SensorDataDialog extends StatelessWidget {
  final List<SensorData> sensorDataList;

  const SensorDataDialog({Key? key, required this.sensorDataList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: screenWidth * 0.9,
        height: screenWidth * 1.2,
        decoration: const BoxDecoration(
          color: Colors.white, // 배경색을 흰색으로 설정
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: screenWidth * 0.6,
              height: screenWidth * 0.1,
              decoration: BoxDecoration(
                color: const Color(0xffe8a44b), // 배경색을 흰색으로 설정
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '엑셀 및 브레이크 압력',
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '파일로 받고 싶다면, TABA 서비스 센터에 전화바랍니다.',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Table(
                  border: TableBorder.all(color: Colors.grey),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                      ),
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '브레이크\n압력값',
                              style: GoogleFonts.notoSans(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              ' 엑셀\n압력값',
                              style: GoogleFonts.notoSans(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: Text(
                              '속력',
                              style: GoogleFonts.notoSans(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: Text(
                              '시각',
                              style: GoogleFonts.notoSans(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...sensorDataList.map((sensorData) {
                      return TableRow(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '${sensorData.brakePressure}',
                                style: GoogleFonts.notoSans(fontSize: 12),
                              ),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '${sensorData.accelPressure}',
                                style: GoogleFonts.notoSans(fontSize: 12),
                              ),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '${sensorData.speed}',
                                style: GoogleFonts.notoSans(fontSize: 12),
                              ),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                DateFormat('yyyy-MM-dd HH:mm:ss')
                                    .format(sensorData.timestamp!),
                                style: GoogleFonts.notoSans(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF537A9B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4), // 둥근 모서리 반경 설정
                ),
                minimumSize: Size(screenWidth * 0.7,
                    screenHeight * 0.0525), // 버튼의 최소 크기 설정 (너비, 높이)
              ),
              child: Text(
                '닫기',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
