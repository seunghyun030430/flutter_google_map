import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePage extends StatefulWidget {
  const FirestorePage({Key? key}) : super(key: key);
  static const String routeName = '/firestore';

  @override
  State<FirestorePage> createState() => _FirestorePageState();
}

class _FirestorePageState extends State<FirestorePage> {
  CollectionReference place = FirebaseFirestore.instance.collection('place');

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  Future<void> _update(DocumentSnapshot document) async {
    nameController.text = document['lat'].toString();
    priceController.text = document['lng'].toString();

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'lat',
                ),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'lng',
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await document.reference.update({
                    'lat': nameController.text,
                    'lng': priceController.text,
                  });

                  nameController.clear();
                  priceController.clear();
                  Navigator.of(context).pop();
                },
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _create() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'lat',
                ),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'lng',
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await place.add({
                    'lat': nameController.text,
                    'lng': priceController.text,
                  });
                  nameController.clear();
                  priceController.clear();
                  Navigator.of(context).pop();
                },
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _delete(String placeId) async {
    await place.doc(placeId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // 화면 크기 조정
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('Firestore Page'),
        ),
        body: StreamBuilder(
          stream: place.snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
                        title: Text(document['lat'].toString()),
                        subtitle: Text(document['lng'].toString()),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  _update(document);
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _create();
          },
          child: const Icon(Icons.add),
        ));
  }
}
