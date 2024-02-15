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
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

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

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.delayed(Duration.zero, () {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      staffCode = args['staffCode'];
      password = args['password'];
      fetchStaffDetails();
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _isDisposed = true;
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isDisposed) {
        _getCurrentLocation();
      }
    });
  }

  void _startLocationTracking() {
    _startTimer();
    setState(() {
      isLocationTrackingEnabled = true;
    });
  }

  void _stopLocationTracking() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      isLocationTrackingEnabled = false;
    });
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();

    if (status == PermissionStatus.granted) {
      _getCurrentLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
      _showPermissionRequestDialog();
    }
  }

  void _showPermissionRequestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Permission Required"),
          content: const Text("This app requires location permission to function."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _getCurrentLocation();
              },
              child: const Text("Grant"),
            ),
          ],
        );
      },
    );
  }

Future<void> _getCurrentLocation() async {
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
      });

      _getDirections(); // Call _getDirections() to draw polyline
      _moveToCurrentLocation();
    } else {
      setState(() {
        origin = LatLng(position.latitude, position.longitude);
        destination = origin;
        currentAddress = "Unknown";
      });

      _getDirections(); // Call _getDirections() to draw polyline
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


  void _moveToCurrentLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: origin, zoom: 15),
      ),
    );
  }

  Future<List<LatLng>> getDirections() async {
    const String apiKey = 'AIzaSyAFzlw87Pf_trlsQjEjUu-4eP9G7WpcLDc';
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
      if (kDebugMode) {
        print('Error fetching directions: $error');
      }
    }

    return [];
  }
    List<List<LatLng>> routeTracks = [];

    Future<void> _getDirections() async {
      try {
        final directions = await getDirections();
        if (directions.isNotEmpty) {
          setState(() {
            routeTracks.add(directions); // Save directions in list
            polyline = Polyline(
              polylineId: const PolylineId('directions'),
              color: Colors.blue,
              points: routeTracks.expand((track) => track).toList(), // Flatten list of tracks
            );
            markers.clear();
            markers.add(Marker(markerId: const MarkerId('origin'), position: origin));
            markers.add(Marker(markerId: const MarkerId('destination'), position: destination));
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No directions found')),
          );
        }
      } catch (error) {
        print('Error fetching directions: $error');
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
                          CircleAvatar(
                            backgroundImage: staffPhoto.isNotEmpty
                                ? NetworkImage(staffPhoto)
                                : const NetworkImage(
                                    'https://i.guim.co.uk/img/media/97fc02c0ed01d16b8090846535695cb1daa4d084/0_150_2000_1199/master/2000.jpg?width=465&dpr=1&s=none'),
                            foregroundColor: Colors.green,
                            radius: 40.0,
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
              const ListTile(
                leading: Icon(Icons.contact_support, color: Colors.blueAccent),
                title: Text('Contact Us'),
              ),
              const ListTile(
                leading: Icon(Icons.settings, color: Colors.blueAccent),
                title: Text('Settings'),
              ),
              const ListTile(
                leading: Icon(Icons.share, color: Colors.blueAccent),
                title: Text('Share'),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () async {
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
      bottomNavigationBar: ConvexAppBar(
        initialActiveIndex: 0,
        height: 50,
        backgroundColor: const Color.fromARGB(185, 28, 84, 129),
        style: TabStyle.flip,
        items: const [
          TabItem(icon: Icons.home_outlined, title: 'Home'),
          TabItem(icon: Icons.person_outline, title: 'Profile'),
          TabItem(icon: Icons.auto_graph_outlined, title: 'Records'),
          TabItem(icon: Icons.settings_outlined, title: 'Settings')
        ],
        onTap: (int index) {
          // Navigate to the corresponding page based on the selected index
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/home');
              break;
            case 1:
              Navigator.pushNamed(context, '/profile', arguments: {
                'staffCode': staffCode,
                'password': password,
              });
              break;
            case 2:
              Navigator.pushNamed(context, '/records', arguments: {
                'staffCode': staffCode,
                'password': password,
              });
              break;
            case 3:
              Navigator.pushNamed(context, '/settings');
              break;
            default:
              break;
          }
        },
      ),
    );
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
          markers: markers,
          mapType: MapType.normal,
          polylines: {polyline},
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
          currentAddress.isEmpty ? "Fetching address..." : "Current Address: $currentAddress",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Colors.blue),
        ),
      ),
    );
  }

  Widget _trackButton() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () async {
          final service = FlutterBackgroundService();
          bool isRunning = await service.isRunning();
          if (isRunning) {
            service.invoke('stopTracking');
          } else {
            service.startService();
          }
          if (!isRunning) {
            _startLocationTracking();
          } else {
            _stopLocationTracking();
          }
        },
        style: ElevatedButton.styleFrom(
          primary: isLocationTrackingEnabled ? Colors.red : Colors.lightGreen[700],
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
}
