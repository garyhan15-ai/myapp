class VisitedPlace {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final DateTime visitedAt;
  final String memo;

  const VisitedPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.visitedAt,
    this.memo = '',
  });

  VisitedPlace copyWith({String? name, DateTime? visitedAt, String? memo}) {
    return VisitedPlace(
      id: id,
      name: name ?? this.name,
      address: address,
      lat: lat,
      lng: lng,
      visitedAt: visitedAt ?? this.visitedAt,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'visitedAt': visitedAt.toIso8601String(),
        'memo': memo,
      };

  factory VisitedPlace.fromJson(Map<String, dynamic> json) => VisitedPlace(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String? ?? '',
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        visitedAt: DateTime.parse(json['visitedAt'] as String),
        memo: json['memo'] as String? ?? '',
      );
}
