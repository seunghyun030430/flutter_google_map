import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_threat_page.dart';

import 'package:demo/components/CustomTextField.dart';
import 'package:demo/components/CustomButton.dart';

class ThreatDetailPage extends StatefulWidget {
  final String docId;
  const ThreatDetailPage({Key? key, required this.docId}) : super(key: key);
  static const String routeName = '/firestore';

  @override
  State<ThreatDetailPage> createState() => _ThreatDetailPageState();
}

class _ThreatDetailPageState extends State<ThreatDetailPage> {
  CollectionReference threat = FirebaseFirestore.instance.collection('threats');

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
      await threat.doc(placeId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 화면 크기 조정
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Threat Detail'),
        actions: [
          IconButton(
            onPressed: () {
              _delete(widget.docId);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: threat.snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Loading');
                }
                if (snapshot.hasData) {
                  // docId로 문서 가져오기
                  DocumentSnapshot document = snapshot.data!.docs.firstWhere(
                    (element) => element.id == widget.docId,
                  );
                  return Container(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      // 정렬
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          document['description'].toString(),
                        ),
                        Text(
                          "Type",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          document['type'].toString(),
                        ),
                        Text(
                          "Created At",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          document['created_at'].toDate().toString(),
                        ),
                      ],
                    ),
                  );
                }
                return const Text(
                    'No data available'); // Add a default return statement
              },
            ),
          ),
        ],
      ),
    );
  }
}
