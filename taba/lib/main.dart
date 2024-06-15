import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:taba/config.dart';
import 'package:taba/screen/initial_screen/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

void main() async {
  //스플래쉬 화면
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  //세로 방향 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // 웹 환경에서 카카오 로그인을 정상적으로 완료하려면 runApp() 호출 전 아래 메서드 호출 필요
  WidgetsFlutterBinding.ensureInitialized();

  //구글 광고 기능 초기화 하기
  MobileAds.instance.initialize();
  //runApp() 메서드 호출 전에 카카오 Flutter SDK를 초기화해야 함
  KakaoSdk.init(
      nativeAppKey: Config.kakaoNativeAppKey,
      javaScriptAppKey: Config.kakaoJavascriptAppKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final String baseUrl = Config.baseUrl; // 여기에 baseUrl을 설정

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //앱 자체 언어 설정 함으로써 캘린더를 한국어로 변경
      localizationsDelegates: const [
        // 앱의 로컬라이제이션을 구성
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        // 앱에서 지원하는 언어 목록을 설정
        Locale('ko', 'KR'), // 한국어
      ],

      theme: ThemeData(
        dialogBackgroundColor: Colors.white, //다이얼로그 배경색을 흰색으로 설정
      ),
      home: const SplashScreen(), // 앱 초기화면
      routes: const {
        //라우터 추가
        //TabaMainScreen.routeName: (context) => const TabaMainScreen(),
      },
    );
  }
}
