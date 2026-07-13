import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

const Color _kDarkBg   = Color(0xFF080F09);
const Color _kDarkCard = Color(0xFF172018);
const Color _kMeadow   = Color(0xFF4A7C42);
const Color _kSage     = Color(0xFF7AAD70);
const Color _kRose     = Color(0xFFC9747A);
const Color _kGold     = Color(0xFFC9A84C);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<dynamic> _places = [];
  bool _isLoading = true;
  dynamic _selected;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    final data = await ApiService.getVisitedPlaces();
    if (mounted) {
      setState(() {
        _places = data;
        _isLoading = false;
      });
      // Eğer yer varsa haritayı ilk noktaya odakla
      if (data.isNotEmpty && data[0]['location_lat'] != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(
            LatLng(data[0]['location_lat'], data[0]['location_lng']),
            12.0,
          );
        });
      }
    }
  }

  List<Marker> _buildMarkers() {
    return _places
        .where((p) => p['location_lat'] != null && p['location_lng'] != null)
        .map((p) {
      final isSelected = _selected != null && _selected['id'] == p['id'];
      final lat = (p['location_lat'] as num).toDouble();
      final lng = (p['location_lng'] as num).toDouble();
      return Marker(
        point: LatLng(lat, lng),
        width: isSelected ? 48 : 36,
        height: isSelected ? 48 : 36,
        child: GestureDetector(
          onTap: () {
            setState(() => _selected = p);
            _mapController.move(LatLng(lat, lng), 14.0);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: CustomPaint(
              painter: _PinPainter(
                color: isSelected ? _kSage : _kMeadow,
                glowing: isSelected,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validPlaces = _places
        .where((p) => p['location_lat'] != null && p['location_lng'] != null)
        .toList();

    return Scaffold(
      backgroundColor: _kDarkBg,
      body: Stack(
        children: [
          // ── Harita ──────────────────────────────────────────
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _kSage))
              : validPlaces.isEmpty
                  ? _buildEmptyState()
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: validPlaces.isNotEmpty
                            ? LatLng(
                                (validPlaces[0]['location_lat'] as num).toDouble(),
                                (validPlaces[0]['location_lng'] as num).toDouble(),
                              )
                            : const LatLng(41.0082, 28.9784), // İstanbul
                        initialZoom: 12,
                        onTap: (_, __) => setState(() => _selected = null),
                      ),
                      children: [
                        // Karanlık tema tile
                        TileLayer(
                          urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.example.voiceguide_flutter',
                        ),
                        MarkerLayer(markers: _buildMarkers()),
                      ],
                    ),

          // ── Üst Başlık Kartı ────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xDD111A12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.09)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
                  ],
                ),
                child: Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Harita',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    RichText(text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${validPlaces.length}',
                          style: const TextStyle(color: _kSage, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const TextSpan(
                          text: ' yer ziyaret edildi',
                          style: TextStyle(color: Color(0x72FFFFFF), fontSize: 13),
                        ),
                      ],
                    )),
                  ]),
                  const Spacer(),
                  // Konuma git butonu
                  GestureDetector(
                    onTap: () async {
                      final loc = await ApiService.getLocation();
                      if (loc != null) {
                        _mapController.move(LatLng(loc['lat']!, loc['lng']!), 14);
                      }
                    },
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _kMeadow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: _kMeadow.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.my_location, color: _kSage, size: 20),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // ── Seçili yer bilgi kartı ──────────────────────────
          if (_selected != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _SelectedPlaceSheet(
                place: _selected!,
                onClose: () => setState(() => _selected = null),
              ),
            ),

          // ── Boş durum ──────────────────────────────────────
          if (!_isLoading && validPlaces.isEmpty)
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'Henüz ziyaret edilmiş yer yok.',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Kamera ile analiz yapın,\nkonumunuz kaydedilsin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Seçili yer bottom sheet
// ─────────────────────────────────────────────────────────────
class _SelectedPlaceSheet extends StatelessWidget {
  final dynamic place;
  final VoidCallback onClose;

  const _SelectedPlaceSheet({required this.place, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xF0111A12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kSage.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(color: _kMeadow.withOpacity(0.12), blurRadius: 24),
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16),
        ],
      ),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D5A27), Color(0xFF4A7C42)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.location_on, color: Colors.white70, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              place['place_name'] ?? 'Bilinmeyen Yer',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on, size: 11, color: _kRose),
              const SizedBox(width: 3),
              Text(
                '${(place['location_lat'] as num?)?.toStringAsFixed(4) ?? ''}, '
                '${(place['location_lng'] as num?)?.toStringAsFixed(4) ?? ''}',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              place['visited_at']?.toString().split('T')[0] ?? '',
              style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11),
            ),
          ]),
        ),
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close, size: 18, color: Colors.white.withOpacity(0.4)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Özel Pin Painter (damla şekli)
// ─────────────────────────────────────────────────────────────
class _PinPainter extends CustomPainter {
  final Color color;
  final bool glowing;
  const _PinPainter({required this.color, this.glowing = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    if (glowing) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(size.width / 2, size.height * 0.38),
          size.width * 0.38, glowPaint);
    }

    // Daire (baş)
    canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.35), size.width * 0.35, paint);
    canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.35), size.width * 0.35, strokePaint);

    // Üçgen (kuyruk)
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.55)
      ..lineTo(size.width / 2, size.height * 0.95)
      ..lineTo(size.width * 0.72, size.height * 0.55)
      ..close();
    canvas.drawPath(path, paint);

    // Beyaz nokta (iç)
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.35),
        size.width * 0.14, Paint()..color = Colors.white.withOpacity(0.85));
  }

  @override
  bool shouldRepaint(_PinPainter old) =>
      old.color != color || old.glowing != glowing;
}
