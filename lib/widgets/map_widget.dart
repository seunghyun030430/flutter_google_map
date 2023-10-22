import 'dart:async';

import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({Key? key}) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  static const LatLng _sourceLocation = LatLng(37.33500, -122.0327);
  static const LatLng _destination = LatLng(37.33429, -122.0660);
  List<LatLng> polylineCoordinates = [];
  Location _location = Location();
  LocationData? _currentLocation;
  CameraPosition? _cameraPosition;

  // database
  CollectionReference placeCollection =
      FirebaseFirestore.instance.collection('place');
  List<Marker> place_marker_list = [];

  @override
  void initState() {
    _init();
    super.initState();
  }

  void _init() async {
    _getPolyline();
    getLocationUpdate();
    _makePlaceMarker();
  }

  Future<void> getLocationUpdate() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _location.onLocationChanged.listen((LocationData currentLocation) {
      _currentLocation = currentLocation;
      _cameraPosition = CameraPosition(
        target: LatLng(
          _currentLocation?.latitude ?? 0.0,
          _currentLocation?.longitude ?? 0.0,
        ),
        zoom: 8,
      );
      setState(() {});
    });
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

  // firebase에서 place리스트를 가져오는 함수
  Future<List<Map>> _getPlaceList() async {
    List<Map> placeList = [];
    await placeCollection.get().then((querySnapshot) {
      querySnapshot.docs.forEach((element) {
        placeList.add(element.data() as Map);
      });
    });
    return placeList;
  }

  // place marker를 만드는 함수
  Future<void> _makePlaceMarker() async {
    List<Map> placeList = await _getPlaceList();
    placeList.forEach((element) {
      place_marker_list.add(
        Marker(
          markerId: MarkerId(element.toString()),
          position: LatLng(
            element['location'].latitude,
            element['location'].longitude,
          ),
          infoWindow: InfoWindow(
              title: element['name'],
              snippet: element['location'].latitude.toString() +
                  ', ' +
                  element['location'].longitude.toString()),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _currentLocation == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : _buildMap();
  }

  Widget _buildMap() {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _cameraPosition!,
      onMapCreated: (GoogleMapController controller) {
        // now we need a variable to get the controller of google map
        if (!_controller.isCompleted) {
          _controller.complete(controller);
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
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          ),
        ),
        ...Set<Marker>.from(place_marker_list),
      },
    );
  }
}
