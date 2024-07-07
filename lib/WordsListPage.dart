import 'package:flutter/material.dart';
import 'package:testgame/word_model.dart';

import 'db_helper.dart';

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  DatabaseHelper dbHelper = DatabaseHelper();
  WordModel? currentQuestion;
  bool? isCorrect;
  int currentScore = 0;
  int currentLevel = 1;

  @override
  void initState() {
    super.initState();
    loadNewQuestion();
  }

  Future<void> loadNewQuestion() async {
    final word = await dbHelper.fetchRandomWord();
    if (word != null) {
      final incorrectMeanings = await dbHelper.fetchRandomMeanings(word.id!);
      final options = List<String>.from(incorrectMeanings)
        ..add(word.meaning)
        ..shuffle();
      setState(() {
        currentQuestion = word;
        currentQuestion!.options = options;
        isCorrect = null;
      });
    } else {
      setState(() {
        currentQuestion = WordModel(
          id: 0,
          word: 'No words available',
          meaning: '',
          options: [],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dictionary Quiz'),
      ),
      body: currentQuestion == null
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              currentQuestion!.word,
              style: TextStyle(fontSize: 24),
            ),
          ),
          ...currentQuestion!.options!.map<Widget>((option) {
            return ListTile(
              title: Text(option),
              onTap: () {
                setState(() {
                  isCorrect = option == currentQuestion!.meaning;
                });
                if (isCorrect!) {
                  setState(() {
                    currentScore += 10;
                    currentLevel += 1;
                  });
                }
                loadNewQuestion();
              },
            );
          }).toList(),
          if (isCorrect != null)
            Text(
              isCorrect! ? 'Correct!' : 'Wrong!',
              style: TextStyle(
                fontSize: 24,
                color: isCorrect! ? Colors.green : Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}
