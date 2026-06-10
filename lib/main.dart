import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'features/auth/screens/loading_screen.dart';
import 'core/services/history_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
final ValueNotifier<String> languageNotifier = ValueNotifier<String>('fr');
final ValueNotifier<String> currentSimulationModeNotifier = ValueNotifier<String>('normal');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await HistoryService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return ValueListenableBuilder<String>(
          valueListenable: languageNotifier,
          builder: (_, String currentLang, __) {
            return MaterialApp(
              title: 'Feedcom Digital Twin',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: currentMode,

              // 🚀 التعديل هنا: التطبيق يقلع دائماً من شاشة التحميل أولاً
              home: const LoadingScreen(), 
            );
          },
        );
      },
    );
  }
}