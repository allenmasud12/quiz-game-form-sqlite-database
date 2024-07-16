import 'package:flutter/material.dart';
import 'WordsListPage.dart';
import 'db_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LevelSelectionScreen extends StatefulWidget {
  @override
  _LevelSelectionScreenState createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  User? user;
  Map<int, bool> levelCompletionStatus = {};

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  Future<void> getCurrentUser() async {
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await FirebaseAuth.instance.signInAnonymously();
      user = FirebaseAuth.instance.currentUser;
    }
    loadLevelCompletionStatus();
  }

  Future<void> loadLevelCompletionStatus() async {
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (snapshot.exists) {
        setState(() {
          levelCompletionStatus = {
            1: snapshot.data()?['level1Complete'] ?? false,
            2: snapshot.data()?['level2Complete'] ?? false,
            3: snapshot.data()?['level3Complete'] ?? false,
          };
        });
      }
    }
  }

  void updateLevelCompletion(int level, bool status) async {
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'level${level}Complete': status,
      }, SetOptions(merge: true));
      loadLevelCompletionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Level'),
      ),
      body: ListView.builder(
        itemCount: 10, // Fixed number of levels
        itemBuilder: (context, index) {
          bool isLocked = index > 0 && !(levelCompletionStatus[index] ?? false);
          return Card(
            child: ListTile(
              title: Text('Level ${index + 1}'),
              trailing: isLocked ? Icon(Icons.lock, color:  Colors.grey,) : null,
              onTap: isLocked
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                      level: index + 1,
                      onComplete: () {
                        updateLevelCompletion(index + 1, true);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
