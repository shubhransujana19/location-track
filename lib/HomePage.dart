import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share/share.dart';
import 'package:location/back_services.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  Polyline polyline = const Polyline(polylineId: PolylineId('directions'), points: []);
  String currentAddress = "";
  LatLng origin = const LatLng(0.0, 0.0);
  LatLng destination = const LatLng(0.0, 0.0);
  bool isLocationTrackingEnabled = false;
  Timer? _timer;
  bool _isDisposed = false;
  late String staffCode = '';
  late String password = '';
  String staffName = 'Loading...';
  String designation = '';
  String photoPath = '';
  String staffPhoto = '';
  List<LatLng> route = []; // Store the user's location history
  double _totalDistance = 0.0; 


  @override
  void initState() {
    super.initState();
    // _requestLocationPermission();
    if (staffCode.isNotEmpty && password.isNotEmpty ) {
       _checkLocationPermission();
    }   
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.delayed(Duration.zero, () {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      staffCode = args['staffCode'];
      password = args['password'];
      fetchStaffDetails();
      // _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _isDisposed = true;
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!_isDisposed) {
        _getCurrentLocation();
      }
    });
  }



Future<void> _checkLocationPermission() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool? hasPermission = prefs.getBool('locationPermission');

  if (hasPermission == null || !hasPermission) {
    // Location permission has not been granted yet, request permission
    await _requestLocationPermission();
  } else {
    // Location permission has been granted or denied
    final status = await Permission.location.status;
    if (status == PermissionStatus.denied || status == PermissionStatus.permanentlyDenied) {
      // Location permission has been denied, show permission request dialog
      _showPermissionRequestDialog();
    } else {
      // Location permission has been granted, get current location
      _getCurrentLocation();
    }
  }
}

Future<void> _requestLocationPermission() async {
  final status = await Permission.location.request();

  if (status == PermissionStatus.granted) {
    // Permission granted, save permission status and get current location
    _savePermissionStatus(true);
    _getCurrentLocation();
  } else if (status == PermissionStatus.denied || status == PermissionStatus.permanentlyDenied) {
    // Permission denied, save permission status
    // _savePermissionStatus(false);
    // Show permission request dialog
    _showPermissionRequestDialog();
  }
}

void _showPermissionRequestDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Location Permission Required"),
        content: const Text(
          "This app requires access to your device's location to function properly. Please grant the location permission in order to start tracking your location."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Open app settings for the user to manually enable location permission
              await openAppSettings();
            },
            child: const Text("Go to Settings"),
          ),
        ],
      );
    },
  );
}

  Future<void> _savePermissionStatus(bool hasPermission) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('locationPermission', hasPermission);
}


void _getCurrentLocation() async {
  try {
    Position position = await Geolocator.getCurrentPosition();
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks.first;
      String street = placemark.thoroughfare ?? placemark.street ?? "Unnamed Road";
      String city = placemark.locality ?? placemark.subLocality ?? placemark.administrativeArea ?? "Unknown";
      String country = placemark.country ?? "Unknown";

      setState(() {
        if (origin.latitude == 0.0 && origin.longitude == 0.0) {
          origin = LatLng(position.latitude, position.longitude);
        }
        destination = LatLng(position.latitude, position.longitude);
        currentAddress = '$street, $city, $country';

        route.add(LatLng(position.latitude, position.longitude)); // Add current location to the route
      });

      _moveToCurrentLocation();
      _updatePolyline(); // Draw polyline with updated route
      _calculateDistance(); // Calculate distance after updating route
      // Add marker for the current location
      addMarker(position.latitude, position.longitude);
      // Convert route to the required format
      List<Map<String, double>> routeData = route.map((latLng) => {
        'latitude': latLng.latitude,
        'longitude': latLng.longitude,
      }).toList();

      // Send tracking data to server
      sendTrackingDataToServer(route, currentAddress, staffCode);
      if (kDebugMode) {
        print(routeData);
      }
    } else {
      setState(() {
        origin = LatLng(position.latitude, position.longitude);
        destination = origin;
        currentAddress = "Unknown";
      });

      _moveToCurrentLocation();
    }
  } catch (error) {
    if (kDebugMode) {
      print('Error getting current location: $error');
    }
    if (!_isDisposed) {
      setState(() {
        currentAddress = "Error fetching location";
      });
    }
  }
}


  void _updatePolyline() {
    setState(() {
      polyline = Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        points: List<LatLng>.from(route),
      );
    });
  }

  void _moveToCurrentLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: destination, zoom: 15),
      ),
    );
  }

