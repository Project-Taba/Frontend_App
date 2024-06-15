import 'dart:convert';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taba/config.dart';
import 'package:taba/models/car_model.dart';
import 'package:taba/screen/taba_main/taba_main_page.dart';
import 'package:taba/services/car_service.dart';
import 'package:taba/widgets/bar/sub_app_bar.dart';
import 'package:taba/widgets/dialog/custom_alter_dialog.dart';
import 'package:taba/widgets/dialog/insurance_dialog.dart';
import 'package:taba/widgets/dialog/yes_no.dart';

class CarAddInformation extends StatefulWidget {
  final int userId;
  final int carId;

  const CarAddInformation({Key? key, required this.userId, required this.carId})
      : super(key: key);

  @override
  _CarAddInformationState createState() => _CarAddInformationState();
}

class _CarAddInformationState extends State<CarAddInformation> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _carController = TextEditingController();
  final TextEditingController _insuranceController = TextEditingController();
  final TextEditingController _carNumberController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();

  String? _selectedCarType;
  File? _selectedImage;
  String? _base64Image;
  static const baseUrl = Config.baseUrl;
  final CarService carService = CarService(baseUrl: baseUrl);

  @override
  void dispose() {
    _dateController.dispose();
    _carController.dispose();
    _insuranceController.dispose();
    _carNumberController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 15);
    final DateTime lastDate =
        DateTime(now.year + 3); // 이제 lastDate는 현재 연도로부터 10년 후
    final ThemeData customTheme = ThemeData(
      primaryColor: const Color(0xFF093d57),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF093d57),
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      dialogBackgroundColor: Colors.white,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF093d57),
        ),
      ),
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now, // initialDate를 현재 날짜로 설정
      firstDate: firstDate, //15년전
      lastDate: lastDate, //3년후
      locale: const Locale('ko', 'KR'), // 한국어 설정
      helpText: '구매 날짜 선택',
      cancelText: '취소',
      confirmText: '확인',
      builder: (context, child) {
        return Theme(
          data: customTheme,
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        _selectedImage = File(image.path);
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _signUp() async {
    // 차량 크기 변환 함수
    String convertCarSize(String carSize) {
      switch (carSize) {
        case '소형':
          return 'SMALL';
        case '중형':
          return 'MEDIUM';
        case '대형':
          return 'LARGE';
        default:
          return '';
      }
    }

    bool validateFields() {
      print("Car: ${_carController.text}");
      print("Car Type: $_selectedCarType");
      print("Mileage: ${_mileageController.text}");
      print("Car Number: ${_carNumberController.text}");
      print("Insurance: ${_insuranceController.text}");
      print("Date: ${_dateController.text}");
      print("Image: $_base64Image");

      if (_carController.text.isEmpty ||
          _selectedCarType == null ||
          _mileageController.text.isEmpty ||
          _carNumberController.text.isEmpty ||
          _insuranceController.text.isEmpty ||
          _dateController.text.isEmpty ||
          _base64Image == null) {
        return false;
      }
      return true;
    }

// 필드가 비어있으면 다이얼로그 표시
    if (!validateFields()) {
      CustomAlertDialog(
        context: context,
        title: 'TABA',
        message: '모든 정보를 입력해야 합니다!',
      ).show();
      return;
    }

    // 모든 정보가 입력된 경우 확인 다이얼로그 표시
    YesNoDialog(
      context: context,
      message: '입력하신 정보가 맞으십니까?',
      yesText: '네',
      noText: '아니요',
      onYesPressed: () async {
        Navigator.of(context).pop();

        final car = Car(
            carName: _carController.text,
            carSize: convertCarSize(_selectedCarType ?? ''),
            totalDistance: int.tryParse(_mileageController.text
                    .replaceAll('Km', '')
                    .replaceAll(',', '')) ??
                0,
            carNumber: _carNumberController.text,
            insurance: _insuranceController.text,
            userId: widget.userId,
            photo: _base64Image ?? '',
            purchaseDate: _dateController.text,
            drivingScore: 100);

        try {
          final response = await carService.addCar(car);

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TabaMainScreen(userId: widget.userId),
            ),
          );
        } catch (e) {
          print('Failed to create car. Error: $e');
          CustomAlertDialog(
            context: context,
            title: '오류',
            message: '서버 오류가 발생했습니다.',
          ).show();
        }
      },
      onNoPressed: () => Navigator.of(context).pop(),
    ).show();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFB00020)),
            borderRadius: BorderRadius.circular(8.0),
          ),
          backgroundColor: Colors.white,
          content: Text(
            message,
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '확인',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  color: const Color(0xFFB00020),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: const SubAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06666),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.0375),
              const Text(
                '차량 사진을 업로드하세요.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              SizedBox(height: screenHeight * 0.0125),
              GestureDetector(
                onTap: _selectImage,
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(
                          _selectedImage!,
                          width: screenWidth * 0.8666667,
                          height: screenHeight * 0.25,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: screenWidth * 0.8666667,
                        height: screenHeight * 0.25,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Icon(
                          Icons.add_circle_outline_sharp,
                          size: 40,
                          color: Color(0xFF595959),
                        ),
                      ),
              ),
              SizedBox(height: screenHeight * 0.0125),
              const Text(
                '어떤 차를 소유하고 있나요?',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              SizedBox(height: screenHeight * 0.0125),
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.0584,
                child: TextField(
                  controller: _carController,
                  decoration: const InputDecoration(
                    hintText: 'Genesis GV80',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF14314A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF14314A), width: 2.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.01875),
              const Text(
                '언제 구매 하셨나요?',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              SizedBox(height: screenHeight * 0.0125),
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.0584,
                child: TextField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    hintText: '날짜 선택',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF14314A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF14314A), width: 2.0),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 16),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
              ),
              SizedBox(height: screenHeight * 0.01875),
              const Text(
                '어떤 보험에 가입 했나요?',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              SizedBox(height: screenHeight * 0.0125),
              InkWell(
                onTap: () async {
                  final selectedInsurance = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      return InsuranceDialog(
                          insuranceController: _insuranceController);
                    },
                  );

                  if (selectedInsurance != null) {
                    setState(() {
                      _insuranceController.text = selectedInsurance;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: screenHeight * 0.0584,
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _insuranceController.text.isEmpty
                            ? '삼성화재 자동차 다이렉트 보험'
                            : _insuranceController.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: _insuranceController.text.isEmpty
                              ? Colors.black45 // 선택 전 힌트 텍스트 색상
                              : Colors.black87, // 선택 후 텍스트 색상
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.01875),
              const Text(
                '차량 번호를 알려주세요.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              SizedBox(height: screenHeight * 0.0125),
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.0584,
                child: TextField(
                  controller: _carNumberController,
                  decoration: const InputDecoration(
                    hintText: '395누 2548',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF14314A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF14314A), width: 2.0),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 16),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.01875),
              const Text(
                '총 주행거리는 얼마인가요?',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              SizedBox(height: screenHeight * 0.0125),
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.0584,
                child: TextField(
                  controller: _mileageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(12),
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final newText = '${newValue.text.replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match match) => '${match[1]},',
                      )}Km';
                      return TextEditingValue(
                        text: newText,
                        selection:
                            TextSelection.collapsed(offset: newText.length - 2),
                      );
                    }),
                  ],
                  decoration: const InputDecoration(
                    hintText: '104300Km',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF14314A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF14314A), width: 2.0),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 16),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.01875),
              const Text(
                '차급은 어떻게 되나요?',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              SizedBox(height: screenHeight * 0.0125),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['소형', '중형', '대형'].map((carType) {
                  final isSelected = _selectedCarType == carType;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.01111),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCarType = carType;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? const Color(0xFF14314A)
                              : const Color(0xFFD9D9D9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          carType,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: screenHeight * 0.05),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, screenHeight * 0.07142),
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF213E57),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                ),
                onPressed: _signUp,
                child: const SizedBox(
                  width: double.infinity,
                  child: Text(
                    '차량 정보 입력하기',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.0125),
            ],
          ),
        ),
      ),
    );
  }
}
