import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taba/models/car_model.dart';

class CarService {
  final String baseUrl;

  CarService({required this.baseUrl});

  // POST 요청: 새로운 차량 데이터를 서버에 전송
  Future<Map<String, dynamic>> addCar(Car car) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/cars'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(car.toJson()), // UTF-8 인코딩 사용
    );

    final responseData =
        json.decode(utf8.decode(response.bodyBytes)); // UTF-8 디코딩 사용

    if (responseData['success'] == true) {
      print('Car added successfully.');
      return {'success': true, 'data': Car.fromJson(responseData['data'])};
    } else {
      print('Failed to add car: ${responseData['error']}');
      return {'success': false, 'error': responseData['error']};
    }
  }

  // GET 요청: ID로 차량 데이터 조회
  Future<Car> getCarById(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/cars/$id'),
    );

    final responseData =
        json.decode(utf8.decode(response.bodyBytes)); // UTF-8 디코딩 사용

    if (responseData['success'] == true) {
      print(Car.fromJson(responseData['data']));

      return Car.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to fetch car: ${responseData['error']}');
    }
  }

  // PUT 요청: 차량 데이터 업데이트
  Future<Car> updateCar(String id, Car car) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/cars/$id'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(car.toJson()), // UTF-8 인코딩 사용
    );

    final responseData =
        json.decode(utf8.decode(response.bodyBytes)); // UTF-8 디코딩 사용

    if (responseData['success'] == true) {
      print(Car.fromJson(responseData['data']));
      print('Car updated successfully.');
      return Car.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to update car: ${responseData['error']}');
    }
  }

  // DELETE 요청: 차량 데이터 삭제
  Future<void> deleteCar(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/cars/$id'),
    );

    final responseData =
        json.decode(utf8.decode(response.bodyBytes)); // UTF-8 디코딩 사용

    if (responseData['success'] == true) {
      print('Car deleted successfully.');
    } else {
      throw Exception('Failed to delete car: ${responseData['error']}');
    }
  }

  // GET 요청: 사용자 ID로 모든 차량 데이터 조회
  Future<List<Car>> getCarsByUserId(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/cars/user/$userId'),
    );

    final responseData =
        json.decode(utf8.decode(response.bodyBytes)); // UTF-8 디코딩 사용

    if (responseData['success'] == true) {
      final List<dynamic> carListJson = responseData['data'];
      return carListJson.map((json) => Car.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch cars: ${responseData['error']}');
    }
  }

  // PUT 요청: 차량 점수 업데이트
  Future<Car> updateCarScore(String id, int newScore) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/cars/score/$id'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'driving_score': newScore}), // 점수만 업데이트
    );

    final responseData =
        json.decode(utf8.decode(response.bodyBytes)); // UTF-8 디코딩 사용

    if (responseData['success'] == true) {
      print('차 점수 업데이트 내용:');
      print('Data: ${responseData['data']['driving_score']}'); // 'data' 필드 출력
      return Car.fromJson(responseData['data']);
    } else {
      print('Failed to update car: ${responseData['error']}');
      throw Exception('Failed to update car: ${responseData['error']}');
    }
  }
}
