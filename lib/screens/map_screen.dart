import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../models/visited_place.dart';
import '../services/place_store.dart';
import 'place_list_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _store = PlaceStore();
  final _searchController = TextEditingController();
  KakaoMapController? _map;
  List<VisitedPlace> _places = [];

  @override
  void initState() {
    super.initState();
    _store.load().then((places) {
      if (mounted) setState(() => _places = places);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Marker> get _markers => [
        for (final p in _places)
          Marker(
            markerId: p.id,
            latLng: LatLng(p.lat, p.lng),
            infoWindowContent: p.name,
          ),
      ];

  Future<void> _persist() => _store.save(_places);

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addPlace({
    required String name,
    required String address,
    required LatLng latLng,
  }) async {
    final result = await showDialog<_PlaceFormResult>(
      context: context,
      builder: (_) => _PlaceFormDialog(
        title: '방문 기록 추가',
        name: name,
        visitedAt: DateTime.now(),
        memo: '',
      ),
    );
    if (result == null) return;
    final place = VisitedPlace(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: result.name,
      address: address,
      lat: latLng.latitude,
      lng: latLng.longitude,
      visitedAt: result.visitedAt,
      memo: result.memo,
    );
    setState(() => _places = [..._places, place]);
    await _persist();
  }

  Future<void> _editPlace(VisitedPlace place) async {
    final result = await showDialog<_PlaceFormResult>(
      context: context,
      builder: (_) => _PlaceFormDialog(
        title: '기록 수정',
        name: place.name,
        visitedAt: place.visitedAt,
        memo: place.memo,
      ),
    );
    if (result == null) return;
    setState(() {
      _places = [
        for (final p in _places)
          p.id == place.id
              ? p.copyWith(
                  name: result.name,
                  visitedAt: result.visitedAt,
                  memo: result.memo)
              : p,
      ];
    });
    await _persist();
  }

  Future<void> _deletePlace(VisitedPlace place) async {
    setState(() => _places = _places.where((p) => p.id != place.id).toList());
    await _map?.clearMarker(markerIds: [place.id]);
    await _persist();
  }

  Future<void> _search() async {
    final keyword = _searchController.text.trim();
    final map = _map;
    if (keyword.isEmpty || map == null) return;
    FocusScope.of(context).unfocus();
    try {
      final response =
          await map.keywordSearch(KeywordSearchRequest(keyword: keyword));
      if (!mounted) return;
      if (response.list.isEmpty) {
        _snack('검색 결과가 없어요');
        return;
      }
      final picked = await showModalBottomSheet<KeywordAddress>(
        context: context,
        builder: (_) => ListView(
          children: [
            for (final r in response.list)
              ListTile(
                title: Text(r.placeName ?? ''),
                subtitle: Text(r.roadAddressName?.isNotEmpty == true
                    ? r.roadAddressName!
                    : r.addressName ?? ''),
                onTap: () => Navigator.pop(context, r),
              ),
          ],
        ),
      );
      if (picked == null || picked.x == null || picked.y == null) return;
      final latLng =
          LatLng(double.parse(picked.y!), double.parse(picked.x!));
      await map.panTo(latLng);
      if (!mounted) return;
      await _addPlace(
        name: picked.placeName ?? keyword,
        address: picked.roadAddressName?.isNotEmpty == true
            ? picked.roadAddressName!
            : picked.addressName ?? '',
        latLng: latLng,
      );
    } catch (e) {
      _snack('검색에 실패했어요: $e');
    }
  }

  void _showDetail(VisitedPlace place) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.name,
                  style: Theme.of(context).textTheme.titleLarge),
              if (place.address.isNotEmpty) Text(place.address),
              const SizedBox(height: 8),
              Text('방문일: ${formatDate(place.visitedAt)}'),
              if (place.memo.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(place.memo),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _deletePlace(place);
                    },
                    child: const Text('삭제'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _editPlace(place);
                    },
                    child: const Text('수정'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openList() async {
    final selected = await Navigator.push<VisitedPlace>(
      context,
      MaterialPageRoute(builder: (_) => PlaceListScreen(places: _places)),
    );
    if (selected != null) {
      await _map?.panTo(LatLng(selected.lat, selected.lng));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('여행 지도 (${_places.length})'),
        actions: [
          IconButton(
            tooltip: '방문 목록',
            icon: const Icon(Icons.list),
            onPressed: _openList,
          ),
        ],
      ),
      body: Stack(
        children: [
          KakaoMap(
            center: LatLng(37.5665, 126.9780),
            currentLevel: 8,
            markers: _markers,
            onMapCreated: (c) => _map = c,
            onMarkerTap: (id, latLng, zoom) {
              final matches = _places.where((p) => p.id == id);
              if (matches.isNotEmpty) _showDetail(matches.first);
            },
            onMapLongPress: (latLng) {
              _addPlace(name: '', address: '', latLng: latLng);
            },
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: KakaoMapPointerInterceptor(
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(8),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: '장소 검색 (길게 누르면 지도에서 직접 추가)',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _search,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String formatDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

class _PlaceFormResult {
  final String name;
  final DateTime visitedAt;
  final String memo;
  const _PlaceFormResult(this.name, this.visitedAt, this.memo);
}

class _PlaceFormDialog extends StatefulWidget {
  final String title;
  final String name;
  final DateTime visitedAt;
  final String memo;

  const _PlaceFormDialog({
    required this.title,
    required this.name,
    required this.visitedAt,
    required this.memo,
  });

  @override
  State<_PlaceFormDialog> createState() => _PlaceFormDialogState();
}

class _PlaceFormDialogState extends State<_PlaceFormDialog> {
  late final _name = TextEditingController(text: widget.name);
  late final _memo = TextEditingController(text: widget.memo);
  late DateTime _date = widget.visitedAt;

  @override
  void dispose() {
    _name.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '장소 이름'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _memo,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '메모'),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('방문일: ${formatDate(_date)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
                context, _PlaceFormResult(name, _date, _memo.text.trim()));
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
