import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform; // Platform 클래스를 import합니다.
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:taba/config.dart';

class MyController extends GetxController {
  NativeAd? nativeAd;
  RxBool isAdLoaded = false.obs;
  late final String adUnitId; // adUnitId를 late로 선언합니다.

  @override
  void onInit() {
    super.onInit();
    // 플랫폼에 따라 adUnitId를 초기화
    adUnitId = Platform.isAndroid
        ? Config.AndroidAdUnitId // Android adUnitId
        : Config.IosAdUnitId; // iOS adUnitId
    loadAd();
  }

  // loadAd 함수
  Future<void> loadAd() async {
    nativeAd?.dispose(); // 기존 광고가 있으면 해제
    nativeAd = NativeAd(
        adUnitId: adUnitId,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            isAdLoaded.value = true;
            log("Ad Loaded");
          },
          onAdFailedToLoad: (ad, error) {
            log('Ad failed to load: ${error.message}');
            isAdLoaded.value = false;
            nativeAd?.dispose();
            nativeAd = null;
            // 실패 후 일정 시간 대기 후 재시도
            Future.delayed(const Duration(seconds: 5), () {
              loadAd();
            });
          },
        ),
        request: const AdRequest(),
        nativeTemplateStyle:
            NativeTemplateStyle(templateType: TemplateType.small));
    nativeAd!.load();
  }

  // 끄기 함수
  @override
  Future<void> dispose() async {
    nativeAd?.dispose();
    super.dispose();
  }
}
