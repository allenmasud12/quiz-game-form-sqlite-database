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
    int offset = (level - 1) * 20;
    List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT * FROM testgame LIMIT 20 OFFSET ?', [offset]);
    return result.map((word) => WordModel.fromMap(word)).toList();
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

