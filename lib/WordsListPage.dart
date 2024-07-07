import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:testgame/word_model.dart';
import 'db_helper.dart';
import 'dart:async';

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
  User? user;
  String? selectedOption;
  FlutterTts flutterTts = FlutterTts();
  AudioPlayer audioPlayer = AudioPlayer();
  bool isLoadingQuestion = false;

  @override
  void initState() {
    super.initState();
    loadNewQuestion();
    getCurrentUser();
    configureTts();
  }

  Future<void> getCurrentUser() async {
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await FirebaseAuth.instance.signInAnonymously();
      user = FirebaseAuth.instance.currentUser;
    }
  }

  Future<void> loadNewQuestion() async {
    setState(() {
      isLoadingQuestion = true;
    });

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
        selectedOption = null;
      });
      await flutterTts.speak(currentQuestion!.word);
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

    setState(() {
      isLoadingQuestion = false;
    });
  }

  Future<void> saveScore() async {
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'score': currentScore,
        'level': currentLevel,
      }, SetOptions(merge: true));
    }
  }

  Future<void> checkAnswer(String option) async {
    setState(() {
      selectedOption = option;
      isCorrect = option == currentQuestion!.meaning;
    });

    if (isCorrect!) {
      currentScore += 10;
      currentLevel += 1;
      final responses = ["Awesome!", "Excellent!", "Great!"];
      final response = (responses..shuffle()).first;
      await audioPlayer.play(AssetSource('correct.wav'));
      await flutterTts.speak(response);
    } else {
      await audioPlayer.play(AssetSource('wrong.mp3'));
    }

    await saveScore();

    await Future.delayed(Duration(seconds: 0));
    loadNewQuestion();
  }

  void configureTts() {
    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dictionary Quiz'),
      ),
      body: currentQuestion == null || isLoadingQuestion
          ? Center(child: CircularProgressIndicator())
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              currentQuestion!.word,
              style: TextStyle(fontSize: 24),
            ),
          ),
          ...currentQuestion!.options!.map<Widget>((option) {
            Color? tileColor;
            if (selectedOption == option) {
              tileColor = isCorrect! ? Colors.green : Colors.red;
            }
            return ListTile(
              tileColor: tileColor,
              title: Text(option),
              onTap: selectedOption == null
                  ? () => checkAnswer(option)
                  : null,
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
          SizedBox(height: 20),
          Text(
            'Score: $currentScore',
            style: TextStyle(fontSize: 20),
          ),
          Text(
            'Level: $currentLevel',
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }
}