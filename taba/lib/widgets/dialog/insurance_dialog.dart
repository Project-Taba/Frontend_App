import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InsuranceDialog extends StatefulWidget {
  final TextEditingController insuranceController;

  const InsuranceDialog({Key? key, required this.insuranceController})
      : super(key: key);

  @override
  _InsuranceDialogState createState() => _InsuranceDialogState();
}

class _InsuranceDialogState extends State<InsuranceDialog> {
  final List<String> _insuranceList = [
    '삼성화재 다이렉트 자동차보험',
    '현대해상 하이카 자동차 보험',
    'DB손해보험 다이렉트 자동차 보험',
    'KB손해보험 다이렉트 자동차 보험',
    '메리츠화재 다이렉트 자동차 보험',
    '한화손해보험 다이렉트 자동차 보험',
    '롯데손해보험 다이렉트 자동차 보험',
    '흥국화재 다이렉트 자동차 보험',
    'MG손해보험 다이렉트 자동차 보험',
    'NH농협손해보험 다이렉트 자동차 보험',
    '더케이손해보험 다이렉트 자동차 보험',
    'AXA 다이렉트 자동차 보험',
    'AIG 다이렉트 자동차 보험',
    '하나손해보험 다이렉트 자동차 보험',
    '캐롯 퍼마일 자동차 보험',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      backgroundColor: const Color.fromARGB(255, 105, 154, 195),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9, // 다이얼로그 폭 조정
          height: MediaQuery.of(context).size.height * 0.7,

          child: SingleChildScrollView(
            padding: const EdgeInsets.only(right: 2.0), // 스크롤바 여백 추가
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _insuranceList.map((insurance) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 45, 82, 115),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 5.0, // 버튼의 입체감을 높이기 위해 그림자 추가
                      shadowColor: Colors.black54, // 그림자 색상
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(insurance);
                    },
                    child: Text(
                      insurance,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        fontSize: 16, // 제목 글꼴 크기 조정
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
