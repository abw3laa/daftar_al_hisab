import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'daftar_al_hisab.db');
    return openDatabase(
      path,
      version: 4,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workshops (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, location TEXT,
        status TEXT NOT NULL DEFAULT 'active', created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE workers (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, profession TEXT,
        phone TEXT, default_workshop_id TEXT, created_at TEXT NOT NULL,
        FOREIGN KEY (default_workshop_id) REFERENCES workshops (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE journal_entries (
        id TEXT PRIMARY KEY, worker_id TEXT NOT NULL, workshop_id TEXT NOT NULL,
        date TEXT NOT NULL, wage REAL NOT NULL DEFAULT 0,
        work_fraction REAL NOT NULL DEFAULT 1, overtime_hours REAL NOT NULL DEFAULT 0,
        overtime_rate REAL NOT NULL DEFAULT 0, deduction REAL NOT NULL DEFAULT 0,
        notes TEXT, present INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL,
        FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE,
        FOREIGN KEY (workshop_id) REFERENCES workshops (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY, worker_id TEXT NOT NULL, date TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0, type TEXT NOT NULL DEFAULT 'advance',
        notes TEXT, created_at TEXT NOT NULL,
        FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE
      )
    ''');
    await _createLedger(db);
    await _createPayrollPeriods(db);
    await _createIndexes(db);
  }

  Future<void> _createLedger(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS account_transactions (
        id TEXT PRIMARY KEY,
        worker_id TEXT,
        workshop_id TEXT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        debit REAL NOT NULL DEFAULT 0,
        credit REAL NOT NULL DEFAULT 0,
        reference_type TEXT,
        reference_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE,
        FOREIGN KEY (workshop_id) REFERENCES workshops (id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE journal_entries ADD COLUMN work_fraction REAL NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE journal_entries ADD COLUMN overtime_hours REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE journal_entries ADD COLUMN overtime_rate REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE journal_entries ADD COLUMN deduction REAL NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await _createLedger(db);
      await db.execute('''
        INSERT INTO account_transactions
        (id, worker_id, workshop_id, date, type, description, debit, credit, reference_type, reference_id, created_at)
        SELECT 'legacy-j-' || id, worker_id, workshop_id, date, 'wage',
          'أجر يومية', 0,
          CASE WHEN present = 1 THEN MAX(0, (wage * work_fraction) + (overtime_hours * overtime_rate) - deduction) ELSE 0 END,
          'journal', id, created_at
        FROM journal_entries
      ''');
      await db.execute('''
        INSERT INTO account_transactions
        (id, worker_id, date, type, description, debit, credit, reference_type, reference_id, created_at)
        SELECT 'legacy-p-' || id, worker_id, date, 'payment', 'دفعة للعامل',
          amount, 0, 'payment', id, created_at
        FROM payments
      ''');
    }
    if (oldVersion < 4) {
      await _createPayrollPeriods(db);
    }
    await _createIndexes(db);
  }

  Future<void> _createPayrollPeriods(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payroll_periods (
        id TEXT PRIMARY KEY,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'open',
        notes TEXT,
        created_at TEXT NOT NULL,
        closed_at TEXT,
        UNIQUE(year, month)
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_journal_worker ON journal_entries (worker_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_journal_workshop ON journal_entries (workshop_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_journal_date ON journal_entries (date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_worker ON payments (worker_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ledger_worker_date ON account_transactions (worker_id, date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ledger_workshop ON account_transactions (workshop_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ledger_reference ON account_transactions (reference_type, reference_id)');
  }

  Future<void> closeDb() async {
    final db = _db;
    if (db != null) { await db.close(); _db = null; }
  }

  Future<void> wipeAllData() async {
    final db = await database;
    await db.delete('payroll_periods');
    await db.delete('account_transactions');
    await db.delete('payments');
    await db.delete('journal_entries');
    await db.delete('workers');
    await db.delete('workshops');
  }
}