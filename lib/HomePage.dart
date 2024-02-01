import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  Polyline polyline = Polyline(polylineId: PolylineId('directions'), points: []);
  bool isLoading = true;

  LatLng origin = LatLng(0.0, 0.0); // Default to (0, 0)
  LatLng destination = LatLng(0.0, 0.0);

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();

    if (status == PermissionStatus.granted) {
      _getCurrentLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission denied')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        origin = LatLng(position.latitude, position.longitude);
        destination = origin;
      });

      _getDirections();
    } catch (error) {
      print('Error getting current location: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting current location. Please try again.')),
      );
    }
  }

  Future<List<LatLng>> getDirections() async {
    const String apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        final routes = responseJson['routes'] as List;

        if (routes.isNotEmpty) {
          final legs = routes.first['legs'] as List;

          if (legs.isNotEmpty) {
            final steps = legs.first['steps'] as List;
            return steps.map((step) => LatLng(step['start_location']['lat'], step['start_location']['lng'])).toList();
          }
        }
      }
    } catch (error) {
      print('Error fetching directions: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching directions. Please try again.')),
      );
    }

    return [];
  }

  void _getDirections() async {
    try {
      final directions = await getDirections();
      setState(() {
        polyline = Polyline(polylineId: PolylineId('directions'), points: directions);
        markers.add(
          Marker(
            markerId: MarkerId('origin'),
            position: origin,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
        markers.add(
          Marker(
            markerId: MarkerId('destination'),
            position: destination,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
        isLoading = false;

        // Adjust camera position to fit both markers
        _fitMarkersInCamera();
      });
    } catch (error) {
      print('Error fetching directions: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching directions. Please try again.')),
      );
    }
  }

void _fitMarkersInCamera() {
  LatLngBounds bounds = LatLngBounds(
    southwest: LatLng(
      markers.map((marker) => marker.position.latitude).reduce((min, current) => min > current ? current : min),
      markers.map((marker) => marker.position.longitude).reduce((min, current) => min > current ? current : min),
    ),
    northeast: LatLng(
      markers.map((marker) => marker.position.latitude).reduce((max, current) => max < current ? current : max),
      markers.map((marker) => marker.position.longitude).reduce((max, current) => max < current ? current : max),
    ),
  );

  mapController.animateCamera(CameraUpdate.newLatLngBounds(
    bounds,
    EdgeInsets.all(50.0) as double, // Add padding around the bounds
  ));
}

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: Text('Google Maps Directions'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _googleMapView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _googleMapView() {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 400,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: origin, zoom: 12),
          onMapCreated: (controller) => mapController = controller,
          markers: markers,
          mapType: MapType.normal,
          polylines: {polyline},
          zoomControlsEnabled: true,
        ),
      ),
    );
  }
}
