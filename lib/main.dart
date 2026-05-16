import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/dashboard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/services/notification_service.dart';
import 'firebase_options.dart';
import 'setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configured = await DynamicFirebaseOptions.isConfigured();

  if (configured) {
    final options = await DynamicFirebaseOptions.currentPlatform;
    await Firebase.initializeApp(options: options);
    final notificationService = NotificationService();
    await notificationService.init();
    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const MyApp(),
      ),
    );
  } else {
    runApp(const SetupApp());
  }
}

class SetupApp extends StatelessWidget {
  const SetupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agro Teching Setup',
      theme: ThemeData(colorSchemeSeed: Colors.green),
      home: SetupScreen(
        onSetupComplete: () async {
          final options = await DynamicFirebaseOptions.currentPlatform;
          await Firebase.initializeApp(options: options);
          runApp(
            ChangeNotifierProvider(
              create: (context) => ThemeProvider(),
              child: const MyApp(),
            ),
          );
        },
      ),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Agro Teching',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        textTheme: GoogleFonts.poppinsTextTheme(),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.green,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        brightness: Brightness.dark,
      ),
      themeMode: themeProvider.themeMode,
      home: const DashboardScreen(),
    );
  }
}
