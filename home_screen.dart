import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/checkin_service.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController(); // Controller to programmatically handle map
  
  String locationDisplay = 'Tap Refresh to get location';
  String distanceText = 'Distance: --';
  double? userLat, userLng;
  int totalPoints = 0;
  bool isAtFair = false;

  final String fairName = "Southern Career Fair 2026";
  final double targetLat = 1.5336; 
  final double targetLng = 103.6819;
  final double radius = 150.0; 
  final int fairPoints = 50;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    int p = await CheckInService.getTotalPoints();
    setState(() => totalPoints = p);
  }

  Future<void> _updateLocation() async {
    try {
      final pos = await _locationService.getCurrentLocation();
      final addr = await _locationService.getAddressFromCoordinates(pos);
      double dist = _locationService.calculateDistance(pos.latitude, pos.longitude, targetLat, targetLng);

      setState(() {
        userLat = pos.latitude;
        userLng = pos.longitude;
        locationDisplay = "You are at $addr\n(Lat: ${pos.latitude}, Lng: ${pos.longitude})";
        distanceText = dist >= 1000 
            ? "Distance: ${(dist / 1000).toStringAsFixed(2)} km to fair" 
            : "Distance: ${dist.toStringAsFixed(0)} m to fair";
        isAtFair = dist <= radius;
      });

      // Move map to user's new location smoothly
      _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(targetLat, targetLng),
              initialZoom: 16,
              // ENABLE ZOOM AND GESTURES HERE
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all, // Enables all gestures including pinch-to-zoom
              ),
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              CircleLayer(circles: [
                CircleMarker(
                  point: LatLng(targetLat, targetLng), 
                  color: Colors.indigo.withOpacity(0.2), 
                  useRadiusInMeter: true, 
                  radius: radius, 
                  borderColor: Colors.indigo, 
                  borderStrokeWidth: 2
                ),
              ]),
              MarkerLayer(markers: [
                Marker(point: LatLng(targetLat, targetLng), child: const Icon(Icons.location_on, color: Colors.red, size: 40)),
                if (userLat != null)
                  Marker(point: LatLng(userLat!, userLng!), child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40)),
              ]),
            ],
          ),

          // Floating Action Buttons for Manual Zoom (Optional extra)
          Positioned(
            right: 15,
            top: 15,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: "zoom_in",
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: "zoom_out",
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          Positioned(bottom: 20, left: 15, right: 15,
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(fairName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 5),
                    Text(locationDisplay, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(distanceText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(Icons.circle, color: isAtFair ? Colors.green : Colors.red, size: 12),
                          const SizedBox(width: 5),
                          Text(isAtFair ? "Status: At Fair" : "Status: Not At Fair"),
                        ]),
                        Text("Total Points: $totalPoints", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton(onPressed: _updateLocation, child: const Text("Refresh"))),
                        const SizedBox(width: 10),
                        Expanded(child: ElevatedButton(
                          onPressed: () async {
                            if (!isAtFair) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Validation Failed: Too far!")));
                              return;
                            }
                            await CheckInService.addCheckIn(fairName, fairPoints, locationDisplay);
                            _loadPoints();
                          }, 
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                          child: const Text("Join Fair")
                        )),
                      ],
                    ),
                    TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())), 
                    child: const Text("View History"))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}