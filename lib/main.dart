// ignore_for_file: non_constant_identifier_names, avoid_print

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'data/data_store.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';

void main(dynamic DefaultFirebaseOptions) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyAV3z3dM3YnW2srDjhh7vJBtcKnOEVlR9o",
        authDomain: "japs-db-49db6.firebaseapp.com",
        projectId: "japs-db-49db6",
        storageBucket: "japs-db-49db6.firebasestorage.app",
        messagingSenderId: "715922902130",
        appId: "1:715922902130:web:fef5b3dd32ba6bcb2486eb",
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const JapsApp());
}

// App Root Widget (JAPS App)
class JapsApp extends StatefulWidget {
  const JapsApp({super.key});

  @override
  State<JapsApp> createState() => _JapsAppState();
}

class _JapsAppState extends State<JapsApp> {
  final DataStore store = DataStore();
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    // 👈 Wrap MaterialApp inside DataScope so all routes can access 'store'
    return DataScope(
      store: store,
      child: AuthScope(
        authService: authService,
        child: MaterialApp(
          title: 'JAPS Transport',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.bg,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            fontFamily: 'Roboto',
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: AppColors.textDark),
            ),
          ),
          home: const LoginScreen(),
        ),
      ),
    );
  }
}

class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({super.key, required AuthService authService, required super.child})
      : super(notifier: authService);

  static AuthService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in context');
    return scope!.notifier!;
  }
}