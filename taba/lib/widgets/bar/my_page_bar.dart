import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts 패키지 추가

class MyPageBar extends StatelessWidget implements PreferredSizeWidget {
  const MyPageBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 1,
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: const Color(0xFFFFFFFF),
          title: Text(
            '내 정보',
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
          centerTitle: true, // 제목을 가운데로 ㄹ정렬
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_outlined),
            onPressed: () => Navigator.of(context).maybePop(), // 스택 뒤로가기 처리
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight); // AppBar의 선호하는 높이 설정
}
