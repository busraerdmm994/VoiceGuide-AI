import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';

// ── Renk paleti ──────────────────────────────────────────────
const Color _kDarkBg   = Color(0xFF080F09);
const Color _kDarkCard = Color(0xFF172018);
const Color _kMeadow   = Color(0xFF4A7C42);
const Color _kSage     = Color(0xFF7AAD70);
const Color _kRose     = Color(0xFFC9747A);
const Color _kDimText  = Color(0x72FFFFFF);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  // Aktif oynatıcı
  final AudioPlayer _player = AudioPlayer();
  String? _playingId;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _fetchHistory();

    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _isPlaying = s == PlayerState.playing);
    });
    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
        _playingId = null;
      });
    });
  }

  Future<void> _fetchHistory() async {
    final data = await ApiService.getHistory();
    if (mounted) setState(() { _history = data; _isLoading = false; });
  }

  Future<void> _togglePlay(dynamic item) async {
    final id  = item['id']?.toString() ?? '';
    final url = item['audio_url']?.toString() ?? '';
    if (url.isEmpty) return;

    if (_playingId == id) {
      // Aynı track → durdur/devam et
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.resume();
      }
    } else {
      // Yeni track
      await _player.stop();
      setState(() { _playingId = id; _position = Duration.zero; _duration = Duration.zero; });
      await _player.play(UrlSource(url));
    }
  }

  Future<void> _seek(double value) async {
    final target = Duration(milliseconds: (value * _duration.inMilliseconds).round());
    await _player.seek(target);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Başlık ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Geçmiş',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${_history.length} analiz kaydedildi',
                    style: const TextStyle(color: _kSage, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // ── Liste ──
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kSage))
                : _history.isEmpty
                  ? Center(child: Text('Henüz hiç geçmiş yok.',
                      style: TextStyle(color: Colors.white.withOpacity(0.4))))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _history.length,
                      itemBuilder: (ctx, i) => _HistoryCard(
                        item: _history[i],
                        isActive: _playingId == _history[i]['id']?.toString(),
                        isPlaying: _isPlaying && _playingId == _history[i]['id']?.toString(),
                        position: _playingId == _history[i]['id']?.toString() ? _position : Duration.zero,
                        duration: _playingId == _history[i]['id']?.toString() ? _duration : Duration.zero,
                        onToggle: () => _togglePlay(_history[i]),
                        onSeek: _seek,
                        fmt: _fmt,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  History Kartı + Inline Oynatıcı
// ─────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final dynamic item;
  final bool isActive;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onToggle;
  final ValueChanged<double> onSeek;
  final String Function(Duration) fmt;

  const _HistoryCard({
    required this.item,
    required this.isActive,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onToggle,
    required this.onSeek,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final hasAudio = (item['audio_url']?.toString() ?? '').isNotEmpty;
    final progress = (duration.inMilliseconds > 0)
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF1F3020)
            : _kDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? _kMeadow.withOpacity(0.5)
              : Colors.white.withOpacity(0.07),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: _kMeadow.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4))]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Üst satır: ikon + bilgi + play butonu ──
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D5A27), Color(0xFF4A7C42)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.location_on, color: Colors.white54, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['place_name'] ?? 'Bilinmeyen Yer',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on, size: 11, color: _kRose),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item['location_name'] ?? 'Türkiye',
                          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text(
                        item['created_at']?.toString().split('T')[0] ?? '',
                        style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 10),
                      ),
                      if ((item['duration_str'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.circle, size: 3, color: Colors.white24),
                        const SizedBox(width: 6),
                        Text(item['duration_str'] ?? '',
                            style: const TextStyle(color: _kSage, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ]),
                  ],
                ),
              ),
              if (hasAudio)
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? _kMeadow : _kMeadow.withOpacity(0.18),
                      border: Border.all(
                        color: isActive ? _kMeadow : _kMeadow.withOpacity(0.4), width: 1.5),
                      boxShadow: isActive
                          ? [BoxShadow(color: _kMeadow.withOpacity(0.4), blurRadius: 12)]
                          : [],
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white, size: 22,
                    ),
                  ),
                ),
            ],
          ),

          // ── Oynatıcı (sadece aktif kart açılır) ──
          if (isActive && hasAudio) ...[
            const SizedBox(height: 16),
            // Dalga çizgisi (dekoratif)
            _WaveformBar(isPlaying: isPlaying),
            const SizedBox(height: 10),

            // Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: _kMeadow,
                inactiveTrackColor: Colors.white.withOpacity(0.12),
                thumbColor: _kSage,
                overlayColor: _kMeadow.withOpacity(0.2),
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: onSeek,
              ),
            ),

            // Zaman etiketi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(fmt(position),
                    style: TextStyle(color: Colors.white.withOpacity(0.35),
                        fontSize: 11, fontFamily: 'monospace')),
                  Text(fmt(duration),
                    style: TextStyle(color: Colors.white.withOpacity(0.35),
                        fontSize: 11, fontFamily: 'monospace')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Animasyonlu dalga çubuğu
// ─────────────────────────────────────────────────────────────
class _WaveformBar extends StatefulWidget {
  final bool isPlaying;
  const _WaveformBar({required this.isPlaying});
  @override
  State<_WaveformBar> createState() => _WaveformBarState();
}

class _WaveformBarState extends State<_WaveformBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  final List<double> _heights = [0.4, 0.7, 1.0, 0.6, 0.85, 0.5, 0.9, 0.65,
                                 0.45, 0.8, 0.55, 0.75, 1.0, 0.4, 0.7, 0.9,
                                 0.5, 0.65, 0.85, 0.6, 0.45, 0.8, 0.7, 0.55, 0.4];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_heights.length, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 30),
        lowerBound: 0.2, upperBound: 1.0,
      )..value = _heights[i];
      if (widget.isPlaying) c.repeat(reverse: true);
      return c;
    });
  }

  @override
  void didUpdateWidget(_WaveformBar old) {
    super.didUpdateWidget(old);
    for (final c in _controllers) {
      widget.isPlaying ? c.repeat(reverse: true) : c.stop();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_controllers.length, (i) {
          return AnimatedBuilder(
            animation: _controllers[i],
            builder: (_, __) {
              return Container(
                width: 3,
                height: 32 * _controllers[i].value,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: _kMeadow.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
