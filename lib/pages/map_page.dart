import 'dart:async';

import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Completer<GoogleMapController> _googleMapController = Completer();
  static const LatLng _sourceLocation = LatLng(37.33500, -122.0327);
  static const LatLng _destination = LatLng(37.33429, -122.0660);
  List<LatLng> polylineCoordinates = [];
  LocationData? _currentLocation;

  @override
  void initState() {
    _getPolyline();
    _getCurrentLocation();
    super.initState();
  }

  void _getCurrentLocation() async {
    Location location = Location();
    location.getLocation().then((locationData) {
      _currentLocation = locationData;
    });
    //테스트용으로 _sourceLocation로 변경
    // _currentLocation = LocationData.fromMap({
    //   "latitude": _sourceLocation.latitude,
    //   "longitude": _sourceLocation.longitude
    // }

    // );
  }

  moveToPosition(LatLng latLng) async {
    GoogleMapController mapController = await _googleMapController.future;
    mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 15)));
  }

  void _getPolyline() async {
    PolylinePoints polylinePoints = PolylinePoints();

    //flutter run -d chrome --web-browser-flag "--disable-web-security"
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      google_map_api_key,
      PointLatLng(_sourceLocation.latitude, _sourceLocation.longitude),
      PointLatLng(_destination.latitude, _destination.longitude),
    );

    if (result.points.isNotEmpty) {
      result.points.forEach(
        (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return (Scaffold(
      appBar: AppBar(
        title: const Text('Map Page'),
      ),
      body: _currentLocation == null
          ? const Center(child: Text("Loading..."))
          : GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentLocation?.latitude ?? 0.0,
                  _currentLocation?.longitude ?? 0.0,
                ),
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                if (!_googleMapController.isCompleted) {
                  _googleMapController.complete(controller);
                }
              },
              polylines: {
                  Polyline(
                    polylineId: const PolylineId("polyline"),
                    color: Colors.red,
                    points: polylineCoordinates,
                    width: 5,
                  ),
                },
              markers: {
                  Marker(
                    markerId: const MarkerId("currentLocation"),
                    position: LatLng(
                      _currentLocation?.latitude ?? 0.0,
                      _currentLocation?.longitude ?? 0.0,
                    ),
                  ),
                  const Marker(
                    markerId: MarkerId("source"),
                    position: _sourceLocation,
                  ),
                  const Marker(
                    markerId: MarkerId("destination"),
                    position: _destination,
                  ),
                }),
    ));
  }
}
