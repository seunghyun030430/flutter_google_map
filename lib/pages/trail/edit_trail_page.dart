import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';

import 'package:demo/components/CustomTextField.dart';
import 'package:demo/components/CustomButton.dart';

class EditTrailPage extends StatefulWidget {
  final DocumentSnapshot document;
  const EditTrailPage({Key? key, required this.document});

  @override
  _EditTrailPageState createState() => _EditTrailPageState();
}

class _EditTrailPageState extends State<EditTrailPage> {
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
    _initInputValue();
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

  Future<void> _initInputValue() async {
    _trailNameController.text = widget.document['name'];
    _trailDescriptionController.text = widget.document['description'];
    _selectedTrailType = widget.document['type'];
    final List<dynamic> coords = widget.document['coords'];
    final List<GeoPoint> geoPoints =
        coords.map((coord) => coord as GeoPoint).toList();
    final List<LocationData> locations = geoPoints
        .map((geoPoint) => LocationData.fromMap(
            {'latitude': geoPoint.latitude, 'longitude': geoPoint.longitude}))
        .toList();

    setState(() {
      _recordedLocations.addAll(locations);
    });

    final List<dynamic> imageUrls = widget.document['image_urls'];

    for (var imageUrl in imageUrls) {
      final File file = File(imageUrl);
      final XFile xFile = XFile(file.path);
      setState(() {
        _selectedImages.add(xFile);
      });
    }
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
    if (_selectedTrailType != null && _recordedLocations.isNotEmpty) {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final List<Future<String>> uploadTasks = [];
      final List<String> existingImageUrls = [];

      for (var selectedImage in _selectedImages) {
        if (selectedImage != null) {
          if (selectedImage.path.startsWith('http')) {
            // 이미 URL로 되어 있는 이미지를 별도의 리스트에 저장
            existingImageUrls.add(selectedImage.path);
          } else {
            uploadTasks.add(_uploadFile(selectedImage.path));
          }
        }
      }

      Future.wait(uploadTasks).then((List<String> newImageUrls) {
        // 기존의 이미지 URL들과 새로 업로드한 이미지 URL들을 결합
        final allImageUrls = [...existingImageUrls, ...newImageUrls];

        firestore.collection('trail').doc(widget.document.id).update({
          'name': _trailNameController.text,
          'description': _trailDescriptionController.text,
          'type': _selectedTrailType,
          'coords': _recordedLocations
              .map((location) =>
                  GeoPoint(location.latitude ?? 0.0, location.longitude ?? 0.0))
              .toList(),
          'image_urls': allImageUrls,
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
        title: const Text('Edit Trail'),
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
                  var item = _selectedImages[index - 1];

                  if (item!.path.startsWith('http')) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Image.network(
                        item.path,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Image.file(
                        File(item.path),
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    );
                  }
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
