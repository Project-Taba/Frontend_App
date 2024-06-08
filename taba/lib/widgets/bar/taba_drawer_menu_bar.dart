import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taba/config.dart';
import 'package:taba/screen/login/login_screen.dart';
import 'package:taba/screen/taba_main/driving_log_tab/driving_log.dart';
import 'package:taba/screen/taba_main/driving_start_tab/driving_start_screen.dart';
import 'package:taba/screen/taba_main/my_page_tab/my_page_screen.dart';
import 'package:taba/services/user_service.dart';
import 'package:taba/models/user_model.dart';

class TabaDrawerMenu extends StatefulWidget {
  final Function(int) selectPage;
  final int userId;
  const TabaDrawerMenu(
      {Key? key, required this.selectPage, required this.userId})
      : super(key: key);

  @override
  _TabaDrawerMenuState createState() => _TabaDrawerMenuState();
}

class _TabaDrawerMenuState extends State<TabaDrawerMenu> {
  static const baseUrl = Config.baseUrl;
  final UserService userService = UserService(baseUrl: baseUrl);
  User? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final fetchedUser = await userService.fetchUserById(widget.userId);
      setState(() {
        user = fetchedUser;
        isLoading = false;
      });
    } catch (e) {
      print('Failed to fetch user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            DrawerHeader(
              margin: EdgeInsets.zero,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading
                          ? '로딩 중...'
                          : '${user?.name ?? '이름 없음'}님 안녕하세요!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      user?.email ?? '이메일 없음',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      '운전 시작',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () => widget.selectPage(1),
                  ),
                  ListTile(
                    title: Text(
                      '운전 로그',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () => widget.selectPage(2),
                  ),
                  ListTile(
                    title: Text(
                      '급발진 사고',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () => widget.selectPage(3),
                  ),
                  ListTile(
                    title: Text(
                      '마이 페이지',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () => widget.selectPage(4),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(
                thickness: 2,
                height: 1,
                color: Color(0xFFD9D9D9),
              ),
            ),
            ListTile(
              title: Text(
                '로그아웃',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFFBFBFBF),
                ),
              ),
              //로그아웃
              onTap: () => showCustomLogoutDialog(context),
            ),
            SizedBox(
              height: screenHeight * 0.0681,
            )
          ],
        ),
      ),
    );
  }

  void showCustomLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54, // 배경색을 회색으로 설정
      builder: (BuildContext dialogContext) {
        return Center(
          child: Container(
            width: MediaQuery.of(dialogContext).size.width * 0.75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
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
                  child: Text(
                    "로그아웃 하시겠습니까?",
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _logoutButton(dialogContext, '취소',
                        () => Navigator.of(dialogContext).pop()),
                    _logoutButton(dialogContext, '로그아웃', () {
                      Navigator.of(dialogContext).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _logoutButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14314A),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
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
}
