import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taba/ads_controller.dart';
import 'package:taba/services/kakao_local_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final myContr = Get.put(MyController(), tag: "search");
  final TextEditingController _searchController = TextEditingController();
  final KakaoLocalService kakaoService = KakaoLocalService();
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _searchHistory = [];
  List<String> _searchDates = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
      _searchDates = prefs.getStringList('search_dates') ?? [];
    });
  }

  Future<void> _saveSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
    await prefs.setStringList('search_dates', _searchDates);
  }

  Future<void> _searchPlaces(String query) async {
    try {
      final results =
          await kakaoService.searchKeyword(37.5665, 126.9780, query);
      setState(() {
        _searchResults = results;
        _query = query;
      });
    } catch (e) {
      print('Error searching places: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _addToSearchHistory(String placeName) async {
    setState(() {
      final currentDate = DateFormat('MM.dd').format(DateTime.now());
      if (!_searchHistory.contains(placeName)) {
        _searchHistory.insert(0, placeName);
        _searchDates.insert(0, currentDate);
        _saveSearchHistory();
      }
    });
  }

  Future<void> _removeFromSearchHistory(String query, int index) async {
    setState(() {
      _searchHistory.removeAt(index);
      _searchDates.removeAt(index);
    });
    await _saveSearchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "장소, 버스, 지하철, 주소 검색",
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults.clear();
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              _searchPlaces(value);
            } else {
              setState(() {
                _searchResults.clear();
              });
            }
          },
        ),
      ),
      body: Column(
        children: [
          Obx(() {
            if (myContr.isAdLoaded.value) {
              return Container(
                color: Colors.grey[200],
                height: 100, // 광고 높이 조정
                child: AdWidget(ad: myContr.nativeAd!),
              );
            } else {
              return Container(
                color: Colors.grey[200],
                height: 100,
                child: Center(
                  child: Text(
                    '광고 로드 중...',
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            }
          }),
          Divider(
            color: Colors.grey[300],
            thickness: 1,
            height: 1,
          ),
          if (_searchResults.isEmpty) _buildSearchHistory(),
          if (_searchResults.isNotEmpty) Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Expanded(
      child: ListView.builder(
        itemCount: _searchHistory.length,
        itemBuilder: (context, index) {
          final history = _searchHistory[index];
          final date = _searchDates[index];
          return Column(
            children: [
              ListTile(
                leading: Icon(Icons.search, color: Colors.grey[650]),
                title: Text(
                  history,
                  style: GoogleFonts.notoSans(
                    fontSize: 15,
                    color: Colors.grey[650],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      date,
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Colors.grey[500],
                      ),
                      onPressed: () {
                        _removeFromSearchHistory(history, index);
                      },
                    ),
                  ],
                ),
                onTap: () async {
                  final results = await kakaoService.searchKeyword(
                      37.5665, 126.9780, history);
                  if (results.isNotEmpty) {
                    Navigator.pop(context, {
                      'query': history,
                      'result': results.first,
                    });
                  }
                },
              ),
              Divider(
                color: Colors.grey[300],
                thickness: 1,
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final place = _searchResults[index];
        return ListTile(
          leading: const Icon(Icons.place),
          title: Text(place['place_name']),
          subtitle: Text(place['address_name']),
          trailing: Text('${place['distance']}m'),
          onTap: () {
            _addToSearchHistory(place['place_name']);
            Navigator.pop(
                context, {'query': place['place_name'], 'result': place});
          },
        );
      },
    );
  }
}
