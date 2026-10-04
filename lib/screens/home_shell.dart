import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../providers/app_data.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/restore_prompt_dialog.dart';
import '../widgets/update_dialog.dart';
import '../widgets/whats_new_dialog.dart';
import '../daftar_al_hisab_template/connected_accounts_screen.dart';
import 'about_screen.dart';
import 'backup_screen.dart';
import 'accounting_screen.dart';
import 'payroll_periods_screen.dart';
import 'dashboard_screen.dart';
import 'my_journal_tab.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'workers_screen.dart';
import 'workshops_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final data = context.read<AppData>();
      await RestorePromptDialog.showIfNeeded(context, data);
      if (!mounted) return;
      await WhatsNewDialog.showIfNeeded(context, data.language);
      final update = await UpdateService.checkForUpdate();
      if (update != null && mounted) {
        await UpdateDialog.show(context, update, data.language);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final isWorkerMode = data.usageMode == UsageMode.worker;

    final screens = isWorkerMode
        ? const [MyJournalTab(), WorkshopsScreen(), WorkersScreen()]
        : const [DashboardScreen(), WorkshopsScreen(), WorkersScreen()];

    final titles = [
      isWorkerMode ? data.t('nav_my_journal') : data.t('nav_journal'),
      data.t('nav_workshops'),
      data.t('nav_workers'),
    ];

    if (_index >= screens.length) _index = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index], style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const _AppDrawer(),
      body: IndexedStack(
        index: _index,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(height: 72,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: Icon(
                isWorkerMode ? Icons.badge_outlined : Icons.dashboard_outlined),
            selectedIcon: Icon(isWorkerMode ? Icons.badge : Icons.dashboard),
            label: titles[0],
          ),
          NavigationDestination(
            icon: const Icon(Icons.home_work_outlined),
            selectedIcon: const Icon(Icons.home_work),
            label: titles[1],
          ),
          NavigationDestination(
            icon: const Icon(Icons.group_outlined),
            selectedIcon: const Icon(Icons.group),
            label: titles[2],
          ),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.primary,
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    data.t('app_name'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text('المحاسبة'),
              subtitle: const Text('الأرصدة والحركات والالتزامات'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AccountingScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_tree_outlined),
              title: const Text('الحسابات الجديدة'),
              subtitle: const Text('واجهة حسابات مرتبطة بالبيانات الحالية'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectedTemplateAccountsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('فترات الحساب'),
              subtitle: const Text('فتح وإغلاق ومراجعة الفترات الشهرية'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollPeriodsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(data.t('drawer_reports')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(data.t('drawer_settings')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: Text(data.t('drawer_backup')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BackupScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(data.t('drawer_about')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()));
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '1.0.0';
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${data.t('app_version')} $version',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
