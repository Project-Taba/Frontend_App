import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:taba/config.dart';
import 'package:taba/screen/taba_main/home_tab/car_add_information.dart';
import 'package:taba/screen/taba_main/my_page_tab/user_car_information.dart';
import 'package:taba/models/car_model.dart';
import 'package:taba/services/car_service.dart';
import 'package:taba/services/user_service.dart';
import 'package:taba/models/user_model.dart';
import 'dart:typed_data';

class MyPage extends StatefulWidget {
  final int userId;

  const MyPage({super.key, required this.userId});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  static const baseUrl = Config.baseUrl;
  final CarService carService = CarService(baseUrl: baseUrl);
  final UserService userService = UserService(baseUrl: baseUrl);

  List<Car?> carList = [null, null, null, null]; // 차량 정보를 저장할 리스트
  User? user; // 사용자 정보를 저장할 변수
  bool isLoading = true; // 로딩 상태를 나타내는 변수

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // 사용자 정보와 차량 정보 동시 가져오기
      final fetchedUser = await userService.fetchUserById(widget.userId);
      final cars = await carService.getCarsByUserId(widget.userId);

      setState(() {
        user = fetchedUser;
        for (var car in cars) {
          if (car.carId != null && car.carId! <= 4) {
            carList[car.carId! - 1] = car;
          }
        }
        isLoading = false; // 데이터 로딩 완료
      });
    } catch (e) {
      print('Failed to fetch data: $e');
      setState(() {
        isLoading = false; // 데이터 로딩 실패
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중 표시
          : Column(
              children: <Widget>[
                // 사용자 정보 컨테이너
                Container(
                  color: const Color(0xFF14314A),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  width: double.infinity,
                  child: user == null
                      ? const Text('사용자 정보를 불러올 수 없습니다.')
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              user!.name, // 여기서 user.name을 출력
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user!.email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                ),
                // 보유중 텍스트
                const Padding(
                  padding: EdgeInsets.only(left: 24, top: 28, bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '보유중',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // 이미지 그리드
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 148 / 172,
                    ),
                    itemCount: carList.length,
                    itemBuilder: (context, index) {
                      if (carList[index] != null) {
                        Uint8List photoBytes =
                            base64Decode(carList[index]!.photo);
                        return Hero(
                          tag: 'car_${carList[index]!.carId}',
                          child: Column(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UserCarInformation(
                                          userId: widget.userId,
                                          carId: carList[index]!.carId!,
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                    child: Image.memory(
                                      photoBytes,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserCarInformation(
                                        userId: widget.userId,
                                        carId: carList[index]!.carId!,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 36,
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF595959),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 12),
                                        child: Text(
                                          '정보수정',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(right: 12),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return GestureDetector(
                          onTap: () {
                            // CarAddInformation 페이지로 이동
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CarAddInformation(
                                  userId: widget.userId,
                                  carId: index + 1,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_circle_outline_sharp,
                                size: 40,
                                color: Color(0xFF595959),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
