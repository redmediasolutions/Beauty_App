import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthStateNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;
  User? _user;

  bool get isInitialized => _isInitialized;
  User? get user => _user;

  late final StreamSubscription<User?> _subscription;

  AuthStateNotifier() {
    _subscription = _auth.authStateChanges().listen((user) {
      _user = user;
      _isInitialized = true;

      debugPrint("🔥 Auth changed: ${user?.uid}");

      notifyListeners(); // 🚨 critical
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}