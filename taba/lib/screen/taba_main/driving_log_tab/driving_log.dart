import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:taba/api_client.dart';
import 'package:taba/config.dart';
import 'package:taba/models/car_model.dart';
import 'package:taba/models/driving_session_model.dart';
import 'package:taba/models/sensor_data_model.dart';
import 'package:taba/screen/taba_main/driving_log_tab/driving_analysis.dart';
import 'package:taba/screen/taba_main/driving_log_tab/driving_history.dart';
import 'package:taba/ads_controller.dart';
import 'package:get/get.dart';
import 'package:taba/services/car_service.dart';
import 'package:taba/services/driving_session_service.dart';
import 'package:taba/services/kakao_local_service.dart';
import 'package:taba/services/sensor_data_service.dart';

class DrivingLog extends StatefulWidget {
  final int userId;

  const DrivingLog({
    super.key,
    required this.userId,
  });

  @override
  DrivingLogState createState() => DrivingLogState();
}

class DrivingLogState extends State<DrivingLog>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final PageController _pageController = PageController(viewportFraction: 1.0);
  //만약 api 호출시 "/new" 디렉토리에서 제거해야함.
  final List<String> imagePaths = [
    'assets/images/new/user_car_seltos.png',
    'assets/images/new/user_car_genesis.png',
    'assets/images/new/user_car_benz.png',
    'assets/images/new/user_car_tesla.png',
  ];

  late Future<NativeAd> _adFuture;

  //카카오주소 서비스
  final KakaoLocalService kakaoService = KakaoLocalService();
  //운전이력, 센서 데이터
  final DrivingSessionService sessionService = DrivingSessionService();
  final SensorDataService sensorDataService = SensorDataService();
  final CarService carService = CarService(baseUrl: Config.baseUrl);

  DrivingSession? latestSession; // 최근 운전 세션을 저장할 변수
  int? finalSessionId;
  String? regionName;
  String drivingHabit = "Loading ...";
  late Map<String, dynamic> _searchResults;
  //자동차 리스트
  List<Car> cars = []; //최대 4개의 차량
  List<int> drivingScore = []; //각각의 차량마다의 점수를 저장하는

  @override
  void initState() {
    super.initState();
    _adFuture = _loadAd();
    sessionService;
    sensorDataService;
    _loadCars();
    _loadLatestSession(); // 가장 최근의 세션을 로드하는 함수를 호출
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<String> getRegionName(double latitude, double longitude) async {
    try {
      final regionData =
          await kakaoService.getRegionByCoordinates(latitude, longitude);
      setState(() {
        _searchResults = regionData;
      });
      return _searchResults['region_2depth_name'] +
          ' ' +
          _searchResults['region_3depth_name'];
    } catch (e) {
      print('Failed to load region data: $e');
      return 'Unknown';
    }
  }

  Future<void> _loadLatestSession() async {
    try {
      final List<DrivingSession> sessions =
          await sessionService.getAllDrivingSessionsByUser(widget.userId);
      if (sessions.isNotEmpty) {
        latestSession = sessions.last; // 가장 최근의 세션을 저장
        finalSessionId = latestSession!.drivingSessionId;
        final List<SensorData> sensorData = await sensorDataService
            .getAllSensorDataByDrivingSessionId(finalSessionId!);
        if (sensorData.isNotEmpty) {
          String firstRegionName = await getRegionName(
              double.parse(sensorData.last.latitude.toString()),
              double.parse(sensorData.last.longitude.toString()));
          String habitText = getDrivingHabitText(latestSession!, sensorData);
          print("로드 완료1: $firstRegionName");
          setState(() {
            regionName = firstRegionName;
            drivingHabit = habitText;
          });
        } else {
          setState(() {
            regionName = "운전 이력이 없습니다.";
            drivingHabit = "운전 습관";
          });
        }
        print("로드 완료2: $regionName");
      } else {
        setState(() {
          regionName = "운전 이력이 없습니다.";
          drivingHabit = "운전 습관";
        });
      }
      print("로드 완료3: $regionName");
    } catch (e) {
      print('Error loading session data: $e');
      setState(() {
        regionName = "오류 발생";
        drivingHabit = "오류 발생";
      });
    }
  }

  Future<NativeAd> _loadAd() async {
    final Completer<NativeAd> completer = Completer();
    final ad = NativeAd(
      adUnitId:
          Platform.isAndroid ? Config.AndroidAdUnitId : Config.IosAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          completer.complete(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          completer.completeError(error);
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle:
          NativeTemplateStyle(templateType: TemplateType.small),
    );
    ad.load();
    return completer.future;
  }

  //메인 탭에서 관리하는 메서드들(탭 클릭시 초기화)
  void reloadLatestSession() {
    _loadLatestSession();
    _loadCars();
  }

  Future<void> _loadCars() async {
    try {
      final loadedCars = await carService.getCarsByUserId(widget.userId);
      List<int> loadedScores = loadedCars
          .map((car) => car.drivingScore)
          .toList(); // 데이터베이스에서 driving_score를 로드
      setState(() {
        cars = loadedCars;
        drivingScore = loadedScores; // 상태 업데이트
      });
    } catch (e) {
      print('Error loading cars: $e');
      setState(() {
        drivingScore = List.filled(cars.length, 0); // 에러 발생시 모든 점수를 0으로 설정
      });
    }
  }

  String getDrivingHabitText(
      DrivingSession latestSession, List<SensorData> sensorDataList) {
    if (latestSession.errorStatus == ErrorStatus.ERROR ||
        latestSession.errorStatus == ErrorStatus.SOLVE) {
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

  Color getDrivingHabitColor(String habitText) {
    var habitColor = habitText == '완벽한 운전이었어요!'
        ? 0xff00d3e0
        : (habitText == '양발운전'
            ? 0xffFF6F61 // 연한 빨강
            : (habitText == '급발진'
                ? 0xffbb0020 // 진한 빨강
                : (habitText == '급출발' || habitText == '급정거'
                    ? 0xFFF2CF01 // 주황
                    : 0xff00d3e0))); // 기본 색상

    return Color(habitColor);
  }

  @override
  Widget build(BuildContext context) {
    final myContr = Get.put(MyController(), tag: "finallist");

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF14314A),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: screenHeight * 0.328,
            decoration: const BoxDecoration(
              color: Color(0xFF14314A), // Background color
            ),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: imagePaths.length,
                    itemBuilder: (context, index) {
                      return buildPageContent(
                          screenWidth, screenHeight, imagePaths[index], index);
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.0389,
                  ),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: imagePaths.length,
                    effect: const WormEffect(
                      dotWidth: 10.0,
                      dotHeight: 10.0,
                      activeDotColor: Color(0xFFE8A44B),
                      dotColor: Colors.white,
                      spacing: 16.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.0666,
                vertical: screenHeight * 0.042,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF537A9B),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween, // 요소들을 양 끝으로 정렬
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "최근운전",
                              style: GoogleFonts.notoSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 22.5,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              height: screenHeight * 0.035,
                              width: screenWidth * 0.263,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => DrivingHistory(
                                              userId: widget.userId,
                                            )),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: Text(
                                  '전체보기',
                                  style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(0.5, 0.05),
                            )
                          ],
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceBetween, // 요소들을 양 끝으로 정렬
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  regionName ??
                                      "Loading ...", // regionName이 null이 아니면 해당 값을, null이면 기본 텍스트 표시
                                  style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  latestSession != null
                                      ? DateFormat('yyyy년 MM월 dd일').format(
                                          DateTime.parse(latestSession!
                                              .startDate
                                              .toString()))
                                      : "Loading ...",
                                  // 최근 세션의 시작 날짜를 문자열로 표시
                                  style: GoogleFonts.notoSans(
                                    color: const Color(0xff8c8c8c),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceBetween, // 요소들을 양 끝으로 정렬
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Card(
                                  color: getDrivingHabitColor(drivingHabit),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        4), // 테두리 둥근 정도를 4로 설정
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8.0,
                                        right: 8.0,
                                        top: 4,
                                        bottom: 4), // 텍스트 주변에 여백 추가
                                    child: Text(
                                      drivingHabit,
                                      style: GoogleFonts.notoSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white, // 글자색을 흰색으로 설정
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: screenHeight * 0.020,
                  ),
                  FutureBuilder<NativeAd>(
                    future: _adFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF537A9B)), // 색상 코드 설정
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return const Center(child: Text('Failed to load ad'));
                      } else {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: screenWidth * 0.86666,
                                minWidth: screenWidth * 0.86666,
                                maxHeight: screenHeight * 0.14,
                                minHeight: screenHeight * 0.14),
                            child: AdWidget(ad: snapshot.data!),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //일반 이미지 업로드
  Widget buildPageContent(
      double screenWidth, double screenHeight, String imagePath, int index) {
    // 점수가 없거나 null, 혹은 index가 범위를 벗어날 때의 처리
    bool hasScore = index < drivingScore.length;
    String scoreText = hasScore ? '${drivingScore[index]}점' : '운전 이력 없음';
    double fontSize = hasScore ? 42.0 : 20.0; // 폰트 크기 조절

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 33),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '운전점수',
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.013),
                Text(
                  scoreText,
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize, // 동적 폰트 크기 적용
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                if (hasScore) ...[
                  // 조건부 렌더링을 사용하여 '운전 이력 없음'인 경우 숨김
                  SizedBox(
                    height: screenHeight * 0.04,
                    width: screenWidth * 0.283,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DrivingAnalysis(
                                drivingScore: drivingScore[index]),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        '운전분석',
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (hasScore) ...[
          // 조건부 렌더링을 사용하여 사진 업로드 부분도 숨김
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 28),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                width: screenWidth * 0.63,
                height: screenHeight * 0.202,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ],
    );
  }

  //누끼 제거 api 사용시
  Future<Widget> buildPageContentForAPi(
      double screenWidth, double screenHeight, String imagePath) async {
    final directory = (await getApplicationDocumentsDirectory()).path;
    final processedImagePath = '$directory/new/${imagePath.split('/').last}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 33),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '운전점수',
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.013),
                Text(
                  '${drivingScore[0]}점',
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 42,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                SizedBox(
                  height: screenHeight * 0.04,
                  width: screenWidth * 0.283,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DrivingAnalysis(drivingScore: drivingScore[0])),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      '운전분석',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 28),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(processedImagePath),
              width: screenWidth * 0.63,
              height: screenHeight * 0.202,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}
