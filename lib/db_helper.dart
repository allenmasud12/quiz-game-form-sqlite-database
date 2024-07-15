import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:testgame/word_model.dart';

class DatabaseHelper {
  Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<void> initializeDatabase() async {
    _database = await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'test.db');
    bool exists = await databaseExists(path);

    if (!exists) {
      await _copyDB(path);
    }

    return await openDatabase(path, version: 1);
  }

  Future<void> _copyDB(String path) async {
    await Directory(dirname(path)).create(recursive: true);
    ByteData data = await rootBundle.load(join("assets", "test.db"));
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    await File(path).writeAsBytes(bytes, flush: true);
  }

  Future<List<WordModel>> fetchWordsByLevel(int level) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('SELECT * FROM testgame');
    List<WordModel> allWords = result.map((word) => WordModel.fromMap(word)).toList();
    allWords.shuffle(); // Shuffle the list of all words

    int wordsPerLevel = 20;
    int totalLevels = 10;

    // Ensure there are enough words to fill the levels
    while (allWords.length < wordsPerLevel * totalLevels) {
      List<WordModel> additionalWords = List.from(allWords); // Create a copy of the list
      allWords.addAll(additionalWords); // Add the copied list
      allWords.shuffle(); // Shuffle again to mix the duplicates
    }

    int startIndex = (level - 1) * wordsPerLevel;
    int endIndex = startIndex + wordsPerLevel;

    return allWords.sublist(startIndex, endIndex);
  }

  Future<List<String>> fetchRandomMeanings(int excludeId, int limit) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT meaning FROM testgame WHERE id != ? ORDER BY RANDOM() LIMIT ?',
        [excludeId, limit]);
    return List.generate(result.length, (i) => result[i]['meaning'] as String);
  }

  Future<int> getTotalWords() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as count FROM testgame');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}