void addMarker(double latitude, double longitude) {
  // Clear existing markers
  markers.clear();

  setState(() {
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'), // Use a fixed marker ID for the current location
        position: LatLng(latitude, longitude), // Provide the position of the marker
        // You can customize the marker icon if needed
        icon: BitmapDescriptor.defaultMarker,
      ),
    );
  });
}
  void _calculateDistance() {
  if (route.length > 1) {
    double distance = 0.0;
    for (int i = 1; i < route.length; i++) {
      distance += Geolocator.distanceBetween(
        route[i - 1].latitude,
        route[i - 1].longitude,
        route[i].latitude,
        route[i].longitude,
      );
    }
    // Convert distance from meters to kilometers and update the state
    setState(() {
      _totalDistance = distance / 1000;
    });
  }
}


  Future<void> fetchStaffDetails() async {
    try {
      final response = await http.post(
        Uri.parse('https://www.wmps.in/staff/gps/location.php'),
        body: jsonEncode({'staffCode': staffCode, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Response Data: $responseData');

        if (responseData != null && responseData['success']) {
          setState(() {
            staffName = responseData['staffDetails']['staff_name'] ?? 'Unknown';
            designation = responseData['staffDetails']['department'] ?? '';
            photoPath = responseData['staffDetails']['photo'];
            staffPhoto = 'https://www.wmps.in/staff/document/photo/$photoPath';
          });
        } else {
          setState(() {
            staffName = 'Failed to load data: ${responseData['message']}';
          });
        }
      } else {
        setState(() {
          staffName = 'Failed to load data: ${response.statusCode}';
        });
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text('Map Directions'),
        actions: const <Widget>[
          Icon(Icons.notification_add, color: Colors.blueAccent),
          SizedBox(width: 9),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _googleMapView(),
              _currentAddress(),
              _trackButton(),
              Text('Total Distance: ${_totalDistance.toStringAsFixed(2)} km'),

            ],
          ),
        ),
      ),
      drawer: Drawer(
        elevation: 12.0,
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: ListView(
            children: <Widget>[
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.white24,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 10.0,
                      top: 16.0,
                      bottom: 16.0,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context, '/profile',
                              arguments: {
                                'staffCode' : staffCode,
                                'password': password,
                              }
                            ),
                            child: CircleAvatar(
                              backgroundImage: staffPhoto.isNotEmpty
                                  ? NetworkImage(staffPhoto)
                                  : const NetworkImage(
                                      'https://i.guim.co.uk/img/media/97fc02c0ed01d16b8090846535695cb1daa4d084/0_150_2000_1199/master/2000.jpg?width=465&dpr=1&s=none'),
                              foregroundColor: Colors.green,
                              radius: 40.0,
                            ),
                          ),
                          const SizedBox(width: 9.0),
                          Text(staffName),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8.0,
                      right: 8.0,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blueAccent),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/profile',
                    arguments: {
                      'staffCode': staffCode,
                      'password': password,
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.blueAccent),
                title: const Text('Bank Details'),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/bank',
                    arguments: {
                      'staffCode': staffCode,
                      'password': password,
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_document, color: Colors.blueAccent),
                title: const Text('Documents'),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/document',
                    arguments: {
                      'staffCode': staffCode,
                      'password': password,
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_graph, color: Colors.blueAccent),
                title: const Text('Track Records'),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/records',
                    arguments: {
                      'staffCode': staffCode,
                      'password': password,
                    },
                  );
                },
              ),

             ListTile(
                leading: const Icon(Icons.contact_support, color: Colors.blueAccent),
                title: const Text('Contact Us'),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/contact',
                    arguments: {
                      'staffCode': staffCode,
                      'password': password,
                    },
                  );
                },

              ),
              const ListTile(
                leading: Icon(Icons.settings, color: Colors.blueAccent),
                title: Text('Settings'),
              ),
               ListTile(
                leading: const Icon(Icons.share, color: Colors.blueAccent),
                title: const Text('Share'),
                onTap: (){
                   // Implement share functionality here
                     const String message = 'Check out this awesome app! for location tracking ';
                     const String subject = 'App Recommendation';

                    Share.share(message, subject: subject);
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () async {
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.remove('staffCode');
                    await prefs.remove('password');

                    Navigator.pushReplacementNamed(context, '/signIn');
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8.0),
                      Text(
                        "Logout",
                        style: TextStyle(color: Colors.red, fontSize: 16.0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),


    );
  }

  void _startLocationTracking() {
  if (staffCode.isNotEmpty && password.isNotEmpty) {
    if (_timer == null || !_timer!.isActive) {
      _startTimer();
      setState(() {
        isLocationTrackingEnabled = true;
      });
    }
  } else {
    print('Staff code or password is empty. Cannot start location tracking.');
  }
}

  void _stopLocationTracking() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      isLocationTrackingEnabled = false;
    });
  }


Widget _googleMapView() {
    return Card(
      elevation: 4.0,
      child: SizedBox(
        width: double.infinity,
        height: 400,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: origin, zoom: 15),
          onMapCreated: (controller) => mapController = controller,
          markers: markers, // Use the markers set here
          mapType: MapType.normal,
          polylines: {polyline}, // Add the polyline here
          zoomControlsEnabled: true,
        ),
      ),
    );
  }

  Widget _currentAddress() {
    return Card(
      elevation: 4.0,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: Text(
          currentAddress.isEmpty ? "Start Tracking to fetch address..." : "Current Address: $currentAddress",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Colors.blue),
        ),
      ),
    );
  }
  
Widget _trackButton() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: ElevatedButton(
      onPressed: () async {
        final service = FlutterBackgroundService();
        bool isRunning = await service.isRunning();
        if (isRunning) {
          service.invoke('stopTracking');
          _stopLocationTracking();
        } else {
          await initializeService(); // Initialize service when user starts tracking
          service.startService();
          _startLocationTracking();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isLocationTrackingEnabled ? Colors.red : Colors.lightGreen[700],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isLocationTrackingEnabled ? Icons.stop : Icons.play_arrow),
          const SizedBox(width: 5),
          Text(isLocationTrackingEnabled ? 'Stop Tracking' : 'Start Tracking', style: const TextStyle(fontSize: 20.0)),
        ],
      ),
    ),
  );
}



Future<void> sendTrackingDataToServer(List<LatLng> route, String locationName, String staffCode) async {
  try {
    final currentTime = DateTime.now().toIso8601String();

    final url = Uri.parse('https://www.wmps.in/staff/gps/location/records.php');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'route': route.map((latLng) => {
          'latitude': latLng.latitude,
          'longitude': latLng.longitude,
        }).toList(),
        'location_name': locationName,
        'staff_code': staffCode,
        'datetime': currentTime,
        'total_distance': _totalDistance,
      }),
    );

    if (response.statusCode == 200) {
      print('Tracking data sent successfully!');
    } else {
      print('Failed to send tracking data. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending tracking data: $e');
  }
}

  
}
