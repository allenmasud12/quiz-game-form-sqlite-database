import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'db_helper.dart';
import 'word_model.dart';

class QuizScreen extends StatefulWidget {
  final int level;

  QuizScreen({required this.level});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  DatabaseHelper dbHelper = DatabaseHelper();
  List<WordModel>? currentLevelWords;
  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  User? user;
  String? selectedOption;
  FlutterTts flutterTts = FlutterTts();
  AudioPlayer audioPlayer = AudioPlayer();
  bool isLoading = false;

  WordModel? currentQuestion;
  bool? isCorrect;
  int currentScore = 0;
  int totalWords = 0;

  @override
  void initState() {
    super.initState();
    loadLevelWords();
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

  Future<void> loadLevelWords() async {
    setState(() {
      isLoading = true;
    });

    currentLevelWords = await dbHelper.fetchWordsByLevel(widget.level);
    if (currentLevelWords != null && currentLevelWords!.isNotEmpty) {
      setState(() {
        isLoading = false;
        totalWords = currentLevelWords!.length;
      });
      loadNewQuestion();
    } else {
      setState(() {
        currentLevelWords = [];
        isLoading = false;
      });
    }
  }

  Future<void> loadNewQuestion() async {
    if (currentIndex < currentLevelWords!.length) {
      final word = currentLevelWords![currentIndex];
      final incorrectMeanings = await dbHelper.fetchRandomMeanings(word.id!, 3);
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
      showLevelCompleteDialog();
    }
  }

  Future<void> saveScore() async {
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'score': currentScore,
        'level': widget.level,
      }, SetOptions(merge: true));
    }
  }

  Future<void> checkAnswer(String option) async {
    setState(() {
      selectedOption = option;
      isCorrect = option == currentQuestion!.meaning;
    });

    if (isCorrect!) {
      correctCount++;
      currentScore += 1;
      final responses = ["Awesome!", "Excellent!", "Great!"];
      final response = (responses..shuffle()).first;
      await audioPlayer.play(AssetSource('correct.wav'));
      await flutterTts.speak(response);
    } else {
      wrongCount++;
      await audioPlayer.play(AssetSource('wrong.mp3'));
    }

    await saveScore();

    await Future.delayed(Duration(seconds: 1));
    setState(() {
      currentIndex++;
    });
    loadNewQuestion();
  }

  void showLevelCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Level Complete!'),
          content: Text('Correct: $correctCount\nWrong: $wrongCount'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
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
        title: Text('Dictionary Quiz - Level ${widget.level}'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : currentLevelWords == null || currentLevelWords!.isEmpty
          ? Center(child: Text('No words available'))
          : currentQuestion == null
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
          ...?currentQuestion?.options?.map<Widget>((option) {
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
            'Level: ${widget.level}',
            style: TextStyle(fontSize: 20),
          ),
          Text(
            'Progress: ${currentIndex + 1}/$totalWords',
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
