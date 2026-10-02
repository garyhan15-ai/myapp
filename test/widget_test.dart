import 'package:flutter_test/flutter_test.dart';
import 'package:travel_map_app/models/visited_place.dart';

void main() {
  test('VisitedPlace JSON round trip', () {
    final place = VisitedPlace(
      id: '1',
      name: '경복궁',
      address: '서울 종로구',
      lat: 37.5796,
      lng: 126.977,
      visitedAt: DateTime(2026, 5, 1),
      memo: '좋았음',
    );
    final restored = VisitedPlace.fromJson(place.toJson());
    expect(restored.name, '경복궁');
    expect(restored.visitedAt, DateTime(2026, 5, 1));
    expect(restored.memo, '좋았음');
  });
}
