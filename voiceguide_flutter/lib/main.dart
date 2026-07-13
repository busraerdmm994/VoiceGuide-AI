import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Kamera başlatılamadı: $e');
  }
  
  final token = await ApiService.getToken();
  
  runApp(VoiceGuideApp(initialToken: token));
}

class VoiceGuideApp extends StatelessWidget {
  final String? initialToken;
  const VoiceGuideApp({super.key, this.initialToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoiceGuide AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: initialToken != null ? MainScreen(cameras: cameras) : const LoginScreen(),
    );
  }
}
