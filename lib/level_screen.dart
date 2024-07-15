import 'package:flutter/material.dart';
import 'WordsListPage.dart';
import 'db_helper.dart';

class LevelSelectionScreen extends StatelessWidget {
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Level'),
      ),
      body: FutureBuilder<int>(
        future: dbHelper.getTotalWords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return ListView.builder(
              itemCount: 10, // Fixed number of levels
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Level ${index + 1}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizScreen(level: index + 1),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
