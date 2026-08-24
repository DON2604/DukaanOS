import 'package:sqflite/sqflite.dart';

class TranscriptBatch {
  const TranscriptBatch({
    required this.batchId,
    required this.transcript,
    required this.startedAt,
    required this.endedAt,
  });

  final String batchId;
  final String transcript;
  final DateTime startedAt;
  final DateTime endedAt;

  Map<String, Object?> toRow() => {
    'batch_id': batchId,
    'transcript': transcript,
    'started_at': startedAt.toUtc().toIso8601String(),
    'ended_at': endedAt.toUtc().toIso8601String(),
  };

  Map<String, Object?> toApiJson() => {
    'batch_id': batchId,
    'transcript': transcript,
    'started_at': startedAt.toUtc().toIso8601String(),
    'ended_at': endedAt.toUtc().toIso8601String(),
  };

  factory TranscriptBatch.fromRow(Map<String, Object?> row) => TranscriptBatch(
    batchId: row['batch_id']! as String,
    transcript: row['transcript']! as String,
    startedAt: DateTime.parse(row['started_at']! as String),
    endedAt: DateTime.parse(row['ended_at']! as String),
  );
}

/// Collapses evolving partial recognition results without repeating prefixes.
class EvolvingTranscript {
  String _text = '';

  String get text => _text;
  bool get isEmpty => _text.trim().isEmpty;

  bool add(String partial) {
    final next = partial.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (next.isEmpty || next == _text) return false;
    if (next.startsWith(_text)) {
      _text = next;
      return true;
    }
    if (_text.startsWith(next)) return false;

    final words = _text.split(' ');
    final incoming = next.split(' ');
    var overlap = 0;
    for (
      var size = 1;
      size <= words.length && size <= incoming.length;
      size++
    ) {
      if (words.sublist(words.length - size).join(' ') ==
          incoming.sublist(0, size).join(' ')) {
        overlap = size;
      }
    }
    _text = [...words, ...incoming.skip(overlap)].join(' ');
    return true;
  }

  String take() {
    final value = _text;
    _text = '';
    return value;
  }
}

abstract class TranscriptQueue {
  Future<void> enqueue(TranscriptBatch batch);
  Future<List<TranscriptBatch>> pending();
  Future<void> delete(String batchId);
  Future<void> clear();
  Future<void> close();
}

class SqliteTranscriptQueue implements TranscriptQueue {
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final path = '${await getDatabasesPath()}/khata_voice.db';
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE transcript_batches('
        'batch_id TEXT PRIMARY KEY, transcript TEXT NOT NULL, '
        'started_at TEXT NOT NULL, ended_at TEXT NOT NULL)',
      ),
    );
    return _database!;
  }

  @override
  Future<void> enqueue(TranscriptBatch batch) async {
    final db = await _db;
    await db.insert(
      'transcript_batches',
      batch.toRow(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await db.execute(
      'DELETE FROM transcript_batches WHERE batch_id NOT IN '
      '(SELECT batch_id FROM transcript_batches '
      'ORDER BY started_at DESC LIMIT 100)',
    );
  }

  @override
  Future<List<TranscriptBatch>> pending() async {
    final rows = await (await _db).query(
      'transcript_batches',
      orderBy: 'started_at ASC',
    );
    return rows.map(TranscriptBatch.fromRow).toList();
  }

  @override
  Future<void> delete(String batchId) async {
    await (await _db).delete(
      'transcript_batches',
      where: 'batch_id = ?',
      whereArgs: [batchId],
    );
  }

  @override
  Future<void> clear() async => (await _db).delete('transcript_batches');

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
