import 'package:flutter/material.dart';

class SubAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SubAppBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        //appbar하단에 그림자 표시
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          //앱바와 페이지의 구분을 주기 위해 BoxShadow로 그림자 만들어서 사용.
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
            ),
          ],
        ),
        child: AppBar(
          automaticallyImplyLeading: false, //뒤로가기 없애기
          backgroundColor: Colors.white,
          // AppBar가 주로 사용하는 영역을 설정
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 로고 이미지
              Image.asset('assets/images/taba.jpeg', height: 22.6),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
