import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../models/payment.dart';
import '../models/worker.dart';
import '../models/workshop.dart';
import '../services/backup_service.dart';
import '../services/cloud_backup_service.dart';
import '../services/notification_service.dart';

const _uuid = Uuid();

enum UsageMode { contractor, worker }

class AppData extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Worker> workers = [];
  List<Workshop> workshops = [];
  List<JournalEntry> journalEntries = [];
  List<Payment> payments = [];

  String currencySymbol = 'ل.ت';
  bool darkMode = false;
  bool dailyReminder = true;
  int reminderHour = 20;
  int reminderMinute = 0;
  AppLanguage language = AppLanguage.ar;
  UsageMode usageMode = UsageMode.contractor;
  String? myWorkerId;
  bool isLoading = true;

  bool autoCloudBackup = false;
  String? cloudAccountEmail;
  DateTime? lastCloudBackupAt;
  bool cloudBackupInProgress = false;
  Timer? _autoBackupDebounce;

  /// Convenience translation helper: `data.t('save')`.
  String t(String key) => AppLocalizations.t(key, language);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    currencySymbol = prefs.getString('currency_symbol') ?? 'ل.ت';
    darkMode = prefs.getBool('dark_mode') ?? false;
    dailyReminder = prefs.getBool('daily_reminder') ?? true;
    reminderHour = prefs.getInt('reminder_hour') ?? 20;
    reminderMinute = prefs.getInt('reminder_minute') ?? 0;
    language = AppLanguageX.fromCode(prefs.getString('language') ?? 'ar');
    usageMode = (prefs.getString('usage_mode') ?? 'contractor') == 'worker'
        ? UsageMode.worker
        : UsageMode.contractor;
    myWorkerId = prefs.getString('my_worker_id');
    autoCloudBackup = prefs.getBool('auto_cloud_backup') ?? false;
    final lastBackupIso = prefs.getString('last_cloud_backup_at');
    lastCloudBackupAt =
        lastBackupIso == null ? null : DateTime.tryParse(lastBackupIso);
    await reloadAll();

    if (dailyReminder) {
      await NotificationService.instance.scheduleDailyReminder(
        hour: reminderHour,
        minute: reminderMinute,
        language: language,
      );
    }

    // Silently restore a previous Google session (no UI) so cloud backup
    // status is accurate without the user having to sign in again.
    final account = await CloudBackupService.signInSilently();
    cloudAccountEmail = account?.email;
    notifyListeners();
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

  // ---------------- Cloud backup (Google Drive) ----------------

  bool get isCloudSignedIn => cloudAccountEmail != null;

  Future<bool> signInToCloud() async {
    final account = await CloudBackupService.signIn();
    cloudAccountEmail = account?.email;
    notifyListeners();
    return account != null;
  }

  Future<void> signOutFromCloud() async {
    await CloudBackupService.signOut();
    cloudAccountEmail = null;
    notifyListeners();
  }

  Future<void> setAutoCloudBackup(bool value) async {
    autoCloudBackup = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_cloud_backup', value);
    notifyListeners();
    if (value && isCloudSignedIn) {
      await backupNowToCloud();
    }
  }

  /// Uploads the current data to Google Drive right now (used by the manual
  /// "Backup now" button, and internally after every data change when auto
  /// backup is enabled).
  Future<bool> backupNowToCloud() async {
    if (!isCloudSignedIn) return false;
    cloudBackupInProgress = true;
    notifyListeners();
    try {
      final map = BackupService.buildBackupMap(
        workers: workers,
        workshops: workshops,
        journalEntries: journalEntries,
        payments: payments,
      );
      await CloudBackupService.uploadBackup(map);
      lastCloudBackupAt = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'last_cloud_backup_at', lastCloudBackupAt!.toIso8601String());
      return true;
    } catch (_) {
      return false;
    } finally {
      cloudBackupInProgress = false;
      notifyListeners();
    }
  }

  /// Downloads and applies the backup stored in the signed-in account's
  /// Google Drive, replacing all local data. Returns false if the account
  /// has no backup yet.
  Future<bool> restoreFromCloud() async {
    if (!isCloudSignedIn) return false;
    final json = await CloudBackupService.downloadBackup();
    if (json == null) return false;
    await importBackup(json);
    return true;
  }

  /// Schedules a debounced upload a few seconds after the most recent data
  /// change, so rapid successive edits don't each trigger a separate
  /// network upload.
  void _scheduleAutoBackup() {
    if (!autoCloudBackup || !isCloudSignedIn) return;
    _autoBackupDebounce?.cancel();
    _autoBackupDebounce = Timer(const Duration(seconds: 6), () {
      backupNowToCloud();
    });
  }

  @override
  void dispose() {
    _autoBackupDebounce?.cancel();
    super.dispose();
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

  Future<void> setLanguage(AppLanguage value) async {
    language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value.code);
    notifyListeners();
    if (dailyReminder) {
      await NotificationService.instance.scheduleDailyReminder(
        hour: reminderHour,
        minute: reminderMinute,
        language: language,
      );
    }
  }

  Future<void> setUsageMode(UsageMode value) async {
    usageMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usage_mode', value.name);
    notifyListeners();
  }

  Future<void> setMyWorkerId(String? id) async {
    myWorkerId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove('my_worker_id');
    } else {
      await prefs.setString('my_worker_id', id);
    }
    notifyListeners();
  }

  Future<void> setDailyReminder(bool value) async {
    dailyReminder = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder', value);
    notifyListeners();
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (granted) {
        await NotificationService.instance.scheduleDailyReminder(
          hour: reminderHour,
          minute: reminderMinute,
          language: language,
        );
      }
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }
  }

  Future<void> setReminderTime(int hour, int minute) async {
    reminderHour = hour;
    reminderMinute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', hour);
    await prefs.setInt('reminder_minute', minute);
    notifyListeners();
    if (dailyReminder) {
      await NotificationService.instance.scheduleDailyReminder(
        hour: hour,
        minute: minute,
        language: language,
      );
    }
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
    _scheduleAutoBackup();
    return workshop;
  }

  Future<void> addWorkshop(Workshop workshop) async {
    final db = await _dbHelper.database;
    await db.insert('workshops', workshop.toMap());
    workshops.insert(0, workshop);
    notifyListeners();
    _scheduleAutoBackup();
  }

  Future<void> updateWorkshop(Workshop workshop) async {
    final db = await _dbHelper.database;
    await db.update('workshops', workshop.toMap(),
        where: 'id = ?', whereArgs: [workshop.id]);
    final idx = workshops.indexWhere((w) => w.id == workshop.id);
    if (idx != -1) workshops[idx] = workshop;
    notifyListeners();
    _scheduleAutoBackup();
  }

  Future<void> deleteWorkshop(String id) async {
    final db = await _dbHelper.database;
    await db.delete('workshops', where: 'id = ?', whereArgs: [id]);
    workshops.removeWhere((w) => w.id == id);
    journalEntries.removeWhere((j) => j.workshopId == id);
    notifyListeners();
    _scheduleAutoBackup();
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
    _scheduleAutoBackup();
  }

  Future<void> updateWorker(Worker worker) async {
    final db = await _dbHelper.database;
    await db.update('workers', worker.toMap(),
        where: 'id = ?', whereArgs: [worker.id]);
    final idx = workers.indexWhere((w) => w.id == worker.id);
    if (idx != -1) workers[idx] = worker;
    notifyListeners();
    _scheduleAutoBackup();
  }

  Future<void> deleteWorker(String id) async {
    final db = await _dbHelper.database;
    await db.delete('workers', where: 'id = ?', whereArgs: [id]);
    workers.removeWhere((w) => w.id == id);
    journalEntries.removeWhere((j) => j.workerId == id);
    payments.removeWhere((p) => p.workerId == id);
    notifyListeners();
    _scheduleAutoBackup();
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
    _scheduleAutoBackup();
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
  List<WorkerTransaction> transactionsForWorker(String workerId) {
    final list = <WorkerTransaction>[];
    for (final j in entriesForWorker(workerId)) {
      final base = language == AppLanguage.ar
          ? 'يومية عمل'
          : language == AppLanguage.tr
              ? 'Çalışma günü'
              : 'Work day';
      list.add(WorkerTransaction(
        date: j.date,
        isCredit: true,
        amount: j.wage,
        title: '$base${j.notes.isNotEmpty ? ' - ${j.notes}' : ''}',
        subtitle: workshopById(j.workshopId)?.name ?? '',
        journalEntry: j,
      ));
    }
    for (final p in paymentsForWorker(workerId)) {
      list.add(WorkerTransaction(
        date: p.date,
        isCredit: false,
        amount: p.amount,
        title: p.type.labelFor(language),
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
    _scheduleAutoBackup();
    return entry;
  }

  Future<void> deleteJournalEntry(String id) async {
    final db = await _dbHelper.database;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
    journalEntries.removeWhere((j) => j.id == id);
    notifyListeners();
    _scheduleAutoBackup();
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
    _scheduleAutoBackup();
    return payment;
  }

  Future<void> deletePayment(String id) async {
    final db = await _dbHelper.database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
    payments.removeWhere((p) => p.id == id);
    notifyListeners();
    _scheduleAutoBackup();
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

  /// Replaces all local data with the contents of a previously exported
  /// backup (see BackupService.exportAndShare for the JSON shape).
  Future<void> importBackup(Map<String, dynamic> json) async {
    await _dbHelper.wipeAllData();
    final db = await _dbHelper.database;

    final batch = db.batch();
    for (final w in (json['workshops'] as List<dynamic>? ?? [])) {
      batch.insert('workshops', Map<String, dynamic>.from(w as Map));
    }
    for (final w in (json['workers'] as List<dynamic>? ?? [])) {
      batch.insert('workers', Map<String, dynamic>.from(w as Map));
    }
    for (final j in (json['journal_entries'] as List<dynamic>? ?? [])) {
      batch.insert('journal_entries', Map<String, dynamic>.from(j as Map));
    }
    for (final p in (json['payments'] as List<dynamic>? ?? [])) {
      batch.insert('payments', Map<String, dynamic>.from(p as Map));
    }
    await batch.commit(noResult: true);
    await reloadAll();
  }
}

class WorkerTransaction {
  final DateTime date;
  final bool isCredit; // true = wage earned (adds to balance), false = payment (subtracts)
  final double amount;
  final String title;
  final String subtitle;
  final JournalEntry? journalEntry;
  final Payment? payment;

  WorkerTransaction({
    required this.date,
    required this.isCredit,
    required this.amount,
    required this.title,
    this.subtitle = '',
    this.journalEntry,
    this.payment,
  });
}

