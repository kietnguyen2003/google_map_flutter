import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map/source/location.dart' as locations;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Map<String, Marker> _markers = {};
  GoogleMapController? _mapController;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    // Kiểm tra dịch vụ vị trí
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng bật dịch vụ vị trí')),
      );
      return;
    }

    // Kiểm tra và yêu cầu quyền
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn'),
        ),
      );
      return;
    }

    // Lấy vị trí hiện tại
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      // Thêm marker cho vị trí hiện tại
      _markers['current_location'] = Marker(
        markerId: const MarkerId('current_location'),
        position: _currentPosition!,
        infoWindow: const InfoWindow(
          title: 'Vị trí của bạn',
          snippet: 'Đây là vị trí hiện tại',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
      // Di chuyển camera đến vị trí hiện tại
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    });
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    final googleOffices = await locations.getGoogleOffices();
    setState(() {
      _markers.clear();
      // Thêm lại marker vị trí hiện tại nếu có
      if (_currentPosition != null) {
        _markers['current_location'] = Marker(
          markerId: const MarkerId('current_location'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(
            title: 'Vị trí của bạn',
            snippet: 'Đây là vị trí hiện tại',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );
      }
      // Thêm các marker văn phòng Google
      for (final office in googleOffices.offices) {
        final marker = Marker(
          markerId: MarkerId(office.name),
          position: LatLng(office.lat, office.lng),
          infoWindow: InfoWindow(title: office.name, snippet: office.address),
        );
        _markers[office.name] = marker;
      }
    });
  }

  // Hàm để focus vào vị trí hiện tại
  void _focusOnCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy vị trí hiện tại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Google Maps with Flutter'),
          elevation: 2,
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: const CameraPosition(
            target: LatLng(0, 0),
            zoom: 2,
          ),
          markers: _markers.values.toSet(),
          myLocationEnabled: true,
          myLocationButtonEnabled:
              false, // Tắt nút mặc định để dùng nút tùy chỉnh
        ),
        floatingActionButton: Align(
          alignment: Alignment.bottomLeft + const Alignment(0.15, 0),

          child: FloatingActionButton(
            onPressed: _focusOnCurrentLocation,
            tooltip: 'Focus vào vị trí hiện tại',
            child: const Icon(Icons.my_location, size: 30, color: Colors.blue),
          ),
        ),
      ),
    );
  }
}
