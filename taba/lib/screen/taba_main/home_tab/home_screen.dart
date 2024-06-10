import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:taba/ads_controller.dart';
import 'package:taba/config.dart';
import 'package:taba/models/car_model.dart';
import 'package:taba/screen/taba_main/home_tab/car_add_information.dart';
import 'package:taba/screen/taba_main/my_page_tab/user_car_information.dart';
import 'package:taba/services/car_service.dart';
import 'dart:convert';
import 'dart:typed_data';

class HomeScreen extends StatefulWidget {
  final int userId;
  static const String routeName = '/home';

  const HomeScreen({super.key, required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const baseUrl = Config.baseUrl;
  final PageController _pageController = PageController(viewportFraction: 0.8);
  final CarService carService = CarService(baseUrl: baseUrl);
  List<Car?> carList = [null, null, null, null];
  late Future<List<Car?>> _carListFuture;
  late Future<NativeAd> _adFuture;

  @override
  void initState() {
    super.initState();
    _carListFuture = _fetchCarData();
    _adFuture = _loadAd();
  }

  Future<List<Car?>> _fetchCarData() async {
    try {
      List<Car> cars = await carService.getCarsByUserId(widget.userId);
      for (var car in cars) {
        if (car.carId != null && car.carId! <= 4) {
          carList[car.carId! - 1] = car;
        }
      }
      return carList;
    } catch (e) {
      print('Failed to fetch car data: $e');
      return carList;
    }
  }

  Future<NativeAd> _loadAd() async {
    final Completer<NativeAd> completer = Completer();
    final ad = NativeAd(
      adUnitId:
          Platform.isAndroid ? Config.AndroidAdUnitId : Config.IosAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          completer.complete(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          completer.completeError(error);
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle:
          NativeTemplateStyle(templateType: TemplateType.small),
    );
    ad.load();
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: screenHeight * 0.05375),
          FutureBuilder<List<Car?>>(
            future: _carListFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF537A9B)), // 색상 코드 설정
                  ),
                );
              } else if (snapshot.hasError) {
                return const Center(child: Text('Failed to load cars'));
              } else {
                return Center(
                  child: SizedBox(
                    height: screenHeight * 0.45375,
                    width: screenWidth * 0.86666,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double value = 1.0;
                            double offset = 0.0;
                            if (_pageController.position.haveDimensions) {
                              double pageOffset = _pageController.page ??
                                  _pageController.initialPage.toDouble();
                              pageOffset = pageOffset - index;
                              value = (1 - (pageOffset.abs() * 0.15))
                                  .clamp(0.5, 1.0);

                              if (pageOffset > 0) {
                                offset = screenWidth * 0.25 * pageOffset;
                              } else if (pageOffset < 0) {
                                offset = screenWidth * 0.25 * pageOffset;
                              }
                            }
                            return Transform.scale(
                              scale: value,
                              child: Transform.translate(
                                offset: Offset(offset, 0),
                                child: Center(
                                  child: SizedBox(
                                    height: screenHeight * 0.45375,
                                    width: screenWidth * 0.5,
                                    child: child,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: snapshot.data![index] != null
                              ? carCard(snapshot.data![index]!, index)
                              : placeholderCard(index),
                        );
                      },
                    ),
                  ),
                );
              }
            },
          ),
          Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.03125),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: 4,
              effect: const WormEffect(
                dotWidth: 10.0,
                dotHeight: 10.0,
                activeDotColor: Color(0xFFE8A44B),
                dotColor: Color(0xFFD9D9D9),
                spacing: 16.0,
              ),
            ),
          ),
          SizedBox(
            height: screenHeight * 0.03125,
          ),
          FutureBuilder<NativeAd>(
            future: _adFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF537A9B)), // 색상 코드 설정
                  ),
                );
              } else if (snapshot.hasError) {
                return const Center(child: Text('Failed to load ad'));
              } else {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: screenWidth * 0.86666,
                        minWidth: screenWidth * 0.86666,
                        maxHeight: screenHeight * 0.16,
                        minHeight: screenHeight * 0.16),
                    child: AdWidget(ad: snapshot.data!),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget carCard(Car car, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    Uint8List photoBytes = base64Decode(car.photo);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserCarInformation(
              carId: car.carId!,
              userId: widget.userId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            SizedBox(height: screenHeight * 0.0125),
            Text(
              car.carName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Hero(
              tag: 'car_${car.carId}_$index',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  photoBytes,
                  fit: BoxFit.cover,
                  width: screenWidth * 0.388889,
                  height: screenHeight * 0.2875,
                ),
              ),
            ),
            Container(
              height: screenHeight * 0.05,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xff213e57),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 14),
                    child: Text(
                      '정보수정',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget placeholderCard(int index) {
    double width = MediaQuery.of(context).size.width * 0.8;
    double height = MediaQuery.of(context).size.width * 0.1;

    return GestureDetector(
      onTap: () {
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
        width: width,
        height: height,
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
}
