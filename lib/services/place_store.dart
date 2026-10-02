import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/visited_place.dart';

/// 방문 기록을 기기 로컬(shared_preferences)에 JSON으로 저장한다.
class PlaceStore {
  static const _key = 'visited_places';

  Future<List<VisitedPlace>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => VisitedPlace.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<VisitedPlace> places) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(places.map((p) => p.toJson()).toList()));
  }
}
