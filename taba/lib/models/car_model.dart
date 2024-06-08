class Car {
  final int? carId;
  final String carName;
  final String carSize;
  final int totalDistance;
  final String carNumber;
  final String photo;
  final int userId;
  final String insurance;
  final String purchaseDate;
  final int? drivingScore;

  Car({
    this.carId,
    required this.carName,
    required this.carSize,
    required this.totalDistance,
    required this.carNumber,
    required this.photo,
    required this.userId,
    required this.insurance,
    required this.purchaseDate,
    this.drivingScore,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      carId: json['carId'] as int?,
      carName: json['carName'] as String,
      carSize: json['carSize'] as String,
      totalDistance: json['totalDistance'] as int,
      carNumber: json['carNumber'] as String,
      photo: json['photo'] as String,
      userId: json['userId'] as int,
      insurance: json['insurance'] as String,
      purchaseDate: json['purchaseDate'] as String,
      drivingScore: json['drivingScore'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carId': carId,
      'carName': carName,
      'carSize': carSize,
      'totalDistance': totalDistance,
      'carNumber': carNumber,
      'photo': photo,
      'userId': userId,
      'insurance': insurance,
      'purchaseDate': purchaseDate,
      'drivingScore': drivingScore,
    };
  }
}
