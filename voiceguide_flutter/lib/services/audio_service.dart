import 'package:audioplayers/audioplayers.dart';
import 'tts_service.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TtsService _ttsService = TtsService();

  /// Backend'den gelen mp3 URL'sini çalar. Eğer başarısız olursa yerel TTS'e (Fallback) düşer.
  Future<void> playAudioUrl(String url, String fallbackText) async {
    try {
      if (url.isEmpty) {
        throw Exception("Audio URL boş geldi");
      }
      // Gerçek MP3 dosyasını stream eder
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      print("AudioPlayer Hatası: $e - Fallback (Yerel TTS) kullanılıyor.");
      // Eğer MP3 çalınamazsa (sunucu kapalıysa, URL geçersizse), yerel ses motoru devreye girer.
      await _ttsService.speak(fallbackText);
    }
  }

  /// Sistem uyarıları ("Yükleniyor", hata mesajları vs.) için her zaman yerel TTS kullanılır.
  Future<void> speakSystemMessage(String text) async {
    await _ttsService.speak(text);
  }

  /// Çalan tüm sesleri (MP3 veya TTS) durdurur.
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _ttsService.stop();
  }
}
