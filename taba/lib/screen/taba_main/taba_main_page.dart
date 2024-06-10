import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taba/screen/taba_main/driving_log_tab/driving_log.dart';
import 'package:taba/screen/taba_main/driving_start_tab/driving_start_screen.dart';
import 'package:taba/screen/taba_main/home_tab/home_screen.dart';
import 'package:taba/screen/taba_main/my_page_tab/my_page_screen.dart';
import 'package:flutter/services.dart';
import 'package:taba/screen/taba_main/triggered_information_tab/triggered_information_sceen.dart';
import 'package:taba/widgets/bar/main_app_bar.dart';
import 'package:taba/widgets/bar/my_page_bar.dart';
import 'package:taba/widgets/bar/taba_drawer_menu_bar.dart';

class TabaMainScreen extends StatefulWidget {
  final int initialIndex;
  final int userId; // 사용자 ID를 받는 필드 추가

  const TabaMainScreen({Key? key, this.initialIndex = 0, required this.userId})
      : super(key: key);

  @override
  State<TabaMainScreen> createState() => _TabaMainScreenState();
}

class _TabaMainScreenState extends State<TabaMainScreen> {
  late int _selectedIndex;
  final GlobalKey<DrivingLogState> _drivingLogKey =
      GlobalKey<DrivingLogState>();
  final GlobalKey<TriggeredInformationScreenState> _triggeredInfoKey =
      GlobalKey<TriggeredInformationScreenState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  List<Widget> get _pages => [
        HomeScreen(userId: widget.userId), // userId를 전달
        DrivingStartScreen(userId: widget.userId), // userId를 전달
        DrivingLog(key: _drivingLogKey, userId: widget.userId),
        TriggeredInformationScreen(
            key: _triggeredInfoKey, userId: widget.userId), // 트리거 정보 화면 추가
        MyPage(userId: widget.userId), // userId를 전달
      ];

  PreferredSizeWidget? _getAppBar() {
    if (_selectedIndex == 4) {
      return const MyPageBar();
    }
    return const MainAppBar();
  }

  Widget? _getEndDrawer() {
    return _selectedIndex == 4
        ? null
        : TabaDrawerMenu(userId: widget.userId, selectPage: _selectPage);
  }

  void _selectPage(int index) {
    Navigator.of(context).pop();
    setState(() {
      _selectedIndex = index;
    });
    if (index == 2) {
      _drivingLogKey.currentState?.reloadLatestSession(); // null 체크 추가
    }
    if (index == 3) {
      _triggeredInfoKey.currentState?.reloadTriggeredInfo(); // null 체크 추가
    }
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex == 0) {
      bool? exitConfirmed = await showCustomExitDialog(context);
      if (exitConfirmed ?? false) {
        SystemNavigator.pop();
      }
      return false;
    } else {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }
  }

  Future<bool?> showCustomExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return Center(
          //Material 혹은 Scaffold로 처리해서 노란색 밑줄 제거
          child: Material(
            type: MaterialType.transparency,
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
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      '앱을 종료하시겠습니까?',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _dialogButton(dialogContext, '아니오',
                          () => Navigator.of(dialogContext).pop(false)),
                      _dialogButton(dialogContext, '예',
                          () => Navigator.of(dialogContext).pop(true)),
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

  Widget _dialogButton(
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: _getAppBar(),
        endDrawer: _getEndDrawer(),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFFE8A44B),
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 2) {
              _drivingLogKey.currentState?.reloadLatestSession();
            }
            if (index == 3) {
              _triggeredInfoKey.currentState?.reloadTriggeredInfo();
            }
          },
          items: [
            _buildBottomNavigationBarItem('home', '홈', 0),
            _buildBottomNavigationBarItem('car', '운전 시작', 1),
            _buildBottomNavigationBarItem('log', '운전 로그', 2),
            _buildBottomNavigationBarItem('alert', '급발진 사고', 3),
            _buildBottomNavigationBarItem('mypage', '마이 페이지', 4),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem(
      String iconName, String label, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return BottomNavigationBarItem(
      icon: SizedBox(
        width: screenWidth / 5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 2,
              color: _selectedIndex == index
                  ? const Color(0xFFE8A44B)
                  : Colors.grey,
            ),
            SizedBox(
              height: screenHeight * 0.0171875,
            ),
            Image.asset(
              'assets/images/${iconName}_${_selectedIndex == index ? "active" : "inactive"}.png',
              width: 28,
              height: 28,
            ),
          ],
        ),
      ),
      label: label,
    );
  }
}
