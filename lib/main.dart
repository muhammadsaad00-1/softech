import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soft/settings_controller.dart';
import 'Login/initialpage.dart';
import 'app_settings.dart';
import 'firebase_options.dart';
import 'homeview.dart';
import 'auth/auth_view_model.dart'; // import your AuthViewModel
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'notes_home.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.loadSettings();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'scheduled_tasks',
        channelName: 'Task reminders',
        channelDescription: 'Notifications for upcoming tasks',
        importance: NotificationImportance.High,
      )
    ],
  );





  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  Gemini.init(apiKey: 'AIzaSyA6dbe8AUb3ouGB0csFwGEB8JZq-txFKCs');
  runApp(ChangeNotifierProvider(create: (context) => settings,  child: MyApp(isLoggedIn: isLoggedIn)));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()), // 💥 Added this line
      ],
      child: MaterialApp(
        theme: settings.lightTheme,
        darkTheme: settings.darkTheme,
        themeMode: settings.themeMode,
        debugShowCheckedModeBanner: false,
        home: isLoggedIn ? const HomeView(emotion: "normal",) : const InitialPage(),
      ),
    );
  }
}