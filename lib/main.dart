import 'package:coretico_firebasenote/firebase_options.dart';
import 'package:coretico_firebasenote/home_page.dart';
import 'package:coretico_firebasenote/login.dart';
import 'package:coretico_firebasenote/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase CRUD Coretico',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If user is logged in, show HomePage
        if (snapshot.hasData && snapshot.data != null) {
          return const HomePage();
        }
        
        // If user is not logged in, show LoginPage
        return const LoginPage();
      },
    );
  }
}