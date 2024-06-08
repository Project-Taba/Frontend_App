import 'package:flutter/material.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:taba/config.dart';
import 'package:taba/models/car_model.dart';
import 'package:taba/screen/loading_screen/LoadingDialog.dart';
import 'package:taba/screen/login/service/kako_login_service.dart';
import 'package:taba/screen/login/service/login_platform.dart';
import 'package:taba/screen/login/service/naver_login_service.dart';
import 'package:taba/services/user_service.dart';
import 'package:taba/services/car_service.dart';
import 'package:taba/models/user_model.dart' as taba;
import 'package:taba/screen/login/sign_up_screen.dart';
import 'package:taba/screen/taba_main/taba_main_page.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  LoginPlatform _loginPlatform = LoginPlatform.none;
  final UserService userService = UserService(baseUrl: Config.baseUrl);
  final CarService carService = CarService(baseUrl: Config.baseUrl);

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/TABA_SignIn_01.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: screenHeight * 0.33125,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Welcome to TABA!',
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 36,
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.45625,
              left: 0,
              right: 0,
              child: Center(
                child: kakaoLoginButton(context),
              ),
            ),
            Positioned(
              top: screenHeight * 0.571875,
              left: 0,
              right: 0,
              child: Center(
                child: naverLoginButton(),
              ),
            ),
            // Positioned(
            //   top: screenHeight * 0.7,
            //   left: 0,
            //   right: 0,
            //   child: Center(
            //     child: testLoginButton(context),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget naverLoginButton() {
    return GestureDetector(
      onTap: () => signInWithNaver(),
      child: Image.asset(
        'assets/images/naver_login.png',
        width: 229,
        height: 60,
        fit: BoxFit.fill,
      ),
    );
  }

  Widget kakaoLoginButton(BuildContext context) {
    return GestureDetector(
      onTap: () => signInWithKakao(context),
      child: Image.asset(
        'assets/images/kakao_login.png',
        width: 240,
        height: 67.5,
        fit: BoxFit.fill,
      ),
    );
  }

  // Widget testLoginButton(BuildContext context) {
  //   return GestureDetector(
  //     onTap: () => signInForTest(context),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
  //       decoration: BoxDecoration(
  //         color: Colors.grey[800],
  //         borderRadius: BorderRadius.circular(5),
  //       ),
  //       child: const Text(
  //         '테스트 로그인',
  //         style: TextStyle(color: Colors.white, fontSize: 16),
  //       ),
  //     ),
  //   );
  // }

  //네이버로 로그인하기
  Future<void> signInWithNaver() async {
    LoadingDialog.show(context);
    NaverLoginService naverLoginService = NaverLoginService();
    try {
      Map<String, dynamic>? userInfo =
          await naverLoginService.getNaverAccountInfo();
      if (userInfo == null) {
        throw Exception('Failed to receive Naver user info');
      }
      String? jwtAccessToken =
          await naverLoginService.sendNaverUserInfoToServer(userInfo);
      if (jwtAccessToken == null) {
        throw Exception('Failed to receive JWT token from server');
      }
      setState(() {
        _loginPlatform = LoginPlatform.naver;
      });

      // 서버에서 사용자 정보를 가져옴
      taba.User user = await userService.fetchUserByAccessToken(jwtAccessToken);

      // 사용자의 차량 정보를 가져옴
      List<Car> cars = await carService.getCarsByUserId(user.id);

      if (!mounted) return; // context 사용 전에 mounted 확인
      LoadingDialog.hide(context);

      if (cars.isEmpty) {
        // 차량 정보가 없으면 SignUpScreen으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SignUpScreen(userId: user.id),
          ),
        );
      } else {
        // 차량 정보가 있으면 메인 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TabaMainScreen(userId: user.id),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      showAlertDialog(context, '로그인 실패',
          '로그인에 실패했습니다. 서버나 네트워크 문제가 있을 수 있으니 잠시 후 다시 시도하거나 관리자에게 문의해주세요.010-1234-5678 (에러코드: $e)');
    }
  }

  //카카오로 로그인하기
  Future<void> signInWithKakao(BuildContext context) async {
    LoadingDialog.show(context);
    KakaoLoginService kakaoLoginService = KakaoLoginService();
    try {
      //인가코드 받기
      final authCode = await kakaoLoginService.getAuthCodeWithKakaoAccount();
      //엑세스 토큰 받기
      final accessToken =
          await kakaoLoginService.sendKakaoAuthCodeToServer(authCode);

      if (accessToken != null) {
        setState(() {
          _loginPlatform = LoginPlatform.kakao;
        });

        // 서버에서 사용자 정보를 가져옴
        taba.User user = await userService.fetchUserByAccessToken(accessToken);

        // 사용자의 차량 정보를 가져옴
        List<Car> cars = await carService.getCarsByUserId(user.id);

        if (!mounted) return; // context 사용 전에 mounted 확인
        LoadingDialog.hide(context);

        if (cars.isEmpty) {
          // 차량 정보가 없으면 SignUpScreen으로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SignUpScreen(userId: user.id),
            ),
          );
        } else {
          // 차량 정보가 있으면 메인 화면으로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TabaMainScreen(userId: user.id),
            ),
          );
        }
      } else {
        throw Exception('taba서버로 부터 JWT accessToken 발급받지 못했습니다.');
      }
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      showAlertDialog(context, '로그인 실패',
          '로그인에 실패했습니다. 서버나 네트워크 문제가 있을 수 있으니 잠시 후 다시 시도하거나 관리자에게 문의해주세요.010-1234-5678 ($e)');
    }
  }

  void showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF537A9B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          content: Text(message,
              style: const TextStyle(color: Colors.white70, fontSize: 18)),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF285373)),
              child: const Text('확인', style: TextStyle(fontSize: 16)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
