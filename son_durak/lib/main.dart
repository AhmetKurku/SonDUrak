import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const SonDurakApp());
}

class SonDurakApp extends StatelessWidget {
  const SonDurakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Son Durak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          primary: Colors.blueAccent,
          secondary: Colors.lightBlue,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(), // Ana ekran: Butonun olduğu yer
    );
  }
}

// Ana Ekran (Home Screen)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blueAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_bus,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Son Durak\'a\nHoş Geldiniz',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Uyumadan önce inmek istediğiniz durağı haritadan seçin.\nYaklaştığınızda alarm ile sizi uyandıracağız.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Haritayı Aç ve Hedef Seç',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Gerçek Harita ve Hedef Seçim Ekranı
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  
  LatLng? _targetDestination;
  StreamSubscription<Position>? _positionStream;
  bool _isAlarmTriggered = false;
  bool _isTrackingStarted = false;

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(37.8716, 32.4921), // Konya
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      _startTrackingUser();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum izni verilmedi. Uygulama düzgün çalışmayabilir.')),
        );
      }
    }
  }

  void _startTrackingUser() {
    setState(() {
      _isTrackingStarted = true;
    });

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 10 metrede bir güncelle
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _updateCameraPosition(position);
        _checkDistanceToDestination(position);
      },
    );
  }

  void _updateCameraPosition(Position position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    }
  }

  void _checkDistanceToDestination(Position currentPos) {
    if (_targetDestination == null || _isAlarmTriggered) return;

    double distanceInMeters = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      _targetDestination!.latitude,
      _targetDestination!.longitude,
    );

    // Kalan mesafeyi konsola (veya UI'ya) yazdırabilirsiniz
    print('Hedefe kalan mesafe: ¤{distanceInMeters.toStringAsFixed(2)} metre');

    if (distanceInMeters <= 500) {
      _isAlarmTriggered = true;
      _showAlarmDialog();
    }
  }

  void _showAlarmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı tıklayarak kapatamasın
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('DURAĞA YAKLAŞTIN, UYAN!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.alarm_on, size: 80, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Hedef durağına 500 metreden az kaldı. Lütfen hazırlan!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ALARMİ KAPAT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // HomeScreen'e dön
              },
            ),
          ],
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_isTrackingStarted) {
      // Map oluşturulduğunda kullanıcının anlık konumunu al ve oraya odaklan
      Geolocator.getCurrentPosition().then((pos) {
        _updateCameraPosition(pos);
      }).catchError((e) {
        print('Konum alınamadı: $e');
      });
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _targetDestination = position;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: position,
          infoWindow: const InfoWindow(
            title: 'Hedef Durak',
            snippet: 'Bu noktada uyandırılacaksınız',
          ),
        ),
      );
    });
  }

  void _confirmAlarm() {
    if (_targetDestination == null) return;
    
    // Alarm sıfırlandı ve artık mesafeyi izliyor
    _isAlarmTriggered = false;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hedef durak başarıyla kaydedildi! Alarm devrede.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hedef İstasyon Seçimi', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            trafficEnabled: true,
            onMapCreated: _onMapCreated,
            initialCameraPosition: _kInitialPosition,
            markers: _markers,
            onTap: _onMapTapped,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            myLocationEnabled: _isTrackingStarted, // Mavi nokta
            myLocationButtonEnabled: true, // Sağ üstteki "Konumuma git" butonu
          ),
          
          if (_targetDestination != null && !_isAlarmTriggered)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Hedef Konum İşaretlendi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _confirmAlarm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Alarmı Kur ve Onayla',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
