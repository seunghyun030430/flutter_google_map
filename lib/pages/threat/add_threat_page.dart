import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddThreatPage extends StatefulWidget {
  const AddThreatPage({Key? key});

  @override
  // ignore: library_private_types_in_public_api
  _AddThreatPageState createState() => _AddThreatPageState();
}

class _AddThreatPageState extends State<AddThreatPage> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile?> _selectedImages = [];
  final TextEditingController _textEditingController = TextEditingController();
  String _enteredText = '';
  final Location _location = Location();
  LocationData? _currentLocation =
      LocationData.fromMap({'latitude': 37.0, 'longitude': -100.0});
  String? _selectedThreatType;
  final List<String> _threatTypes = ['1', '2', '3', '4', '5'];
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    getLocationUpdate();
    super.initState();
  }

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
    });
  }

  Future<void> _takePicture() async {
    final XFile? picture = await _picker.pickImage(source: ImageSource.camera);

    if (picture != null) {
      setState(() {
        _selectedImages.add(picture);
      });
    }
  }

  Future<void> _uploadPicture() async {
    final XFile? picture = await _picker.pickImage(source: ImageSource.gallery);

    if (picture != null) {
      setState(() {
        _selectedImages.add(picture); // Add the selected image to the list
      });
    }
  }

  void _submit() {
    if (_currentLocation != null &&
        _selectedThreatType != null &&
        _textEditingController.text != '') {
      final firestore = FirebaseFirestore.instance;
      final List<Future<String>> uploadTasks = []; // List to store upload tasks

      for (var selectedImage in _selectedImages) {
        if (selectedImage != null) {
          final storage = FirebaseStorage.instance;
          final Reference ref = storage
              .ref()
              .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
          final File file = File(selectedImage.path);
          uploadTasks.add(ref.putFile(file).then((TaskSnapshot taskSnapshot) {
            return ref.getDownloadURL();
          }));
        }
      }

      Future.wait(uploadTasks).then((List<String> imageUrls) {
        firestore.collection('threats').add({
          'coord': GeoPoint(
              _currentLocation!.latitude!, _currentLocation!.longitude!),
          'created_at': FieldValue.serverTimestamp(),
          'type': _selectedThreatType,
          'description': _textEditingController.text,
          //'image_urls': imageUrls,
        }).then((documentReference) {
          setState(() {
            _enteredText = '';
            _selectedThreatType = null;
            _selectedImages.clear();
          });
        }).catchError((error) {});
      });
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Threat'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButton<String>(
              value: _selectedThreatType,
              items: _threatTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedThreatType = newValue;
                });
              },
            ),
            const SizedBox(height: 20),
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Image.file(
                      File(_selectedImages[index]!.path),
                      width: 200,
                      height: 200,
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _textEditingController,
                decoration: const InputDecoration(
                  hintText: 'Enter text',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _submit();
              },
              child: const Text('Submit'),
            ),
            const SizedBox(height: 20),
            Text(_enteredText),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FloatingActionButton(
            onPressed: _takePicture,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            onPressed: _uploadPicture,
            child: const Icon(Icons.photo),
          ),
        ],
      ),
    );
  }
}