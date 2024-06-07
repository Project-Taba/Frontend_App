import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class YesNoDialog {
  final BuildContext context;
  final String message;
  final String yesText;
  final String noText;
  final VoidCallback onYesPressed;
  final VoidCallback onNoPressed;

  YesNoDialog({
    required this.context,
    required this.message,
    required this.yesText,
    required this.noText,
    required this.onYesPressed,
    required this.onNoPressed,
  });

  void show() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54, // 배경색을 회색으로 설정
      builder: (BuildContext dialogContext) {
        return Center(
          // 화면 가운데에 위치
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: MediaQuery.of(dialogContext).size.width * 0.755,
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
                      message,
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _dialogButton(dialogContext, noText, onNoPressed),
                      _dialogButton(dialogContext, yesText, onYesPressed),
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
}
