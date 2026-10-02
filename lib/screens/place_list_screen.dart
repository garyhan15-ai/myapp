import 'package:flutter/material.dart';

import '../models/visited_place.dart';
import 'map_screen.dart' show formatDate;

/// 방문한 장소를 최근 방문일 순으로 보여주고, 탭하면 지도에서 해당 위치로 이동한다.
class PlaceListScreen extends StatelessWidget {
  final List<VisitedPlace> places;

  const PlaceListScreen({super.key, required this.places});

  @override
  Widget build(BuildContext context) {
    final sorted = [...places]
      ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
    return Scaffold(
      appBar: AppBar(title: const Text('방문 목록')),
      body: sorted.isEmpty
          ? const Center(child: Text('아직 기록이 없어요'))
          : ListView(
              children: [
                for (final p in sorted)
                  ListTile(
                    leading: const Icon(Icons.place),
                    title: Text(p.name),
                    subtitle: Text(
                        [formatDate(p.visitedAt), if (p.memo.isNotEmpty) p.memo]
                            .join(' · ')),
                    onTap: () => Navigator.pop(context, p),
                  ),
              ],
            ),
    );
  }
}
