import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/app_data.dart';
import 'screens/home_shell.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';
import 'widgets/whats_new_dialog.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DaftarAlHisabApp());
}

class DaftarAlHisabApp extends StatefulWidget {
  const DaftarAlHisabApp({super.key});

  @override
  State<DaftarAlHisabApp> createState() => _DaftarAlHisabAppState();
}

class _DaftarAlHisabAppState extends State<DaftarAlHisabApp> {
  late final AppData _appData;

  @override
  void initState() {
    super.initState();
    _appData = AppData();
    NotificationService.instance.init();
    _appData.init().then((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runStartupUpdateFlow();
      });
    });
  }

  Future<void> _runStartupUpdateFlow() async {
    if (!mounted) return;

    final update = await UpdateService.checkForUpdate();
    if (!mounted) return;

    if (update != null) {
      await UpdateDialog.show(context, update, _appData.language);
      if (!mounted) return;
    }

    await WhatsNewDialog.showIfNeeded(context, _appData.language);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppData>.value(
      value: _appData,
      child: Consumer<AppData>(
        builder: (context, appData, _) {
          return MaterialApp(
            title: AppLocalizations.t('app_name', appData.language),
            debugShowCheckedModeBanner: false,
            locale: Locale(appData.language.code),
            supportedLocales: const [Locale('ar'), Locale('en'), Locale('tr')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: appData.darkMode ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              return Directionality(
                textDirection: appData.language.textDirection,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: appData.isLoading
                ? const _SplashScreen()
                : const HomeShell(),
          );
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF091426),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 96,
                height: 96,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'دفتر الحساب',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
