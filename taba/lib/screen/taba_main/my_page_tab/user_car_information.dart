import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taba/config.dart';
import 'package:taba/screen/taba_main/taba_main_page.dart';
import 'package:taba/services/car_service.dart';
import 'package:taba/models/car_model.dart';

class UserCarInformation extends StatefulWidget {
  final int userId;
  final int carId;

  const UserCarInformation({
    super.key,
    required this.userId,
    required this.carId,
  });

  @override
  State<UserCarInformation> createState() => _UserCarInformationState();
}

class _UserCarInformationState extends State<UserCarInformation> {
  TextEditingController carNameController = TextEditingController();
  TextEditingController carYearController = TextEditingController();
  TextEditingController insuranceInfoController = TextEditingController();
  TextEditingController carNumberController = TextEditingController();
  TextEditingController carSizeController = TextEditingController();
  String? currentImage;
  final int _selectedIndex = 3;
  static const baseUrl = Config.baseUrl;
  final CarService carService = CarService(baseUrl: baseUrl);

  @override
  void initState() {
    super.initState();
    _loadCarInformation();
  }

  void _selectPage(int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TabaMainScreen(
          initialIndex: index,
          userId: widget.userId,
        ),
      ),
    );
  }

  Future<void> _loadCarInformation() async {
    try {
      Car car = await carService.getCarById(widget.carId.toString());
      setState(() {
        carNameController.text = car.carName;
        carYearController.text = car.purchaseDate.split('-')[0];
        insuranceInfoController.text = car.insurance;
        carNumberController.text = car.carNumber;
        carSizeController.text = car.carSize;
        currentImage = car.photo;
      });
    } catch (e) {
      print('Failed to load car information: $e');
    }
  }

// 서버 업데이트 함수
  Future<void> _updateCarInformation() async {
    try {
      final car = Car(
          carId: widget.carId,
          carName: carNameController.text,
          carSize: selectedCarSize ?? carSizeController.text, // 서버로 보낼 값
          totalDistance: 0,
          carNumber: carNumberController.text,
          insurance: insuranceInfoController.text,
          userId: widget.userId,
          photo: currentImage ?? '',
          purchaseDate: '${carYearController.text}-01-01',
          drivingScore: 100);

      await carService.updateCar(widget.carId.toString(), car);
      _showSuccessDialog('차량 정보가 업데이트되었습니다.');
    } catch (e) {
      print('Failed to update car information: $e');
      _showErrorDialog('차량 정보 업데이트에 실패했습니다.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          backgroundColor: const Color.fromARGB(255, 242, 125, 104),
          content: Text(
            message,
            style: GoogleFonts.notoSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromARGB(255, 232, 99, 75),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '확인',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          backgroundColor: const Color.fromARGB(255, 244, 203, 150),
          content: Text(
            message,
            style: GoogleFonts.notoSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFE8A44B),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '확인',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 차량 사이즈를 매핑하기 위한 맵 변수 추가
  Map<String, String> carSizeMap = {
    '대형': 'LARGE',
    '중형': 'MEDIUM',
    '소형': 'SMALL'
  };

  /// 차량 사이즈 선택과 서버 전송 값을 관리하기 위한 변수
  String? selectedCarSize;

// 차량 사이즈 선택 다이얼로그
  Future<void> _showCarSizeDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // 다이얼로그 바깥을 터치하면 닫히도록 설정
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 231, 182, 118),
          title: Text(
            '차량 사이즈',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8A44B),
                  ),
                  onPressed: () {
                    selectedCarSize = 'LARGE';
                    carSizeController.text = '대형'; // 사용자에게 보여질 값
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    '대형',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8A44B),
                  ),
                  onPressed: () {
                    selectedCarSize = 'MEDIUM';
                    carSizeController.text = '중형';
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    '중형',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8A44B),
                  ),
                  onPressed: () {
                    selectedCarSize = 'SMALL';
                    carSizeController.text = '소형';
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    '소형',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 1,
              ),
            ],
          ),
          child: AppBar(
            title: Text(
              '정보수정',
              style: GoogleFonts.notoSans(
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
            backgroundColor: Colors.white,
            centerTitle: true,
            leading: IconButton(
              iconSize: 18,
              icon: const Icon(Icons.arrow_back_ios_outlined),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.066667),
          child: Column(
            children: <Widget>[
              SizedBox(height: screenHeight * 0.05),
              Hero(
                tag: 'car_${widget.carId}',
                child: GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: screenWidth * 0.18889,
                    backgroundImage: currentImage != null
                        ? MemoryImage(base64Decode(currentImage!))
                        : null,
                    child: currentImage == null
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : null,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              buildEditableField("차량 이름", carNameController),
              buildEditableField("연도", carYearController),
              buildEditableField("보험 정보", insuranceInfoController),
              buildEditableField("차량 번호", carNumberController),
              carSizeField(),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.066667,
                    vertical: screenHeight * 0.01875),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFE8A44B),
                    minimumSize: const Size(312, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _updateCarInformation,
                  child: Center(
                    child: Text(
                      '수정완료',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEditableField(String label, TextEditingController controller) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.0666667, vertical: screenHeight * 0.0125),
      child: SizedBox(
        width: double.infinity,
        height: screenHeight * 0.058,
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(
              color: Colors.black,
            ),
            border: InputBorder.none,
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF14314A), width: 2.0),
            ),
            suffixIcon: TextButton(
              onPressed: () {},
              child: Text(
                '수정',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w200,
                  color: const Color(0xFF8C8C8C),
                ),
              ),
            ),
            fillColor: const Color(0xFFF5F5F5),
            filled: true,
          ),
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        currentImage = base64Encode(bytes);
      });
    }
  }

// 텍스트 필드의 테두리 제거 및 UI 수정
  Widget carSizeField() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.0666667, vertical: screenHeight * 0.0125),
      child: SizedBox(
        width: double.infinity,
        height: screenHeight * 0.058,
        child: TextField(
          controller: carSizeController,
          decoration: const InputDecoration(
            hintText: "차량 사이즈 선택",
            hintStyle: TextStyle(color: Colors.black),
            border: InputBorder.none,
            filled: true,
            fillColor: Color(0xFFF5F5F5),
          ),
          readOnly: true,
          onTap: _showCarSizeDialog,
        ),
      ),
    );
  }
}
