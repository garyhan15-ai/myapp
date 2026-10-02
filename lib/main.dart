import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import 'screens/map_screen.dart';

/// 실행 시 `--dart-define=KAKAO_JS_KEY=발급받은키` 로 전달한다.
const _kakaoJsKey = String.fromEnvironment('KAKAO_JS_KEY');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AuthRepository.initialize(appKey: _kakaoJsKey);
  runApp(const TravelMapApp());
}

class TravelMapApp extends StatelessWidget {
  const TravelMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '여행 지도',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const MapScreen(),
    );
  }
}
