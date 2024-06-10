class DirectionResponse {
  final int code;
  final String message;
  final String currentDateTime;
  final Map<String, List<Route>> route;

  DirectionResponse({
    required this.code,
    required this.message,
    required this.currentDateTime,
    required this.route,
  });

  factory DirectionResponse.fromJson(Map<String, dynamic> json) {
    return DirectionResponse(
      code: json['code'],
      message: json['message'],
      currentDateTime: json['currentDateTime'],
      route: (json['route'] as Map<String, dynamic>).map((key, value) {
        return MapEntry(
          key,
          List<Route>.from(value.map((item) => Route.fromJson(item))),
        );
      }),
    );
  }
}

class Summary {
  final Location start;
  final Location goal;
  final int distance;
  final int duration;
  final int tollFare;
  final int taxiFare;
  final int fuelPrice;

  Summary({
    required this.start,
    required this.goal,
    required this.distance,
    required this.duration,
    required this.tollFare,
    required this.taxiFare,
    required this.fuelPrice,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      start: Location.fromJson(json['start']),
      goal: Location.fromJson(json['goal']),
      distance: json['distance'],
      duration: json['duration'],
      tollFare: json['tollFare'],
      taxiFare: json['taxiFare'],
      fuelPrice: json['fuelPrice'],
    );
  }
}

class Location {
  final double lng;
  final double lat;

  Location({
    required this.lng,
    required this.lat,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lng: json['location'][0],
      lat: json['location'][1],
    );
  }
}

class Route {
  final Summary summary;
  final List<List<double>> path;
  final List<Section> sections;
  final List<Guide> guides;

  Route({
    required this.summary,
    required this.path,
    required this.sections,
    required this.guides,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      summary: Summary.fromJson(json['summary']),
      path: List<List<double>>.from(
          json['path'].map((item) => List<double>.from(item))),
      sections: List<Section>.from(
          json['sections'].map((item) => Section.fromJson(item))),
      guides:
          List<Guide>.from(json['guides'].map((item) => Guide.fromJson(item))),
    );
  }
}

class Section {
  final int pointIndex;
  final int pointCount;
  final int distance;
  final String name;
  final int congestion;
  final int speed;

  Section({
    required this.pointIndex,
    required this.pointCount,
    required this.distance,
    required this.name,
    required this.congestion,
    required this.speed,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      pointIndex: json['pointIndex'],
      pointCount: json['pointCount'],
      distance: json['distance'],
      name: json['name'],
      congestion: json['congestion'],
      speed: json['speed'],
    );
  }
}

class Guide {
  final int pointIndex;
  final int type;
  final String instructions;
  final int distance;
  final int duration;

  Guide({
    required this.pointIndex,
    required this.type,
    required this.instructions,
    required this.distance,
    required this.duration,
  });

  factory Guide.fromJson(Map<String, dynamic> json) {
    return Guide(
      pointIndex: json['pointIndex'],
      type: json['type'],
      instructions: json['instructions'],
      distance: json['distance'],
      duration: json['duration'],
    );
  }
}
