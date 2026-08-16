import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TerminalSession {
  final int? id;
  final String name;
  final String command;
  final String? workingDirectory;
  final DateTime createdAt;
  final DateTime? lastUsed;

  TerminalSession({
    this.id,
    required this.name,
    required this.command,
    this.workingDirectory,
    required this.createdAt,
    this.lastUsed,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'command': command,
        'workingDirectory': workingDirectory,
        'createdAt': createdAt.toIso8601String(),
        'lastUsed': lastUsed?.toIso8601String(),
      };

  factory TerminalSession.fromMap(Map<String, dynamic> map) => TerminalSession(
        id: map['id'] as int?,
        name: map['name'] as String,
        command: map['command'] as String,
        workingDirectory: map['workingDirectory'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        lastUsed: map['lastUsed'] != null ? DateTime.parse(map['lastUsed'] as String) : null,
      );

  TerminalSession copyWith({int? id}) => TerminalSession(
        id: id ?? this.id,
        name: name,
        command: command,
        workingDirectory: workingDirectory,
        createdAt: createdAt,
        lastUsed: lastUsed,
      );
}

class SessionManagerService {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'openclaw_sessions.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            command TEXT NOT NULL,
            workingDirectory TEXT,
            createdAt TEXT NOT NULL,
            lastUsed TEXT
          )
        ''');
      },
    );
  }

  static Future<List<TerminalSession>> getSessions() async {
    final db = await database;
    final maps = await db.query('sessions', orderBy: 'lastUsed DESC');
    return maps.map((m) => TerminalSession.fromMap(m)).toList();
  }

  static Future<TerminalSession> saveSession(TerminalSession session) async {
    final db = await database;
    final id = await db.insert('sessions', session.toMap());
    return session.copyWith(id: id);
  }

  static Future<void> updateLastUsed(int id) async {
    final db = await database;
    await db.update(
      'sessions',
      {'lastUsed': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteSession(int id) async {
    final db = await database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }
}