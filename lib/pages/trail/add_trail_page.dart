import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';

import 'package:demo/components/CustomTextField.dart';
import 'package:demo/components/CustomButton.dart';

class AddTrailPage extends StatefulWidget {
  const AddTrailPage({Key? key});

  @override
  _AddTrailPageState createState() => _AddTrailPageState();
}

class _AddTrailPageState extends State<AddTrailPage> {
  final Location _location = Location();
  String? _selectedTrailType;
  final List<String> _trailTypes = [
    'Hiking',
    'Cycling',
    'Running',
    'Walking',
    'Other'
  ];

  bool _isRecording = false;
  final List<LocationData> _recordedLocations = [];
  final List<XFile?> _selectedImages = [];
  final TextEditingController _trailNameController = TextEditingController();
  final TextEditingController _trailDescriptionController =
      TextEditingController();

  late Timer _timer;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _location.onLocationChanged.listen((LocationData newLocation) {
      if (_isRecording) {
        setState(() {
          _recordedLocations.add(newLocation);
        });
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 30), (Timer timer) {
      if (_isRecording && _recordedLocations.isNotEmpty) {
        _saveTrail();
      }
    });
  }

  Future<String> _uploadFile(String path) async {
    final storage = FirebaseStorage.instance;
    final Reference ref = storage
        .ref()
        .child('trail_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final File file = File(path);
    final result = await ref.putFile(file);
    final url = await result.ref.getDownloadURL();
    return url;
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: Icon(Icons.camera_alt),
                    title: Text('Take a Picture'),
                    onTap: () {
                      _takePicture();
                      Navigator.pop(context);
                    }),
                ListTile(
                  leading: Icon(Icons.photo),
                  title: Text('Choose from Gallery'),
                  onTap: () {
                    _uploadPicture();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        });
  }

  Future<void> _saveTrail() async {
    print(_selectedTrailType);
    print(_recordedLocations);
    if (_selectedTrailType != null && _recordedLocations.isNotEmpty) {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final List<Future<String>> uploadTasks = [];

      for (var selectedImage in _selectedImages) {
        if (selectedImage != null) {
          uploadTasks.add(_uploadFile(selectedImage.path));
        }
      }

      Future.wait(uploadTasks).then((List<String> imageUrls) {
        firestore.collection('trail').add({
          'name': _trailNameController.text,
          'description': _trailDescriptionController.text,
          'type': _selectedTrailType,
          'coords': _recordedLocations
              .map((location) =>
                  GeoPoint(location.latitude ?? 0.0, location.longitude ?? 0.0))
              .toList(),
          'image_urls': imageUrls,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        setState(() {
          _recordedLocations.clear();
          _selectedImages.clear();
        });
      });
    }
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
        _selectedImages.add(picture);
      });
    }
  }

  Future<void> _saveAndClose() async {
    await _saveTrail();

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 52, 52, 52),
        title: const Text('Add Trail'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            SizedBox(
              width: 400,
              child: CustomTextField(
                controller: _trailNameController,
                labelText: 'Enter name',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 400,
              child: CustomTextField(
                controller: _trailDescriptionController,
                labelText: 'Enter description',
              ),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedTrailType,
              items: _trailTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTrailType = newValue;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 60),
                      child: OutlinedButton(
                        onPressed: () {
                          _showUploadOptions(context);
                        },
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: Icon(Icons.add_a_photo),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(200, 200),
                        ),
                      ),
                    );
                  }
                  return Image.file(
                    File(_selectedImages[index - 1]!.path),
                    width: 200,
                    height: 200,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isRecording = !_isRecording;
                });
              },
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Save',
              onTap: _saveAndClose,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
