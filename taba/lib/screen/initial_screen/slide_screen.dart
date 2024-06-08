import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taba/screen/login/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SlideScreen(),
    );
  }
}

class SlideScreen extends StatefulWidget {
  const SlideScreen({super.key});

  @override
  _SlideScreenState createState() => _SlideScreenState();
}

class _SlideScreenState extends State<SlideScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          PageView(
            controller: _controller,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: <Widget>[
              buildPage('assets/images/TABA_Information_01.png',
                  '언제 발생할지 모르는\n급발진 사고\n두렵지 않으신가요?'),
              buildPage('assets/images/TABA_Information_02.png',
                  'TABA에서는\n급발진 사고에 대한\n법적 근거 자료를 제공합니다.'),
              buildPage('assets/images/TABA_Information_03.png',
                  'TABA는 급발진 사고 발생 즉시\n응급 대처팀과 연결하여\n운전자의 안전을 고려합니다.'),
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/TABA_Information_04.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: screenWidth * 0.05555,
                      top: screenHeight * 0.11363,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'TABA?\n',
                              style: GoogleFonts.notoSans(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 22,
                              ),
                            ),
                            TextSpan(
                              text: '한번 ',
                              style: GoogleFonts.notoSans(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 22,
                              ),
                            ),
                            TextSpan(
                              text: '타봐!',
                              style: GoogleFonts.notoSans(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFE8A44B), // 노란색
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: 4,
                effect: const WormEffect(
                  dotWidth: 10.0,
                  dotHeight: 10.0,
                  activeDotColor: Color(0xFFE8A44B),
                  dotColor: Colors.white,
                  spacing: 16.0,
                ),
              ),
            ),
          ),
          if (_currentPage == _totalPages - 1)
            Positioned(
              bottom: 120,
              left: 30,
              right: 30,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: Color(0xFFE8A44B), width: 1), // 테두리 색상과 굵기
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6), // 모서리 둥글기
                  ),
                  backgroundColor: Colors.transparent, // 배경색 투명
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue',
                        style: TextStyle(
                          color: Color(0xFFE8A44B),
                          fontSize: 20,
                        )),
                    SizedBox(width: 200), // 텍스트 색상
                    Icon(Icons.keyboard_double_arrow_right,
                        size: 35, color: Color(0xFFE8A44B)), // 아이콘 색상
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildPage(String imagePath, String text) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.fill,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: screenWidth * 0.05555,
            top: screenHeight * 0.11363,
            child: Text(
              text,
              style: GoogleFonts.notoSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SocialLoginScreen extends StatelessWidget {
  const SocialLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Social Login"),
      ),
      body: const Center(
        child: Text("Welcome to the Social Login Screen!"),
      ),
    );
  }
}
