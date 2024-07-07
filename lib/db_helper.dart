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
    List<int> bytes =
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    await File(path).writeAsBytes(bytes, flush: true);
  }

  Future<WordModel?> fetchRandomWord() async {
    final db = await database;
    List<Map<String, dynamic>> result =
    await db.rawQuery('SELECT * FROM testgame ORDER BY RANDOM() LIMIT 1');
    if (result.isNotEmpty) {
      return WordModel(
        id: result[0]['id'],
        word: result[0]['word'],
        meaning: result[0]['meaning'],
      );
    }
    return null;
  }

  Future<List<String>> fetchRandomMeanings(int excludeId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT meaning FROM testgame WHERE id != ? ORDER BY RANDOM() LIMIT 3',
        [excludeId]);
    return List.generate(result.length, (i) => result[i]['meaning'] as String);
  }
}
