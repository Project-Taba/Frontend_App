import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:taba/config.dart';

//누끼 따는 api_client 메서드
class ApiClient {
  //List<String> carImages: 최대 4까지 사용자 차량 이미지를 파라미터로 설정
  Future<void> removeBackgroundAndSave(List<String> carImages) async {
    final directory = await getApplicationDocumentsDirectory();
    final newPath = Directory('${directory.path}/new');
    if (!await newPath.exists()) {
      await newPath.create(recursive: true);
    }

    for (String imagePath in carImages) {
      //이미지명(경로를 '/'으로 구분하고, 맨마지막 이름)
      String imageName = imagePath.split('/').last;
      // 몇 바이트인지
      var bytes = await rootBundle.load(imagePath);
      // 바이트단위의 버퍼
      var buffer = bytes.buffer;

      var unit8List =
          buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
      //요청값
      var request = http.MultipartRequest(
          'POST', Uri.parse('https://api.remove.bg/v1.0/removebg'));
      request.files.add(http.MultipartFile.fromBytes('image_file', unit8List,
          filename: imageName));
      request.fields['size'] = 'auto';
      request.headers['X-Api-Key'] = Config.backGroundRemoveApiKey;

      //요청의 응답값
      var response = await request.send();

      //응답 성공시
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        File file = File('${newPath.path}/$imageName');
        await file.writeAsBytes(responseData);
        print("$imageName saved successfully in ${newPath.path}.");
      } else {
        print("Failed to remove background from $imageName.");
      }
    }
  }
}
