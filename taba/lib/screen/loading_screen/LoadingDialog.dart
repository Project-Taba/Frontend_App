import 'package:flutter/material.dart';

class LoadingDialog {
  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 사용자가 다이얼로그 바깥을 터치해도 닫히지 않음
      barrierColor: Colors.transparent, // 다이얼로그의 배경을 투명하게 설정
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent, // 다이얼로그 내부 배경을 투명하게 설정
            elevation: 0, // 그림자 제거
            child: Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF537A9B)), // 색상 코드 설정
              ),
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
