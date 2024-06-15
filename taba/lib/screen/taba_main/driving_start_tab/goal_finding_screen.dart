import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taba/screen/taba_main/driving_start_tab/driving_start_screen.dart';
import 'package:taba/screen/taba_main/driving_start_tab/navigation_screen.dart';
import 'package:taba/screen/taba_main/driving_start_tab/search_screen.dart';

class GoalFindingScreen extends StatefulWidget {
  final int carId;
  final int userId;

  const GoalFindingScreen({
    super.key,
    required this.carId,
    required this.userId,
  });

  @override
  _GoalFindingScreenState createState() => _GoalFindingScreenState();
}

class _GoalFindingScreenState extends State<GoalFindingScreen> {
  late GoogleMapController mapController;
  LatLng _initialPosition = const LatLng(37.5665, 126.9780); // 기본 서울 중심 좌표
  LatLng? _searchPosition;
  Marker? _searchMarker;
  Marker? _currentLocationMarker;
  bool _isLoading = true;
  String _searchQuery = '';
  String _distance = '';
  String _searchPlaceName = '';

  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor navigation = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    addCustomIcon();
    addCustomNavigationIcon();
    _getCurrentLocation();
  }

  // Custom marker
  void addCustomIcon() {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(), "assets/images/marker4.png")
        .then(
      (icon) {
        setState(() {
          markerIcon = icon;
        });
      },
    );
  }

  // Custom navigation marker
  void addCustomNavigationIcon() {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(), "assets/images/navigation3.png")
        .then(
      (icon) {
        setState(() {
          navigation = icon;
        });
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 위치 서비스가 비활성화된 경우 처리
      setState(() {
        _isLoading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // 위치 권한이 거부된 경우 처리
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 위치 권한이 영구적으로 거부된 경우 처리
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      _currentLocationMarker = Marker(
        markerId: const MarkerId('current_location'),
        position: _initialPosition,
        icon: navigation,
        infoWindow: InfoWindow(
          title: '',
          onTap: () {},
        ),
      );
      _isLoading = false;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _moveCameraToLocation(LatLng newPosition, String placeName) async {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: newPosition,
          zoom: 16.3,
        ),
      ),
    );

    setState(() {
      _searchPosition = newPosition;
      _searchPlaceName = placeName;
      _searchMarker = Marker(
        markerId: const MarkerId('search_result'),
        position: newPosition,
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: placeName,
          onTap: () {},
        ),
      );
    });
  }

  Future<bool> _onWillPop() async {
    showCustomNavigationCloseDialog(context);
    return false;
  }

  void showCustomNavigationCloseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: MediaQuery.of(dialogContext).size.width * 0.755,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "내비게이션을 종료 하시겠습니까?",
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavigationCloseButton(dialogContext, '취소', () {
                        Navigator.of(dialogContext).pop();
                      }),
                      _NavigationCloseButton(dialogContext, '네', () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pop();
                        // Navigator.pushReplacement(
                        //   context,
                        //   MaterialPageRoute(
                        //       builder: (context) =>
                        //           DrivingStartScreen(userId: widget.userId)),
                        // );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _NavigationCloseButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14314A),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: const BorderSide(
              color: Colors.black,
            ),
          ),
        ),
        onPressed: onPressed,
        child: Text(text,
            style: GoogleFonts.notoSans(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // 기능 버튼 (예: 현재 위치로 돌아가기)
            mapController.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: _initialPosition, zoom: 16.3),
              ),
            );
          },
          backgroundColor: Colors.white.withOpacity(0.9),
          foregroundColor: Colors.blue[500],
          child: const Icon(Icons.location_searching),
        ),
        floatingActionButtonLocation:
            CustomFabLocation(0.04, 0.25), // 위치 지정: 화면 왼쪽 아래쪽
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF537A9B)),
                ),
              )
            : Stack(
                children: <Widget>[
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _initialPosition,
                      zoom: 16.3,
                    ),
                    markers: {
                      if (_searchMarker != null) _searchMarker!,
                      if (_currentLocationMarker != null)
                        _currentLocationMarker!,
                    },
                    mapType: MapType.normal,
                  ),
                  Positioned(
                    top: 40,
                    left: 15,
                    right: 15,
                    child: _buildSearchField(context),
                  ),
                  if (_searchQuery.isNotEmpty)
                    Positioned(
                      bottom: 10,
                      left: 15,
                      right: 15,
                      child: _buildSearchResultInfo(context),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
        if (result != null) {
          final data = result as Map<String, dynamic>;
          final place = data['result'] as Map<String, dynamic>;
          final query = data['query'] as String;
          final lat = double.parse(place['y']);
          final lng = double.parse(place['x']);
          _moveCameraToLocation(LatLng(lat, lng), query);
          setState(() {
            _searchQuery = query;
            _distance = (Geolocator.distanceBetween(
                      _initialPosition.latitude,
                      _initialPosition.longitude,
                      lat,
                      lng,
                    ) /
                    1000)
                .toStringAsFixed(1);
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        child: Row(
          children: <Widget>[
            const Icon(Icons.search),
            const SizedBox(width: 10),
            Text(
              _searchQuery.isEmpty ? "목적지를 입력하세요" : _searchQuery,
              style: GoogleFonts.notoSans(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultInfo(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '검색된 위치와의 거리: $_distance km',
            style: GoogleFonts.notoSans(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[500],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.navigation,
              color: Colors.white,
            ),
            label: Text(
              '운전 시작',
              style: GoogleFonts.notoSans(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              // final sessionId = await _createDrivingSession();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => NavigationScreen(
                    currentLocation: _initialPosition,
                    destination: _searchMarker!.position,
                    carId: widget.carId,
                    userId: widget.userId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CustomFabLocation extends FloatingActionButtonLocation {
  final double x;
  final double y;

  CustomFabLocation(this.x, this.y);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // xOffset와 yOffset을 사용하여 버튼 위치 조정
    final double xOffset = x * scaffoldGeometry.scaffoldSize.width;
    final double yOffset = y * scaffoldGeometry.scaffoldSize.height;
    return Offset(xOffset, scaffoldGeometry.scaffoldSize.height - yOffset);
  }
}
