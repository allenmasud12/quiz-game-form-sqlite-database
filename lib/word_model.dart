class WordModel {
  int? id;
  final String word;
  final String meaning;
  List<String>? options;

  WordModel({
    required this.word,
    required this.meaning,
    this.id,
    this.options,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'options': options,
    };
  }

  static WordModel fromMap(Map<String, dynamic> map) {
    return WordModel(
      id: map['id'],
      word: map['word'],
      meaning: map['meaning'],
      options: map['options'] != null ? List<String>.from(map['options']) : null,
    );
  }
}
