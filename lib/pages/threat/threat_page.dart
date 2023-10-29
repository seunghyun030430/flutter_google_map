import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_threat_page.dart';

import 'package:demo/components/CustomTextField.dart';
import 'package:demo/components/CustomButton.dart';

class ThreatPage extends StatefulWidget {
  const ThreatPage({Key? key}) : super(key: key);
  static const String routeName = '/firestore';

  @override
  State<ThreatPage> createState() => _ThreatPageState();
}

class _ThreatPageState extends State<ThreatPage> {
  CollectionReference trail = FirebaseFirestore.instance.collection('trail');
  CollectionReference typeCollection =
      FirebaseFirestore.instance.collection('type');

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  // Future<void> _update(DocumentSnapshot document) async {
  //   nameController.text = document['name'].toString();

  //   await showModalBottomSheet(
  //     isScrollControlled: true,
  //     context: context,
  //     builder: (BuildContext context) {
  //       return EditTrailPage(document: document);
  //     },
  //   );
  // }

  Future<void> _create() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return AddThreatPage();
      },
    );
  }

  Future<void> _delete(String placeId) async {
    // 사용자에게 삭제를 확인하는 다이얼로그 표시
    final bool? result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this place?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (result == true) {
      await trail.doc(placeId).delete();
    }
  }

  Future<List<Map>> _getTrailList() async {
    List<Map> trailList = [];
    await trail.get().then((querySnapshot) {
      querySnapshot.docs.forEach((element) {
        trailList.add(element.data() as Map);
      });
    });
    return trailList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // 화면 크기 조정
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              child: Row(children: [
                const Text(
                  'Trails',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
            ),
            Expanded(
              child: StreamBuilder(
                stream: trail.snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Loading');
                  }
                  if (snapshot.hasData) {
                    return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final DocumentSnapshot document =
                              snapshot.data!.docs[index];
                          return Card(
                            child: ListTile(
                              // 첫번째 이미지 가져오기
                              leading: document['image_urls'] != null &&
                                      document['image_urls'].length > 0
                                  ? Image.network(
                                      document['image_urls'][0],
                                      width: 50, // 원하는 너비를 설정할 수 있습니다.
                                      height: 50, // 원하는 높이를 설정할 수 있습니다.
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              title: Text(
                                //geoPoint를 string으로 변환
                                document['name'].toString(),
                              ),
                              subtitle: Text(
                                document['description'].toString(),
                              ),
                              trailing: SizedBox(
                                width: 100,
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        // _update(document);
                                      },
                                      icon: const Icon(Icons.edit),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _delete(document.id);
                                      },
                                      icon: const Icon(Icons.delete),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        });
                  }
                  return const Text(
                      'No data available'); // Add a default return statement
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 50.0),
          child: FloatingActionButton(
            onPressed: () {
              _create();
            },
            child: const Icon(Icons.add),
          ),
        ));
  }
}
