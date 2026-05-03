import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const HomeScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService _audioService = AudioService();
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  bool _isLoading = false;
  bool _hasResult = false;
  String _resultText = "";
  String _detailsText = "";

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // Ayrı widget karmaşasından kurtulup kamerayı doğrudan sayfaya entegre ediyoruz
  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;
    
    _cameraController = CameraController(widget.cameras[0], ResolutionPreset.max, enableAudio: false);
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Kamera başlatılamadı: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _audioService.stop();
    super.dispose();
  }

  Future<void> _takePhotoAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasResult = false;
      _resultText = "Yapay zeka çevreyi dinliyor, lütfen bekleyin...";
      _detailsText = "";
    });

    await _audioService.speakSystemMessage("Fotoğraf işleniyor, lütfen bekleyin.");

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      var result = await ApiService.analyzeImage(File(imageFile.path));

      if (result != null && result['status'] == 'success') {
        var data = result['data'];
        String description = data['description'] ?? "";
        String details = data['details'] ?? "";
        String audioUrl = data['audio_url'] ?? "";

        setState(() {
          _resultText = description;
          _detailsText = details;
          _isLoading = false;
          _hasResult = true;
        });

        String fullText = "$description $details";
        await _audioService.playAudioUrl(audioUrl, fullText);
      } else {
        _showError("Analiz başarısız oldu. Lütfen tekrar deneyin.");
      }
    } catch (e) {
      _showError("Kamera veya bağlantı hatası oluştu.");
    }
  }

  void _showError(String msg) {
    setState(() {
      _resultText = msg;
      _isLoading = false;
      _hasResult = true;
    });
    _audioService.speakSystemMessage(msg);
  }

  void _reset() async {
    _audioService.stop();
    setState(() {
      _hasResult = false;
      _isLoading = false;
      _isCameraInitialized = false;
    });
    // Android ImageReader çökmesini (NullPointerException) önlemek için kamerayı tazeliyoruz.
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    _initCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Koyu Mavi/Siyah Arka Plan
      appBar: AppBar(
        title: const Text(
          'VoiceGuide AI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.stop_circle, color: Colors.redAccent, size: 30),
            onPressed: () => _audioService.stop(),
            tooltip: "Sesi Sustur",
          )
        ],
      ),
      extendBodyBehindAppBar: true, // Uygulamayı tam ekran hissettirir
      body: Stack(
        children: [
          // 1. KATMAN: Kamera Önizlemesi (Ekranın tamamını kaplar)
          if (_isCameraInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),
            
          // 2. KATMAN: Karartma Filtresi (Arayüzün okunaklı olması için)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          // 3. KATMAN: Duruma Göre Değişen Dinamik UI
          SafeArea(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStateUI(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStateUI() {
    if (_isLoading) {
      return _buildLoadingUI();
    } else if (_hasResult) {
      return _buildResultUI();
    } else {
      return _buildCaptureUI();
    }
  }

  // --- UI BİLEŞENLERİ (Temiz Tasarım) ---

  Widget _buildCaptureUI() {
    return GestureDetector(
      onTap: _takePhotoAndAnalyze,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueAccent.withOpacity(0.85),
          border: Border.all(color: Colors.white, width: 8),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.6),
              blurRadius: 40,
              spreadRadius: 10,
            )
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, color: Colors.white, size: 60),
              SizedBox(height: 12),
              Text(
                "DOKUN\nVE ÇEK",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingUI() {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.95), // Yarı saydam koyu kart
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 5),
          const SizedBox(height: 24),
          Text(
            _resultText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultUI() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.95), // Yüksek Kontrastlı Siyah Kart
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "FİZİKSEL BETİMLEME",
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: "Fiziksel Betimleme",
              child: Text(
                _resultText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24, // Görme engelliler için çok büyük ve okunaklı font
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: Colors.white24, thickness: 1.5),
            ),
            
            if (_detailsText.isNotEmpty) ...[
              const Text(
                "TARİHİ & KÜLTÜREL DETAYLAR",
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: "Detaylar",
                child: Text(
                  _detailsText,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0), // Göz yormayan gri-beyaz
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 40),
            
            // Dev "Yeniden Çek" Butonu
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.camera_alt, size: 28),
                label: const Text(
                  "YENİ FOTOĞRAF ÇEK", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
