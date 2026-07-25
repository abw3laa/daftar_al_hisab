import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';
import '../models/journal_entry.dart';
import '../models/payment.dart';
import '../models/worker.dart';
import '../models/workshop.dart';

const _uuid = Uuid();

class AppData extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Worker> workers = [];
  List<Workshop> workshops = [];
  List<JournalEntry> journalEntries = [];
  List<Payment> payments = [];

  String currencySymbol = 'ل.ت';
  bool darkMode = false;
  bool dailyReminder = true;
  bool isLoading = true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    currencySymbol = prefs.getString('currency_symbol') ?? 'ل.ت';
    darkMode = prefs.getBool('dark_mode') ?? false;
    dailyReminder = prefs.getBool('daily_reminder') ?? true;
    await reloadAll();
  }

  Future<void> reloadAll() async {
    isLoading = true;
    notifyListeners();
    final db = await _dbHelper.database;
    final workshopMaps = await db.query('workshops', orderBy: 'created_at DESC');
    final workerMaps = await db.query('workers', orderBy: 'created_at DESC');
    final journalMaps = await db.query('journal_entries', orderBy: 'date DESC');
    final paymentMaps = await db.query('payments', orderBy: 'date DESC');

    workshops = workshopMaps.map((e) => Workshop.fromMap(e)).toList();
    workers = workerMaps.map((e) => Worker.fromMap(e)).toList();
    journalEntries = journalMaps.map((e) => JournalEntry.fromMap(e)).toList();
    payments = paymentMaps.map((e) => Payment.fromMap(e)).toList();

    isLoading = false;
    notifyListeners();
  }

  // ---------------- Settings ----------------

  Future<void> setCurrencySymbol(String symbol) async {
    currencySymbol = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_symbol', symbol);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    notifyListeners();
  }

  Future<void> setDailyReminder(bool value) async {
    dailyReminder = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder', value);
    notifyListeners();
  }

  // ---------------- Workshops ----------------

  Workshop? workshopById(String id) {
    try {
      return workshops.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Finds a workshop by (case-insensitive) name, or creates a new one.
  Future<Workshop> findOrCreateWorkshopByName(String name,
      {String location = ''}) async {
    final trimmed = name.trim();
    final existing = workshops.firstWhere(
      (w) => w.name.trim().toLowerCase() == trimmed.toLowerCase(),
      orElse: () => Workshop(id: '', name: ''),
    );
    if (existing.id.isNotEmpty) return existing;

    final workshop = Workshop(id: _uuid.v4(), name: trimmed, location: location);
    final db = await _dbHelper.database;
    await db.insert('workshops', workshop.toMap());
    workshops.insert(0, workshop);
    notifyListeners();
    return workshop;
  }

  Future<void> addWorkshop(Workshop workshop) async {
    final db = await _dbHelper.database;
    await db.insert('workshops', workshop.toMap());
    workshops.insert(0, workshop);
    notifyListeners();
  }

  Future<void> updateWorkshop(Workshop workshop) async {
    final db = await _dbHelper.database;
    await db.update('workshops', workshop.toMap(),
        where: 'id = ?', whereArgs: [workshop.id]);
    final idx = workshops.indexWhere((w) => w.id == workshop.id);
    if (idx != -1) workshops[idx] = workshop;
    notifyListeners();
  }

  Future<void> deleteWorkshop(String id) async {
    final db = await _dbHelper.database;
    await db.delete('workshops', where: 'id = ?', whereArgs: [id]);
    workshops.removeWhere((w) => w.id == id);
    journalEntries.removeWhere((j) => j.workshopId == id);
    notifyListeners();
  }

  List<JournalEntry> entriesForWorkshop(String workshopId) =>
      journalEntries.where((j) => j.workshopId == workshopId).toList();

  int totalWorkDaysForWorkshop(String workshopId) =>
      entriesForWorkshop(workshopId).length;

  double totalCostForWorkshop(String workshopId) => entriesForWorkshop(workshopId)
      .fold(0.0, (sum, j) => sum + j.wage);

  DateTime? lastActivityForWorkshop(String workshopId) {
    final entries = entriesForWorkshop(workshopId);
    if (entries.isEmpty) return null;
    return entries
        .map((e) => e.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  // ---------------- Workers ----------------

  Worker? workerById(String id) {
    try {
      return workers.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addWorker(Worker worker) async {
    final db = await _dbHelper.database;
    await db.insert('workers', worker.toMap());
    workers.insert(0, worker);
    notifyListeners();
  }

  Future<void> updateWorker(Worker worker) async {
    final db = await _dbHelper.database;
    await db.update('workers', worker.toMap(),
        where: 'id = ?', whereArgs: [worker.id]);
    final idx = workers.indexWhere((w) => w.id == worker.id);
    if (idx != -1) workers[idx] = worker;
    notifyListeners();
  }

  Future<void> deleteWorker(String id) async {
    final db = await _dbHelper.database;
    await db.delete('workers', where: 'id = ?', whereArgs: [id]);
    workers.removeWhere((w) => w.id == id);
    journalEntries.removeWhere((j) => j.workerId == id);
    payments.removeWhere((p) => p.workerId == id);
    notifyListeners();
  }

  /// Finds a worker by (case-insensitive) name, or creates a new one.
  Future<Worker> findOrCreateWorkerByName(String name,
      {String profession = ''}) async {
    final trimmed = name.trim();
    final existing = workers.firstWhere(
      (w) => w.name.trim().toLowerCase() == trimmed.toLowerCase(),
      orElse: () => Worker(id: '', name: ''),
    );
    if (existing.id.isNotEmpty) return existing;

    final worker = Worker(id: _uuid.v4(), name: trimmed, profession: profession);
    final db = await _dbHelper.database;
    await db.insert('workers', worker.toMap());
    workers.insert(0, worker);
    notifyListeners();
    return worker;
  }

  List<JournalEntry> entriesForWorker(String workerId) =>
      journalEntries.where((j) => j.workerId == workerId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<Payment> paymentsForWorker(String workerId) =>
      payments.where((p) => p.workerId == workerId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  double totalJournalForWorker(String workerId) =>
      entriesForWorker(workerId).fold(0.0, (sum, j) => sum + j.wage);

  double totalPaymentsForWorker(String workerId) =>
      paymentsForWorker(workerId).fold(0.0, (sum, p) => sum + p.amount);

  /// Balance owed to worker = total wages earned - total paid out.
  double balanceForWorker(String workerId) =>
      totalJournalForWorker(workerId) - totalPaymentsForWorker(workerId);

  /// Combined, date-sorted transaction feed for a worker (journal + payments).
  List<_WorkerTransaction> transactionsForWorker(String workerId) {
    final list = <_WorkerTransaction>[];
    for (final j in entriesForWorker(workerId)) {
      list.add(_WorkerTransaction(
        date: j.date,
        isCredit: true,
        amount: j.wage,
        title: 'يومية عمل${j.notes.isNotEmpty ? ' - ${j.notes}' : ''}',
        subtitle: workshopById(j.workshopId)?.name ?? '',
        journalEntry: j,
      ));
    }
    for (final p in paymentsForWorker(workerId)) {
      list.add(_WorkerTransaction(
        date: p.date,
        isCredit: false,
        amount: p.amount,
        title: p.type.label,
        subtitle: p.notes,
        payment: p,
      ));
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ---------------- Journal Entries ----------------

  List<JournalEntry> entriesForDate(DateTime date) => journalEntries
      .where((j) =>
          j.date.year == date.year &&
          j.date.month == date.month &&
          j.date.day == date.day)
      .toList();

  Future<JournalEntry> addJournalEntry({
    required String workerName,
    required String workshopName,
    required double wage,
    String notes = '',
    DateTime? date,
    bool present = true,
  }) async {
    final worker = await findOrCreateWorkerByName(workerName);
    final workshop = await findOrCreateWorkshopByName(workshopName);

    final entry = JournalEntry(
      id: _uuid.v4(),
      workerId: worker.id,
      workshopId: workshop.id,
      date: date ?? DateTime.now(),
      wage: wage,
      notes: notes,
      present: present,
    );

    final db = await _dbHelper.database;
    await db.insert('journal_entries', entry.toMap());
    journalEntries.insert(0, entry);
    notifyListeners();
    return entry;
  }

  Future<void> deleteJournalEntry(String id) async {
    final db = await _dbHelper.database;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
    journalEntries.removeWhere((j) => j.id == id);
    notifyListeners();
  }

  // ---------------- Payments ----------------

  Future<Payment> addPayment({
    required String workerId,
    required double amount,
    PaymentType type = PaymentType.advance,
    String notes = '',
    DateTime? date,
  }) async {
    final payment = Payment(
      id: _uuid.v4(),
      workerId: workerId,
      date: date ?? DateTime.now(),
      amount: amount,
      type: type,
      notes: notes,
    );
    final db = await _dbHelper.database;
    await db.insert('payments', payment.toMap());
    payments.insert(0, payment);
    notifyListeners();
    return payment;
  }

  Future<void> deletePayment(String id) async {
    final db = await _dbHelper.database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
    payments.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // ---------------- Global stats ----------------

  double get totalOwedToAllWorkers =>
      workers.fold(0.0, (sum, w) => sum + balanceForWorker(w.id));

  double get totalWagesThisMonth {
    final now = DateTime.now();
    return journalEntries
        .where((j) => j.date.year == now.year && j.date.month == now.month)
        .fold(0.0, (sum, j) => sum + j.wage);
  }

  Future<void> wipeAllData() async {
    await _dbHelper.wipeAllData();
    await reloadAll();
  }
}

class _WorkerTransaction {
  final DateTime date;
  final bool isCredit; // true = wage earned (adds to balance), false = payment (subtracts)
  final double amount;
  final String title;
  final String subtitle;
  final JournalEntry? journalEntry;
  final Payment? payment;

  _WorkerTransaction({
    required this.date,
    required this.isCredit,
    required this.amount,
    required this.title,
    this.subtitle = '',
    this.journalEntry,
    this.payment,
  });
}

typedef WorkerTransaction = _WorkerTransaction;
