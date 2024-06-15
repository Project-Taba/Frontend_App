import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taba/config.dart';
import 'package:taba/screen/taba_main/driving_start_tab/calibration_screen.dart';
import 'package:taba/screen/taba_main/driving_start_tab/goal_finding_screen.dart';
import 'package:taba/screen/taba_main/taba_main_page.dart';
import 'package:taba/services/car_service.dart';
import 'package:taba/services/calibration_service.dart';
import 'package:taba/models/car_model.dart';

class DrivingStartScreen extends StatefulWidget {
  final int userId;

  const DrivingStartScreen({super.key, required this.userId});

  @override
  State<DrivingStartScreen> createState() => _DrivingStartState();
}

class _DrivingStartState extends State<DrivingStartScreen> {
  int? selectedCarId;
  String? selectedCarName;
  List<Car> cars = [];
  static const baseUrl = Config.baseUrl;
  final CarService carService = CarService(baseUrl: baseUrl);
  final CalibrationService calibrationService = CalibrationService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCarData();
  }

  Future<void> _fetchCarData() async {
    try {
      List<Car> fetchedCars = await carService.getCarsByUserId(widget.userId);
      setState(() {
        cars = fetchedCars;
        selectedCarId = cars.isNotEmpty ? cars[0].carId : null;
        selectedCarName = cars.isNotEmpty ? cars[0].carName : null;
        isLoading = false;
      });
    } catch (e) {
      print('Failed to fetch car data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkCalibrationAndProceed() async {
    if (selectedCarName != null) {
      try {
        final response = await calibrationService
            .getCalibrationsResponseByCarName(selectedCarName!);
        print(response);
        print('서버로부터 값 수신 성공');
        if (response['success'] == true &&
            response['data'] != null &&
            response['data'].isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => GoalFindingScreen(
                      carId: selectedCarId!,
                      userId: widget.userId,
                    )),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalibrationScreen(
                carId: selectedCarId!,
                baseUrl: calibrationService.baseUrl,
                userId: widget.userId,
              ),
            ),
          );
        }
      } catch (e) {
        print('Failed to check calibration: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double containerHeight = MediaQuery.of(context).size.height * 0.233;
    double buttonHeight = containerHeight * 0.25;

    return Scaffold(
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF537A9B)), // 색상 코드 설정
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: MediaQuery.of(context).size.width * 0.755,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        Text(
                          "오늘은 어떤 차로 운전할까요?",
                          style: GoogleFonts.notoSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 0.5),
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: selectedCarId,
                            style: GoogleFonts.notoSans(
                                fontSize: 18,
                                color: Colors.grey), // Style for selected item
                            icon: const Icon(Icons
                                .keyboard_arrow_down_outlined), // Custom dropdown icon
                            iconSize: 36, // Icon size
                            iconEnabledColor: const Color(
                                0xFF434343), // Icon color when enabled
                            dropdownColor: Colors.white,
                            underline: Container(), // Removes underline
                            items: cars.map<DropdownMenuItem<int>>((Car car) {
                              return DropdownMenuItem<int>(
                                value: car.carId,
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: Colors.grey[300]!)),
                                  ),
                                  child: Text(car.carName,
                                      style: GoogleFonts.notoSans(
                                          fontSize: 16, color: Colors.black)),
                                ),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              setState(() {
                                if (newValue != null &&
                                    newValue != selectedCarId) {
                                  Car selectedCarObject = cars.firstWhere(
                                      (car) => car.carId == newValue);
                                  cars.remove(selectedCarObject);
                                  cars.insert(0, selectedCarObject);
                                  selectedCarId = newValue;
                                  selectedCarName = selectedCarObject.carName;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Buttons container
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.755,
                    height: buttonHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF14314A),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: const RoundedRectangleBorder(
                                side: BorderSide(color: Colors.black),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TabaMainScreen(
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            },
                            child: Text('닫기',
                                style: GoogleFonts.notoSans(
                                    fontSize: 16, color: Colors.white)),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF14314A),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: const RoundedRectangleBorder(
                                side: BorderSide(color: Colors.black),
                              ),
                            ),
                            onPressed: () {
                              _checkCalibrationAndProceed();
                            },
                            child: Text('확인',
                                style: GoogleFonts.notoSans(
                                    fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
