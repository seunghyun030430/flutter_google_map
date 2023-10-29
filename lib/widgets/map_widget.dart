import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:demo/pages/threat_detail_page.dart';

import 'package:custom_info_window/custom_info_window.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({Key? key}) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  LocationData? _currentLocation;
  List<LatLng> polylineCoordinates = [];
  List<Marker> customMarkers = [];
  final Location _location = Location();
  Set<Polyline> polylines = {};

  LatLng? _infoWindowLocation;
  String? _infoWindowTitle;
  String? _infoWindowDescription;

  @override
  void dispose() {
    _customInfoWindowController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    getLocationUpdate();
    _getThreatMarkers();
    _getRouteMarkers();
    super.initState();
  }

  // void _navigateToThreatDetail(String type, String description) {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(
  //       builder: (context) =>
  //           ThreatDetailPage(type: type, description: description),
  //     ),
  //   );
  // }

  Future<void> getLocationUpdate() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _location.onLocationChanged.listen((LocationData currentLocation) {
      _currentLocation = currentLocation;
      setState(() {});
    });
  }

  Future<List<Map>> _getThreatList() async {
    List<Map> threatList = [];
    CollectionReference threats =
        FirebaseFirestore.instance.collection('threats');
    // ignore: non_constant_identifier_names, avoid_function_literals_in_foreach_calls
    await threats.get().then((Snapshot) => Snapshot.docs.forEach((element) {
          threatList.add(element.data() as Map);
        }));
    return threatList;
  }

  void _getThreatMarkers() async {
    List<Map> threatList = await _getThreatList();

    for (var doc in threatList) {
      double lat = doc['coord'].latitude;
      double lng = doc['coord'].longitude;
      String type = doc['type'];
      String description = doc['description'];

      customMarkers.add(
        Marker(
          markerId: MarkerId('Threat-${doc['id']}'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () {
            print('Marker tapped');
            _customInfoWindowController.addInfoWindow!(
              Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_circle,
                              color: Colors.white,
                              size: 30,
                            ),
                            SizedBox(
                              width: 8.0,
                            ),
                            Text(
                              type,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ],
              ),
              LatLng(lat, lng),
            );
          },
        ),
      );
    }
  }

  Future<List<Map>> _getRouteList() async {
    List<Map> threatList = [];
    CollectionReference routes =
        FirebaseFirestore.instance.collection('routes');
    // ignore: non_constant_identifier_names, avoid_function_literals_in_foreach_calls
    await routes.get().then((Snapshot) => Snapshot.docs.forEach((element) {
          threatList.add(element.data() as Map);
        }));
    return threatList;
  }

  Future<void> _getRouteMarkers() async {
    List<Map> routeList = await _getRouteList();

    for (var doc in routeList) {
      List<dynamic> coords = doc['coords'];
      String type = doc['type'];

      List<LatLng> coordinates = coords.map((coord) {
        double lat = coord.latitude;
        double lng = coord.longitude;
        return LatLng(lat, lng);
      }).toList();

      customMarkers.add(
        Marker(
          markerId: const MarkerId('Start'),
          position: coordinates.first,
          infoWindow: InfoWindow(title: 'Start of Trail', snippet: type),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen), // Customize the marker icon
        ),
      );

      // Add a marker at the end of the route
      customMarkers.add(
        Marker(
          markerId: const MarkerId('End'),
          position: coordinates.last,
          infoWindow: InfoWindow(title: 'End of Trail', snippet: type),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed), // Customize the marker icon
        ),
      );

      Polyline polyline = Polyline(
        polylineId: PolylineId(type),
        color: Colors.blue,
        points: coordinates,
        width: 5,
      );
      polylines.add(polyline);

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          child: _currentLocation == null
              ? const Center(child: Text("Loading..."))
              : GoogleMap(
                  onTap: (position) {
                    _customInfoWindowController.hideInfoWindow!();
                  },
                  onCameraMove: (position) {
                    _customInfoWindowController.onCameraMove!();
                  },
                  onMapCreated: (GoogleMapController controller) async {
                    _customInfoWindowController.googleMapController =
                        controller;
                  },
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentLocation!.latitude!,
                      _currentLocation!.longitude!,
                    ),
                    zoom: 5,
                  ),
                  polylines: polylines, // Use the set of polylines
                  markers: Set<Marker>.from(customMarkers),
                ),
        ),
        CustomInfoWindow(
          controller: _customInfoWindowController,
          height: 75,
          width: 150,
          offset: 50,
        ),
      ],
    );
  }
}
