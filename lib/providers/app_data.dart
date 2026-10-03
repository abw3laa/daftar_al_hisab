import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../models/payment.dart';
import '../models/payroll_period.dart';
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
  List<PayrollPeriod> payrollPeriods = [];

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
    final payrollMaps = await db.query('payroll_periods', orderBy: 'year DESC, month DESC');

    workshops = workshopMaps.map((e) => Workshop.fromMap(e)).toList();
    workers = workerMaps.map((e) => Worker.fromMap(e)).toList();
    journalEntries = journalMaps.map((e) => JournalEntry.fromMap(e)).toList();
    payments = paymentMaps.map((e) => Payment.fromMap(e)).toList();
    payrollPeriods = payrollMaps.map((e) => PayrollPeriod.fromMap(e)).toList();
    final ledgerRows = await db.rawQuery('SELECT COUNT(*) AS count FROM account_transactions');
    final ledgerCount = (ledgerRows.first['count'] as num?)?.toInt() ?? 0;
    if (ledgerCount == 0 && (journalEntries.isNotEmpty || payments.isNotEmpty)) {
      await rebuildAccountingLedger();
    }

    isLoading = false;
    notifyListeners();
  }

  // ---------------- Payroll periods ----------------

  PayrollPeriod? payrollPeriodFor(DateTime date) {
    for (final p in payrollPeriods) {
      if (p.year == date.year && p.month == date.month) return p;
    }
    return null;
  }

  Future<PayrollPeriod> ensurePayrollPeriod(int year, int month) async {
    final existing = payrollPeriods.where((p) => p.year == year && p.month == month).firstOrNull;
    if (existing != null) return existing;
    final period = PayrollPeriod(id: _uuid.v4(), year: year, month: month);
    final db = await _dbHelper.database;
    await db.insert('payroll_periods', period.toMap());
    payrollPeriods.insert(0, period);
    notifyListeners();
    return period;
  }

  Future<void> closePayrollPeriod(PayrollPeriod period, {String notes = ''}) async {
    final db = await _dbHelper.database;
    period.status = 'closed';
    period.notes = notes;
    period.closedAt = DateTime.now();
    await db.update('payroll_periods', period.toMap(), where: 'id = ?', whereArgs: [period.id]);
    notifyListeners();
    _scheduleAutoBackup();
  }

  Future<void> reopenPayrollPeriod(PayrollPeriod period) async {
    final db = await _dbHelper.database;
    period.status = 'open';
    period.closedAt = null;
    await db.update('payroll_periods', period.toMap(), where: 'id = ?', whereArgs: [period.id]);
    notifyListeners();
    _scheduleAutoBackup();
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
        payrollPeriods: payrollPeriods,
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
      .fold(0.0, (sum, j) => sum + j.calculatedWage);

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
      entriesForWorker(workerId).fold(0.0, (sum, j) => sum + j.calculatedWage);

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
        amount: j.calculatedWage,
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
    double workFraction = 1.0,
    double overtimeHours = 0.0,
    double overtimeRate = 0.0,
    double deduction = 0.0,
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
      workFraction: workFraction,
      overtimeHours: overtimeHours,
      overtimeRate: overtimeRate,
      deduction: deduction,
      notes: notes,
      present: present,
    );

    final db = await _dbHelper.database;
    await db.insert('journal_entries', entry.toMap());
    await _upsertJournalLedger(entry);
    journalEntries.insert(0, entry);
    notifyListeners();
    _scheduleAutoBackup();
    return entry;
  }

  /// Throws when a journal/payment belongs to a closed payroll period.
  /// The check is synchronous because payrollPeriods is already kept in memory.
  void _ensurePeriodOpen(DateTime date) {
    final period = payrollPeriodFor(date);
    if (period?.isClosed ?? false) {
      throw StateError('لا يمكن تعديل حركة ضمن فترة محاسبية مغلقة: ${period!.label}');
    }
  }

  Future<void> updateJournalEntry(JournalEntry entry) async {\n    _ensurePeriodOpen(entry.date);
    final db = await _dbHelper.database;
    await db.update('journal_entries', entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
    await _upsertJournalLedger(entry);
    final index = journalEntries.indexWhere((j) => j.id == entry.id);
    if (index != -1) journalEntries[index] = entry;
    notifyListeners();
    _scheduleAutoBackup();
  }

  Future<void> deleteJournalEntry(String id) async {
    final db = await _dbHelper.database;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
    await _deleteLedgerReference('journal', id);
    journalEntries.removeWhere((j) => j.id == id);
    notifyListeners();
    _scheduleAutoBackup();
  }

  // ---------------- Accounting ledger ----------------

  Future<void> _upsertJournalLedger(JournalEntry entry) async {
    final db = await _dbHelper.database;
    final amount = entry.calculatedWage;
    final existing = await db.query('account_transactions', where: 'reference_type = ? AND reference_id = ?', whereArgs: ['journal', entry.id], limit: 1);
    final map = {
      'id': existing.isEmpty ? 'ledger-j-' + entry.id : existing.first['id'],
      'worker_id': entry.workerId, 'workshop_id': entry.workshopId, 'date': entry.date.toIso8601String(),
      'type': 'wage', 'description': entry.present ? 'أجر يومية' : 'غياب', 'debit': 0.0, 'credit': amount,
      'reference_type': 'journal', 'reference_id': entry.id, 'created_at': entry.createdAt.toIso8601String(),
    };
    if (existing.isEmpty) await db.insert('account_transactions', map);
    else await db.update('account_transactions', map, where: 'id = ?', whereArgs: [existing.first['id']]);
  }

  Future<void> _upsertPaymentLedger(Payment payment) async {
    final db = await _dbHelper.database;
    final existing = await db.query('account_transactions', where: 'reference_type = ? AND reference_id = ?', whereArgs: ['payment', payment.id], limit: 1);
    final map = {
      'id': existing.isEmpty ? 'ledger-p-' + payment.id : existing.first['id'], 'worker_id': payment.workerId,
      'date': payment.date.toIso8601String(), 'type': 'payment', 'description': payment.type.labelFor(language),
      'debit': payment.amount, 'credit': 0.0, 'reference_type': 'payment', 'reference_id': payment.id,
      'created_at': payment.createdAt.toIso8601String(),
    };
    if (existing.isEmpty) await db.insert('account_transactions', map);
    else await db.update('account_transactions', map, where: 'id = ?', whereArgs: [existing.first['id']]);
  }

  Future<void> _deleteLedgerReference(String type, String id) async {
    final db = await _dbHelper.database;
    await db.delete('account_transactions', where: 'reference_type = ? AND reference_id = ?', whereArgs: [type, id]);
  }

  Future<void> rebuildAccountingLedger() async {
    final db = await _dbHelper.database;
    await db.delete('account_transactions');
    for (final j in journalEntries) {
      await _upsertJournalLedger(j);
    }
    for (final p in payments) {
      await _upsertPaymentLedger(p);
    }
  }

  Future<List<Map<String, dynamic>>> ledgerForWorker(String workerId, {DateTime? from, DateTime? to}) async {
    final db = await _dbHelper.database;
    final clauses = <String>['worker_id = ?']; final args = <dynamic>[workerId];
    if (from != null) { clauses.add('date >= ?'); args.add(from.toIso8601String()); }
    if (to != null) { clauses.add('date < ?'); args.add(to.toIso8601String()); }
    return db.query('account_transactions', where: clauses.join(' AND '), whereArgs: args, orderBy: 'date ASC, created_at ASC');
  }

  Future<WorkerAccounting> accountingForWorker(String workerId, {DateTime? from, DateTime? to}) async {
    final rows = await ledgerForWorker(workerId, from: from, to: to); var credits = 0.0; var debits = 0.0;
    for (final row in rows) { credits += (row['credit'] as num? ?? 0).toDouble(); debits += (row['debit'] as num? ?? 0).toDouble(); }
    return WorkerAccounting(earned: credits, paid: debits, balance: credits - debits, transactions: rows);
  }

  Future<CompanyAccounting> companyAccounting({DateTime? from, DateTime? to}) async {
    final db = await _dbHelper.database; final clauses = <String>[]; final args = <dynamic>[];
    if (from != null) { clauses.add('date >= ?'); args.add(from.toIso8601String()); }
    if (to != null) { clauses.add('date < ?'); args.add(to.toIso8601String()); }
    final rows = await db.query('account_transactions', where: clauses.isEmpty ? null : clauses.join(' AND '), whereArgs: clauses.isEmpty ? null : args);
    var earned = 0.0; var paid = 0.0;
    for (final row in rows) { earned += (row['credit'] as num? ?? 0).toDouble(); paid += (row['debit'] as num? ?? 0).toDouble(); }
    return CompanyAccounting(totalWages: earned, totalPayments: paid, outstanding: earned - paid);
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
    await _upsertPaymentLedger(payment);
    payments.insert(0, payment);
    notifyListeners();
    _scheduleAutoBackup();
    return payment;
  }

  Future<void> updatePayment(Payment payment) async {
    _ensurePeriodOpen(payment.date);
    final db = await _dbHelper.database;
    await db.update('payments', payment.toMap(),
        where: 'id = ?', whereArgs: [payment.id]);
    await _upsertPaymentLedger(payment);
    final index = payments.indexWhere((p) => p.id == payment.id);
    if (index != -1) payments[index] = payment;
    notifyListeners();
    _scheduleAutoBackup();
  }

  Future<void> deletePayment(String id) async {
    final db = await _dbHelper.database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
    await _deleteLedgerReference('payment', id);
    payments.removeWhere((p) => p.id == id);
    notifyListeners();
    _scheduleAutoBackup();
  }

  // ---------------- Global stats ----------------

  double get totalOwedToAllWorkers => workers.fold(
      0.0,
      (sum, w) => sum +
          (balanceForWorker(w.id) > 0 ? balanceForWorker(w.id) : 0.0));

  double get totalWagesThisMonth {
    final now = DateTime.now();
    return journalEntries
        .where((j) => j.date.year == now.year && j.date.month == now.month)
        .fold(0.0, (sum, j) => sum + j.calculatedWage);
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
    for (final p in (json['payroll_periods'] as List<dynamic>? ?? [])) {
      batch.insert('payroll_periods', Map<String, dynamic>.from(p as Map));
    }
    await batch.commit(noResult: true);
    await reloadAll();
    await rebuildAccountingLedger();
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



class WorkerAccounting { final double earned; final double paid; final double balance; final List<Map<String, dynamic>> transactions; const WorkerAccounting({required this.earned, required this.paid, required this.balance, required this.transactions}); }
class CompanyAccounting { final double totalWages; final double totalPayments; final double outstanding; const CompanyAccounting({required this.totalWages, required this.totalPayments, required this.outstanding}); }
